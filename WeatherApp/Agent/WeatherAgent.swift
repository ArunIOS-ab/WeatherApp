//
//  WeatherAgent.swift
//  WeatherApp
//
//  The agent loop. Plans, dispatches tool calls, observes results, iterates,
//  and produces an answer. Backend-agnostic and safe to run off the main actor.
//

import Foundation

// MARK: - Conversation types

enum AgentRole: Sendable, Equatable {
    case user
    case agent
    /// A tool invocation shown inline in the transcript so the user can see the
    /// agent's work rather than just its conclusions.
    case toolCall(name: String, detail: String)
    case insight
}

struct AgentMessage: Identifiable, Sendable, Equatable {
    let id: UUID
    let role: AgentRole
    let text: String
    let timestamp: Date
    /// Reasoning trace, collapsed in the UI but available on demand.
    var reasoning: String?
    /// Whether this turn is still streaming or being produced.
    var isPending: Bool

    init(role: AgentRole,
         text: String,
         reasoning: String? = nil,
         isPending: Bool = false) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.timestamp = Date()
        self.reasoning = reasoning
        self.isPending = isPending
    }

    static func == (lhs: AgentMessage, rhs: AgentMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Agent errors

enum WeatherAgentError: LocalizedError {
    case noSnapshot
    case maxStepsExceeded
    case backendFailure(String)

    var errorDescription: String? {
        switch self {
        case .noSnapshot:
            return "Weather data isn't available for this location yet."
        case .maxStepsExceeded:
            return "The agent couldn't reach an answer and stopped."
        case .backendFailure(let reason):
            return "Reasoning backend failed: \(reason)"
        }
    }
}

// MARK: - Agent

/// Orchestrates the reason -> act -> observe loop.
///
/// Marked `@unchecked Sendable` via the actor below rather than being a class
/// with mutable state: conversation state lives in the `WeatherAgentActor`, so
/// the struct itself is immutable and trivially safe to hand across tasks.
struct WeatherAgent: Sendable {
    let registry: WeatherToolRegistry
    let backend: any AgentReasoningBackend
    let maxSteps: Int

    init(registry: WeatherToolRegistry,
         backend: any AgentReasoningBackend,
         maxSteps: Int = 6) {
        self.registry = registry
        self.backend = backend
        self.maxSteps = maxSteps
    }

    /// Default wiring: local heuristic reasoning over the standard tool set.
    static func standard(dataSource: any WeatherDataSource) -> WeatherAgent {
        WeatherAgent(registry: .standard(dataSource: dataSource),
                     backend: HeuristicReasoningBackend())
    }

    /// Runs one conversational turn to completion, streaming intermediate tool
    /// activity through `onActivity` so the UI can show the agent thinking.
    ///
    /// - Returns: the agent's final message plus the observations it produced.
    func respond(to userMessage: String,
                 intent: AgentIntent,
                 location: GeoLocation,
                 snapshot: WeatherSnapshot?,
                 transcript: [AgentMessage],
                 onActivity: @Sendable @escaping (AgentMessage) -> Void) async throws -> AgentTurnResult {

        guard snapshot != nil else { throw WeatherAgentError.noSnapshot }

        var observations: [ToolObservation] = []
        var reasoningTrace: [String] = []

        for _ in 0..<maxSteps {
            let prompt = AgentPrompt(userMessage: userMessage,
                                     intent: intent,
                                     location: location,
                                     observations: observations,
                                     snapshot: snapshot,
                                     transcript: transcript,
                                     availableTools: registry.all)

            let plan: AgentPlan
            do {
                plan = try await backend.reason(prompt)
            } catch {
                // A backend failure must not lose the conversation. Fall back to
                // the local planner rather than surfacing an error state.
                reasoningTrace.append("Falling back to on-device analysis.")
                let fallback = HeuristicReasoningBackend()
                guard let fallbackPlan = try? await fallback.reason(prompt) else {
                    throw WeatherAgentError.backendFailure(error.localizedDescription)
                }
                plan = fallbackPlan
            }

            if !plan.thought.isEmpty {
                reasoningTrace.append(plan.thought)
            }

            if let answer = plan.finalAnswer {
                let message = AgentMessage(role: .agent, text: answer,
                                           reasoning: reasoningTrace.joined(separator: " "))
                onActivity(message)
                return AgentTurnResult(message: message, observations: observations)
            }

            guard !plan.toolCalls.isEmpty else {
                let message = AgentMessage(
                    role: .agent,
                    text: "I couldn't work that out from the data I have.",
                    reasoning: reasoningTrace.joined(separator: " ")
                )
                onActivity(message)
                return AgentTurnResult(message: message, observations: observations)
            }

            // Dispatch. Independent calls run concurrently; a failing call
            // becomes an observation rather than aborting the turn, so the
            // agent can report partial success honestly.
            let results = await execute(plan.toolCalls)

            for (call, observation) in zip(plan.toolCalls, results) {
                observations.append(observation)
                onActivity(AgentMessage(role: .toolCall(name: call.tool, detail: describe(observation)),
                                          text: ""))
            }
        }

        throw WeatherAgentError.maxStepsExceeded
    }

    // MARK: Tool execution

    private func execute(_ calls: [PlannedToolCall]) async -> [ToolObservation] {
        await withTaskGroup(of: ToolObservation.self) { group in
            for call in calls {
                group.addTask {
                    do {
                        let tool = try self.registry.tool(named: call.tool)
                        let result = try await tool.run(arguments: call.arguments)
                        return ToolObservation(tool: call.tool, arguments: call.arguments, result: result)
                    } catch {
                        return ToolObservation(tool: call.tool, arguments: call.arguments,
                                               errorMessage: error.localizedDescription)
                    }
                }
            }

            var collected: [ToolObservation] = []
            for await observation in group {
                collected.append(observation)
            }
            return collected
        }
    }

    /// One-line rendering of a tool call for the transcript. Deliberately shows
    /// inputs as well as outcomes so the user can audit the agent.
    private func describe(_ observation: ToolObservation) -> String {
        let location = observation.arguments.string("location")
        let target = location.map { " \($0)" } ?? ""
        if let result = observation.result {
            return "\(observation.tool)(\(target)) → \(result.summary)"
        }
        return "\(observation.tool)(\(target)) → failed: \(observation.errorMessage ?? "unknown error")"
    }
}

// MARK: - Turn result

struct AgentTurnResult: Sendable {
    let message: AgentMessage
    let observations: [ToolObservation]
}

// MARK: - State holder

/// Thread-safe sink for the agent's streaming callbacks.
///
/// The `onActivity` closure is `@Sendable` and may fire from any task, so it
/// cannot capture a plain `var` array (that is a concurrency error under
/// Swift 6). A lock-guarded reference type keeps the call site simple and
/// stays correct under concurrent tool dispatch.
final class ActivityCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [AgentMessage] = []

    func append(_ message: AgentMessage) {
        lock.lock()
        storage.append(message)
        lock.unlock()
    }

    var messages: [AgentMessage] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

/// Owns the conversation and the insight feed. Isolated as an actor so the
/// agent loop and any background refresh cannot race the UI.
actor WeatherAgentActor {
    private let agent: WeatherAgent
    private let dataSource: any WeatherDataSource

    private(set) var messages: [AgentMessage] = []
    private(set) var insights: [AgentInsight] = []
    private var transcript: [AgentMessage] = []

    init(agent: WeatherAgent, dataSource: any WeatherDataSource) {
        self.agent = agent
        self.dataSource = dataSource
    }

    var messageList: [AgentMessage] { messages }

    func send(_ text: String, location: GeoLocation, snapshot: WeatherSnapshot?) async throws {
        let userMessage = AgentMessage(role: .user, text: text)
        messages.append(userMessage)
        transcript.append(userMessage)

        let intent = IntentClassifier.classify(text)

        // Tool activity is collected into a Sendable box rather than hopping to
        // the actor from inside the callback. Hopping there would let tool
        // messages race the final answer, so the transcript could show the
        // reply above the tool calls that produced it.
        let collector = ActivityCollector()

        do {
            let result = try await agent.respond(
                to: text,
                intent: intent,
                location: location,
                snapshot: snapshot,
                transcript: transcript
            ) { event in
                collector.append(event)
            }

            // Commit atomically: tool calls first, then the answer they
            // produced. There is no pending placeholder to clean up, so there
            // is no path that can strand a spinner on screen.
            messages.append(contentsOf: collector.messages.filter { Self.isToolCall($0) })
            messages.append(result.message)
            transcript.append(result.message)

        } catch {
            // Replace the user's turn with a readable failure. Appending a
            // partial transcript here would leave the user looking at their own
            // question with no reply.
            messages.append(AgentMessage(
                role: .agent,
                text: (error as? WeatherAgentError)?.errorDescription
                    ?? error.localizedDescription,
                reasoning: nil
            ))
            throw error
        }
    }

    private static func isToolCall(_ message: AgentMessage) -> Bool {
        if case .toolCall = message.role { return true }
        return false
    }

    /// Regenerates proactive insights from the latest snapshot. Called whenever
    /// weather data refreshes, not just on user action.
    func refreshInsights(location: GeoLocation, snapshot: WeatherSnapshot) {
        insights = InsightGenerator.generate(for: snapshot, location: location)
    }
}

// MARK: - Agent insights

enum InsightKind: Sendable {
    case timing
    case warning
    case preparation
    case comfort

    var symbolName: String {
        switch self {
        case .timing: return "clock.badge.exclamationmark"
        case .warning: return "exclamationmark.triangle.fill"
        case .preparation: return "umbrella.fill"
        case .comfort: return "figure.run"
        }
    }

    var tint: String {
        switch self {
        case .timing: return "Bluegray700"
        case .warning: return "Red400"
        case .preparation: return "IndigoA400"
        case .comfort: return "Bluegray900"
        }
    }
}

/// A proactive recommendation surfaced on the dashboard without the user asking.
struct AgentInsight: Identifiable, Sendable, Equatable {
    let id: UUID
    let kind: InsightKind
    let title: String
    let detail: String
    /// Higher sorts first.
    let priority: Int
    let createdAt: Date

    init(kind: InsightKind, title: String, detail: String, priority: Int) {
        self.id = UUID()
        self.kind = kind
        self.title = title
        self.detail = detail
        self.priority = priority
        self.createdAt = Date()
    }

    static func == (lhs: AgentInsight, rhs: AgentInsight) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Insight generation

/// Derives dashboard insights from a snapshot. This runs without any model —
/// proactive hints should be available instantly and offline, not gated on a
/// network round trip.
enum InsightGenerator {

    static func generate(for snapshot: WeatherSnapshot, location: GeoLocation) -> [AgentInsight] {
        var results: [AgentInsight] = []
        let current = snapshot.current
        let assessment = ComfortAssessment.assess(snapshot)

        // Imminent rain: the highest-value proactive insight, because it is
        // actionable in a way the user cannot see from a static chart.
        if let rainSoon = firstWettingHour(in: snapshot, withinHours: 2) {
            // Match the wording to what is actually falling.
            let kind = precipitationKind(for: snapshot, hour: rainSoon)
            let minutes = Int(rainSoon.date.timeIntervalSinceNow / 60)
            let when: String
            if minutes <= 0 {
                when = "in the next few minutes"
            } else if minutes < 60 {
                when = "in about \(minutes) minutes"
            } else {
                when = "in about \(minutes / 60) hour\(minutes / 60 == 1 ? "" : "s")"
            }

            let isSnow = kind == "snow"
            let advice = isSnow
                ? "Allow extra time and wear something water-resistant."
                : "Take an umbrella or leave a few extra minutes."

            results.append(AgentInsight(
                kind: isSnow ? .warning : .preparation,
                title: "\(kind.capitalized) expected \(when)",
                detail: "Precipitation probability climbs to \(rainSoon.precipChance)% "
                    + "around \(rainSoon.date.formatted(.dateTime.hour().minute())). "
                    + advice,
                priority: 100
            ))
        }

        // Strong wind, framed around the next calendar hour rather than all day,
        // so it stays actionable.
        let nextHours = snapshot.hourly.prefix(3)
        let peakWind = max(current.windKph, nextHours.map(\.windKph).max() ?? 0)
        if peakWind >= 35 {
            results.append(AgentInsight(
                kind: .warning,
                title: "Windy in the next few hours",
                detail: "Gusts reach \(peakWind.formatted(.number.precision(.fractionLength(0)))) kph. "
                    + "Bicycles and lightweight umbrellas will be awkward; loose items need securing.",
                priority: 80
            ))
        }

        // Cold enough that waiting helps: find the warmest part of today.
        if current.apparentTempC < 4, let warmest = bestOutdoorHour(in: snapshot) {
            results.append(AgentInsight(
                kind: .timing,
                title: "Delay your trip until \(warmest.date.formatted(.dateTime.hour().minute()))",
                detail: "It is \(current.apparentTempC.formatted(.number.precision(.fractionLength(0))))°C "
                    + "feels-like now, improving to "
                    + "\(warmest.tempC.formatted(.number.precision(.fractionLength(0))))°C mid-day.",
                priority: 70
            ))
        }

        // Storms take priority over comfort suggestions.
        if let alert = snapshot.alerts.first {
            results.append(AgentInsight(
                kind: .warning,
                title: alert.headline,
                detail: alert.detail,
                priority: 95
            ))
        }

        // Only offer exercise guidance when it is actually informative, rather
        // than on every refresh.
        if assessment.exerciseScore < 0.45 {
            results.append(AgentInsight(
                kind: .comfort,
                title: "Poor conditions for a run",
                detail: "Rain risk, wind and cold combine to make this a \(assessment.comfortLabel.lowercased()) "
                    + "window. An indoor session or a later start would be better.",
                priority: 50
            ))
        } else if assessment.exerciseScore >= 0.75 {
            let best = bestOutdoorHour(in: snapshot)
            results.append(AgentInsight(
                kind: .comfort,
                title: "Great conditions for a run",
                detail: best.map {
                    "\($0.date.formatted(.dateTime.hour().minute())) looks best — "
                    + "\($0.tempC.formatted(.number.precision(.fractionLength(0))))°C, "
                    + "\($0.windKph.formatted(.number.precision(.fractionLength(0)))) kph wind."
                } ?? "Light wind and a low rain chance right through the next few hours.",
                priority: 40
            ))
        }

        // Heat and UV advice, combined since they share a mitigation: sunscreen
        // and shade handle both.
        if assessment.heatStress > 0.35 || assessment.uvStress > 0.4 {
            var parts: [String] = []
            if let peakUV = snapshot.hourly.prefix(12).map(\.uvIndex).max(), peakUV >= 7 {
                parts.append("UV peaks at \(peakUV.formatted(.number.precision(.fractionLength(1))))")
            }
            if assessment.heatStress > 0.35 {
                parts.append("humidity will make it feel hotter as you warm up")
            }

            results.append(AgentInsight(
                kind: .warning,
                title: "Sun protection needed",
                detail: (parts.isEmpty ? "Conditions are harsh around midday." : parts.joined(separator: ", ") + ".")
                    + " Use sunscreen and seek shade around midday.",
                priority: 45
            ))
        }

        return results.sorted { $0.priority > $1.priority }
    }

    /// Describes what is actually falling, so the insight card does not say
    /// "rain expected" during a snowstorm.
    private static func precipitationKind(for snapshot: WeatherSnapshot, hour: HourlyForecast) -> String {
        let condition = hour.conditionText.lowercased()
        let freezing = hour.tempC <= 1.0 || snapshot.current.tempC <= 1.0

        if condition.contains("snow") || condition.contains("sleet") || condition.contains("blizzard") {
            return "snow"
        }
        if condition.contains("ice") || condition.contains("freezing") { return "freezing rain" }
        if condition.contains("thunder") { return "thunderstorms" }
        if condition.contains("drizzle") { return "drizzle" }
        return freezing ? "freezing rain" : "rain"
    }

    /// First hour within the window where rain becomes likely enough to act on.
    /// Uses an 8 percentage-point hysteresis so a single blip does not trigger
    /// an "imminent rain" card.
    private static func firstWettingHour(in snapshot: WeatherSnapshot, withinHours hours: Int) -> HourlyForecast? {
        let threshold = 45
        return snapshot.hourly.prefix(hours).first { hour in
            hour.date >= Date().addingTimeInterval(-900) && hour.precipChance >= threshold
        }
    }

    /// The hour with the best combined conditions, used for timing advice.
    private static func bestOutdoorHour(in snapshot: WeatherSnapshot) -> HourlyForecast? {
        let candidates = snapshot.hourly.prefix(12)
            .filter { $0.isDay && $0.date >= Date() }
        guard !candidates.isEmpty else { return nil }

        return candidates.max { lhs, rhs in
            score(lhs) < score(rhs)
        }
    }

    private static func score(_ hour: HourlyForecast) -> Double {
        let rain = Double(hour.precipChance) / 100.0
        let wind = hour.windKph / 50.0
        // Mild temperature is ideal; both directions degrade.
        let deviation = abs(hour.feelsLikeC - 16) / 14.0
        return 1.0 - (rain * 1.5 + wind + min(deviation, 1.0) * 0.6)
    }
}
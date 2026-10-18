//
//  WeatherReasoningBackend.swift
//  WeatherApp
//
//  The reasoning layer. `AgentReasoningBackend` is the seam between the agent's
//  tool-calling loop and whichever model is doing the thinking, so the same
//  agent loop works with local heuristics or an on-device LLM.
//

import Foundation

// MARK: - Intent

/// What the user is actually asking for. Detected up front by the planner and
/// used to pick a tool chain, choose which factors to weigh, and shape the tone
/// of the reply.
enum AgentIntent: String, Sendable, CaseIterable {
    case outdoorActivity
    case packing
    case currentConditions
    case futureForecast
    case weatherTiming
    case travelCommute
    case alerts
    case general

    /// Whether this intent needs more than one tool call to answer well.
    var benefitsFromChaining: Bool {
        switch self {
        case .outdoorActivity, .packing, .weatherTiming, .travelCommute:
            return true
        case .currentConditions, .futureForecast, .alerts, .general:
            return false
        }
    }
}

// MARK: - Plans

/// One requested tool invocation.
struct PlannedToolCall: Sendable, Equatable {
    let tool: String
    let arguments: ToolArguments
    /// Provider-assigned call id, when the call originated from a model.
    /// Carried through to the observation so the result can be paired with it.
    let toolCallID: String?
    /// The arguments as the model wrote them.
    let rawArguments: String?

    init(tool: String,
         arguments: ToolArguments,
         toolCallID: String? = nil,
         rawArguments: String? = nil) {
        self.tool = tool
        self.arguments = arguments
        self.toolCallID = toolCallID
        self.rawArguments = rawArguments
    }

    static func == (lhs: PlannedToolCall, rhs: PlannedToolCall) -> Bool {
        lhs.tool == rhs.tool
    }
}

/// What the backend decided to do for one turn: think, act, or answer.
struct AgentPlan: Sendable {
    /// Visible reasoning, surfaced in the UI as "thinking" text.
    var thought: String = ""
    var toolCalls: [PlannedToolCall] = []
    /// Set when the backend can answer without further tool calls.
    var finalAnswer: String?

    var isTerminal: Bool { finalAnswer != nil }
}

/// Everything the backend sees when deciding what to do.
struct AgentPrompt: Sendable {
    let userMessage: String
    let intent: AgentIntent
    let location: GeoLocation
    /// Results of tool calls already executed this turn.
    let observations: [ToolObservation]
    /// Direct access to the snapshot for grounded reasoning.
    let snapshot: WeatherSnapshot?
    /// Short history for conversational context.
    let transcript: [AgentMessage]
    /// Tools this backend may call. Supplied by the agent loop so a model
    /// backend can advertise its full function-calling surface.
    let availableTools: [any WeatherTool]
}

/// A completed tool call plus its result or error.
struct ToolObservation: Sendable, Identifiable {
    let id: UUID
    let tool: String
    let arguments: ToolArguments
    let result: ToolResult?
    let errorMessage: String?

    /// The model's own id for this call, when a backend issued it.
    ///
    /// Must be echoed back in the following request: OpenAI-compatible APIs pair
    /// each `tool` message with the assistant `tool_calls` entry that carries
    /// the same id. Inventing an id here breaks the pairing and the API rejects
    /// the turn.
    let toolCallID: String?

    /// The arguments exactly as the model wrote them, for replay. Re-serialising
    /// `ToolArguments` can reorder or normalise the JSON, which need not match
    /// what the model emitted.
    let rawArguments: String?

    init(tool: String,
         arguments: ToolArguments,
         result: ToolResult? = nil,
         errorMessage: String? = nil,
         toolCallID: String? = nil,
         rawArguments: String? = nil) {
        self.id = UUID()
        self.tool = tool
        self.arguments = arguments
        self.result = result
        self.errorMessage = errorMessage
        self.toolCallID = toolCallID
        self.rawArguments = rawArguments
    }

    var succeeded: Bool { result != nil }
}

// MARK: - Backend protocol

protocol AgentReasoningBackend: Sendable {
    /// Human-readable label shown in the UI so the user knows what is thinking.
    var displayName: String { get }

    /// Decides the next step given the prompt. May return a terminal answer or
    /// request tool calls; the agent loop handles re-entry.
    func reason(_ prompt: AgentPrompt) async throws -> AgentPlan
}

// MARK: - Heuristic backend

/// A fully local, deterministic planner. No network, no model, works on every
/// device and every deployment target. This is the default so the agent is
/// functional out of the box; it is also the fallback when a model backend
/// fails or is unavailable.
struct HeuristicReasoningBackend: AgentReasoningBackend {
    let displayName = "On-device analysis"

    func reason(_ prompt: AgentPrompt) async throws -> AgentPlan {
        // Once tools have run, we have everything needed to answer. The local
        // planner never needs a second round trip.
        if !prompt.observations.isEmpty {
            return AgentPlan(thought: "Composing the answer from retrieved conditions.",
                             toolCalls: [],
                             finalAnswer: compose(prompt))
        }

        let calls = planCalls(for: prompt)

        guard !calls.isEmpty else {
            // Nothing to fetch. If we have a snapshot we can still ground the
            // reply in it rather than shrugging.
            return AgentPlan(thought: "Answering from the current snapshot.",
                             toolCalls: [],
                             finalAnswer: prompt.snapshot.map { _ in compose(prompt) }
                                ?? "I don't have conditions for \(prompt.location.fullName) right now.")
        }

        return AgentPlan(thought: explainPlan(calls, for: prompt.intent), toolCalls: calls)
    }

    // MARK: Planning

    private func planCalls(for prompt: AgentPrompt) -> [PlannedToolCall] {
        let location = prompt.location.fullName

        switch prompt.intent {
        case .outdoorActivity:
            // Chained: hourly window for the near-term, current conditions to
            // confirm, daily range for the wider outlook.
            return [
                PlannedToolCall(tool: "getHourlyWindow",
                                arguments: ToolArguments(["location": .string(location), "hours": .number(6)])),
                PlannedToolCall(tool: "fetchCurrentWeather",
                                arguments: ToolArguments(["location": .string(location)]))
            ]

        case .packing:
            return [PlannedToolCall(tool: "calculateClothingLayers",
                                    arguments: ToolArguments(["location": .string(location), "days": .number(3)]))]

        case .weatherTiming:
            return [PlannedToolCall(tool: "getHourlyWindow",
                                    arguments: ToolArguments(["location": .string(location), "hours": .number(12)]))]

        case .travelCommute:
            // Chain the forecast with the calendar so the agent can time the
            // departure against the user's actual commitments. The calendar call
            // is what makes the "schedule" claim true — without it this branch
            // was no different from a plain forecast question.
            return [
                PlannedToolCall(tool: "getHourlyWindow",
                                arguments: ToolArguments(["location": .string(location), "hours": .number(6)])),
                PlannedToolCall(tool: "getCalendarSchedule",
                                arguments: ToolArguments(["hoursAhead": .number(12)]))
            ]

        case .currentConditions:
            return [PlannedToolCall(tool: "fetchCurrentWeather",
                                    arguments: ToolArguments(["location": .string(location)]))]

        case .futureForecast, .alerts, .general:
            return [PlannedToolCall(tool: "getForecastRange",
                                    arguments: ToolArguments(["location": .string(location), "days": .number(5)]))]
        }
    }

    private func explainPlan(_ calls: [PlannedToolCall], for intent: AgentIntent) -> String {
        let names = calls.map(\.tool).joined(separator: " and ")
        switch intent {
        case .outdoorActivity:
            return "Checking the next few hours of wind, rain and temperature before judging the run."
        case .packing:
            return "Working out the temperature range and worst-case precipitation for the trip."
        case .travelCommute:
            return "Checking when conditions deteriorate against your schedule."
        case .weatherTiming:
            return "Looking hour by hour to find the best window."
        default:
            return "Fetching conditions with \(names)."
        }
    }

    // MARK: Composition

    /// Builds the reply. Prefers real tool output where available and falls
    /// back to the snapshot, so a failed tool degrades rather than leaves the
    /// user with nothing.
    private func compose(_ prompt: AgentPrompt) -> String {
        let successful = prompt.observations.filter(\.succeeded)
        let failures = prompt.observations.filter { !$0.succeeded }

        var sections: [String] = []

        for observation in successful {
            if let text = responseText(for: observation, prompt: prompt) {
                sections.append(text)
            }
        }

        if sections.isEmpty, let snapshot = prompt.snapshot {
            sections.append(composeFromSnapshot(snapshot, intent: prompt.intent))
        }

        // If a tool failed, say so plainly. Silently dropping a failed call is
        // how an agent ends up confidently answering with partial information.
        if !failures.isEmpty {
            let names = failures.map(\.tool).joined(separator: ", ")
            sections.append("I couldn't reach \(names) — this answer uses what's already cached.")
        }

        return sections.joined(separator: "\n\n")
    }

    /// Folds the user's calendar into a commute answer.
    ///
    /// Without this the calendar tool's output was fetched and discarded, so the
    /// commute branch advertised a schedule check it never performed. Returns
    /// nil when there is nothing to say, letting the weather section stand alone.
    private func calendarContext(_ prompt: AgentPrompt) -> String? {
        guard let observation = prompt.observations.first(where: { $0.tool == "getCalendarSchedule" }),
              let summary = observation.result?.summary
        else { return nil }

        // The tool reports its own "nothing scheduled" case; do not restate it.
        guard !summary.lowercased().contains("nothing on your calendar") else {
            return "You don't have anything scheduled in the next few hours, so there's no fixed "
                + "departure time to work around."
        }
        return "Against your calendar — \(summary)"
    }

    private func responseText(for observation: ToolObservation, prompt: AgentPrompt) -> String? {
        switch observation.tool {
        case "fetchCurrentWeather":
            return snapshotVerdict(prompt)

        case "calculateClothingLayers":
            return observation.result?.summary

        case "getHourlyWindow":
            return hourlyVerdict(prompt)

        case "getForecastRange":
            return snapshotVerdict(prompt)

        case "getCalendarSchedule":
            return calendarContext(prompt)

        default:
            return observation.result?.summary
        }
    }

    /// The core answer for "should I go out" style questions, grounded in the
    /// comfort model rather than a single threshold.
    private func snapshotVerdict(_ prompt: AgentPrompt) -> String? {
        guard let snapshot = prompt.snapshot else { return nil }
        let assessment = ComfortAssessment.assess(snapshot)
        let current = snapshot.current

        guard prompt.intent == .outdoorActivity else {
            return observationSummaryForForecast(prompt)
        }

        var parts: [String] = []
        let headline: String
        switch assessment.exerciseScore {
        case 0.75...: headline = "Yes, this is a good day for it."
        case 0.55..<0.75: headline = "Generally yes, with a couple of caveats."
        case 0.35..<0.55: headline = "It's borderline — conditions are workable but not pleasant."
        case 0.15..<0.35: headline = "I'd skip it or move it indoors."
        default: headline = "No — conditions are genuinely bad for this."
        }
        parts.append(headline)

        // Built by concatenation rather than a multi-line literal: source line
        // breaks inside an interpolation are emitted verbatim and shred the
        // sentence across lines.
        let temp = current.tempC.formatted(.number.precision(.fractionLength(0)))
        let feels = current.apparentTempC.formatted(.number.precision(.fractionLength(0)))
        let wind = current.windKph.formatted(.number.precision(.fractionLength(0)))
        let uv = current.uvIndex.formatted(.number.precision(.fractionLength(1)))

        parts.append("Right now \(temp)°C (feels like \(feels)°C), "
            + "\(current.conditionText), wind \(wind) kph, UV \(uv). "
            + "Overall that's \(assessment.comfortLabel.lowercased()) for sustained exercise.")

        // Reasons, ordered by how much they actually matter for exertion.
        var concerns: [String] = []
        if assessment.precipitationRisk > 0.35 {
            concerns.append("\(precipitationNoun(for: snapshot)) is likely in the next few hours")
        }
        if assessment.windStress > 0.4 {
            concerns.append("the wind is strong enough to affect balance and pace")
        }
        if assessment.coldStress > 0.4 {
            concerns.append("the wind chill makes exposed skin painful past about \(String(Int(current.apparentTempC.rounded())))°")
        }
        if assessment.heatStress > 0.4 {
            concerns.append("heat and humidity will pile up as you warm up")
        }
        if assessment.uvStress > 0.4 {
            concerns.append("UV is high enough to burn without protection")
        }

        if concerns.isEmpty {
            parts.append("Nothing stands out as a problem right now — no meaningful "
                + "precipitation, wind or temperature stress in the next few hours.")
            // Be explicit about a later spike. Saying "no precipitation stress"
            // without qualification while 90% rain is forecast later reads as
            // the agent missing it.
            let later = snapshot.hourly.dropFirst(3).prefix(9)
            if let worst = later.max(by: { $0.precipChance < $1.precipChance }),
               worst.precipChance >= 50 {
                let when = snapshot.hourMinute(worst.date)
                let kind = precipitationNoun(for: snapshot, hour: worst)
                parts.append("That said, \(kind) risk climbs to \(worst.precipChance)% "
                    + "around \(when), so it is not uniformly clear.")
            }
        } else {
            parts.append("Watch out: " + concerns.joined(separator: ", ") + ".")

            // Only offer advice that maps to a specific detected problem.
            var advice: [String] = []
            let precip = precipitationNoun(for: snapshot)
            let freezingPrecip = precip == "snow" || precip == "freezing rain"

            if assessment.precipitationRisk > 0.35 {
                advice.append(freezingPrecip
                              ? "wear something water-resistant rather than an umbrella"
                              : "take a light shell")
            }
            if assessment.coldStress > 0.4 {
                advice.append("cover your extremities and skip cotton")
                // Below about -5C wind chill, exposed skin is a real injury risk
                // rather than just discomfort, and that deserves saying outright.
                if current.apparentTempC <= -5 {
                    advice.append("keep covered skin off the wind — frostbite risk, not just discomfort")
                }
            }
            if assessment.heatStress > 0.4 { advice.append("slow your pace and carry water") }
            if assessment.uvStress > 0.4 { advice.append("use sunscreen even under cloud") }
            if assessment.windStress > 0.4 { advice.append("facing into the wind on the way out will feel harder") }
            if !advice.isEmpty {
                parts.append("So: " + advice.joined(separator: ", ") + ".")
            }
        }

        return parts.joined(separator: "\n\n")
    }

    private func observationSummaryForForecast(_ prompt: AgentPrompt) -> String? {
        prompt.observations.first(where: { $0.tool == "getForecastRange" })?.result?.summary
    }

    /// Finds the calmest, driest window rather than just reporting the list.
    private func hourlyVerdict(_ prompt: AgentPrompt) -> String? {
        guard let snapshot = prompt.snapshot,
              let window = prompt.observations.first(where: { $0.tool == "getHourlyWindow" }),
              window.succeeded,
              window.result != nil
        else { return nil }

        let scored = snapshot.hourly.prefix(12).map { hour in
            let rainPenalty = Double(hour.precipChance) / 100.0 * 2.0
            let windPenalty = hour.windKph / 40.0
            let coldPenalty = hour.feelsLikeC < 8 ? Double(8 - hour.feelsLikeC) / 10.0 : 0
            let heatPenalty = hour.feelsLikeC > 27 ? Double(hour.feelsLikeC - 27) / 10.0 : 0
            let comfort = max(0, 1 - (rainPenalty + windPenalty + coldPenalty + heatPenalty))
            return (hour, comfort)
        }

        guard let best = scored.max(by: { $0.1 < $1.1 }), best.1 > 0.4 else {
            return "Looking at the next 12 hours for \(snapshot.location.fullName), "
                + "there isn't a stretch that stands out as comfortable — "
                + "it's unsettled throughout."
        }

        let start = snapshot.hourMinute(best.0.date)
        let end = snapshot.hourMinute(best.0.date.addingTimeInterval(3600))

        let temp = best.0.tempC.formatted(.number.precision(.fractionLength(0)))
        let wind = best.0.windKph.formatted(.number.precision(.fractionLength(0)))
        let kind = precipitationNoun(for: snapshot, hour: best.0)

        var answer = "The best window in the next 12 hours for \(snapshot.location.fullName) is "
            + "roughly \(start)–\(end), around \(temp)°C with "
            + "\(best.0.precipChance)% chance of \(kind) and \(wind) kph wind."

        // Calling out the worst hour matters even when the best hour is calm:
        // "0% chance of rain" alone would hide rain arriving an hour later, and
        // the user plans a whole outing, not one hour.
        let upcoming = snapshot.hourly.prefix(12)
        if let worst = upcoming.max(by: { $0.precipChance < $1.precipChance }),
           worst.precipChance >= 40,
           worst.precipChance > best.0.precipChance + 15 {
            let worstTime = snapshot.hourMinute(worst.date)
            let worstKind = precipitationNoun(for: snapshot, hour: worst)
            answer += " Note that \(worstKind) risk climbs to \(worst.precipChance)% "
                + "around \(worstTime), so plan to be inside by then."
        }

        return answer
    }

    /// Picks the right word for what is actually falling. Saying "rain" when it
    /// is snowing is the kind of detail that makes an assistant sound careless.
    /// Below-freezing conditions imply frozen precipitation, which changes both
    /// the wording and the practical advice.
    private func precipitationNoun(for snapshot: WeatherSnapshot, hour: HourlyForecast? = nil) -> String {
        // Prefer the forecast hour being talked about, falling back to current
        // conditions, then to the temperature alone.
        let condition = (hour?.conditionText ?? snapshot.current.conditionText).lowercased()
        let temp = hour?.tempC ?? snapshot.current.tempC
        let freezing = temp <= 1.0 || snapshot.current.tempC <= 1.0

        if condition.contains("snow") || condition.contains("sleet") || condition.contains("blizzard") {
            return "snow"
        }
        if condition.contains("ice") || condition.contains("freezing") { return "freezing rain" }
        if condition.contains("thunder") { return "thunderstorms" }
        if condition.contains("drizzle") { return "drizzle" }
        if condition.contains("rain") { return freezing ? "freezing rain" : "rain" }
        return freezing ? "snow or freezing rain" : "rain"
    }

    private func composeFromSnapshot(_ snapshot: WeatherSnapshot, intent: AgentIntent) -> String {
        let current = snapshot.current
        let temp = current.tempC.formatted(.number.precision(.fractionLength(0)))
        let wind = current.windKph.formatted(.number.precision(.fractionLength(0)))
        let uv = current.uvIndex.formatted(.number.precision(.fractionLength(1)))

        let base = "\(snapshot.location.fullName): \(temp)°C, \(current.conditionText), "
            + "wind \(wind) kph, UV \(uv), \(current.humidity)% humidity."

        guard let tomorrow = snapshot.daily.dropFirst().first else { return base }
        return base + "\n\n" + "Tomorrow: \(tomorrow.maxTempC.formatted(.number.precision(.fractionLength(0))))°/\(tomorrow.minTempC.formatted(.number.precision(.fractionLength(0))))°, \(tomorrow.conditionText)."
    }
}

// MARK: - Intent classification

enum IntentClassifier {
    /// Keyword scoring rather than an embedding model: the vocabulary of weather
    /// questions is small and bounded, and this has to run offline.
    static func classify(_ message: String) -> AgentIntent {
        let text = message.lowercased()

        func has(_ words: [String]) -> Bool {
            words.contains { text.contains($0) }
        }

        // Alerts win first: if the user asks about a storm, everything else is
        // secondary.
        if has(["warning", "alert", "storm", "hurricane", "tornado", "flood", "dangerous", "safe"]) {
            return .alerts
        }

        if has(["pack", "packing", "bring", "luggage", "suitcase", "coat", "jacket",
                "umbrella", "wear", "clothes", "clothing", "travel to", "trip"]) {
            return .packing
        }

        if has(["calendar", "schedule", "meeting", "appointment", "commute",
                "drive", "traffic", "leave", "depart", "train", "bus", "flight"]) {
            return .travelCommute
        }

        // Timing signals outrank activity signals. "When should I go for a
        // walk?" is a question about timing that happens to mention an
        // activity, and it needs the hourly window, not a yes/no verdict.
        let asksAboutTiming = has(["when", "best time", "what time", "soon", "hour",
                                   "before", "until", "timing", "evening", "morning",
                                   "tonight", "later today", "right now"])

        if has(["run", "running", "jog", "jogging", "hike", "hiking", "cycle", "cycling",
                "workout", "exercise", "bike", "swim", "walk", "outdoor", "outside",
                "bbq", "barbecue", "picnic", "golf", "morning run"]) {
            return asksAboutTiming ? .weatherTiming : .outdoorActivity
        }

        if asksAboutTiming {
            return .weatherTiming
        }

        if has(["tomorrow", "weekend", "next", "forecast", "later", "days", "will it"]) {
            return .futureForecast
        }

        if has(["now", "right now", "currently", "current", "today"]) {
            return .currentConditions
        }

        return .general
    }
}
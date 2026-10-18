//
//  FoundationModelsBackend.swift
//  WeatherApp
//
//  On-device LLM backend built on Apple's Foundation Models framework.
//
//  AVAILABILITY — THIS FILE IS DISABLED AND STAYS THAT WAY ON iOS 16.1
//
//  Foundation Models requires iOS 26 AND an Apple Intelligence capable device.
//  This project targets iOS 16.1, where it can never run.
//
//  Why the guard below is not `canImport(FoundationModels)`:
//  that check passes on ANY modern SDK, even when the deployment target is
//  iOS 16. Verified — with Xcode 26 installed and IPHONEOS_DEPLOYMENT_TARGET
//  at 16.1, `canImport(FoundationModels)` evaluates TRUE, so a canImport-only
//  guard compiles this file in and fails the build.
//
//  Same problem with `compiler(>=6.2)`: it reflects the toolchain, not the
//  deployment target, so it is also true here.
//
//  The only reliable gate is the deployment target itself, hence the explicit
//  `DEPLOYMENT_TARGET_SUPPORTS_FOUNDATION_MODELS` flag below. To enable this
//  backend you must:
//    1. Raise IPHONEOS_DEPLOYMENT_TARGET to 26.0, AND
//    2. Define SWIFT_ACTIVE_COMPILATION_CONDITIONS with
//       DEPLOYMENT_TARGET_SUPPORTS_FOUNDATION_MODELS
//  Both are required. Until then this file compiles to nothing.
//
//  Device support is still checked at runtime by `WeatherViewModel`, which
//  falls back to the heuristic engine on unsupported hardware.
//
//  If you are not planning to ship the on-device model, delete this file and
//  remove it from the target — nothing else depends on it.
//

// Set this in the target's build settings ONLY alongside deployment target 26:
//   SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) DEPLOYMENT_TARGET_SUPPORTS_FOUNDATION_MODELS
#if canImport(FoundationModels) && DEPLOYMENT_TARGET_SUPPORTS_FOUNDATION_MODELS

import Foundation
import FoundationModels

// MARK: - Tool adapters

/// Bridges one of the agent's backend-agnostic tools to the Foundation Models
/// `Tool` protocol.
///
/// The agent's tools stay framework-agnostic; this adapter plus
/// `AgentToolArguments` are the only code that knows about `@Generable`.
@available(iOS 26.0, macOS 26.0, *)
struct WeatherToolAdapter: Tool {
    typealias Arguments = AgentToolArguments
    typealias Output = ToolResultText

    let name: String
    let description: String
    let inner: any WeatherTool

    /// The schema the model sees. This must be a real, available property:
    /// `Tool` requires it, so marking it `@available(*, unavailable)`
    /// prevents the conformance from being satisfied entirely.
    var parameters: GenerationSchema { AgentToolArguments.generationSchema }

    @concurrent
    func call(arguments: AgentToolArguments) async throws -> ToolResultText {
        let result = try await inner.run(arguments: arguments.toToolArguments())
        return ToolResultText(summary: result.summary)
    }
}

/// Structured arguments for every tool.
///
/// A single shared argument type is deliberate: it means one decoding path for
/// all tools, and the fields are optional so the model can omit anything it
/// does not need. Each tool validates and defaults the fields it cares about
/// (see `ToolArguments`).
///
/// This is NOT an empty struct. A zero-field `@Generable` would produce an
/// empty schema, leaving the model with no fields to populate, so arguments
/// would never arrive.
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct AgentToolArguments {
    /// City name, optionally with country, e.g. "Chicago, IL".
    @Guide(description: "City name to look up, including country when ambiguous, e.g. 'Chicago, IL'.")
    var location: String?

    /// Forecast horizon in days.
    @Guide(description: "How many days of forecast to retrieve, between 1 and 7.")
    var days: Int?

    /// Forecast horizon in hours.
    @Guide(description: "How many hours ahead to look, between 1 and 24.")
    var hours: Int?

    /// Calendar lookahead in hours.
    @Guide(description: "How many hours ahead to check the calendar, between 1 and 48.")
    var hoursAhead: Int?

    /// Converts to the agent's backend-agnostic argument container.
    func toToolArguments() -> ToolArguments {
        var values: [String: JSONValue] = [:]
        if let location { values["location"] = .string(location) }
        if let days { values["days"] = .number(Double(days)) }
        if let hours { values["hours"] = .number(Double(hours)) }
        if let hoursAhead { values["hoursAhead"] = .number(Double(hoursAhead)) }
        return ToolArguments(values)
    }
}

/// Tool output must conform to `PromptRepresentable`; a string wrapper is the
/// simplest valid payload.
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct ToolResultText {
    /// Prose summary of the tool result. No `@Guide`: guides describe model
    /// *arguments*, and this is output the framework reads, not fills in.
    var summary: String
}

// MARK: - Backend

@available(iOS 26.0, macOS 26.0, *)
struct FoundationModelsSDKBackend: AgentReasoningBackend {

    let displayName = "Apple Foundation Models"

    private static let systemPrompt = """
        You are the reasoning layer of an iOS weather app. You answer questions \
        about weather by calling the available tools, never by guessing values.

        Rules:
        - Call a tool whenever the answer depends on live data.
        - You may call several tools at once when a question needs multiple facts.
        - When a tool returns an error, say what is missing instead of working around it.
        - Weather beyond about 48 hours is low confidence. Say so when relevant.
        - Lead with the answer, then one short paragraph of reasoning.
        """

    func reason(_ prompt: AgentPrompt) async throws -> AgentPlan {
        let adapters = prompt.availableTools.map { tool in
            WeatherToolAdapter(name: tool.name,
                               description: tool.description,
                               inner: tool)
        }

        // Grounding: replay observations so the model can answer from them, and
        // include the raw snapshot when it has not called a tool yet.
        var instructions = Self.systemPrompt
        if let snapshot = prompt.snapshot, prompt.observations.isEmpty {
            instructions += "\n\n" + Self.contextBlock(snapshot)
        }

        // Argument order matters: `tools` precedes `instructions` in the
        // LanguageModelSession initialiser.
        let session = LanguageModelSession(tools: adapters, instructions: instructions)

        do {
            let response = try await session.respond(to: Self.userPrompt(prompt))
            let answer = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

            return AgentPlan(
                thought: prompt.observations.isEmpty
                    ? "Answering from the on-device model."
                    : "Composing the answer from retrieved conditions.",
                toolCalls: [],
                finalAnswer: answer.isEmpty ? nil : answer
            )
        } catch {
            // Surface the failure so WeatherAgent can fall back to the heuristic
            // engine rather than showing the user an error.
            throw WeatherAgentError.backendFailure(error.localizedDescription)
        }
    }

    // MARK: Prompt assembly

    private static func userPrompt(_ prompt: AgentPrompt) -> String {
        var text = "User question: \(prompt.userMessage)\n"
        text += "Location: \(prompt.location.fullName)\n"

        if !prompt.observations.isEmpty {
            text += "\nTool results:\n"
            for observation in prompt.observations {
                if let result = observation.result {
                    text += "- \(observation.tool): \(result.summary)\n"
                } else {
                    text += "- \(observation.tool) failed: \(observation.errorMessage ?? "unknown")\n"
                }
            }
        }

        return text
    }

    static func contextBlock(_ snapshot: WeatherSnapshot) -> String {
        let current = snapshot.current

        // Format in the forecast city's zone so the model reads the same
        // wall-clock times a resident would.
        let hourFormat = DateFormatter()
        hourFormat.dateFormat = "HH:mm"
        hourFormat.timeZone = snapshot.timeZone
        let dayFormat = DateFormatter()
        dayFormat.dateFormat = "EEE d MMM"
        dayFormat.timeZone = snapshot.timeZone

        let hourly = snapshot.hourly.prefix(8).map { hour in
            "\(hourFormat.string(from: hour.date)): \(hour.tempC)°C, rain \(hour.precipChance)%, wind \(hour.windKph)kph"
        }.joined(separator: " | ")

        let daily = snapshot.daily.prefix(5).map { day in
            "\(dayFormat.string(from: day.date)): \(day.minTempC)/\(day.maxTempC)°C, rain \(day.precipChance)%, \(day.conditionText)"
        }.joined(separator: " | ")

        let alerts = snapshot.alerts.isEmpty
            ? "none"
            : snapshot.alerts.map { "\($0.severity.rawValue): \($0.headline)" }.joined(separator: "; ")

        return """
            APP SNAPSHOT (\(snapshot.location.fullName)):
            current: \(current.tempC)°C, feels \(current.apparentTempC)°C, \
            \(current.conditionText), wind \(current.windKph)kph \(current.windDirection), \
            humidity \(current.humidity)%, UV \(current.uvIndex)
            hourly: \(hourly)
            daily: \(daily)
            alerts: \(alerts)
            """
    }
}
#endif
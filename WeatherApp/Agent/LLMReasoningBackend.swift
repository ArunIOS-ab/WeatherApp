//
//  LLMReasoningBackend.swift
//  WeatherApp
//
//  Remote LLM backend using OpenAI-compatible tool/function calling. This is the
//  backend that actually works on iOS 16: the agent loop, tool definitions and
//  tool dispatch are all local, and only the reasoning step is off-device.
//
//  The API key is read from Info.plist so it is not committed. For production,
//  proxy this through your own backend rather than shipping a key in the app.
//

import Foundation

// MARK: - Configuration

struct LLMConfiguration: Sendable {
    let endpoint: URL
    let apiKey: String
    let model: String
    let temperature: Double
    let maxTokens: Int

    static let infoPlistKey = "LLM_API_KEY"

    /// Reads configuration from Info.plist. Returns nil when unconfigured so
    /// the app can fall back to heuristics instead of failing.
    static func fromInfoPlist(bundle: Bundle = .main) -> LLMConfiguration? {
        guard let key = bundle.object(forInfoDictionaryKey: infoPlistKey) as? String,
              !key.isEmpty,
              key != "API_KEY"
        else { return nil }

        let endpoint = (bundle.object(forInfoDictionaryKey: "LLM_ENDPOINT") as? String)
            .flatMap(URL.init(string:))
            ?? URL(string: "https://api.openai.com/v1/chat/completions")!

        let model = bundle.object(forInfoDictionaryKey: "LLM_MODEL") as? String ?? "gpt-4o-mini"

        return LLMConfiguration(endpoint: endpoint, apiKey: key, model: model,
                                temperature: 0.2, maxTokens: 600)
    }
}

// MARK: - Backend

struct LLMReasoningBackend: AgentReasoningBackend {
    let displayName = "Weather reasoning model"
    let configuration: LLMConfiguration
    let registry: WeatherToolRegistry
    private let session: URLSession

    init(configuration: LLMConfiguration, registry: WeatherToolRegistry) {
        self.configuration = configuration
        self.registry = registry
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    /// Builds the request body, including the tool-calling contract and any
    /// observations already gathered this turn.
    private func requestBody(_ prompt: AgentPrompt) throws -> [String: Any] {
        var messages: [[String: Any]] = [
            ["role": "system", "content": Self.systemPrompt]
        ]

        // Recent turns only. The tool results in the current turn carry most of
        // the signal, and long histories just cost tokens.
        for message in prompt.transcript.suffix(6) {
            guard case .user = message.role else { continue }
            messages.append(["role": "user", "content": message.text])
        }

        // Tool results must be replayed together with the assistant message that
        // requested them.
        //
        // OpenAI-compatible chat completions require every `tool` message to
        // reference a `tool_call_id` from an immediately preceding assistant
        // `tool_calls` entry. Sending results alone — or with invented ids, as
        // this previously did — is rejected by the API on the second request of
        // any tool-using turn, which silently drops the agent back to
        // heuristics.
        if !prompt.observations.isEmpty {
            var calls: [[String: Any]] = []
            var results: [[String: Any]] = []

            for observation in prompt.observations {
                // Fall back to the observation id only if the model gave none.
                let id = observation.toolCallID ?? observation.id.uuidString
                calls.append([
                    "id": id,
                    "type": "function",
                    "function": [
                        "name": observation.tool,
                        "arguments": observation.rawArguments ?? "{}"
                    ]
                ])

                let payload = observation.result.map { $0.summary }
                    ?? "Error: \(observation.errorMessage ?? "unknown failure")"
                results.append([
                    "role": "tool",
                    "tool_call_id": id,
                    "content": payload
                ])
            }

            messages.append(["role": "assistant", "tool_calls": calls])
            messages.append(contentsOf: results)
        }

        messages.append(["role": "user", "content": prompt.userMessage])

        var body: [String: Any] = [
            "model": configuration.model,
            "messages": messages,
            "temperature": configuration.temperature,
            "max_tokens": configuration.maxTokens,
            "tools": registry.openAIFunctionSpecs(),
            // Parallel tool calls let the agent batch independent fetches, which
            // is most of the latency win in a chained request.
            "tool_choice": prompt.observations.isEmpty ? "auto" : "none",
            "parallel_tool_calls": true
        ]

        // Grounding: giving the model the raw snapshot stops it hallucinating
        // conditions that contradict the app's own data.
        if let snapshot = prompt.snapshot, prompt.observations.isEmpty {
            body["user_context"] = Self.contextBlock(snapshot)
        }

        return body
    }

    func reason(_ prompt: AgentPrompt) async throws -> AgentPlan {
        let body = try requestBody(prompt)
        let data = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: configuration.endpoint)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        let (responseData, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WeatherAgentError.backendFailure("HTTP \(status)")
        }

        let message = try Self.extractMessage(from: responseData)
        let toolCalls = message["tool_calls"] as? [[String: Any]] ?? []

        if !toolCalls.isEmpty {
            let planned = toolCalls.compactMap { call -> PlannedToolCall? in
                guard let fn = call["function"] as? [String: Any],
                      let name = fn["name"] as? String,
                      let rawArgs = fn["arguments"] as? String
                else { return nil }

                // The model may emit an empty string rather than "{}".
                let argumentData = (rawArgs.data(using: .utf8)) ?? Data("{}".utf8)
                let args = (try? ToolArguments(from: argumentData)) ?? ToolArguments()

                // Drop calls to tools we do not have rather than failing the turn.
                guard (try? registry.tool(named: name)) != nil else { return nil }

                // Keep the id and the verbatim argument JSON: both are needed to
                // pair the result with this call on the following request.
                return PlannedToolCall(tool: name,
                                       arguments: args,
                                       toolCallID: call["id"] as? String,
                                       rawArguments: rawArgs)
            }

            guard !planned.isEmpty else {
                // The model asked for something unavailable. Fall back to
                // heuristics so the user still gets an answer.
                throw WeatherAgentError.backendFailure("Model requested an unknown tool.")
            }

            return AgentPlan(thought: "Gathering the data needed to answer that.",
                             toolCalls: planned, finalAnswer: nil)
        }

        guard let content = message["content"] as? String,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw WeatherAgentError.backendFailure("Empty response.")
        }

        return AgentPlan(thought: "Answering from the retrieved conditions.",
                         toolCalls: [], finalAnswer: content)
    }

    // MARK: Parsing

    private static func extractMessage(from data: Data) throws -> [String: Any] {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any]
        else {
            throw WeatherAgentError.backendFailure("Unexpected response shape.")
        }
        return message
    }

    // MARK: Prompt assets

    static let systemPrompt = """
        You are the reasoning layer of an iOS weather app. You answer questions
        about weather using the tools provided.

        Rules:
        - Never state a weather value that did not come from a tool result. If
          you have not called a tool, call one.
        - Chain tools when a question needs several facts, for example the
          hourly window plus the forecast range. You may call more than one at once.
        - Prefer concrete numbers with units over vague phrasing.
        - Weather more than about 48 hours out is low confidence; acknowledge
          that when the question spans that range.
        - Lead with the answer, then one short paragraph of reasoning. No
          preamble, no bullet lists unless the user asked for one.
        - Keep replies under 120 words.
        """

    /// Serialises the snapshot into a compact context block.
    static func contextBlock(_ snapshot: WeatherSnapshot) -> String {
        let current = snapshot.current
        let hourFormat = DateFormatter()
        hourFormat.dateFormat = "HH:mm"
        let dayFormat = DateFormatter()
        dayFormat.dateFormat = "yyyy-MM-dd"

        let hourly = snapshot.hourly.prefix(6).map { hour in
            "\(hourFormat.string(from: hour.date)): \(hour.tempC)°C, rain \(hour.precipChance)%, wind \(hour.windKph)kph"
        }.joined(separator: " | ")

        let daily = snapshot.daily.prefix(5).map { day in
            "\(dayFormat.string(from: day.date)): \(day.minTempC)/\(day.maxTempC)°C, rain \(day.precipChance)%, \(day.conditionText)"
        }.joined(separator: " | ")

        let alerts = snapshot.alerts.isEmpty
            ? "none"
            : snapshot.alerts.map { "\($0.severity.rawValue): \($0.headline)" }.joined(separator: "; ")

        return """
            APP SNAPSHOT (\(snapshot.location.fullName), fetched \(snapshot.fetchedAt.formatted(.iso8601))):
            current: \(current.tempC)°C, feels \(current.apparentTempC)°C,
            \(current.conditionText), wind \(current.windKph)kph \(current.windDirection),
            humidity \(current.humidity)%, UV \(current.uvIndex)
            hourly: \(hourly)
            daily: \(daily)
            alerts: \(alerts)
            """
    }
}
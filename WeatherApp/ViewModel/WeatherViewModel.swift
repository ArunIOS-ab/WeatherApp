//
//  WeatherViewModel.swift
//  WeatherApp
//
//  The MVVM seam. Owns weather state and a `WeatherAgentActor`, refreshes
//  insights when data changes, and forwards user questions to the agent.
//

import Foundation
import Combine

@MainActor
final class WeatherViewModel: ObservableObject {

    // MARK: Published state

    @Published private(set) var snapshot: WeatherSnapshot?
    @Published private(set) var insights: [AgentInsight] = []
    @Published private(set) var messages: [AgentMessage] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isAgentThinking = false
    @Published var location: GeoLocation
    @Published var errorMessage: String?

    /// Identifies the snapshot currently on screen, so the UI can tell stale
    /// insights from live ones.
    @Published private(set) var dataUpdatedAt: Date?

    // MARK: Collaborators

    private let dataSource: any WeatherDataSource
    private let agent: WeatherAgent
    private let agentActor: WeatherAgentActor
    private var refreshTask: Task<Void, Never>?

    // MARK: Init

    init(location: GeoLocation,
         dataSource: any WeatherDataSource,
         backend: any AgentReasoningBackend? = nil) {
        self.location = location
        self.dataSource = dataSource

        let registry = WeatherToolRegistry.standard(dataSource: dataSource)

        // Pick the best available backend. Preference order: configured remote
        // model, then on-device Foundation Models, then local heuristics. The
        // heuristic engine is the guaranteed floor and never fails to load.
        let resolvedBackend: any AgentReasoningBackend
        if let provided = backend {
            resolvedBackend = provided
        } else if let config = LLMConfiguration.fromInfoPlist() {
            resolvedBackend = LLMReasoningBackend(configuration: config, registry: registry)
        } else if let onDevice = FoundationModelsBackend.makeBackend() {
            resolvedBackend = onDevice
        } else {
            resolvedBackend = HeuristicReasoningBackend()
        }

        let agent = WeatherAgent(registry: registry, backend: resolvedBackend)
        self.agent = agent
        self.agentActor = WeatherAgentActor(agent: agent, dataSource: dataSource)
    }

    /// Convenience initialiser for the standard stack.
    convenience init(location: GeoLocation) {
        let source = WeatherAPIClient.shared
        self.init(location: location, dataSource: source)
    }

    deinit {
        refreshTask?.cancel()
    }

    // MARK: Data loading

    func load() async {
        await refresh()
    }

    /// Pulls the latest weather, regenerates insights, and publishes.
    func refresh() async {
        refreshTask?.cancel()
        isLoading = true
        defer { isLoading = false }

        do {
            let fresh = try await dataSource.snapshot(for: location)
            snapshot = fresh
            dataUpdatedAt = fresh.fetchedAt
            errorMessage = nil

            await agentActor.refreshInsights(location: location, snapshot: fresh)
            insights = await agentActor.insights

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Changes location and reloads. Insights are regenerated rather than kept,
    /// since they are location specific.
    func select(location newLocation: GeoLocation) async {
        location = newLocation
        snapshot = nil
        insights = []
        messages = []
        await refresh()
    }

    // MARK: Agent interaction

    /// Whether the agent has enough data to answer a question.
    ///
    /// The UI reads this to avoid opening the chat with no data behind it, which
    /// would otherwise fail the first question with `noSnapshot` before the
    /// initial load had finished.
    var canAskAgent: Bool { snapshot != nil && !isLoading }

    /// Sends a question to the agent and appends the exchange to the transcript.
    func ask(_ question: String) async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // The agent reasons over a snapshot and cannot answer without one. Rather
        // than rejecting immediately, wait for the in-flight load to finish so a
        // fast tap during startup still gets an answer.
        if snapshot == nil {
            isLoading = true
            await refresh()
        }
        guard snapshot != nil else {
            errorMessage = "Still waiting for weather data. Try again in a moment."
            return
        }

        isAgentThinking = true
        defer { isAgentThinking = false }

        do {
            try await agentActor.send(trimmed, location: location, snapshot: snapshot)
        } catch {
            // The actor already appended a readable failure message to the
            // transcript, so only re-read state here. Appending another would
            // show the user the same error twice.
            errorMessage = (error as? WeatherAgentError)?.errorDescription
                ?? error.localizedDescription
        }

        // Read the transcript either way, so the transcript stays correct
        // whether the turn succeeded or failed.
        messages = await agentActor.messageList
    }

    func clearConversation() async {
        messages = []
    }
}
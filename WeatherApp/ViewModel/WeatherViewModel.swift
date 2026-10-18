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

    // MARK: Location search

    @Published var searchQuery: String = ""
    @Published private(set) var searchResults: [GeoLocation] = []
    @Published private(set) var isSearching = false
    @Published private(set) var searchError: String?

    /// Debounces keystrokes so typing does not fire a request per character.
    private var searchTask: Task<Void, Never>?

    /// Cities mentioned in recent questions, so the UI can offer them as
    /// one-tap follow-ups after the user asks about somewhere specific.
    @Published private(set) var recentLocations: [GeoLocation] = []

    // MARK: Collaborators

    private let dataSource: any WeatherDataSource
    private let agent: WeatherAgent
    private let agentActor: WeatherAgentActor
    private var refreshTask: Task<Void, Never>?
    /// Monotonic counter identifying the most recent refresh. A response whose
    /// generation is stale is discarded instead of published.
    private var refreshGeneration = 0
    private let searchDebounce: UInt64

    // MARK: Init

    init(location: GeoLocation,
         dataSource: any WeatherDataSource,
         backend: any AgentReasoningBackend? = nil,
         searchDebounce: UInt64 = 350_000_000) {
        self.location = location
        self.dataSource = dataSource
        self.searchDebounce = searchDebounce

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
    ///
    /// Guards against a stale response overwriting a newer one. `select(location:)`
    /// can start a second refresh while the first is still in flight, and without
    /// this check the slower response would land last and publish the *old* city's
    /// weather under the *new* city's name in the header.
    ///
    /// The requested location is captured before awaiting, and results are only
    /// published if the selection is unchanged and this generation is still the
    /// current one.
    func refresh() async {
        let requested = location
        isLoading = true
        refreshGeneration += 1
        let generation = refreshGeneration
        defer { isLoading = false }

        do {
            let fresh = try await dataSource.snapshot(for: requested)

            // A newer refresh, or a location change, has happened while this
            // request was in flight. Discard rather than publish stale data.
            guard generation == refreshGeneration, requested.id == location.id else {
                return
            }

            snapshot = fresh
            dataUpdatedAt = fresh.fetchedAt
            errorMessage = nil

            await agentActor.refreshInsights(location: requested, snapshot: fresh)
            guard generation == refreshGeneration, requested.id == location.id else {
                return
            }
            insights = await agentActor.insights

        } catch {
            guard generation == refreshGeneration else { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Changes location and reloads. Insights are regenerated rather than kept,
    /// since they are location specific.
    ///
    /// The conversation is intentionally cleared: answers already on screen were
    /// reasoned from the previous location's data, so leaving them in place
    /// would produce a transcript that contradicts the current weather.
    func select(location newLocation: GeoLocation) async {
        location = newLocation
        snapshot = nil
        insights = []
        // Clear the actor's transcript too, otherwise the next turn appends to
        // the previous city's history and repopulates `messages` with answers
        // reasoned from the old location.
        messages = []
        await agentActor.reset()
        messages = await agentActor.messageList

        searchResults = []
        searchQuery = newLocation.name
        errorMessage = nil
        await refresh()
    }

    // MARK: Location search

    /// Runs a debounced search as the user types.
    ///
    /// A search per keystroke would fire a request per character and race its
    /// own results; debouncing collapses that into one request per pause.
    func searchLocations() {
        searchTask?.cancel()

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            searchResults = []
            searchError = nil
            isSearching = false
            return
        }

        searchTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: searchDebounce)
            guard !Task.isCancelled else { return }

            isSearching = true
            defer { isSearching = false }

            do {
                let results = try await dataSource.searchLocations(query: query)
                // A newer keystroke may have landed while this was in flight.
                guard !Task.isCancelled,
                      searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                        .caseInsensitiveCompare(query) == .orderedSame
                else { return }

                searchResults = results
                searchError = results.isEmpty ? StringConstants.kMsgNoPlacesFound : nil
            } catch {
                guard !Task.isCancelled else { return }
                searchResults = []
                searchError = error.localizedDescription
            }
        }
    }

    /// Clears search UI without touching the selected location.
    func clearSearch() {
        searchTask?.cancel()
        searchQuery = ""
        searchResults = []
        searchError = nil
        isSearching = false
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
            // If the user names a different city ("what's it like in Tokyo?"),
            // answer about that city instead of the currently selected one.
            // The agent resolves it through its tools, so this needs no special
            // casing beyond pointing the snapshot at the right place.
            let target = await resolveTargetLocation(for: trimmed)

            var targetSnapshot = snapshot
            if target.id != location.id {
                // Answering about another city must not silently rewrite the
                // user's selected location, so only the snapshot moves.
                targetSnapshot = try await dataSource.snapshot(for: target)
                rememberRecent(target)
            }

            try await agentActor.send(trimmed, location: target, snapshot: targetSnapshot)
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

    /// Extracts a place named in the question, falling back to the selected
    /// location when the user does not name one.
    ///
    /// Matches against real search results rather than a hardcoded city list, so
    /// any place the provider knows works. Matching on a prefix of the full
    /// "City, Region, Country" string keeps "London" from resolving to
    /// "Londonderry, New Hampshire".
    private func resolveTargetLocation(for question: String) async -> GeoLocation {
        guard let mentioned = mentionedPlace(in: question) else { return location }

        let candidates = try? await dataSource.searchLocations(query: mentioned)
        guard let match = bestMatch(for: mentioned, in: candidates ?? []) else {
            return location
        }
        return match
    }

    /// Pulls a probable place name out of a question.
    ///
    /// Deliberately conservative: it looks for the shape of a question about a
    /// place ("in Tokyo", "for chicago", "weather in London") rather than
    /// scraping every capitalised word, which would misfire on "Is it a good
    /// day to Run Outdoors".
    private func mentionedPlace(in question: String) -> String? {
        let patterns = [
            #"\b(?:weather|forecast|temperature|rain|snow|wind)\s+in\s+([a-z][a-z\s'\-]+?)(?:\s+(?:tomorrow|today|tonight|now|this|next)|\?|$)"#,
            #"\bin\s+([a-z][a-z\s'\-]+?)(?:\s+(?:tomorrow|today|tonight|now|next week)\b|\?|$)"#,
            #"\bfor\s+([a-z][a-z\s'\-]+?)\s+(?:weekend|trip|holiday|vacation)"#,
            #"\bat\s+([a-z][a-z\s'\-]+?)(?:\s+(?:tomorrow|today|tonight)\b|\?|$)"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
                  let match = regex.firstMatch(in: question, range: NSRange(question.startIndex..., in: question)),
                  let range = Range(match.range(at: 1), in: question)
            else { continue }

            var candidate = String(question[range])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Strip trailing time words the pattern may have swept up
            // ("New York this" from "...for New York this weekend").
            for filler in [" this", " next"] where candidate.hasSuffix(filler) {
                candidate = String(candidate.dropLast(filler.count))
            }
            candidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines)

            guard Self.isPlausiblePlace(candidate) else { continue }
            return candidate
        }
        return nil
    }

    /// Rejects candidates that are obviously not place names.
    ///
    /// Checks every word, not just the whole string: "the morning" is a phrase
    /// of two non-place words, so a set lookup on the full candidate would miss
    /// it.
    private static func isPlausiblePlace(_ candidate: String) -> Bool {
        let words = candidate.lowercased()
            .split(whereSeparator: { !$0.isLetter && $0 != "'" && $0 != "-" })
            .map(String.init)
        guard !words.isEmpty, words.count <= 4 else { return false }
        return !words.contains { stopWords.contains($0) }
    }

    /// Words that follow a preposition but are never place names.
    ///
    /// Includes activities ("walk", "run") and times of day, both of which
    /// otherwise get swept up by a preposition pattern.
    private static let stopWords: Set<String> = [
        "the", "a", "an", "it", "my", "our", "this", "that", "these", "those",
        "walk", "run", "jog", "hike", "cycle", "drive", "swim", "trip",
        "morning", "afternoon", "evening", "night", "today", "tomorrow", "tonight"
    ]

    /// Chooses the closest match for a mentioned place, preferring an exact
    /// name match over a partial one.
    ///
    /// Returns nil rather than an arbitrary first result when nothing actually
    /// matches: answering about the wrong city is worse than answering about the
    /// one already selected.
    private func bestMatch(for mentioned: String, in candidates: [GeoLocation]) -> GeoLocation? {
        guard !candidates.isEmpty else { return nil }
        let needle = mentioned.lowercased()

        if let exact = candidates.first(where: { $0.name.lowercased() == needle }) {
            return exact
        }
        // Prefix match keeps "London" from resolving to "Londonderry".
        if let prefix = candidates.first(where: { $0.name.lowercased().hasPrefix(needle) }) {
            return prefix
        }
        return candidates.first { $0.name.lowercased().contains(needle) }
    }

    private func rememberRecent(_ place: GeoLocation) {
        recentLocations.removeAll { $0.id == place.id }
        recentLocations.insert(place, at: 0)
        if recentLocations.count > 5 {
            recentLocations.removeLast(recentLocations.count - 5)
        }
    }

    /// Clears the transcript everywhere.
    ///
    /// Clearing only the rendered copy is not enough: the actor retains both
    /// `messages` and `transcript`, and the next `ask` assigns its full
    /// `messageList` back to `messages`, so a cleared chat would reappear.
    func clearConversation() async {
        messages = []
        await agentActor.reset()
        messages = await agentActor.messageList
    }
}
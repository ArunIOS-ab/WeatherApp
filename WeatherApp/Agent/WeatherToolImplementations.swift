//
//  WeatherToolImplementations.swift
//  WeatherApp
//
//  Concrete tools backing the agent's capabilities. Each one is deliberately
//  narrow: it reads a snapshot, derives one answer, and returns it.
//

import Foundation
import EventKit

// MARK: - Tool errors

enum WeatherToolError: LocalizedError {
    case unknownTool(String)
    case missingArgument(String)
    case permissionDenied(String)
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .unknownTool(let name):
            return "No tool named '\(name)' is registered."
        case .missingArgument(let key):
            return "Required argument '\(key)' was missing."
        case .permissionDenied(let what):
            return "Access to \(what) was denied."
        case .failed(let reason):
            return reason
        }
    }
}

// MARK: - Data source

/// Supplies snapshots to tools. Injected rather than referenced directly so
/// tools stay testable and the agent never reaches into the network itself.
protocol WeatherDataSource: Sendable {
    func snapshot(for location: GeoLocation) async throws -> WeatherSnapshot
    func searchLocations(query: String) async throws -> [GeoLocation]
}

/// Wraps an in-memory or cached snapshot. The default implementation used by
/// the sample tools below.
struct StaticWeatherDataSource: WeatherDataSource {
    let snapshots: [GeoLocation: WeatherSnapshot]

    func snapshot(for location: GeoLocation) async throws -> WeatherSnapshot {
        guard let snapshot = snapshots[location] else {
            throw WeatherToolError.failed("No cached weather for \(location.name).")
        }
        return snapshot
    }

    func searchLocations(query: String) async throws -> [GeoLocation] {
        let needle = query.lowercased()
        return snapshots.keys.filter {
            needle.isEmpty || $0.fullName.lowercased().contains(needle)
        }.sorted { $0.name < $1.name }
    }
}

// MARK: - fetchCurrentWeather

struct FetchCurrentWeatherTool: WeatherTool {
    let dataSource: any WeatherDataSource

    let name = "fetchCurrentWeather"
    let description = """
        Get the current observed conditions for a specific city: temperature,
        apparent temperature, wind, humidity, UV index and precipitation. Use
        this for any question about right now or the next few hours. Requires a
        location; omit it to use the user's current city.
        """

    let parameters = ToolSchema(
        properties: [
            "location": .init(type: .string,
                              description: "City name, optionally with country. Omit for the user's current location.")
        ],
        required: []
    )

    func run(arguments: ToolArguments) async throws -> ToolResult {
        let location = try await resolveLocation(from: arguments)
        let snapshot = try await dataSource.snapshot(for: location)
        let c = snapshot.current

        let summary = """
            \(location.fullName) right now: \(c.tempC.formatted(.number.precision(.fractionLength(0))))°C
            (feels like \(c.apparentTempC.formatted(.number.precision(.fractionLength(0))))°C),
            \(c.conditionText), wind \(c.windKph.formatted(.number.precision(.fractionLength(0)))) kph
            from the \(c.windDirection), humidity \(c.humidity)%, UV index
            \(c.uvIndex.formatted(.number.precision(.fractionLength(1)))).
            """

        let data = JSONValue.object([
            "temperatureC": .number(c.tempC),
            "apparentTempC": .number(c.apparentTempC),
            "condition": .string(c.conditionText),
            "windKph": .number(c.windKph),
            "windDirection": .string(c.windDirection),
            "humidity": .number(Double(c.humidity)),
            "uvIndex": .number(c.uvIndex),
            "precipitationMM": .number(c.precipMM)
        ])

        return ToolResult(summary: summary, data: data)
    }

    private func resolveLocation(from arguments: ToolArguments) async throws -> GeoLocation {
        guard let query = arguments.string("location"), !query.isEmpty else {
            throw WeatherToolError.missingArgument("location")
        }
        let matches = try await dataSource.searchLocations(query: query)
        guard let first = matches.first else {
            throw WeatherToolError.failed("Could not find a location matching '\(query)'.")
        }
        return first
    }
}

// MARK: - getForecastRange

struct GetForecastRangeTool: WeatherTool {
    let dataSource: any WeatherDataSource

    let name = "getForecastRange"
    let description = """
        Get the forecast for a city over the next 1-7 days, including daily
        highs, lows, precipitation chance and sunrise/sunset. Use this for
        planning trips, packing, or anything about a specific upcoming day.
        Requires a location.
        """

    let parameters = ToolSchema(
        properties: [
            "location": .init(type: .string, description: "City name, optionally with country."),
            "days": .init(type: .integer, description: "How many days to forecast. Defaults to 5, maximum 7.")
        ],
        required: ["location"]
    )

    func run(arguments: ToolArguments) async throws -> ToolResult {
        guard let query = arguments.string("location") else {
            throw WeatherToolError.missingArgument("location")
        }
        let days = min(max(arguments.int("days") ?? 5, 1), 7)

        let matches = try await dataSource.searchLocations(query: query)
        guard let location = matches.first else {
            throw WeatherToolError.failed("Could not find a location matching '\(query)'.")
        }

        let snapshot = try await dataSource.snapshot(for: location)
        let window = snapshot.daily.prefix(days)

        let lines = window.map { day in
            let date = snapshot.weekday(day.date)
            let high = day.maxTempC.formatted(.number.precision(.fractionLength(0)))
            let low = day.minTempC.formatted(.number.precision(.fractionLength(0)))
            let rain = day.precipChance > 0 ? ", \(day.precipChance)% \(precipKind(day.conditionText, tempC: day.minTempC))" : ""
            return "\(date): \(high)°/\(low)°, \(day.conditionText)\(rain)"
        }

        return ToolResult(
            summary: "\(location.fullName) next \(window.count) days —\n" + lines.joined(separator: "\n"),
            data: .from(Array(window))
        )
    }
}

// MARK: - getHourlyWindow

struct GetHourlyWindowTool: WeatherTool {
    let dataSource: any WeatherDataSource

    let name = "getHourlyWindow"
    let description = """
        Get hour-by-hour conditions for the next several hours: temperature,
        precipitation chance and wind. Use this to answer 'will it rain before
        my meeting', 'when is the best time to walk', or to time an activity
        around the weather. Requires a location.
        """

    let parameters = ToolSchema(
        properties: [
            "location": .init(type: .string, description: "City name, optionally with country."),
            "hours": .init(type: .integer, description: "How many hours to include. Defaults to 12, maximum 24.")
        ],
        required: ["location"]
    )

    func run(arguments: ToolArguments) async throws -> ToolResult {
        guard let query = arguments.string("location") else {
            throw WeatherToolError.missingArgument("location")
        }
        let hours = min(max(arguments.int("hours") ?? 12, 1), 24)

        let matches = try await dataSource.searchLocations(query: query)
        guard let location = matches.first else {
            throw WeatherToolError.failed("Could not find a location matching '\(query)'.")
        }

        let snapshot = try await dataSource.snapshot(for: location)
        let window = snapshot.hourly.prefix(hours)

        let lines = window.map { hour in
            let time = snapshot.hourMinute(hour.date)
            let rain = hour.precipChance > 0 ? ", \(hour.precipChance)% \(precipKind(hour.conditionText, tempC: hour.tempC))" : ""
            return "\(time) \(hour.tempC.formatted(.number.precision(.fractionLength(0))))°, "
                + "\(hour.conditionText)\(rain), wind \(hour.windKph.formatted(.number.precision(.fractionLength(0)))) kph"
        }

        return ToolResult(
            summary: "\(location.fullName) hourly —\n" + lines.joined(separator: "\n"),
            data: .from(Array(window))
        )
    }
}

// MARK: - calculateClothingLayers

struct CalculateClothingLayersTool: WeatherTool {
    let dataSource: any WeatherDataSource

    let name = "calculateClothingLayers"
    let description = """
        Work out what clothing to wear or pack for a city over the next 1-7
        days, accounting for apparent temperature, wind and precipitation. Use
        this for packing questions such as 'what should I bring to Chicago'.
        Requires a location.
        """

    let parameters = ToolSchema(
        properties: [
            "location": .init(type: .string, description: "City name, optionally with country."),
            "days": .init(type: .integer, description: "Number of days to pack for. Defaults to 3.")
        ],
        required: ["location"]
    )

    func run(arguments: ToolArguments) async throws -> ToolResult {
        guard let query = arguments.string("location") else {
            throw WeatherToolError.missingArgument("location")
        }
        let days = min(max(arguments.int("days") ?? 3, 1), 7)

        let matches = try await dataSource.searchLocations(query: query)
        guard let location = matches.first else {
            throw WeatherToolError.failed("Could not find a location matching '\(query)'.")
        }

        let snapshot = try await dataSource.snapshot(for: location)
        let window = Array(snapshot.daily.prefix(days))

        // Plan against the coldest apparent temperature and the worst
        // precipitation, not the daily average. Packing for the average is how
        // people end up cold.
        var coldest = snapshot.current.apparentTempC
        var warmest = snapshot.current.apparentTempC
        var peakRain = snapshot.current.precipMM
        for day in window {
            coldest = min(coldest, day.minTempC)
            warmest = max(warmest, day.maxTempC)
            peakRain = max(peakRain, day.precipMM)
        }

        var items: [String] = []
        if coldest <= 2 {
            items.append("an insulated winter coat or heavy parka")
            items.append("thermal base layer and a wool or fleece mid-layer")
            items.append("gloves, a hat and a scarf")
        } else if coldest <= 10 {
            items.append("a warm jacket or fleece")
            items.append("a light long-sleeve layer underneath")
        } else if coldest <= 17 {
            items.append("a light jacket or cardigan for the cool parts of the day")
        }
        if warmest >= 24 {
            items.append("shorts or light breathable clothing")
        }
        if coldest <= 17 && warmest >= 22 {
            items.append("a layer you can add and remove through the day")
        }

        let anySnowRisk = window.contains { $0.minTempC <= 1 && $0.precipChance >= 30 }

        if peakRain > 0.1 || window.contains(where: { $0.precipChance >= 40 }) {
            items.append("a waterproof jacket")
            // An umbrella is poor advice in snow: it collects weight, blocks
            // your view, and gives way in a gust.
            if anySnowRisk {
                items.append("a hooded waterproof shell rather than an umbrella")
            } else {
                items.append("an umbrella or compact rain shell")
            }
            if coldest <= 10 {
                items.append("waterproof shoes")
            }
        }

        if anySnowRisk {
            items.append("insulated boots with good grip")
        }

        if window.contains(where: { $0.uvIndex >= 7 }) {
            items.append("sunscreen and sunglasses")
        }

        if items.isEmpty {
            items.append("light everyday clothing is enough")
        }

        let range = "\(coldest.formatted(.number.precision(.fractionLength(0))))° to "
            + "\(warmest.formatted(.number.precision(.fractionLength(0))))°C"

        return ToolResult(
            summary: """
                Packing for \(location.fullName) over \(window.count) days
                (range \(range), peak precipitation \(peakRain.formatted(.number.precision(.fractionLength(1))))mm):
                \(items.joined(separator: ", ")).
                """,
            data: .object([
                "coldestC": .number(coldest),
                "warmestC": .number(warmest),
                "items": .array(items.map { .string($0) })
            ])
        )
    }
}

// MARK: - getCalendarSchedule

struct GetCalendarScheduleTool: WeatherTool {
    let name = "getCalendarSchedule"
    let description = """
        Read the user's upcoming calendar events for a date, with start and end
        times. Use this to check whether an activity is outdoors, when the user
        needs to travel, or to warn about weather during an event. Requests
        calendar access if it has not been granted.
        """

    let parameters = ToolSchema(
        properties: [
            "hoursAhead": .init(type: .integer,
                                description: "How many hours ahead to look for events. Defaults to 12, maximum 48.")
        ],
        required: []
    )

    func run(arguments: ToolArguments) async throws -> ToolResult {
        let hoursAhead = min(max(arguments.int("hoursAhead") ?? 12, 1), 48)
        let store = EKEventStore()

        let granted: Bool
        if #available(iOS 17.0, macOS 14.0, *) {
            granted = try await store.requestFullAccessToEvents()
        } else {
            granted = await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { ok, _ in
                    continuation.resume(returning: ok)
                }
            }
        }

        guard granted else {
            throw WeatherToolError.permissionDenied("your calendar")
        }

        let start = Date()
        let end = start.addingTimeInterval(TimeInterval(hoursAhead) * 3600)
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }

        guard !events.isEmpty else {
            return ToolResult(summary: "Nothing on your calendar for the next \(hoursAhead) hours.")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM, HH:mm"
        // Times are the user's own calendar entries, so the device zone is correct here.

        let lines = events.map { event in
            let start = formatter.string(from: event.startDate)
            let end = formatter.string(from: event.endDate)
            let location = event.location ?? ""
            return "\(start)–\(end) \(event.title ?? "Untitled")\(location.isEmpty ? "" : " at \(location)")"
        }

        return ToolResult(
            summary: "\(events.count) upcoming event(s):\n" + lines.joined(separator: "\n"),
            data: .array(events.map { event in
                .object([
                    "title": .string(event.title ?? "Untitled"),
                    "start": .string(formatter.string(from: event.startDate)),
                    "isOutdoor": .bool(Self.looksOutdoor(event))
                ])
            })
        )
    }

    /// Crude but effective heuristic: if an event has a location or notes that
    /// read as outdoors, or a title that does, treat it as an outdoor activity.
    private static func looksOutdoor(_ event: EKEvent) -> Bool {
        let haystack = [event.title, event.location, event.notes]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        let outdoor = ["run", "hike", "walk", "cycle", "bike", "golf", "park",
                       "outdoor", "stadium", "trail", "beach", "picnic"]
        let indoor = ["meeting", "call", "lunch", "office", "interview",
                      "appointment", "standup", "review"]
        if outdoor.contains(where: { haystack.contains($0) }) { return true }
        if indoor.contains(where: { haystack.contains($0) }) { return false }
        return false
    }
}

// MARK: - Shared helpers

/// Describes what is falling so tool output never says "80% rain" during a
/// snowstorm. Kept in one place because both forecast tools need it.
func precipKind(_ condition: String, tempC: Double) -> String {
    let text = condition.lowercased()
    if text.contains("snow") || text.contains("sleet") || text.contains("blizzard") { return "snow" }
    if text.contains("ice") || text.contains("freezing") { return "freezing rain" }
    if text.contains("thunder") { return "thunderstorms" }
    if text.contains("drizzle") { return "drizzle" }
    return tempC <= 1.0 ? "freezing rain" : "rain"
}

// MARK: - Registry

/// Name-to-tool lookup used by the agent's dispatch step and, when a backend
/// needs it, to build the tool list for a model prompt.
struct WeatherToolRegistry: Sendable {
    private let tools: [String: any WeatherTool]

    init(_ tools: [any WeatherTool]) {
        self.tools = Dictionary(uniqueKeysWithValues: tools.map { ($0.name, $0) })
    }

    /// Builds the default registry wired to a data source.
    static func standard(dataSource: any WeatherDataSource) -> WeatherToolRegistry {
        WeatherToolRegistry([
            FetchCurrentWeatherTool(dataSource: dataSource),
            GetForecastRangeTool(dataSource: dataSource),
            GetHourlyWindowTool(dataSource: dataSource),
            CalculateClothingLayersTool(dataSource: dataSource),
            GetCalendarScheduleTool()
        ])
    }

    var all: [any WeatherTool] { Array(tools.values) }

    func tool(named name: String) throws -> any WeatherTool {
        guard let tool = tools[name] else { throw WeatherToolError.unknownTool(name) }
        return tool
    }

    /// Function-calling descriptors for an OpenAI-compatible chat completions
    /// request. Unused by the local heuristic backend.
    func openAIFunctionSpecs() -> [[String: Any]] {
        all.map { tool in
            [
                "type": "function",
                "function": [
                    "name": tool.name,
                    "description": tool.description,
                    "parameters": tool.parameters.jsonDictionary()
                ]
            ]
        }
    }
}
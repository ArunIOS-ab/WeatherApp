//
//  WeatherAPIClient.swift
//  WeatherApp
//
//  Network-backed `WeatherDataSource`. Decodes weatherapi.com forecast payloads
//  into the domain models the agent reasons over, with an in-memory cache so
//  the agent has something to work with when the network is unavailable.
//

import Foundation
import Alamofire

actor WeatherAPIClient: WeatherDataSource {

    static let shared = WeatherAPIClient()

    private var cache: [GeoLocation: WeatherSnapshot] = [:]
    private var cacheTimestamps: [GeoLocation: Date] = [:]
    private let ttl: TimeInterval = 15 * 60
    private let baseURL = "https://api.weatherapi.com/v1"

    /// Stale-while-revalidate: a cached snapshot older than the TTL is still
    /// returned, with a background refresh kicked off. The agent would rather
    /// answer with slightly old data than refuse to answer.
    private func cached(_ location: GeoLocation) -> WeatherSnapshot? {
        cache[location]
    }

    private func isFresh(_ location: GeoLocation) -> Bool {
        guard let ts = cacheTimestamps[location] else { return false }
        return Date().timeIntervalSince(ts) < ttl
    }

    func snapshot(for location: GeoLocation) async throws -> WeatherSnapshot {
        if isFresh(location), let cached = cache[location] {
            return cached
        }

        if let cached = cache[location] {
            Task { try? await self.fetch(location) }
            return cached
        }

        return try await fetch(location)
    }

    private func fetch(_ location: GeoLocation) async throws -> WeatherSnapshot {
        // Fail fast with an actionable message. Without a key every request
        // returns 401, which otherwise surfaces as an opaque decoding failure
        // and looks like a bug in the decoder rather than a setup problem.
        guard AppConstants.isAPIKeyConfigured else {
            throw WeatherToolError.failed(
                "No weatherapi.com key configured. Set WEATHER_API_KEY as a build setting."
            )
        }

        let parameters: Parameters = [
            "key": AppConstants.apiKey,
            "q": "\(location.lat),\(location.lon)",
            "days": 5,
            "aqi": "no",
            "alerts": "yes"
        ]

        let decoded = try await AF.request("\(baseURL)/forecast.json",
                                           method: .get,
                                           parameters: parameters)
            .serializingDecodable(ForecastResponse.self)
            .value

        let snapshot = try decoded.snapshot()

        cache[location] = snapshot
        cacheTimestamps[location] = Date()
        return snapshot
    }

    func searchLocations(query: String) async throws -> [GeoLocation] {
        guard AppConstants.isAPIKeyConfigured else {
            throw WeatherToolError.failed(
                "No weatherapi.com key configured. Set WEATHER_API_KEY as a build setting."
            )
        }

        let parameters: Parameters = [
            "key": AppConstants.apiKey,
            "q": query
        ]

        // Reuses the existing geocoding model rather than duplicating it.
        let results = try await AF.request("\(baseURL)/search.json",
                                           method: .get,
                                           parameters: parameters)
            .serializingDecodable(Welcome.self)
            .value

        return results.map {
            GeoLocation(name: $0.name, region: $0.region, country: $0.country,
                        lat: $0.lat, lon: $0.lon)
        }
    }

    /// Seeds the cache directly. Used by previews and tests.
    func seed(_ snapshot: WeatherSnapshot) {
        cache[snapshot.location] = snapshot
        cacheTimestamps[snapshot.location] = Date()
    }
}

// MARK: - Response decoding

/// Narrow view of the weatherapi.com forecast payload. Only the fields the
/// agent actually uses are modelled.
struct ForecastResponse: Decodable {
    struct Root: Decodable {
        let location: LocationPayload
        let current: CurrentPayload
        let forecast: ForecastPayload
        let alerts: AlertsPayload?
    }

    let location: LocationPayload
    let current: CurrentPayload
    let forecast: ForecastPayload
    let alerts: AlertsPayload?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DataKeys.self)

        // weatherapi returns the forecast fields at the TOP level of
        // /forecast.json. Some responses (and the API's own sample payloads)
        // wrap them in a "data" object instead, so accept both shapes rather
        // than failing with keyNotFound("data") on every request.
        let data: KeyedDecodingContainer<DataKeys>
        if container.contains(.data), let nested = try? container.nestedContainer(keyedBy: DataKeys.self, forKey: .data) {
            data = nested
        } else {
            data = container
        }

        location = try data.decode(LocationPayload.self, forKey: .location)
        current = try data.decode(CurrentPayload.self, forKey: .current)
        forecast = try data.decode(ForecastPayload.self, forKey: .forecast)
        alerts = try? data.decode(AlertsPayload.self, forKey: .alerts)
    }

    private enum DataKeys: String, CodingKey {
        case data, location, current, forecast, alerts
    }

    func snapshot() throws -> WeatherSnapshot {
        let current = CurrentConditions(
            tempC: current.tempC,
            feelsLikeC: current.feelsLikeC,
            windKph: current.windKph,
            windDirection: current.windDirection,
            humidity: current.humidity,
            uvIndex: current.uv,
            isDay: current.isDay == 1,
            conditionText: current.condition.text,
            precipMM: current.precipMM,
            gustKph: current.gustKph,
            cloudCover: current.cloud
        )

        // The forecast clock belongs to the queried city, not to the device. Parsing
        // "2026-10-18 14:00" in the device's zone makes every displayed hour
        // wrong by the zone difference (Tokyo is 13 hours ahead of Toronto), and
        // can land on the wrong calendar day near midnight.
        let zone = Self.timeZone(for: location)

        // Pair each hour with its parent day's date. The closure parameters are
        // named explicitly: an inner `$0` would shadow the ForecastDayPayload
        // and refer to HourPayload, which has no `date` of its own (only `time`).
        //
        // Build every entry before filtering. `forecastday[0].hour` starts at
        // 00:00, so taking a prefix of the flattened list yields midnight-to-23:00
        // of the first date — mostly hours that have already passed. The
        // dashboard, the timing tool and the insights all assume a forward-looking
        // window, so past hours are dropped before the limit is applied.
        let now = Date()
        let hourly = forecast.forecastday
            .flatMap { day in
                day.hour.map { hour in (dayDate: day.date, hour: hour) }
            }
            .map { pair in
                let hour = pair.hour
                return HourlyForecast(
                    date: Self.parseHour(pair.dayDate, time: hour.time, zone: zone),
                    tempC: hour.tempC,
                    feelsLikeC: hour.feelsLikeC,
                    conditionText: hour.condition.text,
                    precipChance: hour.chanceOfRain,
                    precipMM: hour.precipMM,
                    windKph: hour.windKph,
                    humidity: hour.humidity,
                    uvIndex: hour.uv,
                    isDay: hour.isDay == 1
                )
            }
            // Keep the current hour onward. A small negative tolerance keeps the
            // hour in progress rather than dropping straight to the next one.
            .filter { $0.date >= now.addingTimeInterval(-1800) }
            .prefix(24)

        let daily = forecast.forecastday.map { day in
            let astro = day.astro
            return DailyForecast(
                date: Self.parseDate(day.date, zone: zone),
                maxTempC: day.day.maxtempC,
                minTempC: day.day.mintempC,
                conditionText: day.day.condition.text,
                precipChance: day.day.chanceOfRain,
                precipMM: day.day.totalprecipMm,
                uvIndex: day.day.uv,
                windKph: day.day.maxwindKph,
                sunrise: astro.flatMap { Self.parseAstronomy($0.sunrise, on: day.date, zone: zone) },
                sunset: astro.flatMap { Self.parseAstronomy($0.sunset, on: day.date, zone: zone) }
            )
        }

        let alertList = (alerts?.alert ?? []).compactMap { alert -> WeatherAlert? in
            guard let headline = alert.headline ?? alert.event else { return nil }
            let severity = WeatherAlert.Severity(rawValue: alert.severity.lowercased()) ?? .minor
            return WeatherAlert(headline: headline,
                                detail: alert.desc ?? "No further detail provided.",
                                severity: severity)
        }

        return WeatherSnapshot(
            location: GeoLocation(name: location.name, region: location.region,
                                  country: location.country, lat: location.lat, lon: location.lon),
            current: current,
            hourly: Array(hourly),
            daily: daily,
            alerts: alertList,
            fetchedAt: Date(),
            // Retained so consumers can format instants in the city's zone
            // rather than the device's.
            timeZoneIdentifier: location.tzId
        )
    }

    /// Parses one hourly entry into a `Date`.
    ///
    /// weatherapi's `hour[].time` is already a full local timestamp
    /// ("2026-10-18 14:00") — it is NOT a bare clock. The parent day is passed
    /// in only as a fallback for the case where the field carries just a time.
    ///
    /// Prepending the day unconditionally produced strings like
    /// "2026-10-18 2026-10-18 14:00", which fail to parse and silently fall back
    /// to midnight — collapsing the entire hourly series onto one timestamp.
    private static func parseHour(_ day: String, time: String, zone: TimeZone) -> Date {
        // Already a full timestamp: use as-is.
        if let date = makeFormatter("yyyy-MM-dd HH:mm", zone: zone).date(from: time) {
            return date
        }
        // Bare clock ("14:00"): combine with the parent day.
        if let date = makeFormatter("yyyy-MM-dd HH:mm", zone: zone).date(from: "\(day) \(time)") {
            return date
        }
        // Last resort: keep the correct day rather than snapping to "now".
        return parseDate(day, zone: zone)
    }

    /// weatherapi returns local timestamps as "2024-05-01 10:00" with no zone, so
    /// they must be interpreted in the queried city's zone.
    private static func parseDate(_ raw: String, zone: TimeZone) -> Date {
        for format in ["yyyy-MM-dd HH:mm", "yyyy-MM-dd"] {
            if let date = makeFormatter(format, zone: zone).date(from: raw) { return date }
        }
        return Date()
    }

    /// Resolves the forecast location's IANA zone.
    ///
    /// Falls back to the device zone when the provider sends an identifier this
    /// system does not recognise, which is better than failing to parse at all.
    private static func timeZone(for location: LocationPayload) -> TimeZone {
        guard let id = location.tzId, let zone = TimeZone(identifier: id) else {
            return .current
        }
        return zone
    }

    /// Parses a sunrise/sunset clock value.
    ///
    /// weatherapi sends these as "07:23 AM" / "06:12 PM" — a 12-hour clock with
    /// no date. Splitting on whitespace and parsing the first token (the old
    /// behaviour) extracted "07:23" and failed, so sunrise/sunset were always nil.
    ///
    /// - Parameter day: the forecast day, used to supply the missing date.
    private static func parseAstronomy(_ raw: String, on day: String, zone: TimeZone) -> Date? {
        let clock = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clock.isEmpty else { return nil }

        // "hh:mm a" handles the 12-hour values weatherapi sends; "HH:mm" covers any
        // 24-hour variant.
        for format in ["hh:mm a", "HH:mm"] {
            if let parsed = makeFormatter(format, zone: zone).date(from: clock.uppercased()) {
                // Combine the parsed clock with the forecast day's date so the
                // value carries both parts.
                let time = makeFormatter("HH:mm", zone: zone).string(from: parsed)
                if let date = makeFormatter("yyyy-MM-dd HH:mm", zone: zone).date(from: "\(day) \(time)") {
                    return date
                }
            }
        }
        return nil
    }

    /// Formatters keyed by format *and* time zone.
    ///
    /// A `DateFormatter` carries its zone as mutable state, so one shared
    /// instance cannot serve two cities: reassigning `.timeZone` per call would
    /// corrupt every cached formatter. Keying on both makes each combination
    /// safe to reuse.
    private static let formatters: [FormatterKey: DateFormatter] = {
        let zone = TimeZone.current
        return ["yyyy-MM-dd HH:mm", "yyyy-MM-dd", "hh:mm a"]
            .reduce(into: [:]) { result, format in
                result[FormatterKey(format: format, zoneID: zone.identifier)] =
                    make(format, zone: zone)
            }
    }()

    private static func makeFormatter(_ format: String, zone: TimeZone) -> DateFormatter {
        let key = FormatterKey(format: format, zoneID: zone.identifier)
        if let cached = formatters[key] { return cached }

        // Rare (a zone not seen before). Build it; caching it would need a lock
        // for no measurable benefit.
        return make(format, zone: zone)
    }

    private static func make(_ format: String, zone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        // POSIX locale is required, otherwise a user's calendar (for example a
        // Buddhist or Japanese locale) makes parsing fail outright.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.dateFormat = format
        return formatter
    }

    private struct FormatterKey: Hashable {
        let format: String
        let zoneID: String
    }
}

extension ForecastResponse {

    struct LocationPayload: Decodable {
        let name: String
        let region: String
        let country: String
        let lat: Double
        let lon: Double
        /// IANA zone for the forecast, e.g. "Asia/Tokyo". Forecast timestamps
        /// are local wall-clock times in this zone, not the device's.
        let tzId: String?

        enum CodingKeys: String, CodingKey {
            case name, region, country, lat, lon
            case tzId = "tz_id"
        }
    }

    struct ConditionPayload: Decodable {
        let text: String
    }

    struct CurrentPayload: Decodable {
        let tempC: Double
        let feelsLikeC: Double
        let windKph: Double
        let windDirection: String
        let humidity: Int
        let isDay: Int
        let precipMM: Double
        let uv: Double
        let condition: ConditionPayload
        let gustKph: Double?
        let cloud: Int?

        /// weatherapi uses snake_case on the wire. Without these mappings Swift
        /// looks for "tempC", "windKph" and so on, and every request fails with
        /// `keyNotFound`.
        enum CodingKeys: String, CodingKey {
            case tempC = "temp_c"
            case feelsLikeC = "feelslike_c"
            case windKph = "wind_kph"
            case windDirection = "wind_dir"
            case humidity
            case isDay = "is_day"
            case precipMM = "precip_mm"
            case uv
            case condition
            case gustKph = "gust_kph"
            case cloud
        }
    }

    struct HourPayload: Decodable {
        let time: String
        let tempC: Double
        let feelsLikeC: Double
        let precipMM: Double
        let humidity: Int
        let isDay: Int
        let windKph: Double
        let uv: Double
        let chanceOfRain: Int
        let condition: ConditionPayload

        enum CodingKeys: String, CodingKey {
            case time
            case tempC = "temp_c"
            case feelsLikeC = "feelslike_c"
            case precipMM = "precip_mm"
            case humidity
            case isDay = "is_day"
            case windKph = "wind_kph"
            case uv
            case chanceOfRain = "chance_of_rain"
            case condition
        }
    }

    /// Sunrise/sunset for one forecast day.
    ///
    /// `astro` is a single object on the day, not an array, and its times are
    /// clock values like "07:23 AM" with no date attached.
    struct AstroPayload: Decodable {
        let sunrise: String
        let sunset: String
    }

    struct DayPayload: Decodable {
        let maxtempC: Double
        let mintempC: Double
        let uv: Double
        let maxwindKph: Double
        let totalprecipMm: Double
        /// The daily block names this `daily_chance_of_rain`, NOT
        /// `chance_of_rain` (which only appears on hourly entries). Decoding the
        /// hourly name here throws keyNotFound on every real forecast response.
        let chanceOfRain: Int
        let condition: ConditionPayload

        enum CodingKeys: String, CodingKey {
            case maxtempC = "maxtemp_c"
            case mintempC = "mintemp_c"
            case uv
            case maxwindKph = "maxwind_kph"
            case totalprecipMm = "totalprecip_mm"
            case chanceOfRain = "daily_chance_of_rain"
            case condition
        }
    }

    struct ForecastDayPayload: Decodable {
        let date: String
        let day: DayPayload
        let hour: [HourPayload]
        let astro: AstroPayload?
    }

    struct ForecastPayload: Decodable {
        let forecastday: [ForecastDayPayload]
    }

    struct AlertPayload: Decodable {
        let headline: String?
        let event: String?
        let severity: String
        let desc: String?
    }

    struct AlertsPayload: Decodable {
        let alert: [AlertPayload]?
    }
}


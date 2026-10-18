//
//  WeatherModels.swift
//  WeatherApp
//
//  Domain models for the agentic layer. These are the types the reasoning
//  engine and the tools operate on, kept deliberately free of any UI or
//  networking concerns.
//

import Foundation

// MARK: - Location

struct GeoLocation: Codable, Hashable, Identifiable {
    let name: String
    let region: String
    let country: String
    let lat: Double
    let lon: Double

    var id: String { "\(name)-\(lat),\(lon)" }

    /// "Ontario, Canada" with empty segments dropped.
    var displayName: String {
        [region, country].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    /// City plus region, used when the agent needs to name a place in prose.
    var fullName: String {
        displayName.isEmpty ? name : "\(name), \(displayName)"
    }
}

// MARK: - Current conditions

struct CurrentConditions: Codable, Hashable {
    let tempC: Double
    let feelsLikeC: Double
    let windKph: Double
    let windDirection: String
    let humidity: Int
    let uvIndex: Double
    let isDay: Bool
    let conditionText: String
    let precipMM: Double
    let gustKph: Double?
    let cloudCover: Int?

    /// Heat index is only meaningful in warm, humid conditions. In cold weather
    /// wind chill is the dominant factor, so we blend rather than always
    /// trusting the provider's "feels like".
    var apparentTempC: Double {
        if tempC >= 26 {
            return feelsLikeC
        } else if tempC <= 10 && windKph > 4.8 {
            let windChill = 13.12 + 0.6215 * tempC
                - 11.37 * pow(windKph, 0.16) + 0.3965 * tempC * pow(windKph, 0.16)
            return min(windChill, tempC)
        }
        return feelsLikeC
    }
}

// MARK: - Forecasts

struct HourlyForecast: Codable, Hashable, Identifiable {
    let date: Date
    let tempC: Double
    let feelsLikeC: Double
    let conditionText: String
    let precipChance: Int
    let precipMM: Double
    let windKph: Double
    let humidity: Int
    let uvIndex: Double
    let isDay: Bool

    var id: Date { date }
}

struct DailyForecast: Codable, Hashable, Identifiable {
    let date: Date
    let maxTempC: Double
    let minTempC: Double
    let conditionText: String
    let precipChance: Int
    let precipMM: Double
    let uvIndex: Double
    let windKph: Double
    let sunrise: Date?
    let sunset: Date?

    var id: Date { date }

    /// Comfortable running requires a narrow comfort band. A 22 degree spread
    /// between high and low means you will overheat and then freeze.
    var tempSpreadC: Double { maxTempC - minTempC }
}

struct WeatherSnapshot: Codable, Hashable {
    let location: GeoLocation
    let current: CurrentConditions
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
    let alerts: [WeatherAlert]
    let fetchedAt: Date

    /// Forecast horizons the agent is allowed to reason over. Beyond this,
    /// confidence drops far enough that the agent should say so out loud.
    static let reliableHorizonHours: Int = 48
}

struct WeatherAlert: Codable, Hashable, Identifiable {
    let headline: String
    let detail: String
    let severity: Severity

    var id: String { headline }

    enum Severity: String, Codable, Hashable {
        case minor, moderate, severe, extreme
    }
}

// MARK: - Derived comfort metrics

/// Precomputed signals the reasoning engine uses so that the "is it a good day
/// to run" logic lives in one place instead of being scattered across views.
struct ComfortAssessment: Hashable {
    /// 0...1, higher is better for sustained outdoor exertion.
    let exerciseScore: Double
    let precipitationRisk: Double
    let windStress: Double
    let coldStress: Double
    let heatStress: Double
    let uvStress: Double
    let comfortLabel: String

    static func assess(_ snapshot: WeatherSnapshot, lookAheadHours: Int = 3) -> ComfortAssessment {
        let current = snapshot.current
        let window = Array(snapshot.hourly.prefix(lookAheadHours))

        // Precipitation risk is the peak chance across the window, nudged up by
        // any measurable accumulation.
        let peakChance = Double(window.map(\.precipChance).max() ?? 0) / 100.0
        let totalPrecip = window.reduce(0.0) { $0 + $1.precipMM }
        let precipRisk = min(1.0, peakChance + min(0.4, totalPrecip * 0.2))

        // Wind becomes a real problem for running around 25 kph and above, and peaks
        // around 45. Using gusts when available.
        let peakWind = max(current.windKph, window.map(\.windKph).max() ?? 0)
        let gusts = current.gustKph ?? peakWind
        let windStress = Self.normalise(gusts, ideal: 8, tolerance: 32)

        // Comfortable apparent temperature for sustained exercise sits roughly
        // between 10 and 24 degrees. Stress ramps linearly outside that band:
        // cold reaches maximum severity by -10, heat by 38.
        let apparent = current.apparentTempC
        let coldStress = apparent < 10 ? min(1, (10 - apparent) / 20) : 0
        let heatStress = apparent > 24 ? min(1, (apparent - 24) / 14) : 0

        // UV 3 is the comfortable ceiling; 11+ is extreme.
        let peakUV = max(current.uvIndex, window.map(\.uvIndex).max() ?? 0)
        let uvStress = Self.normalise(peakUV, ideal: 3, tolerance: 8)

        // Penalties compound but with diminishing returns: two mild problems are
        // worse than one, three are not nine times worse.
        //
        // Heat and cold carry the most weight because they are the two factors
        // that actually make running unsafe rather than merely unpleasant.
        // UV and wind matter but rarely stop someone outright.
        let penalty = (precipRisk * 0.40)
            + (windStress * 0.20)
            + (coldStress * 0.45)
            + (heatStress * 0.50)
            + (uvStress * 0.18)
        let score = max(0, min(1, 1 - penalty))

        let label: String
        switch score {
        case 0.75...: label = "Excellent"
        case 0.55..<0.75: label = "Good"
        case 0.35..<0.55: label = "Fair"
        case 0.15..<0.35: label = "Poor"
        default: label = "Not advisable"
        }

        return ComfortAssessment(exerciseScore: score,
                                 precipitationRisk: precipRisk,
                                 windStress: windStress,
                                 coldStress: coldStress,
                                 heatStress: heatStress,
                                 uvStress: uvStress,
                                 comfortLabel: label)
    }

    /// Maps a measurement onto 0...1 stress, where 0 is within the ideal band and
    /// 1 is at the far edge of the tolerable band.
    ///
    /// `ideal` is the best-case value and `tolerance` is how far from it stress
    /// starts. This is intentionally different from passing both endpoints and
    /// dividing: the previous form returned 0 for anything under the ideal
    /// value, so 34°C scored as "perfect heat" while 39°C was only 1.0.
    private static func normalise(_ value: Double, ideal: Double, tolerance: Double) -> Double {
        guard tolerance > 0 else { return 0 }
        let excess = abs(value - ideal)
        return max(0, min(1, excess / tolerance))
    }
}
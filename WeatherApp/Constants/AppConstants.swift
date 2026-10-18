//
//  AppConstants.swift
//  WeatherApp
//

import Foundation

struct AppConstants {
    static let serverURL: String = "https://api.weatherapi.com/v1/search.json?key=API_KEY&q=London"

    /// weatherapi.com key, supplied at build time.
    ///
    /// Set `WEATHER_API_KEY` as a User-Defined build setting in .xcconfig and
    /// reference it as `$(WEATHER_API_KEY)` in the target's Info.plist, then read
    /// it here. Do not commit a literal key: anything in the binary is
    /// extractable, and a leaked key can rack up charges. Restrict the key by
    /// API scope in the provider dashboard.
    static let apiKey: String = {
        let key = Bundle.main.object(forInfoDictionaryKey: "WEATHER_API_KEY") as? String ?? ""
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        // Treat the unexpanded build-setting placeholder as "missing" rather
        // than sending it. Sending "API_KEY" produces a 401 that surfaces as a
        // baffling decoding error deep in the network layer, so the placeholder
        // is treated as unset here and reported clearly by `isAPIKeyConfigured`.
        return (trimmed.isEmpty || trimmed == "API_KEY" || trimmed.hasPrefix("$("))
            ? ""
            : trimmed
    }()

    /// False when no usable key is present, so callers can fail fast with a
    /// readable message instead of attempting doomed requests.
    static var isAPIKeyConfigured: Bool { !apiKey.isEmpty }
}

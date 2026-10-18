//
//  WeatherIcon.swift
//  WeatherApp
//
//  Maps weatherapi.com condition text onto SF Symbols.
//
//  The original design used pre-rendered PNGs in the asset catalogue
//  (`img_1161` and friends), which only work for one fixed condition. Mapping to
//  SF Symbols keeps the icon meaningful for any location, which matters now that
//  the weather is real rather than mock data.
//
//  Matching is by keyword rather than exact string: the provider has ~30
//  distinct condition texts ("Patchy rain nearby", "Light rain shower",
//  "Moderate or heavy snow showers"…) and the list shifts over time. A
//  keyword scan degrades gracefully when an unseen text arrives, whereas an
//  exhaustive switch silently falls through to a plain cloud.
//

import Foundation

enum WeatherIcon {

    /// SF Symbol for a condition string.
    ///
    /// Takes the condition *text* rather than a forecast model on purpose: one
    /// `String` parameter means there is no overload that can silently capture
    /// the wrong type at a call site.
    static func symbol(for text: String) -> String {
        let condition = text.lowercased()

        // Ordered most-specific first: "thunder" beats "rain", which beats
        // "cloud". A storm icon must win over a rain icon.
        if condition.contains("thunder") { return "cloud.bolt.rain" }
        if condition.contains("blizzard") || condition.contains("blowing snow") { return "snowflake" }

        if condition.contains("freezing") || condition.contains("sleet")
            || condition.contains("ice pellets") {
            return "cloud.sleet"
        }

        if condition.contains("snow") || condition.contains("ice") {
            return condition.contains("heavy") ? "snowflake" : "cloud.snow"
        }

        if condition.contains("rain") {
            if condition.contains("heavy") || condition.contains("torrential") {
                return "cloud.heavyrain"
            }
            if condition.contains("shower") || condition.contains("patchy")
                || condition.contains("moderate") || condition.contains("light") {
                return "cloud.rain"
            }
            return "cloud.rain"
        }

        if condition.contains("drizzle") { return "cloud.drizzle" }
        if condition.contains("mist") || condition.contains("fog") { return "cloud.fog" }

        // Clear-ish conditions get a day/night treatment: "Clear" at 2am should
        // not render as a bright sun.
        if condition.contains("clear") || condition.contains("sunny") {
            return isNight ? "moon.stars" : "sun.max"
        }
        if condition.contains("partly cloudy") {
            return isNight ? "cloud.moon" : "cloud.sun"
        }
        if condition.contains("overcast") || condition.contains("cloudy") {
            return isNight ? "cloud.moon.fill" : "cloud.fill"
        }

        return "cloud"
    }

    private static var isNight: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 6 || hour >= 19
    }
}
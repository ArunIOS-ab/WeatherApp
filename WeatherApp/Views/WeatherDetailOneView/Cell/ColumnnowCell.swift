//
//  ColumnnowCell.swift
//  WeatherApp
//
import SwiftUI

/// One hourly forecast column: time, icon, temperature.
struct ColumnnowCell: View {
    let hour: HourlyForecast
    /// The forecast city's zone. Required: formatting `hour.date` with the
    /// device's zone would show the wrong time for any city abroad.
    var timeZone: TimeZone = .current

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(timeLabel)
                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(12.0)))
                .fontWeight(.regular)
                .foregroundColor(ColorConstants.Black900)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .frame(width: getRelativeWidth(30.0), height: getRelativeHeight(17.0),
                       alignment: .leading)

            Image(systemName: WeatherIcon.symbol(for: hour.conditionText))
                .resizable()
                .frame(width: getRelativeWidth(16.0), height: getRelativeWidth(16.0))
                .scaledToFit()
                .foregroundColor(ColorConstants.Bluegray400)
                .padding(.top, getRelativeHeight(4.0))
                .padding(.horizontal, getRelativeWidth(5.0))

            // Chance of precipitation only when there is some: a "0%" on every
            // column is noise.
            if hour.precipChance >= 10 {
                Text("\(hour.precipChance)%")
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(10.0)))
                    .foregroundColor(ColorConstants.IndigoA400)
                    .lineLimit(1)
                    .padding(.top, getRelativeHeight(2.0))
            } else {
                Text(" ")
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(10.0)))
            }

            Text(tempLabel)
                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(12.0)))
                .fontWeight(.regular)
                .foregroundColor(ColorConstants.Black900)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .frame(width: getRelativeWidth(28.0), height: getRelativeHeight(17.0),
                       alignment: .leading)
                .padding(.top, getRelativeHeight(4.0))
                .padding(.horizontal, getRelativeWidth(1.0))
        }
        .frame(width: getRelativeWidth(34.0), alignment: .leading)
    }

    /// The next hour reads "Now"; later ones read their clock time.
    private var timeLabel: String {
        let interval = hour.date.timeIntervalSinceNow
        // Within 45 minutes is effectively the current hour.
        guard interval > 45 * 60 else { return StringConstants.kLblNow }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "ha"
        return formatter.string(from: hour.date)
    }

    private var tempLabel: String {
        "\(Int(hour.tempC.rounded()))°c"
    }
}

struct ColumnnowCell_Previews: PreviewProvider {
    static var previews: some View {
        ColumnnowCell(hour: HourlyForecast(
            date: Date(), tempC: 19, feelsLikeC: 20, conditionText: "Partly cloudy",
            precipChance: 20, precipMM: 0, windKph: 10, humidity: 50, uvIndex: 3, isDay: true
        ))
    }
}
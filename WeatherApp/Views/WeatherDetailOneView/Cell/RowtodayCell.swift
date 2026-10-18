//
//  RowtodayCell.swift
//  WeatherApp
//
import SwiftUI

/// One row of the multi-day forecast: day name, icon, high and low.
struct RowtodayCell: View {
    let day: DailyForecast
    /// First row reads "Today", later rows read the weekday.
    var isToday: Bool = false

    var body: some View {
        HStack {
            Text(dayLabel)
                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(12.0)))
                .fontWeight(.regular)
                .foregroundColor(ColorConstants.Bluegray900)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .frame(width: getRelativeWidth(40.0), height: getRelativeHeight(17.0),
                       alignment: .leading)

            HStack {
                Image(systemName: WeatherIcon.symbol(for: day.conditionText))
                    .resizable()
                    .frame(width: getRelativeWidth(23.0), height: getRelativeWidth(23.0))
                    .scaledToFit()
                    .foregroundColor(ColorConstants.Bluegray400)

                if day.precipChance >= 10 {
                    Text("\(day.precipChance)%")
                        .font(FontScheme.kAvenirRoman(size: getRelativeHeight(10.0)))
                        .foregroundColor(ColorConstants.IndigoA400)
                        .lineLimit(1)
                        .padding(.leading, getRelativeWidth(3.0))
                }

                Image(systemName: "arrow.up")
                    .resizable()
                    .frame(width: getRelativeWidth(7.0), height: getRelativeHeight(12.0))
                    .scaledToFit()
                    .padding(.leading, getRelativeWidth(10.0))

                Text(highLabel)
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(14.0)))
                    .fontWeight(.regular)
                    .foregroundColor(ColorConstants.Bluegray900)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(width: getRelativeWidth(30.0), height: getRelativeHeight(20.0),
                           alignment: .leading)
                    .padding(.leading, getRelativeWidth(5.0))

                Image(systemName: "arrow.down")
                    .resizable()
                    .frame(width: getRelativeWidth(7.0), height: getRelativeHeight(12.0))
                    .scaledToFit()
                    .padding(.leading, getRelativeWidth(17.0))

                Text(lowLabel)
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(14.0)))
                    .fontWeight(.regular)
                    .foregroundColor(ColorConstants.Bluegray900)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(width: getRelativeWidth(30.0), height: getRelativeHeight(20.0),
                           alignment: .leading)
                    .padding(.leading, getRelativeWidth(5.0))
            }
            .frame(width: getRelativeWidth(250.0), alignment: .leading)
        }
        .frame(width: getRelativeWidth(300.0), height: getRelativeHeight(32.0),
               alignment: .leading)
    }

    private var dayLabel: String {
        isToday
            ? StringConstants.kLblToday
            : day.date.formatted(.dateTime.weekday(.abbreviated))
    }

    private var highLabel: String { "\(Int(day.maxTempC.rounded()))°" }
    private var lowLabel: String  { "\(Int(day.minTempC.rounded()))°" }
}

struct RowtodayCell_Previews: PreviewProvider {
    static var previews: some View {
        RowtodayCell(
            day: DailyForecast(date: Date(), maxTempC: 20, minTempC: 12,
                               conditionText: "Partly cloudy", precipChance: 30,
                               precipMM: 0.4, uvIndex: 4, windKph: 12,
                               sunrise: nil, sunset: nil),
            isToday: true
        )
    }
}
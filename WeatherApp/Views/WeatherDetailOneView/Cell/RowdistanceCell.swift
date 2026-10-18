//
//  RowdistanceCell.swift
//  WeatherApp
//
import SwiftUI

/// Precipitation and wind for the selected location.
struct RowdistanceCell: View {
    let precipitationMM: Double
    let windKph: Double
    let windDirection: String

    var body: some View {
        HStack {
            // Precipitation
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "drop.fill")
                        .resizable()
                        .frame(width: getRelativeWidth(9.0), height: getRelativeHeight(13.0))
                        .scaledToFit()
                        .foregroundColor(ColorConstants.Bluegray700)
                    Text(StringConstants.kLblPrecipitation)
                        .font(FontScheme.kAvenirRoman(size: getRelativeHeight(12.0)))
                        .fontWeight(.regular)
                        .foregroundColor(ColorConstants.Bluegray700)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                        .frame(width: getRelativeWidth(65.0), height: getRelativeHeight(17.0),
                               alignment: .leading)
                        .padding(.leading, getRelativeWidth(4.0))
                }
                .frame(width: getRelativeWidth(81.0), height: getRelativeHeight(17.0),
                       alignment: .leading)
                .padding(.top, getRelativeHeight(14.0))
                .padding(.horizontal, getRelativeWidth(10.0))

                Text(precipitationLabel)
                    .font(FontScheme.kAvenirMedium(size: getRelativeHeight(16.0)))
                    .fontWeight(.medium)
                    .foregroundColor(ColorConstants.Bluegray900)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(width: getRelativeWidth(80.0), height: getRelativeHeight(22.0),
                           alignment: .leading)
                    .padding(.vertical, getRelativeHeight(5.0))
                    .padding(.horizontal, getRelativeWidth(10.0))
            }
            .frame(width: getRelativeWidth(172.0), height: getRelativeHeight(73.0),
                   alignment: .leading)
            .background(RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0,
                                       bottomRight: 8.0)
                .fill(ColorConstants.Gray102))

            // Wind
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "wind")
                            .resizable()
                            .frame(width: getRelativeWidth(14.0), height: getRelativeHeight(13.0))
                            .scaledToFit()
                            .foregroundColor(ColorConstants.Bluegray700)
                        Text(StringConstants.kLblWind)
                            .font(FontScheme.kAvenirRoman(size: getRelativeHeight(12.0)))
                            .fontWeight(.regular)
                            .foregroundColor(ColorConstants.Bluegray700)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .frame(width: getRelativeWidth(27.0), height: getRelativeHeight(17.0),
                                   alignment: .leading)
                            .padding(.leading, getRelativeWidth(4.0))
                    }
                    .frame(width: getRelativeWidth(47.0), height: getRelativeHeight(17.0),
                           alignment: .leading)
                    .padding(.trailing)

                    Text(windLabel)
                        .font(FontScheme.kAvenirMedium(size: getRelativeHeight(16.0)))
                        .fontWeight(.medium)
                        .foregroundColor(ColorConstants.Bluegray900)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                        .frame(width: getRelativeWidth(61.0), height: getRelativeHeight(22.0),
                               alignment: .leading)
                        .padding(.top, getRelativeHeight(9.0))
                }
                .frame(width: getRelativeWidth(61.0), height: getRelativeHeight(50.0),
                       alignment: .leading)
                .padding(.leading, getRelativeWidth(10.0))

                // Compass point, falling back to a dash when unknown.
                Text(windDirection.isEmpty ? "-" : windDirection)
                    .font(FontScheme.kAvenirBlack(size: getRelativeHeight(30.0)))
                    .fontWeight(.black)
                    .foregroundColor(ColorConstants.Bluegray900)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(width: getRelativeWidth(28.0), height: getRelativeHeight(50.0),
                           alignment: .leading)
                    .padding(.leading, getRelativeWidth(56.0))
                    .padding(.trailing, getRelativeWidth(15.0))
            }
            .frame(width: getRelativeWidth(172.0), height: getRelativeHeight(73.0),
                   alignment: .leading)
            .background(RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0,
                                       bottomRight: 8.0)
                .fill(ColorConstants.Gray102))
            .padding(.leading, getRelativeWidth(13.0))
        }
        .frame(width: getRelativeWidth(359.0), alignment: .leading)
        .hideNavigationBar()
    }

    /// Two significant figures is plenty for rainfall and avoids "0.0 mm".
    private var precipitationLabel: String {
        String(format: "%.1f mm", precipitationMM)
    }

    private var windLabel: String {
        String(format: "%.0f kph", windKph)
    }
}

struct RowdistanceCell_Previews: PreviewProvider {
    static var previews: some View {
        RowdistanceCell(precipitationMM: 1.8, windKph: 29.5, windDirection: "N")
    }
}
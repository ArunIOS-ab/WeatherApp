//
//  Column1Cell.swift
//  WeatherApp
//
import SwiftUI

/// One weather alert. Shows the headline, severity and a trimmed description.
struct Column1Cell: View {
    let alert: WeatherAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: getRelativeWidth(6.0)) {
                Image(systemName: iconName)
                    .resizable()
                    .frame(width: getRelativeWidth(13.0), height: getRelativeWidth(13.0))
                    .scaledToFit()
                    .foregroundColor(tint)

                Text(alert.headline)
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(13.0)))
                    .fontWeight(.regular)
                    .foregroundColor(ColorConstants.Black900)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Text(alert.severity.rawValue.capitalized)
                    .font(FontScheme.kAvenirMedium(size: getRelativeHeight(10.0)))
                    .foregroundColor(tint)
            }
            .padding(.horizontal, getRelativeWidth(10.0))
            .padding(.top, getRelativeHeight(10.0))

            Text(alert.detail)
                .font(FontScheme.kAvenirLight(size: getRelativeHeight(11.0)))
                .foregroundColor(ColorConstants.Bluegray700)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, getRelativeWidth(10.0))
                .padding(.top, getRelativeHeight(5.0))
                .padding(.bottom, getRelativeHeight(10.0))
        }
        .frame(width: getRelativeWidth(341.0), alignment: .leading)
        .background(RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0,
                                   bottomRight: 8.0)
            .fill(ColorConstants.Gray101))
    }

    /// Escalating icon and colour with severity, so a moderate alert does not
    /// look identical to an extreme one.
    private var iconName: String {
        switch alert.severity {
        case .minor:     return "cloud"
        case .moderate:  return "exclamationmark.triangle"
        case .severe:    return "exclamationmark.triangle.fill"
        case .extreme:   return "exclamationmark.octagon.fill"
        }
    }

    private var tint: Color {
        switch alert.severity {
        case .minor:     return ColorConstants.Bluegray700
        case .moderate:  return ColorConstants.IndigoA400
        case .severe:    return ColorConstants.Red400
        case .extreme:   return ColorConstants.Red400
        }
    }
}

struct Column1Cell_Previews: PreviewProvider {
    static var previews: some View {
        Column1Cell(alert: WeatherAlert(headline: "Rainfall warning",
                                        detail: "Heavy rain expected over the next 24 hours.",
                                        severity: .moderate))
    }
}
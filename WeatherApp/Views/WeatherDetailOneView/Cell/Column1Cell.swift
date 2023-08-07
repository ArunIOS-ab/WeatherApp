//
//  Column1Cell.swift
//  WeatherApp
//
import SwiftUI

struct Column1Cell: View {
    var body: some View {
        VStack {
            VStack(alignment: .trailing, spacing: 0) {
                Text(StringConstants.kLblThunderstorm)
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(12.0)))
                    .fontWeight(.regular)
                    .foregroundColor(ColorConstants.WhiteA700)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .frame(width: getRelativeWidth(91.0), height: getRelativeHeight(23.0),
                           alignment: .center)
                    .background(ColorConstants.Yellow900)
                    .padding(.leading)
                    .padding(.leading)
                Text(StringConstants.kMsgEnvironmentCan)
                    .font(FontScheme.kAvenirHeavy(size: getRelativeHeight(16.0)))
                    .fontWeight(.heavy)
                    .foregroundColor(ColorConstants.Black900)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(width: getRelativeWidth(154.0), height: getRelativeHeight(22.0),
                           alignment: .leading)
                    .padding(.trailing, getRelativeWidth(187.0))
                Text(StringConstants.kMsg21Jul20238)
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(12.0)))
                    .fontWeight(.regular)
                    .foregroundColor(ColorConstants.Bluegray400)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(width: getRelativeWidth(238.0), height: getRelativeHeight(17.0),
                           alignment: .leading)
                    .padding(.top, getRelativeHeight(4.0))
                    .padding(.trailing, getRelativeWidth(103.0))
                Text(StringConstants.kMsgConditionsAre)
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(16.0)))
                    .fontWeight(.regular)
                    .foregroundColor(ColorConstants.Black900)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(width: getRelativeWidth(336.0), height: getRelativeHeight(483.0),
                           alignment: .leading)
                    .padding(.top, getRelativeHeight(13.0))
                    .padding(.trailing, getRelativeWidth(4.0))
            }
            .frame(width: getRelativeWidth(341.0), height: getRelativeHeight(563.0),
                   alignment: .leading)
            .background(RoundedCorners(topLeft: 4.0, topRight: 4.0, bottomLeft: 4.0,
                                       bottomRight: 4.0).fill(Color.clear))
            .padding(.vertical, getRelativeHeight(10.0))
            .padding(.horizontal, getRelativeWidth(10.0))
        }
        .frame(width: getRelativeWidth(359.0), alignment: .leading)
        .background(RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0, bottomRight: 8.0)
            .fill(ColorConstants.Gray102))
        
    }
}

/* struct Column1Cell_Previews: PreviewProvider {

 static var previews: some View {
             Column1Cell()
 }
 } */

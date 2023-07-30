//
//  RowdistanceCell.swift
//  WeatherApp
//
import SwiftUI

struct RowdistanceCell: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image("img_vector_bluegray_700_13x11")
                        .resizable()
                        .frame(width: getRelativeWidth(9.0), height: getRelativeHeight(13.0),
                               alignment: .leading)
                        .scaledToFit()
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
                Text(StringConstants.kLbl18Mm)
                    .font(FontScheme.kAvenirMedium(size: getRelativeHeight(16.0)))
                    .fontWeight(.medium)
                    .foregroundColor(ColorConstants.Bluegray900)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(width: getRelativeWidth(52.0), height: getRelativeHeight(22.0),
                           alignment: .leading)
                    .padding(.vertical, getRelativeHeight(5.0))
                    .padding(.horizontal, getRelativeWidth(10.0))
            }
            .frame(width: getRelativeWidth(172.0), height: getRelativeHeight(73.0),
                   alignment: .leading)
            .background(RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0,
                                       bottomRight: 8.0)
                    .fill(ColorConstants.Gray102))
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image("img_vector_bluegray_700_13x16")
                            .resizable()
                            .frame(width: getRelativeWidth(14.0), height: getRelativeHeight(13.0),
                                   alignment: .leading)
                            .scaledToFit()
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
                    Text(StringConstants.kLbl295Kph)
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
                Text(StringConstants.kLblN)
                    .font(FontScheme.kAvenirBlack(size: getRelativeHeight(36.0)))
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
}

/* struct RowdistanceCell_Previews: PreviewProvider {

 static var previews: some View {
             RowdistanceCell()
 }
 } */

//
//  RowCellswift.swift
//  WeatherApp
//
import SwiftUI

struct RowCell: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(StringConstants.kLblOttawa)
                    .font(FontScheme.kNewYorkLargeRegular(size: getRelativeHeight(24.0)))
                    .fontWeight(.regular)
                    .foregroundColor(ColorConstants.Black900)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(width: getRelativeWidth(76.0), height: getRelativeHeight(29.0),
                           alignment: .leading)
                    .padding(.trailing)
                Text(StringConstants.kLblOntarioCanada)
                    .font(FontScheme.kAvenirLight(size: getRelativeHeight(14.0)))
                    .fontWeight(.light)
                    .foregroundColor(ColorConstants.Black900)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(width: getRelativeWidth(101.0), height: getRelativeHeight(20.0),
                           alignment: .leading)
                    .padding(.top, getRelativeHeight(8.0))
            }
            .frame(width: getRelativeWidth(101.0), height: getRelativeHeight(57.0),
                   alignment: .leading)
            VStack(alignment: .trailing, spacing: 0) {
                HStack {
                    Text(StringConstants.kLbl19C)
                        .font(FontScheme.kAvenirRoman(size: getRelativeHeight(24.0)))
                        .fontWeight(.regular)
                        .foregroundColor(ColorConstants.Black900)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                        .frame(width: getRelativeWidth(46.0), height: getRelativeHeight(33.0),
                               alignment: .leading)
                    Spacer()
                    Image("img_image1")
                        .resizable()
                        .frame(width: getRelativeWidth(20.0), height: getRelativeWidth(22.0),
                               alignment: .leading)
                        .scaledToFit()
                        .padding(.vertical, getRelativeHeight(5.0))
                }
                .frame(width: getRelativeWidth(76.0), height: getRelativeHeight(33.0),
                       alignment: .leading)
                Text(StringConstants.kLbl200Am)
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(14.0)))
                    .fontWeight(.regular)
                    .foregroundColor(ColorConstants.Gray500)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(width: getRelativeWidth(49.0), height: getRelativeHeight(20.0),
                           alignment: .leading)
                    .padding(.leading, getRelativeWidth(10.0))
            }
            .frame(width: getRelativeWidth(76.0), height: getRelativeHeight(56.0),
                   alignment: .leading)
            .padding(.leading, getRelativeWidth(180.0))
        }
        .frame(width: getRelativeWidth(359.0), alignment: .leading)
        .hideNavigationBar()
    }
}

/* struct RowottawaCell_Previews: PreviewProvider {

 static var previews: some View {
             RowottawaCell()
 }
 } */

//
//  ColumnnowCell.swift
//  WeatherApp
//
import SwiftUI

struct ColumnnowCell: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(StringConstants.kLblNow)
                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(12.0)))
                .fontWeight(.regular)
                .foregroundColor(ColorConstants.Black900)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
                .frame(width: getRelativeWidth(24.0), height: getRelativeHeight(17.0),
                       alignment: .leading)
            Image("img_1161")
                .resizable()
                .frame(width: getRelativeWidth(14.0), height: getRelativeWidth(16.0),
                       alignment: .leading)
                .scaledToFit()
                .padding(.top, getRelativeHeight(4.0))
                .padding(.horizontal, getRelativeWidth(5.0))
            Text(StringConstants.kLbl19C)
                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(12.0)))
                .fontWeight(.regular)
                .foregroundColor(ColorConstants.Black900)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
                .frame(width: getRelativeWidth(22.0), height: getRelativeHeight(17.0),
                       alignment: .leading)
                .padding(.top, getRelativeHeight(4.0))
                .padding(.horizontal, getRelativeWidth(1.0))
        }
        .frame(width: getRelativeWidth(24.0), alignment: .leading)
        .hideNavigationBar()
    }
}

/* struct ColumnnowCell_Previews: PreviewProvider {

 static var previews: some View {
             ColumnnowCell()
 }
 } */

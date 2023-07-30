//
//  RowtodayCell.swift
//  WeatherApp
//
import SwiftUI

struct RowtodayCell: View {
    var body: some View {
        HStack {
            Text(StringConstants.kLblToday)
                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(12.0)))
                .fontWeight(.regular)
                .foregroundColor(ColorConstants.Bluegray900)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
                .frame(width: getRelativeWidth(30.0), height: getRelativeHeight(17.0),
                       alignment: .leading)
            HStack {
                Image("img_3021")
                    .resizable()
                    .frame(width: getRelativeWidth(23.0), height: getRelativeWidth(25.0),
                           alignment: .leading)
                    .scaledToFit()
                Image("img_vector_bluegray_900_14x11")
                    .resizable()
                    .frame(width: getRelativeWidth(7.0), height: getRelativeHeight(12.0),
                           alignment: .leading)
                    .scaledToFit()
                    .padding(.leading, getRelativeWidth(16.0))
                Text(StringConstants.kLbl20C)
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(14.0)))
                    .fontWeight(.regular)
                    .foregroundColor(ColorConstants.Bluegray900)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(width: getRelativeWidth(26.0), height: getRelativeHeight(20.0),
                           alignment: .leading)
                    .padding(.leading, getRelativeWidth(5.0))
                Image("img_vector_14x11")
                    .resizable()
                    .frame(width: getRelativeWidth(7.0), height: getRelativeHeight(12.0),
                           alignment: .leading)
                    .scaledToFit()
                    .padding(.leading, getRelativeWidth(17.0))
                Text(StringConstants.kLbl12C)
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(14.0)))
                    .fontWeight(.regular)
                    .foregroundColor(ColorConstants.Bluegray900)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .frame(width: getRelativeWidth(26.0), height: getRelativeHeight(20.0),
                           alignment: .leading)
                    .padding(.leading, getRelativeWidth(4.0))
            }
            .frame(width: getRelativeWidth(141.0), height: getRelativeHeight(25.0),
                   alignment: .leading)
            .padding(.leading, getRelativeWidth(147.0))
        }
        .frame(width: getRelativeWidth(321.0), alignment: .leading)
        .hideNavigationBar()
    }
}

/* struct RowtodayCell_Previews: PreviewProvider {

 static var previews: some View {
             RowtodayCell()
 }
 } */

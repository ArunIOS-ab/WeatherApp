//
//  WeatherEmptyView.swift
//  WeatherApp
//
import SwiftUI

struct WeatherEmptyView<Content: View>: View {
    let content: () -> Content
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var groupten: String = ""

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack{
            HStack {
                Spacer()
                Image("img_search")
                    .resizable()
                    .frame(width: getRelativeWidth(19.0), height: getRelativeWidth(19.0),
                           alignment: .center)
                    .scaledToFit()
                    .clipped()
                    .padding(.vertical, getRelativeHeight(12.0))
                    .padding(.leading, getRelativeWidth(11.0))
                    .padding(.trailing, getRelativeWidth(8.0))
                TextField(StringConstants.kMsgCityRegionOr, text: $groupten)
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(16.0)))
                    .foregroundColor(ColorConstants.Gray400)
                    .padding()
            }
            .frame(width: getRelativeWidth(361.0), height: getRelativeHeight(39.0),
                   alignment: .center)
            .background(RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0,
                                       bottomRight: 8.0)
                    .fill(ColorConstants.Gray100))
            Image("img_vector")
                .resizable()
                .frame(width: getRelativeWidth(88.0), height: getRelativeHeight(85.0),
                       alignment: .center)
                .scaledToFit()
                .clipped()
                .padding(.top, getRelativeHeight(84.0))
                .padding(.horizontal, getRelativeWidth(40.0))
            Text(StringConstants.kMsgSearchForACi)
                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(16.0)))
                .fontWeight(.regular)
                .foregroundColor(ColorConstants.Gray400)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .frame(width: getRelativeWidth(278.0), height: getRelativeHeight(43.0),
                       alignment: .center)
                .padding(.top, getRelativeHeight(27.0))
                .padding(.horizontal, getRelativeWidth(40.0))
        }
        .frame(width: getRelativeWidth(363.0), height: getRelativeHeight(279.0),
               alignment: .center)
        .padding(.vertical, getRelativeHeight(34.0))
        .padding(.horizontal, getRelativeWidth(15.0))

    }
}



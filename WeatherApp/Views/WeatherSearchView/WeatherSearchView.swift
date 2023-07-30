//
//  WeatherSearchView.swift
//  WeatherApp
//
//
import SwiftUI

struct WeatherSearchView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var groupthirtyseven: String = ""
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(StringConstants.kLblWeatherApp)
                            .font(FontScheme.kAvenirBlack(size: getRelativeHeight(36.0)))
                            .fontWeight(.black)
                            .foregroundColor(ColorConstants.Black900)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .frame(width: getRelativeWidth(229.0), height: getRelativeHeight(50.0),
                                   alignment: .topLeading)
                            .padding(.trailing)
                    }
                    .frame(width: getRelativeWidth(377.0), height: getRelativeHeight(50.0),
                           alignment: .leading)
                    .padding(.leading, getRelativeWidth(10.0))
                    VStack {
                        HStack {
                            Spacer()
                            Image("img_search")
                                .resizable()
                                .frame(width: getRelativeWidth(19.0),
                                       height: getRelativeWidth(19.0), alignment: .center)
                                .scaledToFit()
                                .clipped()
                                .padding(.top, getRelativeHeight(9.0))
                                .padding(.bottom, getRelativeHeight(10.0))
                                .padding(.horizontal, getRelativeWidth(8.0))
                            TextField(StringConstants.kLblSalem, text: $groupthirtyseven)
                                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(16.0)))
                                .foregroundColor(ColorConstants.Bluegray900)
                                .padding()
                            Image("img_vector_gray_400")
                                .resizable()
                                .frame(width: getRelativeWidth(19.0),
                                       height: getRelativeWidth(19.0), alignment: .center)
                                .scaledToFit()
                                .clipped()
                                .padding(.top, getRelativeHeight(9.0))
                                .padding(.bottom, getRelativeHeight(10.0))
                                .padding(.leading, getRelativeWidth(30.0))
                                .padding(.trailing, getRelativeWidth(8.0))
                            Spacer()
                        }
                        .frame(width: getRelativeWidth(361.0), height: getRelativeHeight(39.0),
                               alignment: .center)
                        .background(RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0,
                                                   bottomRight: 8.0)
                                .fill(ColorConstants.Gray100))
                        .padding(.trailing, getRelativeWidth(16.0))
                    }
                    .frame(width: getRelativeWidth(377.0), height: getRelativeHeight(39.0),
                           alignment: .leading)
                    .padding(.top, getRelativeHeight(29.0))
                    .padding(.leading, getRelativeWidth(10.0))
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Image("img_vector_indigo_a400")
                                .resizable()
                                .frame(width: getRelativeWidth(15.0),
                                       height: getRelativeHeight(13.0), alignment: .center)
                                .scaledToFit()
                                .clipped()
                                .padding(.top, getRelativeHeight(4.0))
                            Text(StringConstants.kMsgCurrentLocatio)
                                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(16.0)))
                                .fontWeight(.regular)
                                .foregroundColor(ColorConstants.IndigoA400)
                                .minimumScaleFactor(0.5)
                                .multilineTextAlignment(.leading)
                                .frame(width: getRelativeWidth(121.0),
                                       height: getRelativeHeight(22.0), alignment: .topLeading)
                                .padding(.leading, getRelativeWidth(6.0))
                        }
                        .frame(width: getRelativeWidth(142.0), height: getRelativeHeight(22.0),
                               alignment: .leading)
                        .padding(.trailing)
                        Text(StringConstants.kMsgSalemTamilNa)
                            .font(FontScheme.kAvenirRoman(size: getRelativeHeight(16.0)))
                            .fontWeight(.regular)
                            .foregroundColor(ColorConstants.Black900)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.leading)
                            .frame(width: getRelativeWidth(177.0), height: getRelativeHeight(22.0),
                                   alignment: .topLeading)
                            .padding(.top, getRelativeHeight(30.0))
                            .padding(.trailing, getRelativeWidth(10.0))
                        
                        VStack(alignment: .trailing, spacing: 0) {
                            Divider()
                                .frame(width: getRelativeWidth(377.0), height: getRelativeHeight(1.0),
                                       alignment: .trailing)
                                .background(ColorConstants.Gray200)
                        }
                        .frame(width: getRelativeWidth(377.0), height: getRelativeHeight(1.0),
                               alignment: .leading)
                        .padding(.top, getRelativeHeight(13.0))
                        .padding(.leading, getRelativeWidth(10.0))
                        
                    }
                    .frame(width: getRelativeWidth(377.0), height: getRelativeHeight(74.0),
                           alignment: .leading)
                    .padding(.top, getRelativeHeight(23.0))
                    .padding(.leading, getRelativeWidth(10.0))
                }
            }
            .frame(width: UIScreen.main.bounds.width, alignment: .topLeading)
            .background(ColorConstants.WhiteA700)
            .padding(.top, getRelativeHeight(50.0))
            .padding(.bottom, getRelativeHeight(40.0))
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .topLeading)
        .background(ColorConstants.WhiteA700)
        .hideNavigationBar()
    }
}

struct WeatherSearchView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherSearchView()
    }
}

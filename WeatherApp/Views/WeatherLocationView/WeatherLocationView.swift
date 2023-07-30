//
//  WeatherLocationView.swift
//  WeatherApp
// RowCell


import SwiftUI

struct WeatherLocationView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var groupten: String = ""
    var body: some View {
        VStack {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(StringConstants.kLblWeatherApp)
                        .font(FontScheme.kAvenirBlack(size: getRelativeHeight(36.0)))
                        .fontWeight(.black)
                        .foregroundColor(ColorConstants.Black900)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                        .frame(width: getRelativeWidth(229.0), height: getRelativeHeight(50.0),
                               alignment: .topLeading)
                        .padding(.horizontal, getRelativeWidth(15.0))
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
                    .padding(.top, getRelativeHeight(34.0))
                    .padding(.horizontal, getRelativeWidth(15.0))
                    VStack(spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack {
                                ForEach(0 ... 3, id: \.self) { index in
                                    RowCell()
                                }
                            }
                        }
                    }
                    .frame(width: getRelativeWidth(361.0), alignment: .center)
                    .padding(.top, getRelativeHeight(37.0))
                    .padding(.horizontal, getRelativeWidth(15.0))
                    Divider()
                        .frame(width: getRelativeWidth(375.0), height: getRelativeHeight(1.0),
                               alignment: .trailing)
                        .background(ColorConstants.Gray200)
                        .padding(.top, getRelativeHeight(11.0))
                        .padding(.leading, getRelativeWidth(10.0))
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text(StringConstants.kLblOntarioCanada)
                                    .font(FontScheme.kAvenirLight(size: getRelativeHeight(14.0)))
                                    .fontWeight(.light)
                                    .foregroundColor(ColorConstants.Black900)
                                    .minimumScaleFactor(0.5)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: getRelativeWidth(19.0),
                                           height: getRelativeHeight(20.0), alignment: .topLeading)
                                    .padding(.vertical, getRelativeHeight(34.0))
                                VStack(alignment: .trailing, spacing: 0) {
                                    HStack {
                                        Text(StringConstants.kLbl24C)
                                            .font(FontScheme
                                                .kAvenirRoman(size: getRelativeHeight(24.0)))
                                            .fontWeight(.regular)
                                            .foregroundColor(ColorConstants.Black900)
                                            .minimumScaleFactor(0.5)
                                            .multilineTextAlignment(.leading)
                                            .frame(width: getRelativeWidth(48.0),
                                                   height: getRelativeHeight(33.0),
                                                   alignment: .topLeading)
                                        Spacer()
                                        Image("img_image1")
                                            .resizable()
                                            .frame(width: getRelativeWidth(22.0),
                                                   height: getRelativeWidth(22.0),
                                                   alignment: .center)
                                            .scaledToFit()
                                            .clipped()
                                            .padding(.vertical, getRelativeHeight(5.0))
                                    }
                                    .frame(width: getRelativeWidth(78.0),
                                           height: getRelativeHeight(33.0), alignment: .leading)
                                    Text(StringConstants.kLbl900Am)
                                        .font(FontScheme
                                            .kAvenirRoman(size: getRelativeHeight(14.0)))
                                        .fontWeight(.regular)
                                        .foregroundColor(ColorConstants.Gray500)
                                        .minimumScaleFactor(0.5)
                                        .multilineTextAlignment(.leading)
                                        .frame(width: getRelativeWidth(51.0),
                                               height: getRelativeHeight(20.0),
                                               alignment: .topLeading)
                                        .padding(.leading, getRelativeWidth(10.0))
                                }
                                .frame(width: getRelativeWidth(78.0),
                                       height: getRelativeHeight(56.0), alignment: .top)
                                .padding(.bottom, getRelativeHeight(5.0))
                                .padding(.leading, getRelativeWidth(180.0))
                            }
                            .frame(width: getRelativeWidth(277.0), height: getRelativeHeight(56.0),
                                   alignment: .leading)
                            .padding(.trailing)
                            Divider()
                                .frame(width: getRelativeWidth(293.0),
                                       height: getRelativeHeight(1.0), alignment: .leading)
                                .background(ColorConstants.Gray200)
                                .padding(.top, getRelativeHeight(11.0))
                        }
                        .frame(width: getRelativeWidth(293.0), height: getRelativeHeight(67.0),
                               alignment: .bottom)
                        .padding(.top, getRelativeHeight(35.0))
                        Spacer()
                        VStack {
                            Text(StringConstants.kLblDelete)
                                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(16.0)))
                                .fontWeight(.regular)
                                .foregroundColor(ColorConstants.WhiteA700)
                                .minimumScaleFactor(0.5)
                                .multilineTextAlignment(.leading)
                                .frame(width: getRelativeWidth(48.0),
                                       height: getRelativeHeight(22.0), alignment: .topLeading)
                                .padding(.vertical, getRelativeHeight(42.0))
                                .padding(.horizontal, getRelativeWidth(21.0))
                        }
                        .frame(width: getRelativeWidth(96.0), height: getRelativeHeight(102.0),
                               alignment: .center)
                        .background(ColorConstants.Red400)
                        Spacer()
                    }
                    .frame(width: UIScreen.main.bounds.width, height: getRelativeHeight(102.0),
                           alignment: .leading)
                }
                .frame(width: UIScreen.main.bounds.width, height: getRelativeHeight(635.0),
                       alignment: .leading)
            }
            .hideNavigationBar()
            .frame(width: UIScreen.main.bounds.width, alignment: .topLeading)
            .background(ColorConstants.WhiteA700)
            .padding(.top, getRelativeHeight(30.0))
            .padding(.bottom, getRelativeHeight(10.0))
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .background(ColorConstants.WhiteA700)
        .ignoresSafeArea()
        .hideNavigationBar()
    }
}

struct WeatherLocationView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherLocationView()
    }
}

//
//  WeatherDetailOneView.swift
//  WeatherApp
//
import SwiftUI

struct WeatherDetailOneView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var groupsevenText: String = ""
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack {
                    HStack {
                        HStack {
                            Image("img_vector_bluegray_900")
                                .resizable()
                                .frame(width: getRelativeWidth(18.0),
                                       height: getRelativeHeight(14.0), alignment: .center)
                                .scaledToFit()
                                .clipped()
                                .padding(.vertical, getRelativeHeight(5.0))
                            Spacer()
                            Text(StringConstants.kLblAdd)
                                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(16.0)))
                                .fontWeight(.regular)
                                .foregroundColor(ColorConstants.Black900)
                                .minimumScaleFactor(0.5)
                                .multilineTextAlignment(.leading)
                                .frame(width: getRelativeWidth(46.0),
                                       height: getRelativeHeight(22.0), alignment: .topLeading)
                        }
                        .frame(width: getRelativeWidth(358.0), height: getRelativeHeight(22.0),
                               alignment: .leading)
                    }
                    .frame(width: getRelativeWidth(358.0), height: getRelativeHeight(22.0),
                           alignment: .leading)
                }
                .frame(width: getRelativeWidth(361.0), height: getRelativeHeight(22.0),
                       alignment: .leading)
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(StringConstants.kLblOttawa)
                                        .font(FontScheme
                                            .kAvenirHeavy(size: getRelativeHeight(36.0)))
                                        .fontWeight(.heavy)
                                        .foregroundColor(ColorConstants.Black900)
                                        .minimumScaleFactor(0.5)
                                        .multilineTextAlignment(.leading)
                                        .frame(width: getRelativeWidth(126.0),
                                               height: getRelativeHeight(46.0),
                                               alignment: .topLeading)
                                        .padding(.trailing)
                                    Text(StringConstants.kLblOntarioCanada)
                                        .font(FontScheme.kAvenirBook(size: getRelativeHeight(16.0)))
                                        .fontWeight(.regular)
                                        .foregroundColor(ColorConstants.Black900)
                                        .minimumScaleFactor(0.5)
                                        .multilineTextAlignment(.leading)
                                        .frame(width: getRelativeWidth(119.0),
                                               height: getRelativeHeight(18.0),
                                               alignment: .topLeading)
                                        .padding(.trailing, getRelativeWidth(10.0))
                                    HStack {
                                        ZStack(alignment: .bottomLeading) {
                                            Text(StringConstants.kLbl19)
                                                .font(FontScheme
                                                    .kAvenirBlack(size: getRelativeHeight(120.0)))
                                                .fontWeight(.black)
                                                .foregroundColor(ColorConstants.Gray900)
                                                .minimumScaleFactor(0.5)
                                                .multilineTextAlignment(.leading)
                                                .frame(width: getRelativeWidth(143.0),
                                                       height: getRelativeHeight(164.0),
                                                       alignment: .topLeading)
                                            HStack {
                                                Image("img_vector_bluegray_900_14x11")
                                                    .resizable()
                                                    .frame(width: getRelativeWidth(11.0),
                                                           height: getRelativeHeight(14.0),
                                                           alignment: .center)
                                                    .scaledToFit()
                                                    .clipped()
                                                Text(StringConstants.kLbl20C)
                                                    .font(FontScheme
                                                        .kAvenirRoman(size: getRelativeHeight(16.0)))
                                                    .fontWeight(.regular)
                                                    .foregroundColor(ColorConstants.Bluegray900)
                                                    .minimumScaleFactor(0.5)
                                                    .multilineTextAlignment(.leading)
                                                    .frame(width: getRelativeWidth(32.0),
                                                           height: getRelativeHeight(21.0),
                                                           alignment: .topLeading)
                                                    .padding(.leading, getRelativeWidth(4.0))
                                                Image("img_vector_14x11")
                                                    .resizable()
                                                    .frame(width: getRelativeWidth(11.0),
                                                           height: getRelativeHeight(14.0),
                                                           alignment: .center)
                                                    .scaledToFit()
                                                    .clipped()
                                                    .padding(.leading, getRelativeWidth(16.0))
                                                Text(StringConstants.kLbl12C)
                                                    .font(FontScheme
                                                        .kAvenirRoman(size: getRelativeHeight(16.0)))
                                                    .fontWeight(.regular)
                                                    .foregroundColor(ColorConstants.Bluegray900)
                                                    .minimumScaleFactor(0.5)
                                                    .multilineTextAlignment(.leading)
                                                    .frame(width: getRelativeWidth(32.0),
                                                           height: getRelativeHeight(21.0),
                                                           alignment: .topLeading)
                                                    .padding(.horizontal, getRelativeWidth(3.0))
                                            }
                                            .frame(width: getRelativeWidth(110.0),
                                                   height: getRelativeHeight(22.0),
                                                   alignment: .bottomLeading)
                                            .padding(.top, getRelativeHeight(141.2))
                                            .padding(.trailing, getRelativeWidth(33.0))
                                        }
                                        .hideNavigationBar()
                                        .frame(width: getRelativeWidth(143.0),
                                               height: getRelativeHeight(164.0), alignment: .center)
                                        Spacer()
                                        Text(StringConstants.kLblC)
                                            .font(FontScheme
                                                .kAvenirRoman(size: getRelativeHeight(40.0)))
                                            .fontWeight(.regular)
                                            .foregroundColor(ColorConstants.Gray900)
                                            .minimumScaleFactor(0.5)
                                            .multilineTextAlignment(.leading)
                                            .frame(width: getRelativeWidth(36.0),
                                                   height: getRelativeHeight(55.0),
                                                   alignment: .topLeading)
                                            .padding(.vertical, getRelativeHeight(30.0))
                                    }
                                    .frame(width: getRelativeWidth(190.0),
                                           height: getRelativeHeight(164.0), alignment: .leading)
                                    .padding(.top, getRelativeHeight(8.0))
                                }
                                .frame(width: getRelativeWidth(190.0),
                                       height: getRelativeHeight(236.0), alignment: .center)
                                .padding(.bottom, getRelativeHeight(6.0))
                                Spacer()
                                VStack(alignment: .trailing, spacing: 0) {
                                    Image("img_1161")
                                        .resizable()
                                        .frame(width: getRelativeWidth(64.0),
                                               height: getRelativeWidth(64.0), alignment: .center)
                                        .scaledToFit()
                                        .clipped()
                                        .padding(.leading)
                                        .padding(.leading)
                                    Text(StringConstants.kLblFeelsLike20C)
                                        .font(FontScheme
                                            .kAvenirLight(size: getRelativeHeight(16.0)))
                                        .fontWeight(.light)
                                        .foregroundColor(ColorConstants.Bluegray900)
                                        .minimumScaleFactor(0.5)
                                        .multilineTextAlignment(.leading)
                                        .frame(width: getRelativeWidth(97.0),
                                               height: getRelativeHeight(22.0),
                                               alignment: .topLeading)
                                        .padding(.top, getRelativeHeight(20.0))
                                }
                                .frame(width: getRelativeWidth(97.0),
                                       height: getRelativeHeight(106.0), alignment: .bottom)
                                .padding(.vertical, getRelativeHeight(134.0))
                            }
                            .frame(width: getRelativeWidth(361.0), height: getRelativeHeight(242.0),
                                   alignment: .leading)
                            VStack {
                                VStack {
                                    HStack(spacing: 0) {
                                        TextField(StringConstants.kLblPartlyCloudy,
                                                  text: $groupsevenText)
                                            .font(FontScheme
                                                .kAvenirBook(size: getRelativeHeight(16.0)))
                                            .foregroundColor(ColorConstants.Black900)
                                            .padding()
                                    }
                                    .frame(width: getRelativeWidth(341.0),
                                           height: getRelativeHeight(31.0), alignment: .center)
                                    Divider()
                                        .background(ColorConstants.Black900)
                                }
                                .frame(width: getRelativeWidth(341.0),
                                       height: getRelativeHeight(31.0), alignment: .center)
                                .padding(.top, getRelativeHeight(11.0))
                                .padding(.horizontal, getRelativeWidth(10.0))
                                HStack(spacing: 0) {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack {
                                            ForEach(0 ... 6, id: \.self) { index in
                                                ColumnnowCell()
                                            }
                                        }
                                    }
                                }
                                .frame(width: getRelativeWidth(339.0), alignment: .center)
                                .padding(.top, getRelativeHeight(7.0))
                                .padding(.bottom, getRelativeHeight(5.0))
                                .padding(.horizontal, getRelativeWidth(10.0))
                            }
                            .frame(width: getRelativeWidth(361.0), height: getRelativeHeight(119.0),
                                   alignment: .leading)
                            .background(RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0,
                                                       bottomRight: 8.0)
                                    .fill(ColorConstants.Gray101))
                            .padding(.top, getRelativeHeight(26.0))
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Image("img_vector_bluegray_700")
                                        .resizable()
                                        .frame(width: getRelativeWidth(15.0),
                                               height: getRelativeHeight(13.0), alignment: .center)
                                        .scaledToFit()
                                        .clipped()
                                    Text(StringConstants.kLbl5DayForecast)
                                        .font(FontScheme
                                            .kAvenirHeavy(size: getRelativeHeight(12.0)))
                                        .fontWeight(.heavy)
                                        .foregroundColor(ColorConstants.Bluegray700)
                                        .minimumScaleFactor(0.5)
                                        .multilineTextAlignment(.leading)
                                        .frame(width: getRelativeWidth(80.0),
                                               height: getRelativeHeight(17.0),
                                               alignment: .topLeading)
                                        .padding(.leading, getRelativeWidth(4.0))
                                }
                                .frame(width: getRelativeWidth(99.0),
                                       height: getRelativeHeight(17.0), alignment: .leading)
                                .padding(.top, getRelativeHeight(13.0))
                                .padding(.horizontal, getRelativeWidth(10.0))
                                VStack(spacing: 0) {
                                    ScrollView(.vertical, showsIndicators: false) {
                                        LazyVStack {
                                            ForEach(0 ... 4, id: \.self) { index in
                                                RowtodayCell()
                                            }
                                        }
                                    }
                                }
                                .frame(width: getRelativeWidth(325.0), alignment: .center)
                                .padding(.top, getRelativeHeight(7.0))
                                .padding(.bottom, getRelativeHeight(6.0))
                                .padding(.horizontal, getRelativeWidth(10.0))
                            }
                            .frame(width: getRelativeWidth(361.0), height: getRelativeHeight(201.0),
                                   alignment: .leading)
                            .background(RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0,
                                                       bottomRight: 8.0)
                                    .fill(ColorConstants.Gray101))
                            .padding(.top, getRelativeHeight(26.0))
                            VStack(spacing: 0) {
                                ScrollView(.vertical, showsIndicators: false) {
                                    LazyVStack {
                                        ForEach(0 ... 1, id: \.self) { index in
                                            RowdistanceCell()
                                        }
                                    }
                                }
                            }
                            .frame(width: getRelativeWidth(361.0), alignment: .leading)
                            .padding(.top, getRelativeHeight(26.0))
                            HStack {
                                Image("img_vector_bluegray_700_14x13")
                                    .resizable()
                                    .frame(width: getRelativeWidth(13.0),
                                           height: getRelativeHeight(14.0), alignment: .center)
                                    .scaledToFit()
                                    .clipped()
                                Text(StringConstants.kLblAlerts)
                                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(12.0)))
                                    .fontWeight(.regular)
                                    .foregroundColor(ColorConstants.Bluegray700)
                                    .minimumScaleFactor(0.5)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: getRelativeWidth(32.0),
                                           height: getRelativeHeight(17.0), alignment: .topLeading)
                                    .padding(.leading, getRelativeWidth(4.0))
                            }
                            .frame(width: getRelativeWidth(49.0), height: getRelativeHeight(17.0),
                                   alignment: .leading)
                            .padding(.top, getRelativeHeight(28.0))
                            .padding(.horizontal, getRelativeWidth(8.0))
                            VStack(spacing: 0) {
                                ScrollView(.vertical, showsIndicators: false) {
                                    LazyVStack {
                                        ForEach(0 ... 1, id: \.self) { index in
                                            Column1Cell()
                                        }
                                    }
                                }
                            }
                            .frame(width: getRelativeWidth(361.0), alignment: .leading)
                            .padding(.top, getRelativeHeight(6.0))
                        }
                        .frame(width: getRelativeWidth(361.0), alignment: .topLeading)
                    }
                }
                .frame(width: getRelativeWidth(361.0), height: UIScreen.main.bounds.height,
                       alignment: .topLeading)
            }
            .frame(width: getRelativeWidth(361.0), alignment: .topLeading)
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

struct WeatherDetailOneView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherDetailOneView()
    }
}

//  
//  WeatherLocationView.swift
//  WeatherApp
//  RowCell


import SwiftUI

struct WeatherLocationView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var groupten: String = ""
    var body: some View {
        NavigationStack{
            VStack{
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
                            //MARK: -  List
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

                    }
                    .frame(width: UIScreen.main.bounds.width, height: getRelativeHeight(635.0),
                           alignment: .leading)
                }
                .hideNavigationBar()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .topLeading)
                .background(ColorConstants.WhiteA700)
                .padding(.bottom, getRelativeHeight(10.0))
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .background(ColorConstants.WhiteA700).padding(.top, getRelativeHeight(80.0))
            
            .hideNavigationBar()
        }
        }
        
}

struct WeatherLocationView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherLocationView()
    }
}

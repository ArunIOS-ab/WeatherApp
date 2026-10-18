//
//  WeatherDetailOneView.swift
//  WeatherApp
//
import SwiftUI

/// Which modal this screen can present.
///
/// A single enum rather than two booleans: SwiftUI only honours the *last*
/// `.sheet` attached to a view, so two separate `.sheet(isPresented:)`
/// modifiers leave one of them permanently dead. This is the documented way to
/// present more than one sheet from one screen.
enum ActiveSheet: String, Identifiable {
    case chat
    case search

    var id: String { rawValue }
}

struct WeatherDetailOneView: View {
    @State private var groupsevenText: String = ""

    // MARK: - Live data bindings

    /// Everything below reads from the snapshot rather than hardcoded strings,
    /// so the whole screen re-scopes when the user picks a new location.

    private var current: CurrentConditions? { viewModel.snapshot?.current }

    /// Today's high/low, taken from the first daily entry. Falls back to the
    /// current temperature before any forecast has arrived.
    private var today: DailyForecast? { viewModel.snapshot?.daily.first }

    private var currentTemp: String {
        guard let c = current else { return "--" }
        return "\(Int(c.tempC.rounded()))°"
    }

    private var currentFeelsLike: String {
        guard let c = current else { return "--" }
        return "\(Int(c.apparentTempC.rounded()))°c"
    }

    private var currentHigh: String {
        guard let d = today else { return "--°" }
        return "\(Int(d.maxTempC.rounded()))°c"
    }

    private var currentLow: String {
        guard let d = today else { return "--°c" }
        return "\(Int(d.minTempC.rounded()))°c"
    }

    private var currentCondition: String {
        current?.conditionText ?? StringConstants.kLblLoading
    }

    /// The next 7 hours, which is what the hourly strip shows.
    private var upcomingHours: [HourlyForecast] {
        Array(viewModel.snapshot?.hourly.prefix(7) ?? [])
    }

    private var forecastDays: [DailyForecast] {
        viewModel.snapshot?.daily ?? []
    }

    // MARK: - Agentic layer

    @StateObject private var viewModel = WeatherViewModel(
        location: GeoLocation(name: "Ottawa",
                             region: "Ontario",
                             country: "Canada",
                             lat: 45.4215,
                             lon: -75.6972)
    )
    @State private var activeSheet: ActiveSheet?
    @State private var followUpQuestion: String?

    var body: some View {
        NavigationStack{
            VStack {
                VStack(alignment: .leading, spacing: 0) {
                    //MARK: - Location header (tappable; opens location search)
                    Button {
                        activeSheet = .search
                    } label: {
                        HStack(spacing: getRelativeWidth(6.0)) {
                            Image(systemName: "mappin.and.ellipse")
                                .resizable()
                                .frame(width: getRelativeWidth(13.0), height: getRelativeWidth(13.0))
                                .scaledToFit()
                                .foregroundColor(ColorConstants.IndigoA400)

                            VStack(alignment: .leading, spacing: getRelativeHeight(2.0)) {
                                Text(viewModel.location.name)
                                    .font(FontScheme.kAvenirHeavy(size: getRelativeHeight(20.0)))
                                    .foregroundColor(ColorConstants.Black900)
                                    .lineLimit(1)

                                if !viewModel.location.displayName.isEmpty {
                                    Text(viewModel.location.displayName)
                                        .font(FontScheme.kAvenirLight(size: getRelativeHeight(12.0)))
                                        .foregroundColor(ColorConstants.Bluegray400)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .frame(width: getRelativeWidth(15.0), height: getRelativeWidth(15.0))
                                .scaledToFit()
                                .foregroundColor(ColorConstants.Gray400)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: getRelativeWidth(361.0), alignment: .leading)
                    .padding(.bottom, getRelativeHeight(6.0))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 0) {
                                //MARK: - Weather UI
                                HStack {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack {
                                            ZStack(alignment: .bottomLeading) {
                                                Text(currentTemp)
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
                                                    Text(currentHigh)
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
                                                    Text(currentLow)
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
                                    //MARK: - Weather feels like UI
                                    VStack(alignment: .trailing, spacing: 0) {
                                        Image(systemName: current.map { WeatherIcon.symbol(for: $0.conditionText) } ?? "cloud")
                                            .resizable()
                                            .frame(width: getRelativeWidth(64.0),
                                                   height: getRelativeWidth(64.0), alignment: .center)
                                            .scaledToFit()
                                            .clipped()
                                            .padding(.leading)
                                            .padding(.leading)
                                        Text("feels like \(currentFeelsLike)")
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

                                //MARK: - Agent Insights (proactive recommendations)
                                AgentInsightsSection(insights: viewModel.insights) { insight in
                                    followUpQuestion = "\(insight.title) — \(insight.detail)"
                                    activeSheet = .chat
                                }
                                .padding(.top, getRelativeHeight(22.0))

                                //MARK: - Ask the Agent CTA
                                Button {
                                    activeSheet = .chat
                                } label: {
                                    HStack(spacing: getRelativeWidth(8.0)) {
                                        if viewModel.isLoading {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        } else {
                                            Image(systemName: "sparkles")
                                                .resizable()
                                                .frame(width: getRelativeWidth(16.0),
                                                       height: getRelativeWidth(16.0))
                                                .scaledToFit()
                                        }
                                        Text(viewModel.isLoading
                                             ? StringConstants.kLblLoading
                                             : StringConstants.kLblAskAgent)
                                            .font(FontScheme.kAvenirMedium(size: getRelativeHeight(14.0)))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .frame(width: getRelativeWidth(10.0),
                                                   height: getRelativeWidth(10.0))
                                            .scaledToFit()
                                    }
                                    .foregroundColor(viewModel.canAskAgent
                                                     ? ColorConstants.IndigoA400
                                                     : ColorConstants.Gray400)
                                    .padding(getRelativeWidth(14.0))
                                    .background(
                                        RoundedCorners(topLeft: 8.0, topRight: 8.0,
                                                       bottomLeft: 8.0, bottomRight: 8.0)
                                            .fill(ColorConstants.Gray101)
                                    )
                                }
                                .buttonStyle(.plain)
                                // Disabled while loading so the user is not taken
                                // into a chat with no weather data behind it.
                                .disabled(!viewModel.canAskAgent)
                                .padding(.top, getRelativeHeight(10.0))

                                //MARK: - Today Forecast(Partly Cloudy) UI
                                VStack {
                                    VStack {
                                        HStack(spacing: 0) {
                                            Text(currentCondition)
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
                                                ForEach(upcomingHours) { hour in
                                                    //MARK: - Hourly Forecast UI
                                                    ColumnnowCell(hour: hour)
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: UIScreen.main.bounds.size.width - 20.0, alignment: .center)
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
                                
                                //MARK: - 5-day Forecast UI
                                
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
                                                ForEach(forecastDays, id: \.date) { day in
                                                    RowtodayCell(day: day,
                                                                isToday: day.id == today?.id)
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
                                
                                //MARK: - WindBox UI
                                VStack(spacing: 0) {
                                    ScrollView(.vertical, showsIndicators: false) {
                                        LazyVStack {
                                            RowdistanceCell(precipitationMM: viewModel.snapshot?.daily.first?.precipMM ?? 0,
                                                       windKph: current?.windKph ?? 0,
                                                       windDirection: current?.windDirection ?? "")
                                        }
                                    }
                                }
                                .frame(width: getRelativeWidth(361.0), alignment: .leading)
                                .padding(.top, getRelativeHeight(26.0))
                                
                                
                                // Only shown when there is something to report.
                                if let alerts = viewModel.snapshot?.alerts, !alerts.isEmpty {
                                    //MARK: - Alerts UI
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
                                                ForEach(viewModel.snapshot?.alerts ?? []) { alert in
                                                    Column1Cell(alert: alert)
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: getRelativeWidth(361.0), alignment: .leading)
                                    .padding(.top, getRelativeHeight(6.0))
                                }
                            }
                            .frame(width: getRelativeWidth(361.0), alignment: .topLeading)
                        }
                    }
                    .frame(width: getRelativeWidth(361.0), height: UIScreen.main.bounds.height,
                           alignment: .topLeading).padding(.top, getRelativeHeight(20.0))
                    
                }
                .frame(width: getRelativeWidth(361.0), alignment: .topLeading)
                .background(ColorConstants.WhiteA700)
                .padding(.top, getRelativeHeight(50.0))
                .padding(.bottom, getRelativeHeight(10.0))
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .top)
            .background(ColorConstants.WhiteA700)
        }
        .task {
            // Pulls the latest snapshot and generates the proactive insights.
            await viewModel.load()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .chat:
                AgentChatView(viewModel: viewModel,
                              initialQuestion: followUpQuestion)
                    .presentationDetents([.large])
            case .search:
                LocationSearchView(viewModel: viewModel)
            }
        }
        .alert(
            StringConstants.kLblWeatherAgent,
            isPresented: Binding(
                get: { viewModel.errorMessage != nil && viewModel.messages.isEmpty },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK") { viewModel.errorMessage = nil } },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }
}

struct WeatherDetailOneView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherDetailOneView()
    }
}

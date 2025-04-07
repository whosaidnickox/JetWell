import SwiftUI

struct DelayFactor {
    let title: String
    let status: String
    let description: String
    let color: Color
    
    static let weatherConditions = DelayFactor(
        title: "Weather conditions",
        status: "Normal",
        description: "It should be noted that flight delays are possible due to late arrival of aircraft, adjustment of the schedule by airlines, as well as increased ground handling time due to de-icing of aircraft before departure.",
        color: .green
    )
    
    static let airportCongestion = DelayFactor(
        title: "Airport congestion",
        status: "Middle",
        description: "Airport congestion can lead to significant delays in departure and arrival times. This is often caused by high traffic volume, limited gate availability, and runway capacity constraints during peak hours.",
        color: .orange
    )
    
    static let probabilityOfDelays = DelayFactor(
        title: "Probability of delays on the route",
        status: "High",
        description: "High probability of delays indicates that multiple risk factors are present on your route. These may include weather conditions at departure or arrival airports, air traffic congestion in key flight corridors, and potential technical or operational constraints.",
        color: .red
    )
}

struct StatusBox: View {
    let status: String
    let color: Color
    
    var body: some View {
        Text(status)
            .font(.system(size: 22, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 77, height: 77)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
            )
    }
}

struct DelayFactorSection: View {
    let title: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            StatusBox(status: status, color: color)
            
            Divider()
                .background(Color.white.opacity(0.5))
        }
        .padding(.vertical)
    }
}

struct StatusBadge: View {
    let status: String
    let color: Color
    
    var body: some View {
        Text(status)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(color)
            )
    }
}

struct DelayFactorRow: View {
    let factor: DelayFactor
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 30) {
                Text(factor.title)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Spacer()
                    StatusBadge(status: factor.status, color: factor.color)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.11))
            .cornerRadius(10)
        }
    }
}

struct DetailModalView: View {
    let factor: DelayFactor
    let isPresented: Binding<Bool>
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented.wrappedValue = false
                }
            
            VStack(alignment: .leading, spacing: 24) {
                Text(factor.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                HStack {
                    Spacer()
                    StatusBadge(status: factor.status, color: factor.color)
                }
                
                Text(factor.description)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button(action: {
                    isPresented.wrappedValue = false
                }) {
                    Text("Accept")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                .padding(.top, 20)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
            )
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: 450)
        }
    }
}

struct DelayView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var weatherViewModel = AutomaticBriefingViewModel()
    @EnvironmentObject private var locationService: LocationService
    @State private var selectedFactor: DelayFactor?
    @State private var showDetailModal = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: themeManager.currentTheme.gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                // Основной контент
                VStack(spacing: 0) {
                    // Заголовок
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Delay")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                            Text("Predictor screen")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    if weatherViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.vertical, 100)
                    } else {
                        // Погодные условия - используем реальную погоду
                        let weatherStatus = getWeatherStatus(weather: weatherViewModel.weatherData)
                        Button {
                            selectedFactor = DelayFactor(
                                title: "Weather conditions",
                                status: weatherStatus.status,
                                description: "It should be noted that flight delays are possible due to late arrival of aircraft, adjustment of the schedule by airlines, as well as increased ground handling time due to de-icing of aircraft before departure. Current weather: \(weatherViewModel.weatherData.weatherType.description), wind speed: \(Int(weatherViewModel.weatherData.windSpeed)) km/h.",
                                color: weatherStatus.color
                            )
                            showDetailModal = true
                        } label: {
                            DelayFactorSection(
                                title: "Weather conditions",
                                status: weatherStatus.status,
                                color: weatherStatus.color
                            )
                        }
                        
                        // Загруженность аэропорта - симулируем на основе погоды
                        let congestionStatus = getAirportCongestion(weather: weatherViewModel.weatherData)
                        Button {
                            selectedFactor = DelayFactor(
                                title: "Airport congestion",
                                status: congestionStatus.status,
                                description: "Airport congestion can lead to significant delays in departure and arrival times. This is often caused by high traffic volume, limited gate availability, and runway capacity constraints during peak hours. Current congestion level based on weather conditions: \(congestionStatus.status).",
                                color: congestionStatus.color
                            )
                            showDetailModal = true
                        } label: {
                            DelayFactorSection(
                                title: "Airport congestion",
                                status: congestionStatus.status,
                                color: congestionStatus.color
                            )
                        }
                        
                        // Вероятность задержек на маршруте - симулируем на основе погоды
                        let delayProbability = getDelayProbability(weather: weatherViewModel.weatherData)
                        Button {
                            selectedFactor = DelayFactor(
                                title: "Probability of delays\non the route",
                                status: delayProbability.status,
                                description: "Probability of delays indicates risk factors present on your route. These include weather conditions at departure or arrival airports, air traffic congestion in flight corridors, and potential technical constraints. Current probability based on weather: \(delayProbability.status).",
                                color: delayProbability.color
                            )
                            showDetailModal = true
                        } label: {
                            VStack(spacing: 25) {
                                Text("Probability of delays\non the route")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                StatusBox(status: delayProbability.status, color: delayProbability.color)
                            }
                            .padding(.vertical)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            
            if showDetailModal, let factor = selectedFactor {
                DetailModalView(factor: factor, isPresented: $showDetailModal)
            }
        }
        .onAppear {
            Task {
                await weatherViewModel.fetchWeather(with: locationService)
            }
        }
    }
    
    // Определение статуса погоды на основе данных о погоде
    private func getWeatherStatus(weather: WeatherData) -> (status: String, color: Color) {
        switch weather.weatherType {
        case .thunderstorm, .tornado, .squall:
            return ("High Risk", Color.red)
        case .snow, .rain, .fog:
            return ("Medium", Color(hex: "FFA64D")) // Orange
        case .clouds, .drizzle, .mist, .haze:
            if weather.windSpeed > 10 {
                return ("Medium", Color(hex: "FFA64D"))
            } else {
                return ("Low", Color(hex: "7EEA7E")) // Green
            }
        case .clear:
            return ("Normal", Color(hex: "7EEA7E"))
        default:
            return ("Normal", Color(hex: "7EEA7E"))
        }
    }
    
    // Определение загруженности аэропорта на основе погоды
    private func getAirportCongestion(weather: WeatherData) -> (status: String, color: Color) {
        switch weather.weatherType {
        case .thunderstorm, .tornado, .squall, .snow:
            return ("High", Color.red)
        case .rain, .drizzle, .fog, .mist, .haze:
            return ("Middle", Color(hex: "FFA64D"))
        case .clouds:
            if weather.windSpeed > 10 {
                return ("Middle", Color(hex: "FFA64D"))
            } else {
                return ("Low", Color(hex: "7EEA7E"))
            }
        case .clear:
            if weather.windSpeed > 15 {
                return ("Low", Color(hex: "7EEA7E"))
            } else {
                return ("Minimal", Color(hex: "7EEA7E"))
            }
        default:
            return ("Low", Color(hex: "7EEA7E"))
        }
    }
    
    // Определение вероятности задержек на основе погоды
    private func getDelayProbability(weather: WeatherData) -> (status: String, color: Color) {
        switch weather.weatherType {
        case .thunderstorm, .tornado, .squall, .snow, .rain, .fog:
            return ("High", Color(hex: "9B1F00"))
        case .drizzle, .mist, .haze:
            if weather.windSpeed > 8 {
                return ("Medium", Color(hex: "FFA64D"))
            } else {
                return ("Low", Color(hex: "7EEA7E"))
            }
        case .clouds:
            if weather.windSpeed > 12 {
                return ("Medium", Color(hex: "FFA64D"))
            } else {
                return ("Low", Color(hex: "7EEA7E"))
            }
        case .clear:
            if weather.windSpeed > 20 {
                return ("Medium", Color(hex: "FFA64D"))
            } else {
                return ("Low", Color(hex: "7EEA7E"))
            }
        default:
            return ("Low", Color(hex: "7EEA7E"))
        }
    }
} 

import SwiftUI
import CoreLocation
import Foundation
import Network
import AVFoundation

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var themeManager: ThemeManager
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    AutomaticBriefingView()
                        .tag(0)
                    
                    HealthView()
                        .tag(1)
                    
                    InfoView()
                        .tag(2)
                    
                    DelayView()
                        .tag(3)
                    
                    ChecksView()
                        .tag(4)
                }
                
                CustomTabBar(selectedTab: $selectedTab)
                    .ignoresSafeArea(.keyboard)
            }
            .ignoresSafeArea(.keyboard)
        }
        .adpeiwqozpr()
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack(alignment: .center) {
            Color.white
                .clipShape(RoundedCorners(radius: 42, corners: [.topLeft, .topRight]))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .edgesIgnoringSafeArea(.bottom)

            HStack(spacing: 0) {
                ForEach(0..<5) { index in
                    Button {
                        selectedTab = index
                    } label: {
                        VStack(spacing: 4) {
                            Image(selectedTab == index ? "\(index + 1)c" : "\(index + 1)")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(selectedTab == index ? Color(hex: "007DFF") : Color(hex: "B1B1B1"))
                            
                            Text(tabName(for: index))
                                .font(.system(size: 12, weight: .light))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(selectedTab == index ? Color(hex: "007DFF") : Color(hex: "B1B1B1"))
                }
            }
            .padding(.top, 10)
        }
        .frame(height: 55)
    }
    
    private func tabName(for index: Int) -> String {
        switch index {
        case 0: return "Main"
        case 1: return "Health"
        case 2: return "Info"
        case 3: return "Delay"
        case 4: return "Checks"
        default: return ""
        }
    }
}

class AutomaticBriefingViewModel: ObservableObject {
    private let weatherService = WeatherService()
    private let networkMonitor = NWPathMonitor()
    private var isNetworkAvailable = true
    
    @Published var weatherData = WeatherData(
        temperature: 22,
        windSpeed: 5,
        weatherType: .clear,
        description: "",
        visibility: "10+ Km",
        cityName: "Moscow"
    )
    
    @Published var notamInfo = "A0125/22 NOTAMR A0123/22"
    @Published var isLoading = false
    @Published var error: String?
    
    init() {
        setupNetworkMonitoring()
        // Останавливаем звук при инициализации на всякий случай
        AudioManager.shared.stopCurrentSound()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
                print("NetworkMonitor: Network connection \(path.status == .satisfied ? "available" : "unavailable")")
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    func fetchWeather(with locationService: LocationService) async {
        print("AutomaticBriefingViewModel: Starting weather request")
        print("AutomaticBriefingViewModel: Location authorization status: \(locationService.authorizationStatus.rawValue)")
        print("AutomaticBriefingViewModel: Current location: \(String(describing: locationService.location?.coordinate))")
        print("AutomaticBriefingViewModel: Network connection: \(isNetworkAvailable ? "available" : "unavailable")")
        
        await MainActor.run { 
            self.isLoading = true 
            self.error = nil
            print("Starting weather fetch with location status: \(locationService.authorizationStatus.rawValue)")
        }
        
        // Останавливаем текущий звук перед запросом новой погоды
        AudioManager.shared.stopCurrentSound()
        
        // Check network connection
        guard isNetworkAvailable else {
            print("AutomaticBriefingViewModel: No internet connection")
            await MainActor.run {
                self.error = "No internet connection. Please check your connection and try again."
                self.isLoading = false
            }
            return
        }
        
        do {
            var weather: WeatherData? = nil // Переменная для хранения результата
            
            print("Checking location...")
            // Пытаемся получить локацию
            guard let determinedLocation = locationService.location else {
                // Проверяем, есть ли ошибка и является ли она kCLErrorDomain error 0
                if let error = locationService.error as? CLError, error.code == .locationUnknown {
                    print("Location error: kCLErrorDomain error 0 (location unknown). Falling back to New York.")
                    // Если ошибка 'location unknown', грузим NY
                    let nyLocation = CLLocation(latitude: 40.7128, longitude: -74.0060)
                    weather = try await weatherService.fetchWeather(location: nyLocation)
                    await MainActor.run {
                        self.weatherData = weather!
                        self.isLoading = false
                        print("AutomaticBriefingViewModel: Weather loaded for NY due to location unknown error.")
                    }
                    return // Выходим после загрузки NY
                }
                
                // Если ошибка другая, выбрасываем её дальше
                if let locationError = locationService.error {
                    print("Location error: \(locationError.localizedDescription)")
                    throw locationError
                }
                
                // Если ошибки нет, но локации нет (и разрешение не запрещено) - грузим NY
                if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
                    print("AutomaticBriefingViewModel: Access to location denied, using NY.")
                    let nyLocation = CLLocation(latitude: 40.7128, longitude: -74.0060)
                    weather = try await weatherService.fetchWeather(location: nyLocation)
                    await MainActor.run {
                        self.weatherData = weather!
                        self.isLoading = false
                        print("AutomaticBriefingViewModel: Weather loaded for NY due to denied permissions.")
                    }
                    return
                } else {
                    // Другие случаи отсутствия локации без ошибки (например, сервис еще не успел определить)
                    print("Location not available yet or status not denied/restricted, using NY.")
                     let nyLocation = CLLocation(latitude: 40.7128, longitude: -74.0060)
                    weather = try await weatherService.fetchWeather(location: nyLocation)
                    await MainActor.run {
                        self.weatherData = weather!
                        self.isLoading = false
                        print("AutomaticBriefingViewModel: Weather loaded for NY (location not available).")
                    }
                    return
                }
            }
            
            // Если геолокация есть:
            if weather == nil { // Если еще не загрузили для NY
                 weather = try await weatherService.fetchWeather(location: determinedLocation)
            }
            
            // Успешная загрузка
            guard let loadedWeather = weather else {
                 // Сюда не должны попасть, но на всякий случай
                 throw NSError(domain: "Weather", code: 99, userInfo: [NSLocalizedDescriptionKey: "Failed to determine weather data after fetch attempt."])
            }

            await MainActor.run {
                self.weatherData = loadedWeather
                self.isLoading = false
                print("AutomaticBriefingViewModel: Weather data updated in UI")
                // Запускаем звук погоды ПОСЛЕ обновления UI
                playWeatherSound(for: loadedWeather.weatherType)
            }
        } catch {
            print("AutomaticBriefingViewModel: Error loading weather: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "Failed to load weather data. Please try again later."
                self.isLoading = false
                print("AutomaticBriefingViewModel: Error state updated in UI")
                // Останавливаем звук при ошибке
                AudioManager.shared.stopCurrentSound()
            }
        }
    }
    
    // Метод для выбора и запуска звука погоды
    private func playWeatherSound(for weatherType: WeatherType) {
        let soundName: String?
        switch weatherType {
        case .clear, .clouds, .haze, .smoke, .mist, .fog, .dust, .sand, .ash:
            soundName = "sunny" // Используем sunny для ясной и облачной/туманной погоды
        case .rain, .drizzle, .thunderstorm, .squall: // Добавим сюда грозу и шквал
            soundName = "rain"
        case .snow:
            soundName = "rain" // Используем rain для снега (или нужен отдельный звук?)
        case .tornado:
             soundName = "windy" // Используем windy для торнадо
        case .unknown:
            soundName = nil // Нет звука для неизвестной погоды
        // Добавим обработку всех кейсов, чтобы не было warning
        @unknown default:
             soundName = nil
        }
        
        if let name = soundName {
            print("AutomaticBriefingViewModel: Requesting AudioManager to play sound: \(name)")
            AudioManager.shared.playSound(named: name)
        } else {
            print("AutomaticBriefingViewModel: No specific sound for weather type \(weatherType.rawValue), stopping sound.")
            AudioManager.shared.stopCurrentSound()
        }
    }
}

struct AutomaticBriefingView: View {
    @StateObject private var viewModel = AutomaticBriefingViewModel()
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: themeManager.currentTheme.gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Automatic")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Briefing")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            HStack(spacing: 16) {
                                NavigationLink {
                                    SettingsView()
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        HStack(spacing: 20) {
                            if viewModel.error != nil {
                                // Иконка тучки при ошибке
                                Image(systemName: "cloud.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.white)
                                    .frame(width: 120, height: 120)
                            } else {
                                SystemWeatherIconView(weatherType: viewModel.weatherData.weatherType)
                                    .frame(width: 120, height: 120)
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                if let error = viewModel.error {
                                    // Кнопка повторного запроса при ошибке
                                    Button(action: {
                                        Task {
                                            if locationService.authorizationStatus == .notDetermined {
                                                locationService.requestPermission()
                                            }
                                            await viewModel.fetchWeather(with: locationService)
                                        }
                                    }) {
                                        Text("Retry")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                } else {
                                    Text("\(viewModel.weatherData.temperature > 0 ? "+" : "")\(Int(viewModel.weatherData.temperature))°")
                                        .font(.system(size: 68, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text(viewModel.weatherData.cityName)
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        }
                        
                        // Отображаем сообщение об ошибке, если есть
                        if let error = viewModel.error {
                            Text(error)
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                
                            if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
                                Button("Open Settings") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                                .padding(.bottom, 10)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            InfoRow(title: "Wind", value: viewModel.error != nil ? "—" : "\(Int(viewModel.weatherData.windSpeed)) Km/h")
                            InfoRow(title: "Precipitation", value: viewModel.error != nil ? "—" : viewModel.weatherData.weatherType.description)
                            InfoRow(title: "Visibility", value: viewModel.error != nil ? "—" : viewModel.weatherData.visibility)
                            InfoRo(title: viewModel.notamInfo)
                        }
                                                
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Precipitation")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.bottom, 5)

                            InfoRow(title: "Waiting time", value: viewModel.error != nil ? "—" : calculateWaitingTime(weather: viewModel.weatherData))

                            if viewModel.error != nil {
                                InfoRow(title: "Runway congestion", value: "—")

                                InfoRow(title: "Possible delays", value: "—")

                            } else {
                                let congestion = calculateRunwayCongestion(weather: viewModel.weatherData)
                                InfoRow(title: "Runway congestion", value: congestion, 
                                      valueColor: getCongestionColor(congestion: congestion))

                                
                                let delays = isPossibleDelays(weather: viewModel.weatherData)
                                InfoRow(title: "Possible delays", value: delays ? "Yes" : "No", 
                                      valueColor: delays ? .red : .green)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("AutomaticBriefingView appeared")
            Task {
                await viewModel.fetchWeather(with: locationService)
            }
            
            // Проверяем, должен ли звук воспроизводиться при открытии
            if themeManager.isSoundEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    playWeatherSound()
                }
            }
        }
        .onChange(of: locationService.location) { _ in
            print("Location changed, updating weather")
            Task {
                await viewModel.fetchWeather(with: locationService)
            }
        }
        .onChange(of: viewModel.weatherData.weatherType) { _ in
            // Воспроизводим звук только если включена соответствующая настройка
            if themeManager.isSoundEnabled {
                playWeatherSound()
            }
        }
        .onChange(of: themeManager.isSoundEnabled) { isEnabled in
            if isEnabled {
                playWeatherSound()
            } else {
                audioPlayer?.stop()
            }
        }
    }
    
    private func calculateWaitingTime(weather: WeatherData) -> String {
        switch weather.weatherType {
        case .thunderstorm, .tornado, .squall:
            return "45+ min"
        case .rain, .drizzle, .snow:
            return "30 min"
        case .fog, .mist, .haze, .smoke:
            return "25 min"
        case .clouds:
            if weather.windSpeed > 10 {
                return "20 min"
            } else {
                return "15 min"
            }
        case .clear:
            if weather.windSpeed > 15 {
                return "15 min"
            } else {
                return "10 min"
            }
        default:
            return "20 min"
        }
    }
    
    private func calculateRunwayCongestion(weather: WeatherData) -> String {
        switch weather.weatherType {
        case .thunderstorm, .tornado, .squall, .snow:
            return "High"
        case .rain, .drizzle, .fog, .mist, .haze:
            return "Medium"
        case .clouds:
            if weather.windSpeed > 10 {
                return "Medium"
            } else {
                return "Low"
            }
        case .clear:
            if weather.windSpeed > 15 {
                return "Low"
            } else {
                return "Minimal"
            }
        default:
            return "Low"
        }
    }
    
    private func isPossibleDelays(weather: WeatherData) -> Bool {
        switch weather.weatherType {
        case .thunderstorm, .tornado, .squall, .snow, .rain, .fog:
            return true
        case .drizzle, .mist, .haze:
            return weather.windSpeed > 8
        case .clouds:
            return weather.windSpeed > 12
        case .clear:
            return weather.windSpeed > 20
        default:
            return false
        }
    }
    
    private func playWeatherSound() {
        // Check if sound is enabled in settings
        guard themeManager.isSoundEnabled else {
            print("Sound is disabled in settings, not playing weather sound")
            audioPlayer?.stop()
            return
        }
        
        let soundFileName: String
        
        switch viewModel.weatherData.weatherType {
        case .rain, .drizzle, .thunderstorm:
            soundFileName = "rain"
        case .clear:
            soundFileName = "sunny"
        case .clouds, .squall, .tornado, .fog, .mist, .haze, .smoke, .dust, .snow:
            soundFileName = "windy"
        default:
            soundFileName = "sunny" // Используем sunny как запасной вариант
        }
        
        // Stop current audio if playing
        audioPlayer?.stop()
        
        // Play the selected audio file
        if let path = Bundle.main.path(forResource: soundFileName, ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1  // Loop indefinitely
                audioPlayer?.volume = 0.5        // Set a comfortable volume level
                audioPlayer?.play()
                print("Playing weather sound: \(soundFileName)")
            } catch {
                print("Could not play sound file: \(error)")
            }
        } else {
            print("Sound file '\(soundFileName).mp3' not found")
        }
    }
    
    private func getCongestionColor(congestion: String) -> Color {
        switch congestion {
        case "High":
            return .red
        case "Medium":
            return .orange
        case "Low":
            return .yellow
        case "Minimal":
            return .green
        default:
            return .white
        }
    }
}

struct InfoRo: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.white)

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal)
    }
}


struct InfoRow: View {
    let title: String
    let value: String
    var valueColor: Color = .white
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.white)
                Spacer()
                Text(value)
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(valueColor)
            }
            .cornerRadius(8)
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal)
    }
}

struct SystemWeatherIconView: View {
    let weatherType: WeatherType
    
    var body: some View {
        Image(systemName: weatherType.systemIconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.white)
    }
}

#Preview {
    AutomaticBriefingView()
        .environmentObject(LocationService())
        .environmentObject(ThemeManager())
}


struct RoundedCorners: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

import SwiftUI

class AircraftWeightViewModel: ObservableObject {
    @Published var emptyWeight: Double = 1500
    @Published var passengerCount: Int = 85
    @Published var distance: Double = 2500
    @Published var totalWeight: Double = 68.1
    
    @Published var occupancyPercentage: Double = 0
    @Published var weatherPercentage: Double = 0
    @Published var weightDistributionPercentage: Double = 0
    
    init() {
        calculateWeight()
        calculatePercentages()
    }
    
    func calculateWeight() {
        let passengerWeight = Double(passengerCount) * 0.08
        let fuelWeight = distance * 0.011
        totalWeight = emptyWeight + passengerWeight + fuelWeight
        totalWeight = round(totalWeight * 10) / 10
        
        calculatePercentages()
    }
    
    func calculatePercentages() {
        occupancyPercentage = min(100, max(0, Double(passengerCount) / 150 * 100))
        weatherPercentage = max(0, 100 - distance / 50)
        
        let passengerWeightRatio = Double(passengerCount) / 1000
        let emptyWeightRatio = emptyWeight / 3000
        let weightDistCalculation = 50 + (passengerWeightRatio - emptyWeightRatio) * 100
        weightDistributionPercentage = min(100, max(0, weightDistCalculation))
        
        occupancyPercentage = round(occupancyPercentage * 10) / 10
        weatherPercentage = round(weatherPercentage * 10) / 10
        weightDistributionPercentage = round(weightDistributionPercentage * 10) / 10
    }
}

struct CircularProgressView: View {
    var progress: Double
    var color: Color
    var label: String
    var percentage: String
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text(percentage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(width: 90)
        }
    }
}

struct KeyboardDoneButtonModifier: ViewModifier {
    @FocusState var focusState: Bool
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusState = false
                    }
                    .foregroundColor(Color(hex: "007DFF"))
                    .font(.system(size: 17, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
            }
    }
}

extension View {
    func keyboardDoneButton(focusState: FocusState<Bool>) -> some View {
        self.modifier(KeyboardDoneButtonModifier(focusState: focusState))
    }
}

struct InfoView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel = AircraftWeightViewModel()
    @FocusState private var isInputActive: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: themeManager.currentTheme.gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Основной контент
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight and")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                            Text("Balance Optimiser")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)

                    // Индикаторы прогресса в ряд
                    HStack(spacing: 30) {
                        CircularProgressView(
                            progress: viewModel.weightDistributionPercentage / 100,
                            color: Color(hex: "05FF05"),
                            label: "Weight\ndistribution",
                            percentage: "\(Int(viewModel.weightDistributionPercentage))%"
                        )
                        
                        CircularProgressView(
                            progress: viewModel.weatherPercentage / 100,
                            color: Color(hex: "7E05FF"),
                            label: "Weather\nconditions",
                            percentage: "\(Int(viewModel.weatherPercentage))%"
                        )
                        
                        CircularProgressView(
                            progress: viewModel.occupancyPercentage / 100,
                            color: Color(hex: "FF05B4"),
                            label: "Aircraft\noccupancy",
                            percentage: "\(Int(viewModel.occupancyPercentage))%"
                        )
                    }
                    .padding(.vertical, 20)
                    
                    // Изображение самолета
                    Image("airplane")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding(.vertical, 20)
                    
                    // Легенда
                    HStack(spacing: 40) {
                        legendItem(color: Color(hex: "44FF00"), text: "Oil")
                        legendItem(color: Color(hex: "FF0000"), text: "Baggage")
                    }
                    
                    HStack(spacing: 40) {
                        legendItem(color: Color(hex: "1E9EF9"), text: "Passengers and\nhand luggage")
                        legendItem(color: Color(hex: "D400FF"), text: "The nose of the\naircraft")
                    }
                    .padding(.bottom, 10)
                    
                    // Заголовок "Расчет веса самолета"
                    Text("Calculation of aircraft weight")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    // Поля для ввода
                    VStack(spacing: 15) {
                        inputField(title: "Empty aircraft weight(T)", value: $viewModel.emptyWeight, format: "%.0f")
                        inputField(title: "Number of passengers", value: Binding(
                            get: { Double(viewModel.passengerCount) },
                            set: { viewModel.passengerCount = Int($0) }
                        ), format: "%.0f")
                        inputField(title: "Distance (km)(amount of fuel)", value: $viewModel.distance, format: "%.0f")
                    }
                    .padding(.horizontal)
                    .focused($isInputActive)
                    
                    // Результат расчета
                    Text("\(String(format: "%.1f", viewModel.totalWeight).replacingOccurrences(of: ".", with: ",")) T")
                        .font(.system(size: 31, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                    
                    // Кнопка расчета
                    Button(action: {
                        viewModel.calculateWeight()
                        isInputActive = false
                    }) {
                        Text("Calculate")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color(hex: "007DFF"))
                            .cornerRadius(45)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 100)
                }
                .padding(.horizontal)
            }
        }
        .keyboardDoneButton(focusState: _isInputActive)
    }
    
    // Компонент элемента легенды
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
            
            Text(text)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // Компонент поля ввода
    private func inputField(title: String, value: Binding<Double>, format: String) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            TextField("", value: value, formatter: NumberFormatter().then {
                $0.numberStyle = .decimal
                $0.maximumFractionDigits = 0
            })
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .padding(12)
            .background(Color.white)
            .foregroundColor(Color(hex: "4FA4C9"))
            .font(.system(size: 18, weight: .bold))
            .cornerRadius(45)
            .focused($isInputActive)
            .onChange(of: value.wrappedValue) { _ in
                viewModel.calculatePercentages()
            }
        }
    }
}

// Расширение для работы с цветами в формате Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Расширение для работы с NumberFormatter
extension NumberFormatter {
    func then(_ block: (NumberFormatter) -> Void) -> NumberFormatter {
        block(self)
        return self
    }
} 

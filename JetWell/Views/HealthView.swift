import SwiftUI
import Combine // Добавим Combine для @ObservedObject/ObservableObject, если еще нет

class HealthViewModel: ObservableObject {
    // Используем @AppStorage для автоматической связи с UserDefaults
    @AppStorage("healthFatigueLevel") var fatigue: Double = 0.0
    @AppStorage("healthStressLevel") var stress: Double = 0.0
    @AppStorage("healthHasTakenTest") var hasTakenTest: Bool = false
    
    var fatigueLevel: String {
        if fatigue < 0.3 {
            return "Low"
        } else if fatigue < 0.7 {
            return "Middle"
        } else {
            return "High"
        }
    }
    
    var stressLevel: String {
        if stress < 0.3 {
            return "Low"
        } else if stress < 0.7 {
            return "Middle"
        } else {
            return "High"
        }
    }
    
    var recommendation: String {
        if !hasTakenTest {
            return "No data available. Please take the fatigue and stress test to get personalized recommendations."
        } else if stress > 0.5 {
            return "To prevent stress from hitting your relationships and well-being, it's important to release it quickly. There is a whole set of techniques that will help you cope in a difficult situation. With their help, you will distract yourself, relax, switch from negative thoughts to positive."
        } else if fatigue > 0.5 {
            return "Your fatigue level is elevated. It's recommended to take regular breaks, ensure you're getting adequate sleep, and consider relaxation techniques such as deep breathing or meditation."
        } else {
            return "Your stress and fatigue levels are within normal range. Continue to maintain a healthy work-life balance and regular rest periods."
        }
    }
    
    // Метод для сброса данных HealthView
    func clearHealthData() {
        print("Attempting to clear Health data...")
        // Удаляем ключи из UserDefaults. @AppStorage автоматически обновит значения на дефолтные.
        UserDefaults.standard.removeObject(forKey: "healthFatigueLevel")
        UserDefaults.standard.removeObject(forKey: "healthStressLevel")
        UserDefaults.standard.removeObject(forKey: "healthHasTakenTest")
        print("Removed health keys from UserDefaults")
        // Убираем явный вызов, полагаемся на @AppStorage
        // objectWillChange.send()
        
        // Установка значений на дефолтные здесь может быть не нужна,
        // так как @AppStorage сам вернет дефолтное значение при отсутствии ключа.
        // Но оставим для надежности, если @AppStorage не среагирует мгновенно.
        fatigue = 0.0
        stress = 0.0
        hasTakenTest = false
        print("Health properties reset in ViewModel")
    }
}

struct HealthView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var viewModel: HealthViewModel
    
    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                gradient: Gradient(colors: themeManager.currentTheme.gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Основной контент со скроллингом
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    // Заголовок
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Health")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                            Text("Tracker")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)

                    // Разделитель
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.white.opacity(0.2))

                    // Индикатор усталости
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Fatigue")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(viewModel.fatigueLevel)
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.white)
                        }
                        
                        ZStack(alignment: .leading) {
                            // Фон прогресс-бара
                            Capsule()
                                .frame(height: 18)
                                .foregroundColor(Color.white.opacity(0.2))
                            
                            // Заполненная часть с градиентом
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "38BBA1"), Color(hex: "3DDFB2")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: getProgressBarWidth(progress: viewModel.fatigue), height: 18)
                        }
                        .animation(.easeInOut(duration: 0.5), value: viewModel.fatigue)
                    }
                    
                    // Разделитель
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Индикатор стресса
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Stress")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(viewModel.stressLevel)
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.white)
                        }
                        
                        ZStack(alignment: .leading) {
                            // Фон прогресс-бара
                            Capsule()
                                .frame(height: 18)
                                .foregroundColor(Color.white.opacity(0.2))
                            
                            // Заполненная часть с градиентом
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "98BB38"), Color(hex: "3DDFB2")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: getProgressBarWidth(progress: viewModel.stress), height: 18)
                        }
                        .animation(.easeInOut(duration: 0.5), value: viewModel.stress)
                    }
                    
                    // Разделитель
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Кнопка тестирования через NavigationLink
                    NavigationLink(destination: FatigueTestView(viewModel: viewModel)) {
                        HStack {
                            Text("Fatigue and stress testing")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 0)
                    
                    // Разделитель
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Рекомендации
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recommendation")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(viewModel.recommendation)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Добавляем отступ внизу для скролла
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // Получение ширины прогресс-бара на основе прогресса
    private func getProgressBarWidth(progress: Double) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 40  // Учитываем отступы
        return screenWidth * CGFloat(progress)
    }
    
    // Эти методы оставляем для обратной совместимости, хотя они больше не используются
    private func getFatigueColor(level: Double) -> Color {
        if level < 0.3 {
            return Color.green
        } else if level < 0.7 {
            return Color.yellow
        } else {
            return Color.red
        }
    }
    
    private func getStressColor(level: Double) -> Color {
        if level < 0.3 {
            return Color.green
        } else if level < 0.7 {
            return Color.yellow
        } else {
            return Color.red
        }
    }
} 

#Preview {
    HealthView()
        .environmentObject(ThemeManager())
        .environmentObject(HealthViewModel())
}

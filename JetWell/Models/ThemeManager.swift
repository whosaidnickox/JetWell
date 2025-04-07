import SwiftUI
import Combine

// Определяем структуры для тем
struct Theme {
    let name: String
    let gradientColors: [Color]
    // Можно добавить другие свойства темы, если нужно
}

class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false {
        didSet {
            updateCurrentTheme()
            // Оповещаем подписчиков об изменении темы
            objectWillChange.send()
        }
    }
    
    // Удаляем @AppStorage для isSoundEnabled
    // @AppStorage("isSoundEnabled") var isSoundEnabled = false
    
    @Published var currentTheme: Theme

    // Определяем светлую и темную темы
    let lightTheme = Theme(name: "Light", gradientColors: [Color(hex: "37A9FA"), Color(hex: "AFFFFF")])
    let darkTheme = Theme(name: "Dark", gradientColors: [Color(hex: "101010"), Color(hex: "101010")])

    init() {
        // Читаем значение isDarkMode напрямую из UserDefaults
        let initialIsDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        // Инициализируем currentTheme на основе прочитанного значения
        self.currentTheme = initialIsDarkMode ? darkTheme : lightTheme
        
        // Теперь self полностью инициализирован, и @AppStorage может работать корректно.
    }

    private func updateCurrentTheme() {
        currentTheme = isDarkMode ? darkTheme : lightTheme
    }
    
    // Свойство isSoundEnabled теперь работает с глобальной настройкой AudioManager
    var isSoundEnabled: Bool {
        get {
            // Читаем глобальную настройку из AudioManager
            AudioManager.shared.soundEnabled
        }
        set {
            // Устанавливаем глобальную настройку через AudioManager
            AudioManager.shared.setSoundEnabled(newValue)
            // Оповещаем подписчиков об изменении состояния звука
            objectWillChange.send()
        }
    }
}

// Расширение для Color для использования HEX (если еще нету)
// extension Color { ... } 

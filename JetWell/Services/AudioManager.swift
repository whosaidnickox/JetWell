import AVFoundation
import Combine
import SwiftUI // Для @AppStorage

class AudioManager: ObservableObject {
    static let shared = AudioManager()

    private var audioPlayer: AVAudioPlayer?
    // Используем @AppStorage для общей настройки вкл/выкл звуков
    @AppStorage("globalSoundEnabled") private var isSoundGloballyEnabled: Bool = true // Звуки включены по умолчанию

    // Удаляем @Published var isPlaying, так как он больше не отражает общее состояние

    private init() {
        // Не вызываем setupAudioPlayer здесь, он будет настраиваться по запросу
        // Настраиваем аудиосессию так, чтобы она была готова к воспроизведению
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default) // .ambient, чтобы не прерывать другую музыку
            try AVAudioSession.sharedInstance().setActive(true)
            print("AudioManager: Audio session configured.")
        } catch {
            print("AudioManager: Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    // Универсальный метод для воспроизведения звука
    func playSound(named soundName: String) {
        // Проверяем глобальную настройку
        guard isSoundGloballyEnabled else {
            print("AudioManager: Sounds are globally disabled.")
            stopCurrentSound() // Останавливаем звук, если он играл, а настройку выключили
            return
        }

        // Останавливаем текущий звук, если он есть и отличается
        if let currentPlayer = audioPlayer, currentPlayer.isPlaying, 
           let currentURL = currentPlayer.url?.deletingPathExtension().lastPathComponent, currentURL != soundName {
            stopCurrentSound()
        }
        
        // Если звук уже играет и это тот же самый, ничего не делаем
        if let currentPlayer = audioPlayer, currentPlayer.isPlaying, 
           let currentURL = currentPlayer.url?.deletingPathExtension().lastPathComponent, currentURL == soundName {
             print("AudioManager: Sound \"\(soundName)\" is already playing.")
            return
        }
        
        // Загружаем и проигрываем новый звук
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("AudioManager: Error - Could not find \"\(soundName).mp3\" in bundle.")
            return
        }

        do {
            // Если плеер уже есть, просто меняем URL и играем
            if audioPlayer != nil {
                // Пересоздаем плеер для нового файла, т.к. смена URL не поддерживается
                 audioPlayer?.stop()
                 audioPlayer = nil
            }
            
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Бесконечный цикл
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("AudioManager: Started playing \"\(soundName).mp3\"")
        } catch {
            print("AudioManager: Error initializing or playing \"\(soundName).mp3\": \(error.localizedDescription)")
            audioPlayer = nil
        }
    }
    
    // Метод для остановки текущего звука
    func stopCurrentSound() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
            print("AudioManager: Stopped current sound.")
            // Не сбрасываем currentTime, так как плеер может быть переиспользован
            // или будет создан новый при следующем playSound.
        }
        // Убираем плеер, чтобы при следующем playSound создался новый
        audioPlayer = nil 
    }

    // Метод для переключения глобальной настройки (вызывается из ThemeManager)
    func setSoundEnabled(_ enabled: Bool) {
        isSoundGloballyEnabled = enabled
        if !enabled {
            stopCurrentSound()
        } 
        // Если включили, звук сам начнется при следующем обновлении погоды.
        print("AudioManager: Global sound setting set to \(enabled)")
    }
    
    // Свойство для чтения глобальной настройки (для ThemeManager)
    var soundEnabled: Bool {
        return isSoundGloballyEnabled
    }
} 
//
//  JetWellApp.swift
//  JetWell
//
//  Created by dsm 5e on 05.04.2025.
//

import SwiftUI
import AVFoundation

@main
struct JetWellApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Creating a LocationService instance at the application level
    @StateObject private var locationService = LocationService()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var healthViewModel = HealthViewModel()
    // Создаем экземпляр AudioManager при старте
    // Используем _ = AudioManager.shared, чтобы вызвать приватный init() и настроить плеер
    let audioManager = AudioManager.shared 
    
    init() {
        // Старую настройку аудиосессии можно убрать, если AudioManager делает это сам
        // setupAudioSession()
    }
    
    /* Убираем старый setupAudioSession, т.к. AudioManager его заменяет
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session successfully initialized")
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    */
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Requesting location access permission when the app launches
                    print("Application appeared, requesting location permission immediately")
                    
                    // Requesting permission immediately at launch
                    locationService.requestPermission()
                    
                    // Also setting a timer for a repeated request after 2 seconds
                    // if the first request did not work properly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if locationService.authorizationStatus == .notDetermined {
                            print("Authorization status still notDetermined after 2 seconds, requesting again")
                            locationService.requestPermission()
                        } else {
                            print("Authorization status after 2 seconds: \(locationService.authorizationStatus.rawValue)")
                        }
                    }
                }
                // Передаем AudioManager в окружение, если он понадобится где-то еще
                // .environmentObject(audioManager) // Раскомментируй, если нужно
                .environmentObject(locationService)
                .environmentObject(themeManager)
                .environmentObject(healthViewModel)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}
class AppDelegate: NSObject, UIApplicationDelegate {
    static var asiuqzoptqxbt = UIInterfaceOrientationMask.portrait {
        didSet {
            if #available(iOS 16.0, *) {
                UIApplication.shared.connectedScenes.forEach { scene in
                    if let windowScene = scene as? UIWindowScene {
                        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: asiuqzoptqxbt))
                    }
                }
                UIViewController.attemptRotationToDeviceOrientation()
            } else {
                if asiuqzoptqxbt == .landscape {
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                }
            }
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.asiuqzoptqxbt
    }
}



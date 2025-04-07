import SwiftUI
import UserNotifications
import StoreKit

class SettingsViewModel: ObservableObject {
    @AppStorage("isSoundEnabled") var isSoundEnabled = false
    @AppStorage("isNotificationEnabled") var isNotificationEnabled = true
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var healthViewModel: HealthViewModel
    @State private var showingClearDataAlert = false
    @State private var showingNotificationSettingsAlert = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: themeManager.currentTheme.gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Settings")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(.top, 20)
                
                VStack(spacing: 24) {
                    HStack {
                        Text("Sounds")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $themeManager.isSoundEnabled)
                        .tint(.green)
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Text("Notification")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $viewModel.isNotificationEnabled)
                            .tint(.green)
                            .onChange(of: viewModel.isNotificationEnabled) { newValue in
                                if newValue {
                                    requestNotificationPermission()
                                }
                            }
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Text("Dark mode")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $themeManager.isDarkMode)
                        .tint(.green)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    SettingsButton(title: "Privacy Policy") {
                        if let url = URL(string: "https://google.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    SettingsButton(title: "Clear Data") {
                        showingClearDataAlert = true
                    }
                    
                    SettingsButton(title: "Rate Us") {
                        print("Requesting review (old method).")
                        SKStoreReviewController.requestReview()
                    }
                }
                .padding(.top, 30)
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(true)
        .alert("Clear Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                print("Clear button tapped in alert.")
                healthViewModel.clearHealthData()
                ChecksView.clearChecklistData()
                print("Clear methods called.")
            }
        } message: {
            Text("Are you sure you want to clear all saved health and checklist data? This action cannot be undone.")
        }
        .alert("Enable Notifications", isPresented: $showingNotificationSettingsAlert) {
            Button("Cancel", role: .cancel) { 
                viewModel.isNotificationEnabled = false
            }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
                viewModel.isNotificationEnabled = false
            }
        } message: {
            Text("To enable notifications, please go to Settings and allow notifications for this app.")
        }
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        DispatchQueue.main.async {
                            if granted {
                                print("Notification permission granted.")
                            } else {
                                print("Notification permission denied by user.")
                                viewModel.isNotificationEnabled = false
                            }
                            if let error = error {
                                print("Error requesting notification permission: \(error.localizedDescription)")
                                viewModel.isNotificationEnabled = false
                            }
                        }
                    }
                case .denied:
                    print("Notification permission previously denied.")
                    showingNotificationSettingsAlert = true
                    
                case .authorized, .provisional, .ephemeral:
                    print("Notification permission already granted.")
                    
                @unknown default:
                    print("Unknown notification authorization status.")
                    viewModel.isNotificationEnabled = false
                }
            }
        }
    }
}

struct SettingsButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "007DFF"))
                .cornerRadius(16)
        }
    }
}

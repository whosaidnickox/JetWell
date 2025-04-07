import SwiftUI

struct ChecklistItem: Identifiable, Codable {
    let id = UUID()
    let text: String
    var isCompleted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case text
        case isCompleted
    }
}

struct ChecklistItemView: View {
    let item: ChecklistItem
    let toggleAction: () -> Void
    
    var body: some View {
        Button(action: toggleAction) {
            HStack(alignment: .top) {
                Text(item.text)
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 8)
                
                Spacer(minLength: 16)
                
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(Color(hex: "F279BA"))
                    .font(.system(size: 30))
                    .frame(width: 30, height: 30)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            )
        }
    }
}

struct ChecksView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var checklistItems: [ChecklistItem] = ChecksView.loadChecklistItems()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: themeManager.currentTheme.gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Checklists")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                        Text("Generator")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach($checklistItems) { $item in
                            ChecklistItemView(
                                item: item,
                                toggleAction: {
                                    item.isCompleted.toggle()
                                    saveChecklistItems()
                                }
                            )
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            // Перезагружаем данные при каждом появлении View
            // чтобы отразить очистку, сделанную в Settings
            print("ChecksView appeared, reloading checklist items.")
            self.checklistItems = ChecksView.loadChecklistItems()
        }
    }
    
    static private func loadChecklistItems() -> [ChecklistItem] {
        let defaultItems = [
            ChecklistItem(text: "Check the operation and maintenance of all security systems, including weapons and explosives detection and control equipment, fire detection and evacuation system."),
            ChecklistItem(text: "Check the operation and maintenance of all baggage handling systems, including baggage sorting, loading and unloading."),
            ChecklistItem(text: "Verify that all airport lighting, ventilation, air conditioning and heating systems are operational and maintained."),
            ChecklistItem(text: "Checking the availability and serviceability of all building maintenance and servicing systems, including the emergency power system."),
            ChecklistItem(text: "Verification of the availability and serviceability of telecommunication systems, including aircraft communication system and radios."),
            ChecklistItem(text: "Verification that all passenger service systems, including the passenger information system, waiting areas, baggage handling system and passenger check-in system, are operational and in good working order."),
            ChecklistItem(text: "Verification of the availability and proper functioning of firefighting equipment, including fire extinguishers and hydrants."),
            ChecklistItem(text: "Checking the presence and proper functioning of the airport's CCTV and security system."),
            ChecklistItem(text: "Verify that the automatic weather information system and airport conditions monitoring system are in place and working properly."),
            ChecklistItem(text: "Verify that the passenger security system, including document verification, drug and weapons detection and border control, is in place and working properly.")
        ]
        
        guard let savedData = UserDefaults.standard.data(forKey: "checklistItemsState"),
              let savedStates = try? JSONDecoder().decode([String: Bool].self, from: savedData) else {
            return defaultItems
        }
        
        var loadedItems = defaultItems
        for i in 0..<loadedItems.count {
            if let savedState = savedStates[loadedItems[i].text] {
                loadedItems[i].isCompleted = savedState
            }
        }
        return loadedItems
    }
    
    private func saveChecklistItems() {
        let statesToSave = Dictionary(uniqueKeysWithValues: checklistItems.map { ($0.text, $0.isCompleted) })
        
        if let encodedData = try? JSONEncoder().encode(statesToSave) {
            UserDefaults.standard.set(encodedData, forKey: "checklistItemsState")
        }
    }
    
    static func clearChecklistData() {
        print("Attempting to clear Checklist data...")
        UserDefaults.standard.removeObject(forKey: "checklistItemsState")
        print("Removed checklist key from UserDefaults")
        // При следующем открытии ChecksView загрузятся дефолтные значения
    }
} 

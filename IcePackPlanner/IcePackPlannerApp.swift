
import SwiftUI

// MARK: - Main App
@main
struct IcePackPlannerApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(appState)
            } else {
                SplashView()
                    .environmentObject(appState)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                // Сохраняем данные при сворачивании приложения
                appState.savePacks()
                appState.saveTrips()
            }
        }
    }
}

// MARK: - Preview
struct IcePackPlanner_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.hasCompletedOnboarding = true
        appState.packs = [
            Pack(name: "Ice Fishing Basic", type: .winter, items: [
                PackItem(name: "Warm jacket", category: .clothing, priority: .high, isChecked: true),
                PackItem(name: "Ice auger", category: .tools, priority: .high),
                PackItem(name: "Fishing rod", category: .tackle, priority: .high),
            ])
        ]
        
        return MainTabView()
            .environmentObject(appState)
    }
}


import SwiftUI

@main
struct IcePackPlannerApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            LightDepthNotesSplashScreen()
        }
    }
}

struct RootView: View {
    
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            if appState.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(appState)
            } else {
                OnboardingView()
                    .environmentObject(appState)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                appState.savePacks()
                appState.saveTrips()
            }
        }
    }
    
}

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

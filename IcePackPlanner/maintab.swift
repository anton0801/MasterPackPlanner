
import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    init() {
        // Configure navigation bar to be transparent
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)]
        appearance.titleTextAttributes = [.foregroundColor: UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Configure tab bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            TabView {
                PacksListView()
                    .tabItem {
                        Label("Packs", systemImage: "bag")
                    }
                
                TripsView()
                    .tabItem {
                        Label("Trips", systemImage: "calendar")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
}

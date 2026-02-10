
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

class MarketingFlow: NSObject {
    var onMarketing: (([AnyHashable: Any]) -> Void)?
    var onRouting: (([AnyHashable: Any]) -> Void)?
    
    private var marketingData: [AnyHashable: Any] = [:]
    private var routingData: [AnyHashable: Any] = [:]
    private var timer: Timer?
    private let processedFlag = "mp_marketing_processed"
    
    func receiveMarketing(_ data: [AnyHashable: Any]) {
        marketingData = data
        scheduleTimer()
        if !routingData.isEmpty { combine() }
    }
    
    func receiveRouting(_ data: [AnyHashable: Any]) {
        guard !isProcessed() else { return }
        routingData = data
        onRouting?(data)
        timer?.invalidate()
        if !marketingData.isEmpty { combine() }
    }
    
    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in self?.combine() }
    }
    
    private func combine() {
        var merged = marketingData
        routingData.forEach { key, value in
            let prefixedKey = "deep_\(key)"
            if merged[prefixedKey] == nil { merged[prefixedKey] = value }
        }
        onMarketing?(merged)
    }
    
    private func isProcessed() -> Bool {
        UserDefaults.standard.bool(forKey: processedFlag)
    }
}

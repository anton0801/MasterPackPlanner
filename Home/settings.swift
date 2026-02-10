
import SwiftUI
import WebKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingResetAlert = false
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            NavigationView {
                List {
                    Section("Statistics") {
                        StatsView()
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                    
                    Section("Data") {
                        Button("Reset All Checklists") {
                            showingResetAlert = true
                        }
                        .foregroundColor(.red)
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                }
                .background(Color.clear)
                .onAppear {
                    UITableView.appearance().backgroundColor = .clear
                }
                .navigationTitle("Settings")
                .alert("Reset All Data?", isPresented: $showingResetAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) {
                        appState.packs.removeAll()
                        appState.trips.removeAll()
                        appState.savePacks()
                        appState.saveTrips()
                    }
                } message: {
                    Text("This will delete all packs and trips. This action cannot be undone.")
                }
            }
        }
    }
}

final class WebHandler: NSObject {
    weak var view: WKWebView?
    
    var bounces = 0
    var bounceLimit = 70
    var previousURL: URL?
    var journey: [URL] = []
    var safeURL: URL?
    var overlays: [WKWebView] = []
    let storage = "pack_cookies"
    
    func open(_ url: URL, in view: WKWebView) {
        print("📦 [Pack] Open: \(url.absoluteString)")
        journey = [url]
        bounces = 0
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        view.load(req)
    }
    
    func loadCookies(in view: WKWebView) {
        guard let stored = UserDefaults.standard.object(forKey: storage) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = view.configuration.websiteDataStore.httpCookieStore
        let cookies = stored.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    func saveCookies(from view: WKWebView) {
        let cookieStore = view.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var stored: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domain = stored[cookie.domain] ?? [:]
                if let props = cookie.properties { domain[cookie.name] = props }
                stored[cookie.domain] = domain
            }
            UserDefaults.standard.set(stored, forKey: self.storage)
        }
    }
}

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @State private var animateProgress = false
    
    var mostForgottenItems: [(String, Int)] {
        var itemFrequency: [String: Int] = [:]
        
        // Count unchecked items across all packs
        for pack in appState.packs {
            for item in pack.items where !item.isChecked {
                itemFrequency[item.name, default: 0] += 1
            }
        }
        
        return itemFrequency.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            StatRow(title: "Total Packs", value: "\(appState.totalPacks)")
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Avg Readiness")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(appState.avgReadiness * 100))%")
                        .font(.headline)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                        
                        Rectangle()
                            .fill(Color.cyan)
                            .frame(width: animateProgress ? geometry.size.width * appState.avgReadiness : 0)
                    }
                }
                .frame(height: 8)
                .cornerRadius(4)
            }
            
            StatRow(title: "Trips Prepared", value: "\(appState.tripsCount)")
            
            if !mostForgottenItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Often Unchecked")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(mostForgottenItems, id: \.0) { item in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(item.0)
                                .font(.subheadline)
                            Spacer()
                            Text("\(item.1)×")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateProgress = true
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}

#Preview {
    PackNotificationView(flux: FluxContainer())
}

struct PackNotificationView: View {
    @ObservedObject var flux: FluxContainer
    
    private var buttons: some View {
        VStack(spacing: 16) {
            Button {
                flux.actions.requestNotificationPermission()
            } label: {
                Text("YES, I WANT BONUSES!")
                    .font(.system(size: 19, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Color(hex: "E52555")
                    )
                    .cornerRadius(52)
            }
            .padding(.horizontal, 32)
            
            Button {
                flux.actions.postponeNotificationPermission()
            } label: {
                Text("Maybe later")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.3))
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 40)
                    .background(
                        .white.opacity(0.1)
                    )
                    .cornerRadius(52)
            }
            .padding(.horizontal, 52)
        }
    }
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("bg_for_notifications")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(0.9)
                
                if g.size.width < g.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        
                        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .multilineTextAlignment(.center)
                        
                        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .multilineTextAlignment(.center)
                        
                        buttons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Spacer()
                            Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .multilineTextAlignment(.center)
                            
                            Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Spacer()
                            buttons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

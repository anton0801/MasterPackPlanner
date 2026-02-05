
import SwiftUI

// MARK: - Settings View
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
                        
                        Button("Export Packs") {
                            // Export functionality
                        }
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

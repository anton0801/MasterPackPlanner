
import SwiftUI

// MARK: - Trips View
struct TripsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTrip = false
    @State private var filterStatus: TripStatus?
    
    var filteredTrips: [Trip] {
        if let status = filterStatus {
            return appState.trips.filter { $0.status == status }
        }
        return appState.trips
    }
    
    var sortedTrips: [Trip] {
        filteredTrips.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            NavigationView {
                ZStack {
                    if appState.trips.isEmpty {
                        EmptyTripsView()
                    } else {
                        VStack(spacing: 0) {
                            // Filter buttons
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    FilterButton(title: "All", isSelected: filterStatus == nil) {
                                        filterStatus = nil
                                    }
                                    
                                    FilterButton(title: "Planning", isSelected: filterStatus == .planning) {
                                        filterStatus = .planning
                                    }
                                    
                                    FilterButton(title: "Ready", isSelected: filterStatus == .ready) {
                                        filterStatus = .ready
                                    }
                                    
                                    FilterButton(title: "Completed", isSelected: filterStatus == .completed) {
                                        filterStatus = .completed
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                            }
                            .background(Color.white.opacity(0.5))
                            
                            if sortedTrips.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("No trips with this status")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxHeight: .infinity)
                            } else {
                                List {
                                    ForEach(sortedTrips) { trip in
                                        NavigationLink(destination: TripDetailView(trip: trip)) {
                                            TripRow(trip: trip)
                                        }
                                        .listRowBackground(Color.white.opacity(0.7))
                                    }
                                    .onDelete { indexSet in
                                        indexSet.forEach { index in
                                            let tripToDelete = sortedTrips[index]
                                            appState.trips.removeAll { $0.id == tripToDelete.id }
                                        }
                                        appState.saveTrips()
                                    }
                                }
                                .listStyle(PlainListStyle())
                                .background(Color.clear)
                                .onAppear {
                                    UITableView.appearance().backgroundColor = .clear
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Trips")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddTrip = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.cyan)
                        }
                        .disabled(appState.packs.isEmpty)
                    }
                }
                .sheet(isPresented: $showingAddTrip) {
                    AddTripView()
                }
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.cyan : Color(.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct TripRow: View {
    let trip: Trip
    @EnvironmentObject var appState: AppState
    
    var pack: Pack? {
        appState.packs.first(where: { $0.id == trip.packId })
    }
    
    var packName: String {
        pack?.name ?? "Unknown Pack"
    }
    
    var displayItems: [PackItem] {
        // Если в trip нет items, берём из pack
        if trip.items.isEmpty, let pack = pack {
            return pack.items
        }
        return trip.items
    }
    
    var completedCount: Int {
        displayItems.filter { $0.isChecked }.count
    }
    
    var progress: Double {
        guard !displayItems.isEmpty else { return 0 }
        return Double(completedCount) / Double(displayItems.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(packName)
                    .font(.headline)
                
                Spacer()
                
                Text(trip.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trip.status.color.opacity(0.2))
                    .foregroundColor(trip.status.color)
                    .cornerRadius(6)
            }
            
            HStack {
                Text(trip.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if displayItems.isEmpty {
                    Text("No items in pack")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(completedCount) / \(displayItems.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !displayItems.isEmpty {
                ProgressView(value: progress)
                    .tint(progress == 1.0 ? .green : .cyan)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyTripsView: View {
    @State private var pulse = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(.gray)
                .scaleEffect(pulse ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
            
            Text("Plan your first trip")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .onAppear {
            pulse = true
        }
    }
}

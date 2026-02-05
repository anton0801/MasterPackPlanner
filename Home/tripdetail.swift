
import SwiftUI

// MARK: - Trip Detail View
struct TripDetailView: View {
    let trip: Trip
    @EnvironmentObject var appState: AppState
    @State private var editedTrip: Trip
    
    init(trip: Trip) {
        self.trip = trip
        _editedTrip = State(initialValue: trip)
    }
    
    var pack: Pack? {
        appState.packs.first(where: { $0.id == trip.packId })
    }
    
    var packName: String {
        pack?.name ?? "Unknown Pack"
    }
    
    var groupedItems: [ItemCategory: [PackItem]] {
        Dictionary(grouping: editedTrip.items, by: { $0.category })
    }
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(editedTrip.date, style: .date)
                                .font(.headline)
                            
                            Spacer()
                            
                            Menu {
                                Button("Planning") {
                                    updateStatus(.planning)
                                }
                                Button("Ready") {
                                    updateStatus(.ready)
                                }
                                Button("Completed") {
                                    updateStatus(.completed)
                                }
                            } label: {
                                HStack {
                                    Text(editedTrip.status.rawValue)
                                        .font(.subheadline)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(editedTrip.status.color.opacity(0.2))
                                .foregroundColor(editedTrip.status.color)
                                .cornerRadius(8)
                            }
                        }
                        
                        HStack {
                            Text("\(editedTrip.items.filter { $0.isChecked }.count) / \(editedTrip.items.count)")
                                .font(.title3)
                            
                            Spacer()
                            
                            Text("\(Int(editedTrip.progress * 100))%")
                                .foregroundColor(.cyan)
                        }
                        
                        ProgressView(value: editedTrip.progress)
                            .tint(editedTrip.progress == 1.0 ? .green : .cyan)
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.white.opacity(0.7))
                
                // Показываем кнопку синхронизации если items пустые или устарели
                if editedTrip.items.isEmpty && pack != nil && !(pack?.items.isEmpty ?? true) {
                    Section {
                        Button {
                            syncItemsFromPack()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Sync items from pack")
                                Spacer()
                                Text("\(pack?.items.count ?? 0) items")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                }
                
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    if let items = groupedItems[category], !items.isEmpty {
                        Section(header: HStack {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                        }) {
                            ForEach(items) { item in
                                ItemRow(item: item) { updatedItem in
                                    updateItem(updatedItem)
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.7))
                    }
                }
                
                // Empty state если нет items
                if editedTrip.items.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "checklist")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No items in this trip")
                                .foregroundColor(.secondary)
                            if pack != nil && !(pack?.items.isEmpty ?? true) {
                                Text("Tap 'Sync items from pack' above")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                }
            }
            .background(Color.clear)
            .navigationTitle(packName)
            .onAppear {
                UITableView.appearance().backgroundColor = .clear
                // Автоматически синхронизируем items если trip пустой
                if editedTrip.items.isEmpty, let pack = pack, !pack.items.isEmpty {
                    syncItemsFromPack()
                }
            }
        }
    }
    
    func syncItemsFromPack() {
        guard let pack = pack else { return }
        
        // Копируем items из pack и сбрасываем галочки
        editedTrip.items = pack.items.map { item in
            var newItem = item
            newItem.isChecked = false
            return newItem
        }
        appState.updateTrip(editedTrip)
    }
    
    func updateStatus(_ status: TripStatus) {
        withAnimation {
            editedTrip.status = status
            appState.updateTrip(editedTrip)
        }
    }
    
    func updateItem(_ item: PackItem) {
        if let index = editedTrip.items.firstIndex(where: { $0.id == item.id }) {
            editedTrip.items[index] = item
            appState.updateTrip(editedTrip)
        }
    }
}

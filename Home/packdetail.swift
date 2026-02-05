
import SwiftUI

// MARK: - Pack Detail View
struct PackDetailView: View {
    let packId: UUID
    @EnvironmentObject var appState: AppState
    @State private var showingAddItem = false
    @State private var selectedCategory: ItemCategory?
    @State private var showingEditName = false
    @State private var editedName = ""
    @State private var showingDuplicateAlert = false
    
    var pack: Pack {
        appState.packs.first(where: { $0.id == packId }) ?? Pack(name: "Unknown", type: .custom)
    }
    
    var groupedItems: [ItemCategory: [PackItem]] {
        Dictionary(grouping: pack.items, by: { $0.category })
    }
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            List {
                Section {
                    VStack(spacing: 12) {
                        HStack {
                            Text("\(pack.completedCount) / \(pack.items.count)")
                                .font(.system(size: 28, weight: .bold))
                            
                            Spacer()
                            
                            Text("\(Int(pack.progress * 100))%")
                                .font(.title3)
                                .foregroundColor(.cyan)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                
                                Rectangle()
                                    .fill(pack.progress == 1.0 ? Color.green : Color.cyan)
                                    .frame(width: geometry.size.width * pack.progress)
                                    .animation(.easeInOut(duration: 0.5), value: pack.progress)
                            }
                        }
                        .frame(height: 8)
                        .cornerRadius(4)
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.white.opacity(0.7))
                
                // Quick actions section
                Section {
                    Button {
                        resetAllChecks()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Checks")
                            Spacer()
                        }
                    }
                    .disabled(pack.completedCount == 0)
                    
                    Button {
                        checkAll()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Check All Items")
                            Spacer()
                        }
                    }
                    .disabled(pack.completedCount == pack.items.count || pack.items.isEmpty)
                    
                    Button {
                        showingDuplicateAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Duplicate Pack")
                            Spacer()
                        }
                    }
                } header: {
                    Text("Quick Actions")
                }
                .listRowBackground(Color.white.opacity(0.7))
                
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
                            .onDelete { indexSet in
                                deleteItems(in: category, at: indexSet)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.7))
                    }
                }
            }
            .background(Color.clear)
            .onAppear {
                UITableView.appearance().backgroundColor = .clear
            }
            .navigationTitle(pack.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingAddItem = true
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                        
                        Button {
                            editedName = pack.name
                            showingEditName = true
                        } label: {
                            Label("Rename Pack", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView(pack: pack) { newItem in
                    var updatedPack = pack
                    updatedPack.items.append(newItem)
                    appState.updatePack(updatedPack)
                }
            }
            .alert("Rename Pack", isPresented: $showingEditName) {
                TextField("Pack Name", text: $editedName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    var updatedPack = pack
                    updatedPack.name = editedName.isEmpty ? pack.name : editedName
                    appState.updatePack(updatedPack)
                }
            }
            .alert("Duplicate Pack", isPresented: $showingDuplicateAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Duplicate") {
                    duplicatePack()
                }
            } message: {
                Text("Create a copy of '\(pack.name)' with all items?")
            }
        }
    }
    
    func updateItem(_ item: PackItem) {
        var updatedPack = pack
        if let index = updatedPack.items.firstIndex(where: { $0.id == item.id }) {
            updatedPack.items[index] = item
            appState.updatePack(updatedPack)
        }
    }
    
    func deleteItems(in category: ItemCategory, at offsets: IndexSet) {
        let categoryItems = groupedItems[category] ?? []
        let itemsToDelete = offsets.map { categoryItems[$0] }
        var updatedPack = pack
        updatedPack.items.removeAll { item in
            itemsToDelete.contains(where: { $0.id == item.id })
        }
        appState.updatePack(updatedPack)
    }
    
    func resetAllChecks() {
        var updatedPack = pack
        updatedPack.items = updatedPack.items.map { item in
            var newItem = item
            newItem.isChecked = false
            return newItem
        }
        appState.updatePack(updatedPack)
    }
    
    func checkAll() {
        var updatedPack = pack
        updatedPack.items = updatedPack.items.map { item in
            var newItem = item
            newItem.isChecked = true
            return newItem
        }
        appState.updatePack(updatedPack)
    }
    
    func duplicatePack() {
        let newItems = pack.items.map { item in
            PackItem(
                id: UUID(),
                name: item.name,
                category: item.category,
                quantity: item.quantity,
                priority: item.priority,
                notes: item.notes,
                isChecked: false
            )
        }
        
        let newPack = Pack(
            id: UUID(),
            name: "\(pack.name) (Copy)",
            type: pack.type,
            items: newItems
        )
        appState.addPack(newPack)
    }
}

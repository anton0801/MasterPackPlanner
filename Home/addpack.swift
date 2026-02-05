
import SwiftUI

// MARK: - Add Pack View
struct AddPackView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedType: PackType = .winter
    @State private var createTrip = false
    @State private var tripDate = Date()
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            NavigationView {
                Form {
                    Section("Pack Details") {
                        TextField("Pack Name", text: $name)
                        
                        Picker("Type", selection: $selectedType) {
                            ForEach(PackType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                    
                    Section {
                        Toggle("Create Trip", isOn: $createTrip)
                        
                        if createTrip {
                            DatePicker("Trip Date", selection: $tripDate, displayedComponents: .date)
                        }
                    } header: {
                        Text("Trip Planning")
                    } footer: {
                        if createTrip {
                            Text("A trip will be created with this pack")
                                .font(.caption)
                        }
                    }
                }
                .background(Color.clear)
                .onAppear {
                    UITableView.appearance().backgroundColor = .clear
                }
                .navigationTitle("New Pack")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            let newPack = Pack(name: name.isEmpty ? "New Pack" : name, type: selectedType)
                            appState.addPack(newPack)
                            
                            if createTrip {
                                // Копируем items из pack в trip (сбрасываем галочки)
                                let tripItems = newPack.items.map { item in
                                    var newItem = item
                                    newItem.isChecked = false
                                    return newItem
                                }
                                
                                let newTrip = Trip(
                                    packId: newPack.id,
                                    date: tripDate,
                                    items: tripItems
                                )
                                appState.addTrip(newTrip)
                            }
                            
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

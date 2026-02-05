
import SwiftUI

// MARK: - Add Trip View
struct AddTripView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedPack: Pack?
    @State private var tripDate = Date()
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            NavigationView {
                Form {
                    Section("Trip Details") {
                        Picker("Select Pack", selection: $selectedPack) {
                            Text("Choose a pack").tag(nil as Pack?)
                            ForEach(appState.packs) { pack in
                                Text(pack.name).tag(pack as Pack?)
                            }
                        }
                        
                        DatePicker("Trip Date", selection: $tripDate, displayedComponents: .date)
                    }
                }
                .background(Color.clear)
                .onAppear {
                    UITableView.appearance().backgroundColor = .clear
                }
                .navigationTitle("New Trip")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create") {
                            if let pack = selectedPack {
                                let newTrip = Trip(
                                    packId: pack.id,
                                    date: tripDate,
                                    items: pack.items.map { item in
                                        var newItem = item
                                        newItem.isChecked = false
                                        return newItem
                                    }
                                )
                                appState.addTrip(newTrip)
                                dismiss()
                            }
                        }
                        .disabled(selectedPack == nil)
                    }
                }
            }
        }
    }
}


import SwiftUI

// MARK: - Add Item View
struct AddItemView: View {
    let pack: Pack
    let onSave: (PackItem) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var category: ItemCategory = .other
    @State private var quantity = 1
    @State private var priority: Priority = .medium
    @State private var notes = ""
    @State private var scaleButton = false
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            NavigationView {
                Form {
                    Section("Item Details") {
                        TextField("Item Name", text: $name)
                        
                        Picker("Category", selection: $category) {
                            ForEach(ItemCategory.allCases, id: \.self) { cat in
                                HStack {
                                    Image(systemName: cat.icon)
                                    Text(cat.rawValue)
                                }
                                .tag(cat)
                            }
                        }
                        
                        Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(Priority.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                    }
                    
                    Section("Notes") {
                        TextEditor(text: $notes)
                            .frame(height: 80)
                    }
                }
                .background(Color.clear)
                .onAppear {
                    UITableView.appearance().backgroundColor = .clear
                }
                .navigationTitle("Add Item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            let newItem = PackItem(
                                name: name.isEmpty ? "New Item" : name,
                                category: category,
                                quantity: quantity,
                                priority: priority,
                                notes: notes
                            )
                            onSave(newItem)
                            dismiss()
                        }
                        .scaleEffect(scaleButton ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: scaleButton)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in scaleButton = true }
                                .onEnded { _ in scaleButton = false }
                        )
                    }
                }
            }
        }
    }
}

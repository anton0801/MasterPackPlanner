
import SwiftUI

struct ItemRow: View {
    let item: PackItem
    let onUpdate: (PackItem) -> Void
    @State private var isChecked: Bool
    @State private var showingNotes = false
    
    init(item: PackItem, onUpdate: @escaping (PackItem) -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        _isChecked = State(initialValue: item.isChecked)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isChecked.toggle()
                        var updatedItem = item
                        updatedItem.isChecked = isChecked
                        onUpdate(updatedItem)
                    }
                } label: {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isChecked ? .green : .gray)
                        .font(.title3)
                        .scaleEffect(isChecked ? 1.1 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .strikethrough(isChecked)
                        .foregroundColor(isChecked ? .secondary : .primary)
                    
                    HStack(spacing: 8) {
                        if item.quantity > 1 {
                            Text("\(item.quantity) pcs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !item.notes.isEmpty {
                            Button {
                                showingNotes = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "note.text")
                                    Text("Notes")
                                }
                                .font(.caption)
                                .foregroundColor(.cyan)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(item.priority.color)
                    .frame(width: 8, height: 8)
            }
            .opacity(isChecked ? 0.6 : 1.0)
        }
        .contentShape(Rectangle())
        .sheet(isPresented: $showingNotes) {
            ZStack {
                GradientBackground()
                
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(item.name)
                                .font(.system(size: 22, weight: .semibold))
                            
                            Text(item.notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .navigationTitle("Notes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingNotes = false
                            }
                        }
                    }
                }
            }
        }
    }
}

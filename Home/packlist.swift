
import SwiftUI

// MARK: - Packs List View
struct PacksListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddPack = false
    @State private var searchText = ""
    
    var filteredPacks: [Pack] {
        if searchText.isEmpty {
            return appState.packs
        }
        return appState.packs.filter { pack in
            pack.name.localizedCaseInsensitiveContains(searchText) ||
            pack.items.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            NavigationView {
                ZStack {
                    if appState.packs.isEmpty {
                        EmptyPacksView()
                    } else {
                        List {
                            ForEach(filteredPacks) { pack in
                                NavigationLink(destination: PackDetailView(packId: pack.id)) {
                                    PackCardRow(packId: pack.id)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { index in
                                    let packToDelete = filteredPacks[index]
                                    appState.deletePack(packToDelete)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .background(Color.clear)
                        .onAppear {
                            UITableView.appearance().backgroundColor = .clear
                        }
                        .searchable(text: $searchText, prompt: "Search packs or items")
                    }
                }
                .navigationTitle("My Packs")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddPack = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.cyan)
                        }
                    }
                }
                .sheet(isPresented: $showingAddPack) {
                    AddPackView()
                }
            }
        }
    }
}

struct PackCardRow: View {
    let packId: UUID
    @EnvironmentObject var appState: AppState
    
    var pack: Pack {
        appState.packs.first(where: { $0.id == packId }) ?? Pack(name: "Unknown", type: .custom)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(pack.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(pack.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(8)
            }
            
            HStack {
                Text("\(pack.completedCount) / \(pack.items.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(pack.progress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
            .frame(height: 6)
            .cornerRadius(3)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct EmptyPacksView: View {
    @State private var pulse = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Image(systemName: "bag")
                    .font(.system(size: 60, weight: .thin))
                    .foregroundColor(.gray)
                
                Image(systemName: "snowflake")
                    .font(.system(size: 30, weight: .thin))
                    .foregroundColor(.cyan)
                    .offset(x: 25, y: -25)
            }
            .scaleEffect(pulse ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
            
            Text("Create your first pack")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .onAppear {
            pulse = true
        }
    }
}

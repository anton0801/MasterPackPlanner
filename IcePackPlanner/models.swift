
import Foundation
import SwiftUI

// MARK: - Pack Model
struct Pack: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var type: PackType
    var items: [PackItem]
    
    var progress: Double {
        guard !items.isEmpty else { return 0 }
        let completed = items.filter { $0.isChecked }.count
        return Double(completed) / Double(items.count)
    }
    
    var completedCount: Int {
        items.filter { $0.isChecked }.count
    }
    
    init(id: UUID = UUID(), name: String, type: PackType, items: [PackItem] = []) {
        self.id = id
        self.name = name
        self.type = type
        self.items = items
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Pack, rhs: Pack) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Pack Type
enum PackType: String, Codable, CaseIterable {
    case winter = "Winter"
    case summer = "Summer"
    case custom = "Custom"
}

// MARK: - Pack Item
struct PackItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: ItemCategory
    var quantity: Int
    var priority: Priority
    var notes: String
    var isChecked: Bool
    
    init(id: UUID = UUID(), name: String, category: ItemCategory, quantity: Int = 1, priority: Priority = .medium, notes: String = "", isChecked: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.priority = priority
        self.notes = notes
        self.isChecked = isChecked
    }
}

// MARK: - Item Category
enum ItemCategory: String, Codable, CaseIterable {
    case clothing = "Clothing"
    case tackle = "Tackle"
    case tools = "Tools"
    case safety = "Safety"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .clothing: return "tshirt"
        case .tackle: return "bag"
        case .tools: return "wrench"
        case .safety: return "cross.case"
        case .other: return "square.grid.2x2"
        }
    }
}

// MARK: - Priority
enum Priority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Trip Model
struct Trip: Identifiable, Codable {
    let id: UUID
    var packId: UUID
    var date: Date
    var status: TripStatus
    var items: [PackItem]
    
    var progress: Double {
        guard !items.isEmpty else { return 0 }
        let completed = items.filter { $0.isChecked }.count
        return Double(completed) / Double(items.count)
    }
    
    init(id: UUID = UUID(), packId: UUID, date: Date, status: TripStatus = .planning, items: [PackItem]) {
        self.id = id
        self.packId = packId
        self.date = date
        self.status = status
        self.items = items
    }
}

// MARK: - Trip Status
enum TripStatus: String, Codable {
    case planning = "Planning"
    case ready = "Ready"
    case completed = "Completed"
    
    var color: Color {
        switch self {
        case .planning: return .blue
        case .ready: return .green
        case .completed: return .gray
        }
    }
}

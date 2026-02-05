
import Foundation
import SwiftUI
import Combine

// MARK: - App State
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var packs: [Pack]
    @Published var trips: [Trip]
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if let packsData = UserDefaults.standard.data(forKey: "packs"),
           let decodedPacks = try? JSONDecoder().decode([Pack].self, from: packsData) {
            self.packs = decodedPacks
        } else {
            self.packs = []
        }
        
        if let tripsData = UserDefaults.standard.data(forKey: "trips"),
           let decodedTrips = try? JSONDecoder().decode([Trip].self, from: tripsData) {
            self.trips = decodedTrips
        } else {
            self.trips = []
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func savePacks() {
        if let encoded = try? JSONEncoder().encode(packs) {
            UserDefaults.standard.set(encoded, forKey: "packs")
        }
    }
    
    func saveTrips() {
        if let encoded = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(encoded, forKey: "trips")
        }
    }
    
    func addPack(_ pack: Pack) {
        packs.append(pack)
        savePacks()
    }
    
    func updatePack(_ pack: Pack) {
        if let index = packs.firstIndex(where: { $0.id == pack.id }) {
            packs[index] = pack
            savePacks()
        }
    }
    
    func deletePack(_ pack: Pack) {
        packs.removeAll { $0.id == pack.id }
        savePacks()
    }
    
    func addTrip(_ trip: Trip) {
        trips.append(trip)
        saveTrips()
    }
    
    func updateTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
            saveTrips()
        }
    }
    
    var totalPacks: Int { packs.count }
    var avgReadiness: Double {
        guard !packs.isEmpty else { return 0 }
        return packs.map { $0.progress }.reduce(0, +) / Double(packs.count)
    }
    var tripsCount: Int { trips.count }
}

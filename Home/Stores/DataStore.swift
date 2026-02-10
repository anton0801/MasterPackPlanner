import SwiftUI
import Combine

@MainActor
final class DataStore: ObservableObject {
    
    @Published private(set) var marketing: MarketingRecord = .empty
    @Published private(set) var routing: RoutingRecord = .empty
    @Published private(set) var settings: SettingsRecord = .initial
    
    struct MarketingRecord {
        let info: [String: String]
        
        var hasData: Bool { !info.isEmpty }
        var isOrganic: Bool { info["af_status"] == "Organic" }
        
        static var empty: MarketingRecord {
            MarketingRecord(info: [:])
        }
    }
    
    struct RoutingRecord {
        let info: [String: String]
        
        var hasData: Bool { !info.isEmpty }
        
        static var empty: RoutingRecord {
            RoutingRecord(info: [:])
        }
    }
    
    struct SettingsRecord {
        var savedURL: String?
        var operationMode: String?
        var virginRun: Bool
        
        static var initial: SettingsRecord {
            SettingsRecord(savedURL: nil, operationMode: nil, virginRun: true)
        }
    }
    
    private weak var dispatcher: Dispatcher?
    private var dispatchToken: Int?
    
    init(dispatcher: Dispatcher) {
        self.dispatcher = dispatcher
        
        self.dispatchToken = dispatcher.register { [weak self] payload in
            self?.handlePayload(payload)
        }
    }
    
    private func handlePayload(_ payload: Payload) {
        switch payload.type {
        case .marketingDataArrived:
            let converted = convertToStringDict(payload.data)
            marketing = MarketingRecord(info: converted)
            
        case .routingDataArrived:
            let converted = convertToStringDict(payload.data)
            routing = RoutingRecord(info: converted)
            
        case .marketingFetchCompleted:
            let converted = convertToStringDict(payload.data)
            marketing = MarketingRecord(info: converted)
            
        case .urlFetchCompleted:
            if let url = payload.data["url"] as? String {
                settings = SettingsRecord(
                    savedURL: url,
                    operationMode: "Active",
                    virginRun: false
                )
            }
            
        default:
            break
        }
    }
    
    private func convertToStringDict(_ dict: [String: Any]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in dict {
            result[key] = "\(value)"
        }
        return result
    }
}

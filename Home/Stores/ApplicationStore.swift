import SwiftUI
import Combine

@MainActor
final class ApplicationStore: ObservableObject {
    
    @Published private(set) var cycle: Cycle = .beginning
    @Published private(set) var targetURL: String?
    @Published private(set) var locked: Bool = false
    
    enum Cycle {
        case beginning
        case warming
        case inspecting
        case inspected
        case executing
        case halted
        case disconnected
    }
    
    private weak var dispatcher: Dispatcher?
    private var dispatchToken: Int?
    
    init(dispatcher: Dispatcher) {
        self.dispatcher = dispatcher
        
        // Register with dispatcher
        self.dispatchToken = dispatcher.register { [weak self] payload in
            self?.handlePayload(payload)
        }
    }
    
    private func handlePayload(_ payload: Payload) {
        switch payload.type {
        case .appStarted:
            cycle = .warming
            
        case .appTimedOut:
            cycle = .halted
            
        case .validationRequested:
            cycle = .inspecting
            
        case .validationPassed:
            cycle = .inspected
            
        case .validationFailed:
            cycle = .halted
            
        case .urlFetchCompleted:
            if let url = payload.data["url"] as? String {
                targetURL = url
                cycle = .executing
                locked = true
            }
            
        case .urlFetchFailed:
            cycle = .halted
            
        case .networkOffline:
            if !locked {
                cycle = .disconnected
            }
            
        case .networkOnline:
            if cycle == .disconnected {
                cycle = .halted
            }
            
        default:
            break
        }
    }
}

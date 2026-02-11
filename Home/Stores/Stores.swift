import Foundation
import Combine

@MainActor
final class PermissionStore: ObservableObject {
    
    // UNIQUE: Published permissions
    @Published private(set) var notification: NotificationPermission = .initial
    
    struct NotificationPermission {
        var granted: Bool
        var declined: Bool
        var askedAt: Date?
        
        var shouldAsk: Bool {
            guard !granted && !declined else { return false }
            
            if let date = askedAt {
                let elapsed = Date().timeIntervalSince(date) / 86400
                return elapsed >= 3
            }
            return true
        }
        
        static var initial: NotificationPermission {
            NotificationPermission(granted: false, declined: false, askedAt: nil)
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
        case .notificationAllowed:
            notification = NotificationPermission(
                granted: true,
                declined: false,
                askedAt: Date()
            )
            
        case .notificationDeclined:
            notification = NotificationPermission(
                granted: false,
                declined: true,
                askedAt: Date()
            )
            
        case .notificationPostponed:
            notification = NotificationPermission(
                granted: false,
                declined: false,
                askedAt: Date()
            )
            
        default:
            break
        }
    }
}

@MainActor
final class UIStore: ObservableObject {
    
    // UNIQUE: Published UI state
    @Published var showNotificationModal: Bool = false
    @Published var showOfflineModal: Bool = false
    @Published var navigateToMain: Bool = false
    @Published var navigateToWeb: Bool = false
    
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
        case .notificationAsked:
            showNotificationModal = true
            
        case .notificationAllowed, .notificationDeclined:
            showNotificationModal = false
            navigateToWeb = true
            
        case .notificationPostponed:
            showNotificationModal = false
            navigateToWeb = true
            
        case .networkOffline:
            showOfflineModal = true
            
        case .networkOnline:
            showOfflineModal = false
            
        case .mainViewRequested:
            navigateToMain = true
            
        case .webViewRequested:
            navigateToWeb = true
            
        default:
            break
        }
    }
}

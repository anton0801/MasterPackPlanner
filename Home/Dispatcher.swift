import Foundation
import Combine

struct Payload {
    let type: PayloadType
    let data: [String: Any]
    
    enum PayloadType {
        case appStarted
        case appTimedOut
        case marketingDataArrived
        case routingDataArrived
        case networkOnline
        case networkOffline
        case validationRequested
        case validationPassed
        case validationFailed
        case marketingFetchRequested
        case marketingFetchCompleted
        case marketingFetchFailed
        case urlFetchRequested
        case urlFetchCompleted
        case urlFetchFailed
        case notificationAsked
        case notificationAllowed
        case notificationDeclined
        case notificationPostponed
        case mainViewRequested
        case webViewRequested
    }
    
    init(type: PayloadType, data: [String: Any] = [:]) {
        self.type = type
        self.data = data
    }
}

@MainActor
final class Dispatcher: ObservableObject {
    
    private var callbacks: [(Payload) -> Void] = []
    
    func register(callback: @escaping (Payload) -> Void) -> Int {
        callbacks.append(callback)
        return callbacks.count - 1
    }
    
    func dispatch(_ payload: Payload) {
        for callback in callbacks {
            callback(payload)
        }
    }
    
    func dispatchAction(_ type: Payload.PayloadType, data: [String: Any] = [:]) {
        dispatch(Payload(type: type, data: data))
    }
}

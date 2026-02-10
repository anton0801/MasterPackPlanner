import SwiftUI
import Combine

@MainActor
final class FluxContainer: ObservableObject {
    
    let dispatcher: Dispatcher
    var appStore: ApplicationStore
    var dataStore: DataStore
    var permStore: PermissionStore
    var uiStore: UIStore
    
    var actions: ActionCreator
    
    @Published var showNotificationModal: Bool = false
    @Published var showOfflineModal: Bool = false
    @Published var navigateToMain: Bool = false
    @Published var navigateToWeb: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Create dispatcher
        self.dispatcher = Dispatcher()
        
        // Create stores
        self.appStore = ApplicationStore(dispatcher: dispatcher)
        self.dataStore = DataStore(dispatcher: dispatcher)
        self.permStore = PermissionStore(dispatcher: dispatcher)
        self.uiStore = UIStore(dispatcher: dispatcher)
        
        // Create action creator
        let dataLayer = DataLayer()
        self.actions = ActionCreator(dispatcher: dispatcher, dataLayer: dataLayer)
        
        // Load saved data
        let loaded = dataLayer.loadAll()
        
        // Dispatch loaded config
        if !loaded.marketing.isEmpty {
            let anyDict = convertToAnyDict(loaded.marketing)
            dispatcher.dispatchAction(.marketingDataArrived, data: anyDict)
        }
        
        if !loaded.routing.isEmpty {
            let anyDict = convertToAnyDict(loaded.routing)
            dispatcher.dispatchAction(.routingDataArrived, data: anyDict)
        }
        
        setupUIStoreBinding()
    }
    
    private func setupUIStoreBinding() {
        uiStore.objectWillChange.sink { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.showNotificationModal = self.uiStore.showNotificationModal
                self.showOfflineModal = self.uiStore.showOfflineModal
                self.navigateToMain = self.uiStore.navigateToMain
                self.navigateToWeb = self.uiStore.navigateToWeb
            }
        }
        .store(in: &cancellables)
    }
    
    private func convertToAnyDict(_ dict: [String: String]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key] = value
        }
        return result
    }
}

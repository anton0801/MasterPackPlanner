import Foundation
import UIKit
import UserNotifications
import Network
import AppsFlyerLib

@MainActor
final class ActionCreator {
    
    private let dispatcher: Dispatcher
    private let dataLayer: DataLayer
    
    private var timeoutTask: Task<Void, Never>?
    private let networkMonitor = NWPathMonitor()
    
    init(dispatcher: Dispatcher, dataLayer: DataLayer) {
        self.dispatcher = dispatcher
        self.dataLayer = dataLayer
        
        setupNetworkMonitoring()
    }
    
    func startApp() {
        dispatcher.dispatchAction(.appStarted)
        scheduleTimeout()
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            await MainActor.run {
                self.dispatcher.dispatchAction(.appTimedOut)
                self.dispatcher.dispatchAction(.mainViewRequested)
            }
        }
    }
    
    // MARK: - Data Arrival
    
    func receiveMarketing(_ data: [String: Any]) {
        dispatcher.dispatchAction(.marketingDataArrived, data: data)
        dataLayer.saveMarketing(data)
        
        Task {
            await performValidation()
        }
    }
    
    func receiveRouting(_ data: [String: Any]) {
        dispatcher.dispatchAction(.routingDataArrived, data: data)
        dataLayer.saveRouting(data)
    }
    
    // MARK: - Validation
    
    private func performValidation() async {
        dispatcher.dispatchAction(.validationRequested)
        
        do {
            let isValid = try await dataLayer.checkValidity()
            
            if isValid {
                dispatcher.dispatchAction(.validationPassed)
                await executeFlow()
            } else {
                dispatcher.dispatchAction(.validationFailed)
                dispatcher.dispatchAction(.mainViewRequested)
            }
        } catch {
            dispatcher.dispatchAction(.validationFailed)
            dispatcher.dispatchAction(.mainViewRequested)
        }
    }
    
    // MARK: - Flow Execution
    
    private func executeFlow() async {
        let loaded = dataLayer.loadAll()
        
        // Check if we have marketing data
        guard !loaded.marketing.isEmpty else {
            if let savedURL = loaded.settings.savedURL {
                completeFlow(url: savedURL, shouldAskPermission: loaded.permission.shouldAsk)
            } else {
                dispatcher.dispatchAction(.mainViewRequested)
            }
            return
        }
        
        // Check for temp URL
        if let temp = UserDefaults.standard.string(forKey: "temp_url") {
            completeFlow(url: temp, shouldAskPermission: loaded.permission.shouldAsk)
            return
        }
        
        // Check if should run organic flow
        if loaded.settings.virginRun && loaded.marketing["af_status"] == "Organic" {
            await runOrganicFlow(loaded: loaded)
            return
        }
        
        // Fetch URL
        await fetchURL(marketing: loaded.marketing, loaded: loaded)
    }
    
    private func runOrganicFlow(loaded: DataLayer.LoadedData) async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        dispatcher.dispatchAction(.marketingFetchRequested)
        
        do {
            let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
            let fetched = try await dataLayer.pullMarketing(deviceID: deviceID)
            
            var merged = fetched
            for (key, value) in loaded.routing {
                if merged[key] == nil {
                    merged[key] = value
                }
            }
            
            dispatcher.dispatchAction(.marketingFetchCompleted, data: merged)
            dataLayer.saveMarketing(merged)
            
            await fetchURL(marketing: convertToStringDict(merged), loaded: loaded)
        } catch {
            dispatcher.dispatchAction(.marketingFetchFailed)
            dispatcher.dispatchAction(.mainViewRequested)
        }
    }
    
    private func fetchURL(marketing: [String: String], loaded: DataLayer.LoadedData) async {
        dispatcher.dispatchAction(.urlFetchRequested)
        
        do {
            let url = try await dataLayer.pullURL(marketing: convertToAnyDict(marketing))
            
            dataLayer.saveURL(url)
            dataLayer.saveMode("Active")
            dataLayer.markVirginDone()
            
            dispatcher.dispatchAction(.urlFetchCompleted, data: ["url": url])
            
            completeFlow(url: url, shouldAskPermission: loaded.permission.shouldAsk)
        } catch {
            dispatcher.dispatchAction(.urlFetchFailed)
            
            if let savedURL = loaded.settings.savedURL {
                completeFlow(url: savedURL, shouldAskPermission: loaded.permission.shouldAsk)
            } else {
                dispatcher.dispatchAction(.mainViewRequested)
            }
        }
    }
    
    private func completeFlow(url: String, shouldAskPermission: Bool) {
        timeoutTask?.cancel()
        
        if shouldAskPermission {
            dispatcher.dispatchAction(.notificationAsked)
        } else {
            dispatcher.dispatchAction(.webViewRequested)
        }
    }
    
    // MARK: - Notifications
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if granted {
                    self.dataLayer.savePermission(granted: true, declined: false)
                    self.dispatcher.dispatchAction(.notificationAllowed)
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    self.dataLayer.savePermission(granted: false, declined: true)
                    self.dispatcher.dispatchAction(.notificationDeclined)
                }
            }
        }
    }
    
    func postponeNotificationPermission() {
        dataLayer.savePermission(granted: false, declined: false)
        dispatcher.dispatchAction(.notificationPostponed)
    }
    
    // MARK: - Network
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                if path.status == .satisfied {
                    self?.dispatcher.dispatchAction(.networkOnline)
                } else {
                    self?.dispatcher.dispatchAction(.networkOffline)
                }
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    // MARK: - Helpers
    
    private func convertToStringDict(_ dict: [String: Any]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in dict {
            result[key] = "\(value)"
        }
        return result
    }
    
    private func convertToAnyDict(_ dict: [String: String]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key] = value
        }
        return result
    }
}

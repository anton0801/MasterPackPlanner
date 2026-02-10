import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    private let marketingFlow = MarketingFlow()
    private let pushFlow = PushFlow()
    private var trackingFlow: TrackingFlow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        marketingFlow.onMarketing = { [weak self] in self?.emitMarketing($0) }
        marketingFlow.onRouting = { [weak self] in self?.emitRouting($0) }
        trackingFlow = TrackingFlow(flow: marketingFlow)
        
        setupFirebase()
        setupMessaging()
        setupTracking()
        
        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushFlow.handle(notification: notification)
        }
        
        observeApp()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
    }
    
    private func setupMessaging() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func setupTracking() {
        trackingFlow?.setup()
    }
    
    private func observeApp() {
        NotificationCenter.default.addObserver(self, selector: #selector(appActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appActive() {
        trackingFlow?.launch()
    }
    
    private func emitMarketing(_ data: [AnyHashable: Any]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: Notification.Name("ConversionDataReceived"), object: nil, userInfo: ["conversionData": data])
        }
    }
    
    private func emitRouting(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: Notification.Name("deeplink_values"), object: nil, userInfo: ["deeplinksData": data])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, error in
            guard error == nil, let token = token else { return }
            UserDefaults.standard.set(token, forKey: "fcm_token")
            UserDefaults.standard.set(token, forKey: "push_token")
            UserDefaults(suiteName: "group.pack.data")?.set(token, forKey: "shared_token")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "fcm_ts")
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        pushFlow.handle(notification: userInfo)
        completionHandler(.newData)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        pushFlow.handle(notification: notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        pushFlow.handle(notification: response.notification.request.content.userInfo)
        completionHandler()
    }
}

class PushFlow: NSObject {
    func handle(notification: [AnyHashable: Any]) {
        guard let url = extractURL(from: notification) else { return }
        UserDefaults.standard.set(url, forKey: "temp_url")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "temp_url_ts")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: Notification.Name("LoadTempURL"), object: nil, userInfo: ["temp_url": url])
        }
    }
    
    private func extractURL(from payload: [AnyHashable: Any]) -> String? {
        if let url = payload["url"] as? String { return url }
        if let data = payload["data"] as? [String: Any], let url = data["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any], let data = aps["data"] as? [String: Any], let url = data["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any], let url = custom["url"] as? String { return url }
        return nil
    }
}

struct AppSettings {
    static let appID = "6758788244"
    static let devKey = "jRGiLbsJu5obLNzXPtAbBJ"
}

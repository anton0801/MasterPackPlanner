import Foundation
import FirebaseDatabase
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

final class DataLayer {
    
    private let disk = UserDefaults(suiteName: "group.pack.data")!
    private let backup = UserDefaults.standard
    private var quickCache: [String: Any] = [:]
    
    // UNIQUE: mp_ prefix
    private enum Keys {
        static let marketing = "mp_marketing_data"
        static let routing = "mp_routing_data"
        static let url = "mp_target_url"
        static let mode = "mp_mode_state"
        static let virgin = "mp_virgin_run"
        static let permGranted = "mp_perm_granted"
        static let permDeclined = "mp_perm_declined"
        static let permDate = "mp_perm_date"
    }
    
    struct LoadedData {
        var marketing: [String: String]
        var routing: [String: String]
        var settings: Settings
        var permission: Permission
        
        struct Settings {
            var savedURL: String?
            var operationMode: String?
            var virginRun: Bool
        }
        
        struct Permission {
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
        }
    }
    
    init() {
        warmCache()
    }
    
    // MARK: - Save
    
    func saveMarketing(_ data: [String: Any]) {
        if let json = toJSON(data) {
            disk.set(json, forKey: Keys.marketing)
            quickCache[Keys.marketing] = json
        }
    }
    
    func saveRouting(_ data: [String: Any]) {
        if let json = toJSON(data) {
            let encoded = encodeString(json)
            disk.set(encoded, forKey: Keys.routing)
        }
    }
    
    func saveURL(_ url: String) {
        disk.set(url, forKey: Keys.url)
        backup.set(url, forKey: Keys.url)
        quickCache[Keys.url] = url
    }
    
    func saveMode(_ mode: String) {
        disk.set(mode, forKey: Keys.mode)
    }
    
    func markVirginDone() {
        disk.set(true, forKey: Keys.virgin)
    }
    
    func savePermission(granted: Bool, declined: Bool) {
        disk.set(granted, forKey: Keys.permGranted)
        disk.set(declined, forKey: Keys.permDeclined)
        disk.set(Date().timeIntervalSince1970 * 1000, forKey: Keys.permDate)
    }
    
    // MARK: - Load
    
    func loadAll() -> LoadedData {
        var marketing: [String: String] = [:]
        if let json = quickCache[Keys.marketing] as? String ?? disk.string(forKey: Keys.marketing),
           let data = fromJSON(json) {
            marketing = convertToStringDict(data)
        }
        
        var routing: [String: String] = [:]
        if let encoded = disk.string(forKey: Keys.routing),
           let json = decodeString(encoded),
           let data = fromJSON(json) {
            routing = convertToStringDict(data)
        }
        
        let url = quickCache[Keys.url] as? String 
               ?? disk.string(forKey: Keys.url) 
               ?? backup.string(forKey: Keys.url)
        
        let mode = disk.string(forKey: Keys.mode)
        let virginRun = !disk.bool(forKey: Keys.virgin)
        
        let granted = disk.bool(forKey: Keys.permGranted)
        let declined = disk.bool(forKey: Keys.permDeclined)
        let ts = disk.double(forKey: Keys.permDate)
        let askedAt = ts > 0 ? Date(timeIntervalSince1970: ts / 1000) : nil
        
        return LoadedData(
            marketing: marketing,
            routing: routing,
            settings: LoadedData.Settings(
                savedURL: url,
                operationMode: mode,
                virginRun: virginRun
            ),
            permission: LoadedData.Permission(
                granted: granted,
                declined: declined,
                askedAt: askedAt
            )
        )
    }
    
    // MARK: - Network
    
    func checkValidity() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            Database.database().reference().child("users/log/data")
                .observeSingleEvent(of: .value) { snapshot in
                    if let url = snapshot.value as? String,
                       !url.isEmpty,
                       URL(string: url) != nil {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    private let httpClient: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }()
    
    func pullMarketing(deviceID: String) async throws -> [String: Any] {
        let base = "https://gcdsdk.appsflyer.com/install_data/v4.0"
        let app = "id\(AppSettings.appID)"
        
        var builder = URLComponents(string: "\(base)/\(app)")
        builder?.queryItems = [
            URLQueryItem(name: "devkey", value: AppSettings.devKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = builder?.url else {
            throw DataError.badURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await httpClient.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DataError.requestFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DataError.parseFailed
        }
        
        return json
    }
    
    private var userAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func pullURL(marketing: [String: Any]) async throws -> String {
        guard let url = URL(string: "https://masterpackplanner.com/config.php") else {
            throw DataError.badURL
        }
        
        var payload: [String: Any] = marketing
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(AppSettings.appID)"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        var lastError: Error?
        let retries: [Double] = [6.0, 12.0, 24.0]
        
        for (index, delay) in retries.enumerated() {
            do {
                let (data, response) = try await httpClient.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw DataError.requestFailed
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let success = json["ok"] as? Bool,
                          success,
                          let endpoint = json["url"] as? String else {
                        throw DataError.parseFailed
                    }
                    
                    return endpoint
                } else if httpResponse.statusCode == 429 {
                    let backoff = delay * Double(index + 1)
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    continue
                } else {
                    throw DataError.requestFailed
                }
            } catch {
                lastError = error
                if index < retries.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? DataError.requestFailed
    }
    
    // MARK: - Helpers
    
    private func warmCache() {
        if let url = disk.string(forKey: Keys.url) {
            quickCache[Keys.url] = url
        }
    }
    
    private func toJSON(_ data: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let string = String(data: jsonData, encoding: .utf8) else { return nil }
        return string
    }
    
    private func fromJSON(_ string: String) -> [String: Any]? {
        guard let data = string.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return dict
    }
    
    private func encodeString(_ string: String) -> String {
        Data(string.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "<")
            .replacingOccurrences(of: "+", with: ">")
    }
    
    private func decodeString(_ string: String) -> String? {
        let base64 = string
            .replacingOccurrences(of: "<", with: "=")
            .replacingOccurrences(of: ">", with: "+")
        
        guard let data = Data(base64Encoded: base64),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
    
    private func convertToStringDict(_ dict: [String: Any]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in dict {
            result[key] = "\(value)"
        }
        return result
    }
}

enum DataError: Error {
    case badURL
    case requestFailed
    case parseFailed
}


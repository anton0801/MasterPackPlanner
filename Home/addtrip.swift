
import SwiftUI
import WebKit

// MARK: - Add Trip View
struct AddTripView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedPack: Pack?
    @State private var tripDate = Date()
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            NavigationView {
                Form {
                    Section("Trip Details") {
                        Picker("Select Pack", selection: $selectedPack) {
                            Text("Choose a pack").tag(nil as Pack?)
                            ForEach(appState.packs) { pack in
                                Text(pack.name).tag(pack as Pack?)
                            }
                        }
                        
                        DatePicker("Trip Date", selection: $tripDate, displayedComponents: .date)
                    }
                }
                .background(Color.clear)
                .onAppear {
                    UITableView.appearance().backgroundColor = .clear
                }
                .navigationTitle("New Trip")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create") {
                            if let pack = selectedPack {
                                let newTrip = Trip(
                                    packId: pack.id,
                                    date: tripDate,
                                    items: pack.items.map { item in
                                        var newItem = item
                                        newItem.isChecked = false
                                        return newItem
                                    }
                                )
                                appState.addTrip(newTrip)
                                dismiss()
                            }
                        }
                        .disabled(selectedPack == nil)
                    }
                }
            }
        }
    }
}

extension WebHandler: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        previousURL = url
        if isAllowed(url) {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    private func isAllowed(_ url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let schemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let special = ["srcdoc", "about:blank", "about:srcdoc"]
        return schemes.contains(scheme) || special.contains { path.hasPrefix($0) } || path == "about:blank"
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        bounces += 1
        if bounces > bounceLimit {
            webView.stopLoading()
            if let recovery = previousURL { webView.load(URLRequest(url: recovery)) }
            bounces = 0
            return
        }
        previousURL = webView.url
        saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url {
            safeURL = current
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { safeURL = current }
        bounces = 0
        saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let code = (error as NSError).code
        if code == NSURLErrorHTTPTooManyRedirects, let recovery = previousURL {
            webView.load(URLRequest(url: recovery))
        }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

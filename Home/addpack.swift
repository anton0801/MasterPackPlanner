
import SwiftUI
import WebKit

// MARK: - Add Pack View
struct AddPackView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedType: PackType = .winter
    @State private var createTrip = false
    @State private var tripDate = Date()
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            NavigationView {
                Form {
                    Section("Pack Details") {
                        TextField("Pack Name", text: $name)
                        
                        Picker("Type", selection: $selectedType) {
                            ForEach(PackType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                    
                    Section {
                        Toggle("Create Trip", isOn: $createTrip)
                        
                        if createTrip {
                            DatePicker("Trip Date", selection: $tripDate, displayedComponents: .date)
                        }
                    } header: {
                        Text("Trip Planning")
                    } footer: {
                        if createTrip {
                            Text("A trip will be created with this pack")
                                .font(.caption)
                        }
                    }
                }
                .background(Color.clear)
                .onAppear {
                    UITableView.appearance().backgroundColor = .clear
                }
                .navigationTitle("New Pack")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            let newPack = Pack(name: name.isEmpty ? "New Pack" : name, type: selectedType)
                            appState.addPack(newPack)
                            
                            if createTrip {
                                // Копируем items из pack в trip (сбрасываем галочки)
                                let tripItems = newPack.items.map { item in
                                    var newItem = item
                                    newItem.isChecked = false
                                    return newItem
                                }
                                
                                let newTrip = Trip(
                                    packId: newPack.id,
                                    date: tripDate,
                                    items: tripItems
                                )
                                appState.addTrip(newTrip)
                            }
                            
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    
    func makeCoordinator() -> WebHandler { WebHandler() }
    
    func makeUIView(context: Context) -> WKWebView {
        let view = createWebView(handler: context.coordinator)
        context.coordinator.view = view
        context.coordinator.open(url, in: view)
        Task { await context.coordinator.loadCookies(in: view) }
        return view
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func createWebView(handler: WebHandler) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs
        
        let controller = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const m = document.createElement('meta');
                m.name = 'viewport';
                m.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(m);
                const s = document.createElement('style');
                s.textContent = `body { touch-action: pan-x pan-y; -webkit-user-select: none; } input, textarea { font-size: 16px !important; }`;
                document.head.appendChild(s);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        controller.addUserScript(script)
        config.userContentController = controller
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        
        let view = WKWebView(frame: .zero, configuration: config)
        view.scrollView.minimumZoomScale = 1.0
        view.scrollView.maximumZoomScale = 1.0
        view.scrollView.bounces = false
        view.scrollView.bouncesZoom = false
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.navigationDelegate = handler
        view.uiDelegate = handler
        return view
    }
}


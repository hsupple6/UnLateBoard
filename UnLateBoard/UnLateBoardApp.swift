import SwiftUI
import GoogleMaps

@main
struct UnLateBoardApp: App {
    // MARK: - App State Management
    @StateObject private var appState = AppStateManager()
    @StateObject private var navigationState = NavigationStateManager()
    @StateObject private var motorManager = MotorManagement()
    @StateObject private var connectionManager = ConnectionManager(
        host: AppConfig.Network.defaultHost,
        port: AppConfig.Network.defaultPort
    )
    @StateObject private var mlProcessor = MLProcessor()
    
    init() {
        // Configure Google Maps
        GMSServices.provideAPIKey(AppConfig.Maps.apiKey)
        
        // Configure app appearance
        configureAppearance()
        
        Logger.shared.info("UnLateBoard app initialized - Version \(AppConfig.Settings.appVersion)")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(navigationState)
                .environmentObject(motorManager)
                .environmentObject(connectionManager)
                .environmentObject(mlProcessor)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    appState.handleAppDidBecomeActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    appState.handleAppWillResignActive()
                }
        }
    }
    
    // MARK: - Private Methods
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppConfig.UI.Colors.background)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(AppConfig.UI.Colors.text)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppConfig.UI.Colors.text)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        Logger.shared.debug("App appearance configured")
    }
    
    private func setupApp() {
        Logger.shared.info("Setting up UnLateBoard app...")
        
        // Connect managers
        motorManager.connectToManager(connectionManager)
        motorManager.connectToMLProcessor(mlProcessor)
        mlProcessor.connectToManager(connectionManager)
        
        // Initialize app state
        appState.initializeApp()
        
        Logger.shared.info("App setup completed")
    }
}

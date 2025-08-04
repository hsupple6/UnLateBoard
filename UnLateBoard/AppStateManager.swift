import SwiftUI
import Foundation

// MARK: - App State Manager
class AppStateManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isInitialized = false
    @Published var currentScreen: AppScreen = .intro
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isUserLoggedIn = false
    
    // MARK: - App Screens
    enum AppScreen {
        case intro
        case login
        case signup
        case main
        case control
        case ml
        case settings
        case aiDebug
    }
    
    // MARK: - Error Types
    enum AppError: LocalizedError {
        case initializationFailed
        case connectionFailed
        case authenticationFailed
        case mlModelLoadFailed
        
        var errorDescription: String? {
            switch self {
            case .initializationFailed:
                return "Failed to initialize app"
            case .connectionFailed:
                return "Failed to connect to device"
            case .authenticationFailed:
                return "Authentication failed"
            case .mlModelLoadFailed:
                return "Failed to load ML model"
            }
        }
    }
    
    // MARK: - Initialization
    func initializeApp() {
        isLoading = true
        Logger.shared.info("Initializing app...")
        
        // Check if user is logged in
        checkUserLoginStatus()
        
        // Initialize app components
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.UI.loadingDelay) {
            self.isInitialized = true
            self.isLoading = false
            
            // Navigate to appropriate screen
            if self.isUserLoggedIn {
                self.currentScreen = .main
                Logger.shared.info("User logged in, navigating to main screen")
            } else {
                self.currentScreen = .intro
                Logger.shared.info("User not logged in, navigating to intro screen")
            }
        }
    }
    
    // MARK: - Navigation
    func navigateTo(_ screen: AppScreen) {
        Logger.shared.debug("Navigating to screen: \(screen)")
        withAnimation(.easeInOut(duration: AppConfig.UI.animationDuration)) {
            currentScreen = screen
        }
    }
    
    func goBack() {
        switch currentScreen {
        case .main:
            currentScreen = .intro
        case .control, .ml, .settings:
            currentScreen = .main
        case .login, .signup:
            currentScreen = .intro
        default:
            break
        }
        Logger.shared.debug("Navigating back from: \(currentScreen)")
    }
    
    // MARK: - Error Handling
    func showError(_ error: AppError) {
        errorMessage = error.localizedDescription
        Logger.shared.error("App error: \(error.localizedDescription)")
        
        // Auto-clear error after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.UI.errorDisplayDuration) {
            self.clearError()
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - User Management
    private func checkUserLoginStatus() {
        isUserLoggedIn = UserDefaults.standard.bool(forKey: "isUserLoggedIn")
        Logger.shared.debug("User login status: \(isUserLoggedIn)")
    }
    
    func loginUser() {
        isUserLoggedIn = true
        UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
        Logger.shared.info("User logged in successfully")
        navigateTo(.main)
    }
    
    func logoutUser() {
        isUserLoggedIn = false
        UserDefaults.standard.set(false, forKey: "isUserLoggedIn")
        Logger.shared.info("User logged out")
        navigateTo(.intro)
    }
    
    // MARK: - App Lifecycle
    func handleAppDidBecomeActive() {
        Logger.shared.info("App became active")
        // Refresh connections and state when app becomes active
    }
    
    func handleAppWillResignActive() {
        Logger.shared.info("App will resign active")
        // Clean up resources when app goes to background
    }
} 
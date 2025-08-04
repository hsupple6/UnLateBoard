import SwiftUI

// MARK: - App Configuration
struct AppConfig {
    // MARK: - Network Configuration
    struct Network {
        static let defaultHost = "192.168.4.1"
        static let defaultPort: UInt16 = 3333
        static let connectionTimeout: TimeInterval = 10.0
        static let reconnectInterval: TimeInterval = 3.0
        static let maxReconnectAttempts = 5
        static let heartbeatInterval: TimeInterval = 2.0
        static let statusPollingInterval: TimeInterval = 5.0
    }
    
    // MARK: - ML Configuration
    struct ML {
        static let modelInputSize = CGSize(width: 416, height: 416)
        static let confidenceThreshold: Float = 0.3
        static let maxFrameSize = 2_000_000
        static let frameHeaderSize = 16
        static let expectedMagic: UInt32 = 0xDEADBEEF
        static let maxFrameRate: Double = 60.0
        static let frameInterval: TimeInterval = 1.0 / maxFrameRate
    }
    
    // MARK: - Motor Configuration
    struct Motor {
        static let defaultMaxSpeed: Double = 25.0 // m/s
        static let defaultMaxAcceleration: Double = 10.0 // m/s²
        static let minSpeedThreshold: Double = 0.1 // m/s
        static let speedUpdateThreshold: Double = 0.1 // m/s
        static let maxSpeedHistorySize = 10
        static let accelerationCalculationWindow: TimeInterval = 1.0
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let animationDuration: Double = 0.3
        static let loadingDelay: TimeInterval = 0.5
        static let errorDisplayDuration: TimeInterval = 3.0
        static let buttonPressDelay: TimeInterval = 0.1
        
        struct Colors {
            static let primary = Color.blue
            static let secondary = Color.green
            static let accent = Color.orange
            static let danger = Color.red
            static let warning = Color.yellow
            static let background = Color.black
            static let surface = Color.gray.opacity(0.2)
            static let text = Color.white
            static let textSecondary = Color.gray
        }
        
        struct Fonts {
            static let title = Font.largeTitle
            static let headline = Font.headline
            static let body = Font.body
            static let caption = Font.caption
        }
        
        struct Spacing {
            static let small: CGFloat = 8
            static let medium: CGFloat = 16
            static let large: CGFloat = 24
            static let extraLarge: CGFloat = 32
        }
        
        struct CornerRadius {
            static let small: CGFloat = 8
            static let medium: CGFloat = 12
            static let large: CGFloat = 16
            static let extraLarge: CGFloat = 20
        }
    }
    
    // MARK: - App Settings
    struct Settings {
        static let appName = "UnLateBoard"
        static let appVersion = "1.0.0"
        static let buildNumber = "1"
        static let supportEmail = "support@unlateboard.com"
        static let privacyPolicyURL = "https://unlateboard.com/privacy"
        static let termsOfServiceURL = "https://unlateboard.com/terms"
    }
    
    // MARK: - Google Maps Configuration
    struct Maps {
        static let apiKey = "AIzaSyA1FLqbSOzAkxXpy1PxN0205kcQeicBTbY"
        static let defaultZoomLevel: Float = 15.0
        static let maxZoomLevel: Float = 20.0
        static let minZoomLevel: Float = 10.0
    }
    
    // MARK: - File Management
    struct Files {
        static let loginFileName = "Login.txt"
        static let settingsFileName = "Settings.plist"
        static let tripDataFileName = "TripData.json"
        static let logsFileName = "AppLogs.txt"
    }
    
    // MARK: - Validation
    struct Validation {
        static let minPasswordLength = 6
        static let maxPasswordLength = 50
        static let minEmailLength = 5
        static let maxEmailLength = 100
        static let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    }
    
    // MARK: - Performance
    struct Performance {
        static let maxLogEntries = 1000
        static let logRetentionDays = 7
        static let maxCachedImages = 10
        static let imageCacheTimeout: TimeInterval = 300 // 5 minutes
    }
    
    // MARK: - Safety
    struct Safety {
        static let maxEmergencyStopDuration: TimeInterval = 2.0
        static let minBrakeIntensity: Double = 0.1
        static let maxBrakeIntensity: Double = 2.0
        static let speedLimitWarningThreshold: Double = 0.9 // 90% of max speed
    }
}

// MARK: - Environment Configuration
enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    var isDebug: Bool {
        return self == .development
    }
    
    var logLevel: LogLevel {
        switch self {
        case .development:
            return .debug
        case .staging:
            return .info
        case .production:
            return .error
        }
    }
}

// MARK: - Logging
enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case fatal = "FATAL"
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fatal: return "💀"
        }
    }
}

// MARK: - Logger
class Logger {
    static let shared = Logger()
    
    private init() {}
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard level.rawValue >= AppEnvironment.current.logLevel.rawValue else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "\(timestamp) \(level.emoji) [\(fileName):\(line)] \(function): \(message)"
        
        print(logMessage)
        
        // In production, you might want to send logs to a service
        if AppEnvironment.current == .production {
            // Send to crash reporting service
        }
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    func fatal(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .fatal, file: file, function: function, line: line)
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Error Types
enum AppError: LocalizedError {
    case networkError(String)
    case mlError(String)
    case motorError(String)
    case configurationError(String)
    case validationError(String)
    case fileError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .mlError(let message):
            return "ML Error: \(message)"
        case .motorError(let message):
            return "Motor Error: \(message)"
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .fileError(let message):
            return "File Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .mlError:
            return "Please restart the ML service and try again."
        case .motorError:
            return "Please check the motor connection and try again."
        case .configurationError:
            return "Please check the app configuration and try again."
        case .validationError:
            return "Please check your input and try again."
        case .fileError:
            return "Please check file permissions and try again."
        case .unknownError:
            return "Please restart the app and try again."
        }
    }
} 
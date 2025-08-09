import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var navigationState: NavigationStateManager
    @EnvironmentObject var motorManager: MotorManagement
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var mlProcessor: MLProcessor
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Main content based on app state
            Group {
                switch appState.currentScreen {
                case .intro:
                    IntroView()
                        .environmentObject(appState)
                        .environmentObject(navigationState)
                        .environmentObject(motorManager)
                        .environmentObject(connectionManager)
                        .environmentObject(mlProcessor)
                    
                case .login:
                    LoginView()
                        .environmentObject(appState)
                        .environmentObject(navigationState)
                        .environmentObject(motorManager)
                        .environmentObject(connectionManager)
                        .environmentObject(mlProcessor)
                    
                case .signup:
                    SignUpView()
                        .environmentObject(appState)
                        .environmentObject(navigationState)
                        .environmentObject(motorManager)
                        .environmentObject(connectionManager)
                        .environmentObject(mlProcessor)
                    
                case .main:
                    MainView()
                        .environmentObject(appState)
                        .environmentObject(navigationState)
                        .environmentObject(motorManager)
                        .environmentObject(connectionManager)
                        .environmentObject(mlProcessor)
                    
                case .control:
                    ControlView(ConnectionManager: connectionManager, dir: .constant(true))
                        .environmentObject(appState)
                        .environmentObject(navigationState)
                        .environmentObject(motorManager)
                        .environmentObject(connectionManager)
                        .environmentObject(mlProcessor)
                    
                case .ml:
                    MLView()
                        .environmentObject(appState)
                        .environmentObject(navigationState)
                        .environmentObject(motorManager)
                        .environmentObject(connectionManager)
                        .environmentObject(mlProcessor)
                    
                case .settings:
                    SettingsView()
                        .environmentObject(appState)
                        .environmentObject(navigationState)
                        .environmentObject(motorManager)
                        .environmentObject(connectionManager)
                        .environmentObject(mlProcessor)
                    
                case .aiDebug:
                    AIDebugView()
                        .environmentObject(appState)
                        .environmentObject(navigationState)
                        .environmentObject(motorManager)
                        .environmentObject(connectionManager)
                        .environmentObject(mlProcessor)
                }
            }
            .transition(.opacity.combined(with: .scale))
            
            // Loading overlay
            if appState.isLoading {
                LoadingView()
            }
            
            // Error overlay
            if let errorMessage = appState.errorMessage {
                ErrorView(message: errorMessage) {
                    appState.clearError()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Loading...")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Dismiss") {
                    onDismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(Color.red)
                .cornerRadius(10)
            }
            .padding(30)
            .background(Color.gray.opacity(0.9))
            .cornerRadius(20)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Main View
struct MainView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var connectionManager: ConnectionManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Text("UnLateBoard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Smart Electric Skateboard")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                    
                    // Connection Status
                    ConnectionStatusView()
                        .environmentObject(connectionManager)
                    
                    Spacer()
                    
                    // Main Menu
                    VStack(spacing: 20) {
                        NavigationButton(
                            title: "Control Panel",
                            subtitle: "Control your board",
                            icon: "gamecontroller.fill",
                            color: .blue
                        ) {
                            appState.navigateTo(.control)
                        }
                        
                        NavigationButton(
                            title: "ML Vision",
                            subtitle: "Object detection",
                            icon: "eye.fill",
                            color: .green
                        ) {
                            appState.navigateTo(.ml)
                        }
                        
                        NavigationButton(
                            title: "AI Debug Console",
                            subtitle: "Monitor AI decisions",
                            icon: "brain.head.profile",
                            color: .purple
                        ) {
                            appState.navigateTo(.aiDebug)
                        }
                        
                        NavigationButton(
                            title: "Settings",
                            subtitle: "App configuration",
                            icon: "gear",
                            color: .orange
                        ) {
                            appState.navigateTo(.settings)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Logout Button
                    Button("Logout") {
                        appState.logoutUser()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.red)
                    .cornerRadius(10)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Navigation Button
struct NavigationButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Connection Status View
struct ConnectionStatusView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    
    var body: some View {
        VStack(spacing: 4) {
            // WiFi Status
            HStack(spacing: 6) {
                Image(systemName: "wifi")
                    .foregroundColor(connectionManager.isOnTargetNetwork ? .green : .orange)
                    .font(.caption2)
                
                Text(connectionManager.currentWiFiSSID)
                    .font(.caption2)
                    .foregroundColor(connectionManager.isOnTargetNetwork ? .green : .orange)
            }
            
            // ESP32 Connection Status  
            HStack(spacing: 6) {
                Circle()
                    .fill(connectionManager.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(connectionManager.isConnected ? "ESP32 Connected" : "ESP32 Disconnected")
                    .font(.caption2)
                    .foregroundColor(connectionManager.isConnected ? .green : .red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
    }
}

// MARK: - ML View
struct MLView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var mlProcessor: MLProcessor
    @State private var showDiagnostics = false
    @State private var logMessages: [LogMessage] = []
    
    struct LogMessage: Identifiable {
        let id = UUID()
        let message: String
        let timestamp: Date
        let type: LogType
        
        enum LogType {
            case info, warning, error, success
            
            var color: Color {
                switch self {
                case .info: return .blue
                case .warning: return .yellow
                case .error: return .red
                case .success: return .green
                }
            }
            
            var icon: String {
                switch self {
                case .info: return "info.circle"
                case .warning: return "exclamationmark.triangle"
                case .error: return "xmark.circle"
                case .success: return "checkmark.circle"
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    // Header
                    HStack {
                        Button("Back") {
                            appState.navigateTo(.main)
                        }
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("ML Vision")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(mlProcessor.isConnected ? "Stop" : "Start") {
                            if mlProcessor.isConnected {
                                mlProcessor.stopStreaming()
                                addLog("Streaming stopped", type: .info)
                            } else {
                                mlProcessor.startStreaming()
                                addLog("Streaming started", type: .info)
                            }
                        }
                        .foregroundColor(mlProcessor.isConnected ? .red : .green)
                    }
                    .padding()
                    
                    // Connection Diagnostics
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(mlProcessor.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text("Connection: \(mlProcessor.isConnected ? "Connected" : "Disconnected")")
                                .font(.caption)
                                .foregroundColor(mlProcessor.isConnected ? .green : .red)
                            
                            Spacer()
                            
                            Text("IP: \(mlProcessor.connectionIP):\(mlProcessor.connectionPort)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Status: \(mlProcessor.connectionStatus)")
                                .font(.caption)
                                .foregroundColor(mlProcessor.isConnected ? .green : .red)
                            
                            Spacer()
                            
                            if mlProcessor.isProcessing {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                                        .scaleEffect(0.5)
                                    Text("Processing")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        
                        HStack {
                            Text("FPS: \(String(format: "%.1f", mlProcessor.fps))")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("Frames: \(mlProcessor.frameCount)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("Model: \(mlProcessor.modelLoadStatus)")
                                .font(.caption)
                                .foregroundColor(mlProcessor.modelLoadStatus == "Loaded successfully" ? .green : .red)
                            
                            Spacer()
                            
                            Text("Processing: \(String(format: "%.1f", mlProcessor.processingTime * 1000))ms")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("Attempts: \(mlProcessor.connectionAttempts)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("Reconnects: \(mlProcessor.reconnectAttempts)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Data: \(ByteCountFormatter.string(fromByteCount: mlProcessor.bytesReceived, countStyle: .file))")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            if let lastFrame = mlProcessor.lastFrameReceived {
                                Text("Last: \(lastFrame, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if let errorMessage = mlProcessor.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Diagnostics Toggle
                    HStack {
                        Button(action: {
                            showDiagnostics.toggle()
                            if showDiagnostics {
                                addLog("Diagnostics enabled", type: .info)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: showDiagnostics ? "eye.slash" : "eye")
                                    .font(.caption)
                                Text(showDiagnostics ? "Hide Logs" : "Show Logs")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            logMessages.removeAll()
                            addLog("Logs cleared", type: .info)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                Text("Clear")
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Content Area
                    if showDiagnostics {
                        // Diagnostics Log
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Diagnostic Log")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ScrollView {
                                LazyVStack(spacing: 4) {
                                    ForEach(logMessages.reversed()) { log in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: log.type.icon)
                                                .foregroundColor(log.type.color)
                                                .font(.caption)
                                                .frame(width: 12)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(log.message)
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Text(log.timestamp, style: .time)
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(6)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(maxHeight: 200)
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    } else {
                        // Detections
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detections (\(mlProcessor.detectedObjects.count))")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ScrollView {
                                LazyVStack(spacing: 10) {
                                    ForEach(mlProcessor.detectedObjects) { object in
                                        DetectionRow(object: object)
                                    }
                                    
                                    if mlProcessor.detectedObjects.isEmpty {
                                        Text("No objects detected")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            addLog("ML View appeared", type: .info)
            addLog("Connecting to \(AppConfig.Network.defaultHost):\(AppConfig.Network.defaultPort)", type: .info)
            mlProcessor.startStreaming()
        }
        .onDisappear {
            addLog("ML View disappeared", type: .info)
            mlProcessor.stopStreaming()
        }
        .onReceive(mlProcessor.$isConnected) { isConnected in
            if isConnected {
                addLog("Successfully connected to ESP32", type: .success)
            } else {
                addLog("Disconnected from ESP32", type: .warning)
            }
        }
        .onReceive(mlProcessor.$connectionStatus) { status in
            addLog("Connection status: \(status)", type: .info)
        }
        .onReceive(mlProcessor.$frameCount) { count in
            if count > 0 && count % 10 == 0 {
                addLog("Processed \(count) frames", type: .success)
            }
        }
        .onReceive(mlProcessor.$fps) { fps in
            if fps > 0 {
                addLog("FPS: \(String(format: "%.1f", fps))", type: .info)
            }
        }
        .onReceive(mlProcessor.$errorMessage) { error in
            if let error = error {
                addLog("Error: \(error)", type: .error)
            }
        }
        .onReceive(mlProcessor.$detectedObjects) { objects in
            if !objects.isEmpty {
                let latestObject = objects.last!
                addLog("Detected: \(latestObject.label) (\(Int(latestObject.confidence * 100))%)", type: .success)
            }
        }
    }
    
    private func addLog(_ message: String, type: LogMessage.LogType) {
        let log = LogMessage(message: message, timestamp: Date(), type: type)
        logMessages.append(log)
        
        // Keep only last 100 messages
        if logMessages.count > 100 {
            logMessages.removeFirst()
        }
    }
}

// MARK: - Detection Row
struct DetectionRow: View {
    let object: MLProcessor.DetectedObject
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(object.label)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Confidence: \(Int(object.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(object.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppStateManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Button("Back") {
                            appState.navigateTo(.main)
                        }
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Settings")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    Text("Settings coming soon...")
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Intro View
struct IntroView: View {
    @EnvironmentObject var appState: AppStateManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Text("Welcome to UnLateBoard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Ride Safe!")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Button("Get Started") {
                            appState.navigateTo(.login)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(10)
                        
                        Button("Sign Up") {
                            appState.navigateTo(.signup)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    HStack {
                        Button("Back") {
                            appState.navigateTo(.intro)
                        }
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Login")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Login") {
                            // Simple login logic
                            if !email.isEmpty && !password.isEmpty {
                                appState.loginUser()
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .disabled(email.isEmpty || password.isEmpty)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    HStack {
                        Button("Back") {
                            appState.navigateTo(.intro)
                        }
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Sign Up")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Sign Up") {
                            // Simple signup logic
                            if !email.isEmpty && !password.isEmpty && password == confirmPassword {
                                appState.loginUser()
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.green)
                        .cornerRadius(10)
                        .disabled(email.isEmpty || password.isEmpty || password != confirmPassword)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
} 
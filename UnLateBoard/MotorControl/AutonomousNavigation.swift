import SwiftUI
import CoreLocation
import Foundation

// MARK: - Debug Log Entry
struct DebugLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let category: LogCategory
    let message: String
    let details: [String: Any]
    
    enum LogLevel: String, CaseIterable {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case decision = "DECISION"
        case request = "REQUEST"
        case action = "ACTION"
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .yellow
            case .error: return .red
            case .decision: return .green
            case .request: return .orange
            case .action: return .purple
            }
        }
    }
    
    enum LogCategory: String, CaseIterable {
        case navigation = "Navigation"
        case safety = "Safety"
        case motor = "Motor"
        case ml = "ML Detection"
        case confirmation = "Confirmation"
        case state = "State Change"
        case sensor = "Sensors"
        case connection = "Connection"
    }
}

// MARK: - Autonomous Navigation System
class AutonomousNavigation: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentState: NavigationState = .idle
    @Published var isAutonomousMode: Bool = false
    @Published var safetyStatus: SafetyStatus = .safe
    @Published var currentAction: String = "Ready"
    @Published var requiresConfirmation: Bool = false
    @Published var confirmationMessage: String = ""
    
    // Debug properties
    @Published var debugLogs: [DebugLogEntry] = []
    @Published var currentDecision: String = "No decision pending"
    @Published var sensorReadings: [String: String] = [:]
    @Published var mlDetections: [String] = []
    @Published var pendingRequests: [String] = []
    @Published var lastError: String = ""
    @Published var performanceMetrics: [String: String] = [:]
    
    // MARK: - Private Properties
    private var navigationState: NavigationStateManager?
    private var motorManager: MotorManagement?
    private var mlProcessor: MLProcessor?
    private var connectionManager: ConnectionManager?
    
    // Safety thresholds
    private let maxSpeed: Double = 15.0 // mph
    private let safeDistanceToTurn: Double = 20.0 // meters
    private let safeDistanceToLight: Double = 30.0 // meters
    private let headingTolerance: Double = 10.0 // degrees
    private let emergencyStopDistance: Double = 5.0 // meters
    
    // State tracking
    private var lastTrafficLightState: TrafficLightState = .unknown
    private var lastCornerDetection: Date?
    private var isWaitingForConfirmation: Bool = false
    
    // Performance tracking
    private var lastUpdateTime: Date = Date()
    private var decisionCount: Int = 0
    private var errorCount: Int = 0
    
    // MARK: - Enums
    enum NavigationState: String, CaseIterable {
        case idle = "Idle"
        case aligning = "Aligning"
        case moving = "Moving"
        case approachingTurn = "Approaching Turn"
        case turning = "Turning"
        case approachingLight = "Approaching Light"
        case waiting = "Waiting"
        case emergencyStop = "Emergency Stop"
        case complete = "Complete"
    }
    
    enum SafetyStatus: String, CaseIterable {
        case safe = "Safe"
        case warning = "Warning"
        case danger = "Danger"
        case emergency = "Emergency"
        
        var color: Color {
            switch self {
            case .safe: return .green
            case .warning: return .yellow
            case .danger: return .orange
            case .emergency: return .red
            }
        }
    }
    
    enum TrafficLightState: String {
        case red = "Red"
        case yellow = "Yellow"
        case green = "Green"
        case unknown = "Unknown"
    }
    
    enum ConfirmationType {
        case startNavigation
        case proceedAtLight
        case proceedAtTurn
        case emergencyOverride
    }
    
    // MARK: - Initialization
    init() {
        addDebugLog(level: .info, category: .navigation, message: "AutonomousNavigation initialized", details: [:])
    }
    
    // MARK: - Debug Logging
    private func addDebugLog(level: DebugLogEntry.LogLevel, category: DebugLogEntry.LogCategory, message: String, details: [String: Any] = [:]) {
        let entry = DebugLogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            details: details
        )
        
        DispatchQueue.main.async {
            self.debugLogs.append(entry)
            
            // Keep only last 100 logs
            if self.debugLogs.count > 100 {
                self.debugLogs.removeFirst()
            }
            
            // Update current decision for important logs
            if level == .decision || level == .request {
                self.currentDecision = message
            }
            
            // Track errors
            if level == .error {
                self.errorCount += 1
                self.lastError = message
            }
            
            // Track decisions
            if level == .decision {
                self.decisionCount += 1
            }
        }
        
        Logger.shared.info("[\(level.rawValue)] [\(category.rawValue)] \(message)")
    }
    
    private func updateSensorReadings() {
        guard let motorManager = motorManager else { return }
        
        sensorReadings = [
            "Speed": "\(String(format: "%.1f", motorManager.speed)) mph",
            "Heading": "\(String(format: "%.1f", motorManager.heading))°",
            "Battery": "100%",
            "Connection": "Connected"//motorManager.isConnected ? "Connected" : "Disconnected"
        ]
    }
    
    private func updateMLDetections() {
        guard let mlProcessor = mlProcessor else { return }
        
        mlDetections = mlProcessor.detectedObjects.map { object in
            "\(object.label) (\(String(format: "%.1f", object.confidence * 100))%)"
        }
    }
    
    private func updatePerformanceMetrics() {
        let now = Date()
        let timeSinceUpdate = now.timeIntervalSince(lastUpdateTime)
        
        performanceMetrics = [
            "Decisions/sec": "\(String(format: "%.1f", Double(decisionCount) / timeSinceUpdate))",
            "Errors": "\(errorCount)",
            "Uptime": "\(String(format: "%.1f", now.timeIntervalSince(lastUpdateTime)))s",
            "Log Count": "\(debugLogs.count)"
        ]
        
        lastUpdateTime = now
        decisionCount = 0
        errorCount = 0
    }
    
    // MARK: - Setup Methods
    func connectToManagers(navigation: NavigationStateManager, motor: MotorManagement, ml: MLProcessor, connection: ConnectionManager) {
        self.navigationState = navigation
        self.motorManager = motor
        self.mlProcessor = ml
        self.connectionManager = connection
        
        addDebugLog(level: .info, category: .connection, message: "Connected to all managers", details: [
            "navigation": "Connected",
            "motor": "Connected", 
            "ml": "Connected",
            "connection": "Connected"
        ])
    }
    
    // MARK: - Main Navigation Algorithm
    func startAutonomousNavigation() {
        guard let navigationState = navigationState,
              let motorManager = motorManager else {
            addDebugLog(level: .error, category: .navigation, message: "Required managers not connected", details: [
                "navigationState": navigationState != nil,
                "motorManager": motorManager != nil
            ])
            return
        }
        
        guard navigationState.isNavigating else {
            addDebugLog(level: .warning, category: .navigation, message: "No active navigation route", details: [:])
            return
        }
        
        isAutonomousMode = true
        currentState = .aligning
        currentAction = "Aligning to initial heading"
        
        addDebugLog(level: .action, category: .navigation, message: "Starting autonomous navigation", details: [
            "startHeading": navigationState.startHeading,
            "destination": navigationState.destination ?? "Unknown"
        ])
        
        // Start the navigation loop
        startNavigationLoop()
    }
    
    func stopAutonomousNavigation() {
        isAutonomousMode = false
        currentState = .idle
        currentAction = "Autonomous mode stopped"
        
        addDebugLog(level: .action, category: .navigation, message: "Stopping autonomous navigation", details: [
            "finalState": currentState.rawValue
        ])
        
        // Emergency stop the skateboard
        emergencyStop()
    }
    
    // MARK: - Navigation Loop
    private func startNavigationLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self,
                  self.isAutonomousMode else {
                timer.invalidate()
                return
            }
            
            self.processNavigationStep()
            self.updateSensorReadings()
            self.updateMLDetections()
            self.updatePerformanceMetrics()
        }
    }
    
    private func processNavigationStep() {
        guard let navigationState = navigationState,
              let motorManager = motorManager,
              let currentStep = navigationState.currentStep else {
            addDebugLog(level: .decision, category: .navigation, message: "No current step - completing navigation", details: [:])
            completeNavigation()
            return
        }
        
        addDebugLog(level: .info, category: .navigation, message: "Processing navigation step", details: [
            "step": currentStep.instruction,
            "distance": currentStep.distance,
            "state": currentState.rawValue
        ])
        
        // Check safety first
        guard checkSafety() else {
            addDebugLog(level: .error, category: .safety, message: "Safety check failed", details: [
                "safetyStatus": safetyStatus.rawValue
            ])
            emergencyStop()
            return
        }
        
        // Process current state
        switch currentState {
        case .idle:
            break
            
        case .aligning:
            processAligningState()
            
        case .moving:
            processMovingState()
            
        case .approachingTurn:
            processApproachingTurnState()
            
        case .turning:
            processTurningState()
            
        case .approachingLight:
            processApproachingLightState()
            
        case .waiting:
            processWaitingState()
            
        case .emergencyStop:
            processEmergencyStopState()
            
        case .complete:
            break
        }
    }
    
    // MARK: - State Processing Methods
    private func processAligningState() {
        guard let navigationState = navigationState,
              let motorManager = motorManager else { return }
        
        let headingDifference = abs(motorManager.heading - navigationState.startHeading)
        
        addDebugLog(level: .info, category: .sensor, message: "Checking alignment", details: [
            "currentHeading": motorManager.heading,
            "targetHeading": navigationState.startHeading,
            "difference": headingDifference,
            "tolerance": headingTolerance
        ])
        
        if headingDifference <= headingTolerance {
            // Successfully aligned
            currentState = .moving
            currentAction = "Moving forward"
            
            addDebugLog(level: .decision, category: .navigation, message: "Successfully aligned - starting movement", details: [
                "headingDifference": headingDifference
            ])
            
            startMoving()
        } else {
            currentAction = "Aligning: \(Int(headingDifference))° off target"
            
            addDebugLog(level: .info, category: .navigation, message: "Still aligning", details: [
                "headingDifference": headingDifference,
                "tolerance": headingTolerance
            ])
        }
    }
    
    private func processMovingState() {
        guard let navigationState = navigationState,
              let currentStep = navigationState.currentStep else { return }
        
        addDebugLog(level: .info, category: .navigation, message: "Processing moving state", details: [
            "currentStep": currentStep.instruction,
            "distance": currentStep.distance
        ])
        
        // Check if approaching a turn
        if isApproachingTurn() {
            currentState = .approachingTurn
            currentAction = "Approaching turn - slowing down"
            
            addDebugLog(level: .decision, category: .navigation, message: "Detected approaching turn", details: [
                "instruction": currentStep.instruction
            ])
            
            slowDown()
            return
        }
        
        // Check if approaching traffic light
        if isApproachingTrafficLight() {
            currentState = .approachingLight
            currentAction = "Approaching traffic light"
            
            addDebugLog(level: .decision, category: .navigation, message: "Detected approaching traffic light", details: [:])
            return
        }
        
        // Continue moving
        currentAction = "Moving to next waypoint"
    }
    
    private func processApproachingTurnState() {
        guard let navigationState = navigationState,
              let currentStep = navigationState.currentStep else { return }
        
        addDebugLog(level: .info, category: .navigation, message: "Processing approaching turn", details: [
            "instruction": currentStep.instruction
        ])
        
        // Check if we're close enough to the turn
        if isNearTurn() {
            currentState = .turning
            currentAction = "Requesting turn confirmation"
            
            addDebugLog(level: .request, category: .confirmation, message: "Requesting turn confirmation", details: [
                "turnType": currentStep.instruction
            ])
            
            requestConfirmation(type: .proceedAtTurn, message: "Proceed with turn?")
        }
    }
    
    private func processTurningState() {
        if !isWaitingForConfirmation {
            // Turn completed
            currentState = .moving
            currentAction = "Turn completed - continuing"
            
            addDebugLog(level: .decision, category: .navigation, message: "Turn completed", details: [:])
            
            startMoving()
        }
    }
    
    private func processApproachingLightState() {
        guard let trafficLightState = getTrafficLightState() else { return }
        
        addDebugLog(level: .info, category: .ml, message: "Processing traffic light", details: [
            "lightState": trafficLightState.rawValue
        ])
        
        switch trafficLightState {
        case .red:
            currentState = .waiting
            currentAction = "Red light - stopping"
            
            addDebugLog(level: .decision, category: .navigation, message: "Red light detected - stopping", details: [:])
            
            stopMoving()
            requestConfirmation(type: .proceedAtLight, message: "Light is green - proceed?")
            
        case .yellow:
            currentAction = "Yellow light - preparing to stop"
            
            addDebugLog(level: .warning, category: .navigation, message: "Yellow light detected - slowing down", details: [:])
            
            slowDown()
            
        case .green:
            currentState = .moving
            currentAction = "Green light - proceeding"
            
            addDebugLog(level: .decision, category: .navigation, message: "Green light detected - proceeding", details: [:])
            
            startMoving()
            
        case .unknown:
            currentAction = "Traffic light unclear - stopping"
            
            addDebugLog(level: .warning, category: .ml, message: "Traffic light state unclear - stopping", details: [:])
            
            stopMoving()
        }
    }
    
    private func processWaitingState() {
        // Waiting for user confirmation
        currentAction = "Waiting for confirmation"
        
        addDebugLog(level: .info, category: .confirmation, message: "Waiting for user confirmation", details: [
            "confirmationMessage": confirmationMessage
        ])
    }
    
    private func processEmergencyStopState() {
        currentAction = "Emergency stop - manual intervention required"
        
        addDebugLog(level: .error, category: .safety, message: "In emergency stop state", details: [:])
        
        stopMoving()
    }
    
    // MARK: - Safety Methods
    private func checkSafety() -> Bool {
        guard let motorManager = motorManager else { return false }
        
        addDebugLog(level: .info, category: .safety, message: "Performing safety check", details: [
            "currentSpeed": motorManager.speed,
            "maxSpeed": maxSpeed,
            "batteryLevel": "100"//motorManager.batteryLevel
        ])
        
        // Check speed limits
        if motorManager.speed > maxSpeed {
            safetyStatus = .danger
            addDebugLog(level: .error, category: .safety, message: "Speed limit exceeded", details: [
                "currentSpeed": motorManager.speed,
                "maxSpeed": maxSpeed
            ])
            return false
        }
        
        // Check for obstacles (ML detection)
        if hasObstacles() {
            safetyStatus = .emergency
            addDebugLog(level: .error, category: .safety, message: "Obstacle detected", details: [
                "obstacles": mlDetections
            ])
            return false
        }
        
        // Check battery level
        if isBatteryLow() {
            safetyStatus = .warning
            addDebugLog(level: .warning, category: .safety, message: "Low battery", details: [
                "batteryLevel": "100"//motorManager.batteryLevel
            ])
        }
        
        safetyStatus = .safe
        return true
    }
    
    private func emergencyStop() {
        currentState = .emergencyStop
        safetyStatus = .emergency
        currentAction = "Emergency stop activated"
        
        addDebugLog(level: .error, category: .safety, message: "Emergency stop activated", details: [:])
        
        // Send emergency stop command
        connectionManager?.sendRawMessage(message: "EMERGENCY_STOP\n")
    }
    
    // MARK: - Movement Control
    private func startMoving() {
        guard let motorManager = motorManager else { return }
        
        // Gradually increase speed
        let targetSpeed = min(maxSpeed, 10.0) // Start with 10 mph
        motorManager.setSpeed(targetSpeed)
        
        addDebugLog(level: .action, category: .motor, message: "Starting movement", details: [
            "targetSpeed": targetSpeed
        ])
    }
    
    private func stopMoving() {
        guard let motorManager = motorManager else { return }
        
        motorManager.setSpeed(0.0)
        
        addDebugLog(level: .action, category: .motor, message: "Stopping movement", details: [:])
    }
    
    private func slowDown() {
        guard let motorManager = motorManager else { return }
        
        let currentSpeed = motorManager.speed
        let newSpeed = max(0.0, currentSpeed - 2.0) // Reduce by 2 mph
        motorManager.setSpeed(newSpeed)
        
        addDebugLog(level: .action, category: .motor, message: "Slowing down", details: [
            "currentSpeed": currentSpeed,
            "newSpeed": newSpeed
        ])
    }
    
    // MARK: - Detection Methods
    private func isApproachingTurn() -> Bool {
        guard let navigationState = navigationState,
              let currentStep = navigationState.currentStep else { return false }
        
        // Check if next instruction contains turn keywords
        let turnKeywords = ["left", "right", "turn"]
        let hasTurnInstruction = turnKeywords.contains { keyword in
            currentStep.instruction.lowercased().contains(keyword)
        }
        
        addDebugLog(level: .info, category: .navigation, message: "Checking for turn", details: [
            "instruction": currentStep.instruction,
            "hasTurn": hasTurnInstruction
        ])
        
        return hasTurnInstruction
    }
    
    private func isNearTurn() -> Bool {
        guard let navigationState = navigationState,
              let currentStep = navigationState.currentStep else { return false }
        
        // Check distance to turn waypoint
        // This would use GPS distance calculation
        let isNear = true // Placeholder
        
        addDebugLog(level: .info, category: .navigation, message: "Checking distance to turn", details: [
            "distance": currentStep.distance,
            "isNear": isNear
        ])
        
        return isNear
    }
    
    private func isApproachingTrafficLight() -> Bool {
        // Check if ML has detected traffic lights
        guard let mlProcessor = mlProcessor else { return false }
        
        let trafficLightDetected = mlProcessor.detectedObjects.contains { object in
            object.label.lowercased().contains("traffic light") ||
            object.label.lowercased().contains("light")
        }
        
        addDebugLog(level: .info, category: .ml, message: "Checking for traffic lights", details: [
            "detected": trafficLightDetected,
            "objects": mlProcessor.detectedObjects.map { $0.label }
        ])
        
        return trafficLightDetected
    }
    
    private func getTrafficLightState() -> TrafficLightState? {
        guard let mlProcessor = mlProcessor else { return nil }
        
        // Analyze ML detections for traffic light state
        let trafficLightObjects = mlProcessor.detectedObjects.filter { object in
            object.label.lowercased().contains("traffic light") ||
            object.label.lowercased().contains("light")
        }
        
        addDebugLog(level: .info, category: .ml, message: "Analyzing traffic light state", details: [
            "trafficLightObjects": trafficLightObjects.map { $0.label }
        ])
        
        // This would use ML to determine light color
        // For now, return unknown
        return .unknown
    }
    
    private func hasObstacles() -> Bool {
        guard let mlProcessor = mlProcessor else { return false }
        
        // Check for obstacles in ML detections
        let obstacleObjects = mlProcessor.detectedObjects.filter { object in
            object.label.lowercased().contains("person") ||
            object.label.lowercased().contains("car") ||
            object.label.lowercased().contains("obstacle")
        }
        
        addDebugLog(level: .info, category: .ml, message: "Checking for obstacles", details: [
            "obstacles": obstacleObjects.map { $0.label }
        ])
        
        return !obstacleObjects.isEmpty
    }
    
    private func isBatteryLow() -> Bool {
        // Check battery level (would need to be implemented)
        return false
    }
    
    // MARK: - Confirmation Methods
    private func requestConfirmation(type: ConfirmationType, message: String) {
        requiresConfirmation = true
        confirmationMessage = message
        isWaitingForConfirmation = true
        
        pendingRequests.append(message)
        
        addDebugLog(level: .request, category: .confirmation, message: "Requesting confirmation", details: [
            "type": String(describing: type),
            "message": message
        ])
    }
    
    func confirmAction() {
        requiresConfirmation = false
        confirmationMessage = ""
        isWaitingForConfirmation = false
        
        if !pendingRequests.isEmpty {
            pendingRequests.removeFirst()
        }
        
        addDebugLog(level: .action, category: .confirmation, message: "Action confirmed", details: [:])
    }
    
    func denyAction() {
        requiresConfirmation = false
        confirmationMessage = ""
        isWaitingForConfirmation = false
        
        if !pendingRequests.isEmpty {
            pendingRequests.removeFirst()
        }
        
        // Stop and wait
        stopMoving()
        currentState = .waiting
        
        addDebugLog(level: .action, category: .confirmation, message: "Action denied", details: [:])
    }
    
    // MARK: - Utility Methods
    private func completeNavigation() {
        currentState = .complete
        currentAction = "Navigation completed"
        isAutonomousMode = false
        
        stopMoving()
        
        addDebugLog(level: .info, category: .navigation, message: "Navigation completed", details: [:])
    }
}

// MARK: - AI Debug View
struct AIDebugView: View {
    @StateObject private var autonomousNav = AutonomousNavigation()
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var navigationState: NavigationStateManager
    @EnvironmentObject var motorManager: MotorManagement
    @EnvironmentObject var mlProcessor: MLProcessor
    @EnvironmentObject var connectionManager: ConnectionManager
    
    @State private var selectedLogLevel: DebugLogEntry.LogLevel? = nil
    @State private var selectedCategory: DebugLogEntry.LogCategory? = nil
    @State private var showRawLogs = false
    
    var filteredLogs: [DebugLogEntry] {
        var logs = autonomousNav.debugLogs
        
        if let level = selectedLogLevel {
            logs = logs.filter { $0.level == level }
        }
        
        if let category = selectedCategory {
            logs = logs.filter { $0.category == category }
        }
        
        return logs
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Status
                        VStack(spacing: 10) {
                            HStack {
                                Circle()
                                    .fill(autonomousNav.safetyStatus.color)
                                    .frame(width: 16, height: 16)
                                Text("AI Status: \(autonomousNav.safetyStatus.rawValue)")
                                    .font(.headline)
                                    .foregroundColor(autonomousNav.safetyStatus.color)
                            }
                            
                            Text("Current State: \(autonomousNav.currentState.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Text(autonomousNav.currentAction)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        
                        // Current Decision
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🤔 Current Decision")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(autonomousNav.currentDecision)
                                .font(.subheadline)
                                .foregroundColor(.yellow)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                        }
                        
                        // Sensor Readings
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📊 Sensor Readings")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(Array(autonomousNav.sensorReadings.keys.sorted()), id: \.self) { key in
                                    VStack(alignment: .leading) {
                                        Text(key)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(autonomousNav.sensorReadings[key] ?? "N/A")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                    .padding(8)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        // ML Detections
                        VStack(alignment: .leading, spacing: 8) {
                            Text("👁️ ML Detections")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if autonomousNav.mlDetections.isEmpty {
                                Text("No objects detected")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                            } else {
                                ForEach(autonomousNav.mlDetections, id: \.self) { detection in
                                    Text("• \(detection)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 2)
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Pending Requests
                        if !autonomousNav.pendingRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("❓ Pending Requests")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                ForEach(autonomousNav.pendingRequests, id: \.self) { request in
                                    Text("• \(request)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 2)
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Performance Metrics
                        VStack(alignment: .leading, spacing: 8) {
                            Text("⚡ Performance")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(Array(autonomousNav.performanceMetrics.keys.sorted()), id: \.self) { key in
                                    VStack(alignment: .leading) {
                                        Text(key)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(autonomousNav.performanceMetrics[key] ?? "N/A")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                    .padding(8)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Last Error
                        if !autonomousNav.lastError.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🚨 Last Error")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                
                                Text(autonomousNav.lastError)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Filter Controls
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🔍 Filter Logs")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Menu("Level: \(selectedLogLevel?.rawValue ?? "All")") {
                                    Button("All") { selectedLogLevel = nil }
                                    ForEach(DebugLogEntry.LogLevel.allCases, id: \.self) { level in
                                        Button(level.rawValue) { selectedLogLevel = level }
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.3))
                                .cornerRadius(8)
                                
                                Menu("Category: \(selectedCategory?.rawValue ?? "All")") {
                                    Button("All") { selectedCategory = nil }
                                    ForEach(DebugLogEntry.LogCategory.allCases, id: \.self) { category in
                                        Button(category.rawValue) { selectedCategory = category }
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Debug Logs
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("📝 Debug Logs (\(filteredLogs.count))")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(showRawLogs ? "Hide Details" : "Show Details") {
                                    showRawLogs.toggle()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            
                            LazyVStack(spacing: 4) {
                                ForEach(filteredLogs.reversed()) { log in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Circle()
                                                .fill(log.level.color)
                                                .frame(width: 8, height: 8)
                                            
                                            Text(log.level.rawValue)
                                                .font(.caption)
                                                .foregroundColor(log.level.color)
                                            
                                            Text(log.category.rawValue)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            Spacer()
                                            
                                            Text(log.timestamp, style: .time)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Text(log.message)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        
                                        if showRawLogs && !log.details.isEmpty {
                                            Text("Details: \(String(describing: log.details))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        appState.navigateTo(.main)
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear Logs") {
                        autonomousNav.debugLogs.removeAll()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            autonomousNav.connectToManagers(
                navigation: navigationState,
                motor: motorManager,
                ml: mlProcessor,
                connection: connectionManager
            )
        }
    }
}

// MARK: - Autonomous Navigation View
struct AutonomousNavigationView: View {
    @StateObject private var autonomousNav = AutonomousNavigation()
    @EnvironmentObject var navigationState: NavigationStateManager
    @EnvironmentObject var motorManager: MotorManagement
    @EnvironmentObject var mlProcessor: MLProcessor
    @EnvironmentObject var connectionManager: ConnectionManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Display
            VStack(spacing: 10) {
                HStack {
                    Circle()
                        .fill(autonomousNav.safetyStatus.color)
                        .frame(width: 12, height: 12)
                    Text("Safety: \(autonomousNav.safetyStatus.rawValue)")
                        .font(.headline)
                        .foregroundColor(autonomousNav.safetyStatus.color)
                }
                
                Text("State: \(autonomousNav.currentState.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(autonomousNav.currentAction)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(10)
            
            // Control Buttons
            VStack(spacing: 15) {
                Button(autonomousNav.isAutonomousMode ? "Stop Autonomous" : "Start Autonomous") {
                    if autonomousNav.isAutonomousMode {
                        autonomousNav.stopAutonomousNavigation()
                    } else {
                        autonomousNav.startAutonomousNavigation()
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(autonomousNav.isAutonomousMode ? Color.red : Color.green)
                .cornerRadius(10)
                
                if autonomousNav.requiresConfirmation {
                    VStack(spacing: 10) {
                        Text(autonomousNav.confirmationMessage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 20) {
                            Button("Confirm") {
                                autonomousNav.confirmAction()
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            
                            Button("Deny") {
                                autonomousNav.denyAction()
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            autonomousNav.connectToManagers(
                navigation: navigationState,
                motor: motorManager,
                ml: mlProcessor,
                connection: connectionManager
            )
        }
    }
} 

import SwiftUI

// MARK: - Enhanced Motor Management
class MotorManagement: ObservableObject {
    // MARK: - Published Properties
    @Published var maxAccel: Double = AppConfig.Motor.defaultMaxAcceleration
    @Published var maxVelo: Double = AppConfig.Motor.defaultMaxSpeed
    
    @Published var speed: Double = 0.0
    @Published var currentAccel: Double = 0.0
    @Published var currentVelo: Double = 0.0
    @Published var targetSpeed: Double = 0.0
    
    @Published var heading: Double = 0.0
    @Published var direction: String = "forward"
    @Published var isMoving: Bool = false
    @Published var isEmergencyStop: Bool = false
    
    // Autopilot control
    @Published var isAutopilotEnabled: Bool = false {
        didSet {
            handleAutopilotStateChange()
        }
    }
    
    // Performance tracking
    @Published var totalDistance: Double = 0.0
    @Published var tripTime: TimeInterval = 0.0
    @Published var averageSpeed: Double = 0.0
    
    // MARK: - Private Properties
    private var connectionManager: ConnectionManager?
    private var mlProcessor: MLProcessor?
    private var initSpeed: Double = 0.0
    private var newSpeed: Double = 0.0
    private var lastSpeedUpdate: TimeInterval = Date().timeIntervalSince1970
    private var tripStartTime: TimeInterval = Date().timeIntervalSince1970
    private var isTripActive: Bool = false
    
    // Speed history for acceleration calculation
    private var speedHistory: [(speed: Double, timestamp: TimeInterval)] = []
    
    // MARK: - Initialization
    init() {
        // Initialize with default values
        resetTrip()
        Logger.shared.info("MotorManagement initialized")
    }
    
    deinit {
        emergencyStop()
    }
    
    // MARK: - Connection Integration
    func connectToManager(_ manager: ConnectionManager) {
        self.connectionManager = manager
        Logger.shared.info("MotorManagement connected to ConnectionManager")
        
        // Start monitoring connection for motor data
        startMotorDataMonitoring()
    }
    
    // Use shared connection if no explicit manager provided
    private func getConnectionManager() -> ConnectionManager? {
        return connectionManager ?? ConnectionManager.shared
    }
    
    func connectToMLProcessor(_ processor: MLProcessor) {
        self.mlProcessor = processor
        Logger.shared.info("MotorManagement connected to MLProcessor")
    }
    
    // MARK: - Autopilot Management
    private func handleAutopilotStateChange() {
        if isAutopilotEnabled {
            enableAutopilot()
        } else {
            disableAutopilot()
        }
    }
    
    private func enableAutopilot() {
        Logger.shared.info("Autopilot enabled - starting ML processing")
        
        // Ensure ML processing is active
        mlProcessor?.startStreaming()
        
        // Send autopilot enable command to ESP32
        sendMotorCommand("autopilot", value: "enabled")
        
        // Set conservative speed limits for autopilot
        let autopilotMaxSpeed = min(maxVelo, 15.0) // Cap at 15 m/s for safety
        setMaxVelocity(autopilotMaxSpeed)
        
        Logger.shared.info("Autopilot enabled with max speed: \(autopilotMaxSpeed) m/s")
    }
    
    private func disableAutopilot() {
        Logger.shared.info("Autopilot disabled")
        
        // Send autopilot disable command to ESP32
        sendMotorCommand("autopilot", value: "disabled")
        
        // Note: We don't stop ML processing here as it might be needed for other features
        // The ML processor will continue running but won't control the motor
        
        Logger.shared.info("Autopilot disabled - ML processing continues for safety")
    }
    
    private func startMotorDataMonitoring() {
        // Listen for motor data notifications from ConnectionManager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMotorDataNotification),
            name: .motorDataReceived,
            object: nil
        )
        
        Logger.shared.debug("Motor data monitoring started")
    }
    
    @objc private func handleMotorDataNotification(_ notification: Notification) {
        guard let message = notification.userInfo?["message"] as? String else { return }
        updateFromStreamingData(message)
    }
    
    // MARK: - Motor Data Processing
    func updateFromConnectionData(_ data: [String: Any]) {
        DispatchQueue.main.async {
            if let motorData = data["motor"] as? [String: Any] {
                self.processMotorData(motorData)
            }
        }
    }
    
    func updateFromStreamingData(_ streamData: String) {
        guard streamData.contains("MOTOR:") else { return }
        
        let motorContent = streamData.components(separatedBy: "MOTOR:").last ?? ""
        let pairs = motorContent.components(separatedBy: ",")
        
        var motorData: [String: Any] = [:]
        
        for pair in pairs {
            let keyValue = pair.components(separatedBy: "=")
            if keyValue.count == 2 {
                let key = keyValue[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = keyValue[1].trimmingCharacters(in: .whitespacesAndNewlines)
                motorData[key] = value
            }
        }
        
        DispatchQueue.main.async {
            self.processMotorData(motorData)
        }
    }
    
    private func processMotorData(_ motorData: [String: Any]) {
        // Process speed
        if let speedValue = motorData["speed"] as? Double {
            updateSpeed(speedValue)
        } else if let speedStr = motorData["speed"] as? String,
                  let speedValue = Double(speedStr) {
            updateSpeed(speedValue)
        }
        
        // Process target speed
        if let targetValue = motorData["targetSpeed"] as? Double {
            targetSpeed = targetValue
        } else if let targetStr = motorData["targetSpeed"] as? String,
                  let targetValue = Double(targetStr) {
            targetSpeed = targetValue
        }
        
        // Process direction
        if let directionValue = motorData["direction"] as? String {
            direction = directionValue
        }
        
        // Process max velocity
        if let maxVeloValue = motorData["maxVelo"] as? Double {
            maxVelo = maxVeloValue
        } else if let maxVeloStr = motorData["maxVelo"] as? String,
                  let maxVeloValue = Double(maxVeloStr) {
            maxVelo = maxVeloValue
        }
        
        // Process max acceleration
        if let maxAccelValue = motorData["maxAccel"] as? Double {
            maxAccel = maxAccelValue
        } else if let maxAccelStr = motorData["maxAccel"] as? String,
                  let maxAccelValue = Double(maxAccelStr) {
            maxAccel = maxAccelValue
        }
        
        // Process current velocity
        if let currentVeloValue = motorData["currentVelo"] as? Double {
            currentVelo = currentVeloValue
            newSpeed = currentVeloValue
        } else if let currentVeloStr = motorData["currentVelo"] as? String,
                  let currentVeloValue = Double(currentVeloStr) {
            currentVelo = currentVeloValue
            newSpeed = currentVeloValue
        }
        
        // Process heading
        if let headingStr = motorData["heading"] as? String,
           let headingValue = Double(headingStr) {
            heading = headingValue
        }
        
        // Process movement status
        if let isMovingValue = motorData["isMoving"] as? Bool {
            isMoving = isMovingValue
        } else if let isMovingStr = motorData["isMoving"] as? String {
            isMoving = (isMovingStr.lowercased() == "true" || isMovingStr == "1")
        }
        
        // Update acceleration
        updateAcceleration()
        
        // Update trip statistics
        updateTripStatistics()
        
        Logger.shared.debug("Motor data processed: speed=\(speed), direction=\(direction), isMoving=\(isMoving)")
    }
    
    private func updateSpeed(_ newSpeedValue: Double) {
        let oldSpeed = speed
        speed = newSpeedValue
        currentVelo = newSpeedValue
        
        // Update movement status
        isMoving = (abs(newSpeedValue) > AppConfig.Motor.minSpeedThreshold)
        
        // Start/stop trip tracking
        if isMoving && !isTripActive {
            startTrip()
        } else if !isMoving && isTripActive {
            stopTrip()
        }
        
        // Add to speed history for acceleration calculation
        let currentTime = Date().timeIntervalSince1970
        speedHistory.append((speed: newSpeedValue, timestamp: currentTime))
        
        // Keep only recent history
        if speedHistory.count > AppConfig.Motor.maxSpeedHistorySize {
            speedHistory.removeFirst()
        }
        
        lastSpeedUpdate = currentTime
    }
    
    private func updateAcceleration() {
        guard speedHistory.count >= 2 else { return }
        
        let currentTime = Date().timeIntervalSince1970
        let recentHistory = speedHistory.filter { currentTime - $0.timestamp <= AppConfig.Motor.accelerationCalculationWindow }
        
        guard recentHistory.count >= 2 else { return }
        
        let first = recentHistory.first!
        let last = recentHistory.last!
        let timeDiff = last.timestamp - first.timestamp
        
        guard timeDiff > 0 else { return }
        
        currentAccel = (last.speed - first.speed) / timeDiff
    }
    
    // MARK: - Motor Control Methods
    func setSpeed(_ newSpeed: Double) {
        let clampedSpeed = max(-maxVelo, min(maxVelo, newSpeed))
        
        if abs(clampedSpeed - speed) > AppConfig.Motor.speedUpdateThreshold {
            speed = clampedSpeed
            isMoving = (abs(clampedSpeed) > AppConfig.Motor.minSpeedThreshold)
            
            // Send speed command to ESP32
            sendMotorCommand("speed", value: clampedSpeed)
            
            Logger.shared.debug("Speed set to \(clampedSpeed) m/s")
        }
    }
    
    func setDirection(_ newDirection: String) {
        guard newDirection != direction else { return }
        
        direction = newDirection
        sendMotorCommand("direction", value: newDirection)
        
        Logger.shared.debug("Direction set to \(newDirection)")
    }
    
    func setMaxAcceleration(_ newMaxAccel: Double) {
        guard newMaxAccel > 0 else { 
            Logger.shared.warning("Invalid max acceleration value: \(newMaxAccel)")
            return 
        }
        
        maxAccel = newMaxAccel
        sendMotorCommand("maxAccel", value: newMaxAccel)
        
        Logger.shared.debug("Max acceleration set to \(newMaxAccel) m/s²")
    }
    
    func setMaxVelocity(_ newMaxVelo: Double) {
        guard newMaxVelo > 0 else { 
            Logger.shared.warning("Invalid max velocity value: \(newMaxVelo)")
            return 
        }
        
        maxVelo = newMaxVelo
        
        // If current speed exceeds new max, reduce it
        if abs(speed) > newMaxVelo {
            setSpeed(speed > 0 ? newMaxVelo : -newMaxVelo)
        }
        
        sendMotorCommand("maxVelo", value: newMaxVelo)
        
        Logger.shared.debug("Max velocity set to \(newMaxVelo) m/s")
    }
    
    // MARK: - Advanced Motor Control
    func smoothTransitionToSpeed(_ targetSpeed: Double) {
        let clampedTarget = max(-maxVelo, min(maxVelo, targetSpeed))
        self.targetSpeed = clampedTarget
        
        // Calculate smooth transition
        let speedDifference = clampedTarget - speed
        let steps = max(5, Int(abs(speedDifference) / 2)) // At least 5 steps
        let stepSize = speedDifference / Double(steps)
        let stepDelay = AppConfig.UI.buttonPressDelay // Use configurable delay
        
        Logger.shared.debug("Starting smooth transition to \(clampedTarget) m/s over \(steps) steps")
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay * Double(i)) {
                let newSpeed = self.speed + (stepSize * Double(i))
                self.setSpeed(newSpeed)
            }
        }
    }
    
    func emergencyStop() {
        isEmergencyStop = true
        setSpeed(0.0)
        setMaxAcceleration(maxAccel * AppConfig.Safety.maxBrakeIntensity) // Increase braking force
        sendMotorCommand("emergencyStop", value: "true")
        
        Logger.shared.warning("Emergency stop activated")
        
        // Reset emergency stop after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Safety.maxEmergencyStopDuration) {
            self.isEmergencyStop = false
            Logger.shared.info("Emergency stop reset")
        }
    }
    
    func brake(intensity: Double = 1.0) {
        let clampedIntensity = max(AppConfig.Safety.minBrakeIntensity, min(AppConfig.Safety.maxBrakeIntensity, intensity))
        let brakeAccel = maxAccel * clampedIntensity
        setMaxAcceleration(brakeAccel)
        setSpeed(0.0)
        
        Logger.shared.debug("Brake applied with intensity \(clampedIntensity)")
    }
    
    func coast() {
        // Gradually reduce speed to zero
        smoothTransitionToSpeed(0.0)
        Logger.shared.debug("Coasting - gradually reducing speed to zero")
    }
    
    // MARK: - Trip Management
    private func startTrip() {
        if !isTripActive {
            tripStartTime = Date().timeIntervalSince1970
            isTripActive = true
            Logger.shared.info("Trip started")
        }
    }
    
    private func stopTrip() {
        if isTripActive {
            updateTripStatistics()
            isTripActive = false
            Logger.shared.info("Trip stopped - Distance: \(String(format: "%.2f", totalDistance))m, Time: \(String(format: "%.1f", tripTime))s")
        }
    }
    
    private func updateTripStatistics() {
        guard isTripActive else { return }
        
        let currentTime = Date().timeIntervalSince1970
        tripTime = currentTime - tripStartTime
        
        // Calculate average speed
        if tripTime > 0 {
            averageSpeed = totalDistance / tripTime
        }
        
        // Update total distance (simplified calculation)
        if speedHistory.count >= 2 {
            let recentHistory = speedHistory.suffix(2)
            let timeDiff = recentHistory.last!.timestamp - recentHistory.first!.timestamp
            let avgSpeed = (recentHistory.first!.speed + recentHistory.last!.speed) / 2
            totalDistance += avgSpeed * timeDiff
        }
    }
    
    func resetTrip() {
        totalDistance = 0.0
        tripTime = 0.0
        averageSpeed = 0.0
        tripStartTime = Date().timeIntervalSince1970
        isTripActive = false
        speedHistory.removeAll()
        
        Logger.shared.info("Trip statistics reset")
    }
    
    // MARK: - Communication with ESP32
    private func sendMotorCommand(_ command: String, value: Any) {
        guard let connectionManager = getConnectionManager() else {
            Logger.shared.error("No connection manager available for motor command")
            return
        }
        
        let message = "MOTOR:\(command)=\(value)\n"
        connectionManager.sendRawMessage(message: message)
    }
    
    // MARK: - Utility Methods
    func getSpeedInMPH() -> Double {
        return speed * 2.237 // Convert m/s to mph
    }
    
    func getAccelerationInMPHPS() -> Double {
        return currentAccel * 2.237 // Convert m/s² to mph/s
    }
    
    func getMaxSpeedInMPH() -> Double {
        return maxVelo * 2.237
    }
    
    func getMaxAccelerationInMPHPS() -> Double {
        return maxAccel * 2.237
    }
    
    func isSpeedWithinLimits() -> Bool {
        return abs(speed) <= maxVelo
    }
    
    func isAccelerationWithinLimits() -> Bool {
        return abs(currentAccel) <= maxAccel
    }
    
    func isSpeedLimitWarning() -> Bool {
        return abs(speed) >= maxVelo * AppConfig.Safety.speedLimitWarningThreshold
    }
    
    // MARK: - Status Methods
    func getMotorStatus() -> [String: Any] {
        return [
            "speed": speed,
            "targetSpeed": targetSpeed,
            "currentVelo": currentVelo,
            "currentAccel": currentAccel,
            "maxVelo": maxVelo,
            "maxAccel": maxAccel,
            "direction": direction,
            "heading": heading,
            "isMoving": isMoving,
            "isEmergencyStop": isEmergencyStop,
            "totalDistance": totalDistance,
            "tripTime": tripTime,
            "averageSpeed": averageSpeed
        ]
    }
    
    func getMotorStatusString() -> String {
        let status = getMotorStatus()
        let pairs = status.map { "\($0.key)=\($0.value)" }
        return "MOTOR:" + pairs.joined(separator: ",")
    }
}


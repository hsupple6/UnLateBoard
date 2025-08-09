import SwiftUI
import CoreBluetooth
import Network
import SystemConfiguration.CaptiveNetwork

// MARK: - Enhanced Connection Manager (Singleton)
class ConnectionManager: ObservableObject {
    // MARK: - Singleton
    static let shared = ConnectionManager()
    
    // MARK: - Properties
    private var connection: NWConnection?
    private(set) var host: String
    private(set) var port: UInt16
    private var reconnectTimer: Timer?
    private var statusPollingTimer: Timer?
    private var heartbeatTimer: Timer?
    private let responseQueue = DispatchQueue(label: "com.app.responseQueue", qos: .userInitiated)
    private var connectionQueue = DispatchQueue(label: "com.app.connectionQueue", qos: .userInitiated)
    private var messageQueue = DispatchQueue(label: "com.app.messageQueue", qos: .userInitiated)
    
    // Command buffering and flow control
    private var commandBuffer: [String] = []
    private var isProcessingCommands = false
    private var lastCommandSent: Date?
    private let minCommandInterval: TimeInterval = 0.05 // 50ms between commands
    private let maxBufferSize = 10
    
    // MARK: - Published Properties
    @Published var isConnected: Bool = false
    @Published var receivedMessage: String = ""
    @Published var errorMessage: String?
    @Published var deviceStatus: String = "Unknown"
    @Published var lastCommand: String = "None"
    @Published var isReconnecting: Bool = false
    @Published var connectionAttempts: Int = 0
    @Published var connectionQuality: ConnectionQuality = .unknown
    @Published var lastHeartbeat: Date?
    @Published var currentWiFiSSID: String = "Unknown"
    @Published var isOnTargetNetwork: Bool = false
    
    private var messageBuffer = ""
    private var isProcessingMessage = false
    private var networkMonitor: NWPathMonitor?
    
    // MARK: - Connection Quality
    enum ConnectionQuality: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        case unknown = "Unknown"
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .yellow
            case .poor: return .red
            case .unknown: return .gray
            }
        }
    }
    
    enum ConnectionState: String {
        case disconnected
        case connecting
        case connected
        case failed
        case reconnecting
    }
    
    @Published var state: ConnectionState = .disconnected {
        didSet {
            if state == .connected {
                startStatusPollingTimer()
                startHeartbeatTimer()
            } else {
                stopStatusPollingTimer()
                stopHeartbeatTimer()
            }
        }
    }
    
    // MARK: - Initialization
    private init(host: String = AppConfig.Network.defaultHost, port: UInt16 = AppConfig.Network.defaultPort) {
        self.host = host
        self.port = port
        Logger.shared.info("ConnectionManager singleton initialized with \(host):\(port)")
        startNetworkMonitoring()
    }
    
    // Public method to update connection parameters if needed
    func updateConnectionParameters(host: String, port: UInt16) {
        if self.host != host || self.port != port {
            Logger.shared.info("Updating connection parameters from \(self.host):\(self.port) to \(host):\(port)")
            disconnect()
            self.host = host
            self.port = port
        }
    }
    
    deinit {
        disconnect()
        stopReconnectTimer()
        stopStatusPollingTimer()
        stopHeartbeatTimer()
        stopNetworkMonitoring()
    }
    
    // MARK: - Connection Management
    func connect() {
        guard state != .connecting && state != .connected else { 
            Logger.shared.warning("Connection already in progress or connected")
            return 
        }
        
        // Clear previous connection state
        disconnect()
        
        DispatchQueue.main.async {
            self.state = .connecting
            self.connectionAttempts += 1
            self.errorMessage = nil
        }
        
        Logger.shared.info("Attempting connection to \(host):\(port) (attempt \(connectionAttempts))")
        
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        parameters.acceptLocalOnly = false
        parameters.preferNoProxies = true
        
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: parameters)
        self.connection = connection
        
        // Set connection timeout
        DispatchQueue.global().asyncAfter(deadline: .now() + AppConfig.Network.connectionTimeout) { [weak self] in
            guard let self = self else { return }
            
            if self.connection?.state != .ready {
                Logger.shared.error("Connection timed out after \(AppConfig.Network.connectionTimeout) seconds")
                self.connection?.cancel()
                DispatchQueue.main.async {
                    self.isConnected = false
                    self.state = .failed
                    self.errorMessage = "Connection timed out after \(Int(AppConfig.Network.connectionTimeout)) seconds"
                }
            }
        }
        
        connection.stateUpdateHandler = { [weak self] newState in
            guard let self = self else { return }
            
            switch newState {
            case .ready:
                Logger.shared.info("Connection established successfully")
                self.connectionQueue.async {
                    self.handleSuccessfulConnection()
                }
            case .preparing:
                Logger.shared.debug("Connection preparing...")
            case .setup:
                Logger.shared.debug("Connection setup...")
            case .waiting(let error):
                Logger.shared.warning("Connection waiting: \(error.localizedDescription)")
                self.handleConnectionFailure(error: error)
            case .failed(let error):
                Logger.shared.error("Connection failed: \(error.localizedDescription)")
                self.handleConnectionFailure(error: error)
            case .cancelled:
                Logger.shared.info("Connection cancelled")
                DispatchQueue.main.async {
                    self.isConnected = false
                    self.state = .disconnected
                    self.errorMessage = "Connection cancelled"
                }
            default:
                break
            }
        }
        
        connection.viabilityUpdateHandler = { [weak self] isViable in
            guard let self = self else { return }
            
            if !isViable && self.isConnected {
                Logger.shared.warning("Connection lost viability")
                DispatchQueue.main.async {
                    self.errorMessage = "Connection lost"
                    self.isConnected = false
                    self.startReconnectProcess()
                }
            }
        }
        
        connection.betterPathUpdateHandler = { [weak self] hasBetterPath in
            if hasBetterPath {
                Logger.shared.info("A better network path is available")
                self?.refreshConnection()
            }
        }
        
        // Start the connection on a background queue
        connection.start(queue: connectionQueue)
    }
    
    private func handleSuccessfulConnection() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isConnected = true
            self.state = .connected
            self.errorMessage = nil
            self.connectionAttempts = 0
            self.isReconnecting = false
            self.connectionQuality = .excellent
            Logger.shared.info("Connected to \(self.host) on port \(self.port)")
        }
        
        // Start receiving data
        self.receive()
        
        // Request initial status after connection
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.UI.loadingDelay) { [weak self] in
            self?.fetchStatus()
        }
    }
    
    private func handleConnectionFailure(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isConnected = false
            self.errorMessage = "Connection failed: \(error.localizedDescription)"
            self.connectionQuality = .unknown
            
            if self.isReconnecting {
                if self.connectionAttempts < AppConfig.Network.maxReconnectAttempts {
                    Logger.shared.warning("Reconnection attempt \(self.connectionAttempts) failed, will retry")
                } else {
                    self.state = .failed
                    self.isReconnecting = false
                    Logger.shared.error("Max reconnection attempts reached")
                }
            } else {
                self.state = .failed
            }
        }
    }
    
    func refreshConnection() {
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.UI.loadingDelay) { [weak self] in
            self?.connect()
        }
    }
    
    private func startReconnectProcess() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isReconnecting = true
            self.state = .reconnecting
            self.startReconnectTimer()
        }
    }
    
    private func startReconnectTimer() {
        stopReconnectTimer()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.Network.reconnectInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.connectionAttempts < AppConfig.Network.maxReconnectAttempts {
                Logger.shared.info("Attempting reconnection \(self.connectionAttempts + 1)/\(AppConfig.Network.maxReconnectAttempts)")
                self.connect()
            } else {
                self.stopReconnectTimer()
                DispatchQueue.main.async {
                    self.isReconnecting = false
                    self.state = .failed
                    self.errorMessage = "Failed to reconnect after \(AppConfig.Network.maxReconnectAttempts) attempts"
                }
            }
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - Data Transmission
    func sendRawMessage(message: String) {
        guard isConnected, let connection = connection else {
            Logger.shared.warning("Cannot send message: not connected")
            DispatchQueue.main.async {
                self.errorMessage = "Cannot send message: not connected"
            }
            return
        }
        
        messageQueue.async {
            let data = Data(message.utf8)
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                if let error = error {
                    Logger.shared.error("Failed to send message: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to send message: \(error.localizedDescription)"
                        // Trigger reconnection if send fails
                        if self?.isConnected == true {
                            self?.startReconnectProcess()
                        }
                    }
                } else {
                    Logger.shared.debug("Message sent successfully: \(message.trimmingCharacters(in: .whitespacesAndNewlines))")
                    DispatchQueue.main.async {
                        self?.lastCommand = message.trimmingCharacters(in: .whitespacesAndNewlines)
                        self?.errorMessage = nil // Clear error on successful send
                    }
                }
            })
        }
    }
    
    func sendCommand(_ command: String, parameters: [String: Any] = [:]) {
        var message = command
        
        if !parameters.isEmpty {
            let paramString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
            message += " \(paramString)"
        }
        
        message += "\n"
        
        // Use buffered sending for better flow control
        bufferCommand(message)
    }
    
    private func bufferCommand(_ command: String) {
        messageQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check buffer size
            if self.commandBuffer.count >= self.maxBufferSize {
                // Remove oldest command if buffer is full
                self.commandBuffer.removeFirst()
                Logger.shared.warning("Command buffer full, dropping oldest command")
            }
            
            self.commandBuffer.append(command)
            self.processCommandBuffer()
        }
    }
    
    private func processCommandBuffer() {
        guard !isProcessingCommands && !commandBuffer.isEmpty else { return }
        
        isProcessingCommands = true
        
        // Check if enough time has passed since last command
        let now = Date()
        if let lastSent = lastCommandSent, now.timeIntervalSince(lastSent) < minCommandInterval {
            // Schedule processing after the minimum interval
            let delay = minCommandInterval - now.timeIntervalSince(lastSent)
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.continueProcessingBuffer()
            }
        } else {
            continueProcessingBuffer()
        }
    }
    
    private func continueProcessingBuffer() {
        messageQueue.async { [weak self] in
            guard let self = self, !self.commandBuffer.isEmpty else {
                self?.isProcessingCommands = false
                return
            }
            
            let command = self.commandBuffer.removeFirst()
            self.lastCommandSent = Date()
            
            // Send the command
            self.sendRawMessage(message: command)
            
            // Continue processing if there are more commands
            self.isProcessingCommands = false
            if !self.commandBuffer.isEmpty {
                self.processCommandBuffer()
            }
        }
    }
    
    // MARK: - Data Reception
    private func receive() {
        guard let connection = connection else { return }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                Logger.shared.error("Receive error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Receive error: \(error.localizedDescription)"
                }
                return
            }
            
            if let data = data, let message = String(data: data, encoding: .utf8) {
                self.processReceivedMessage(message)
            }
            
            // Continue receiving
            if self.isConnected {
                self.receive()
            }
        }
    }
    
    private func processReceivedMessage(_ message: String) {
        messageBuffer += message
        
        // Process complete messages (lines)
        while let range = messageBuffer.range(of: "\n") {
            let completeMessage = String(messageBuffer[..<range.lowerBound])
            messageBuffer.removeSubrange(..<range.upperBound)
            
            DispatchQueue.main.async {
                self.receivedMessage = completeMessage
                self.handleMessage(completeMessage)
            }
        }
    }
    
    private func handleMessage(_ message: String) {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Update connection quality based on message frequency
        updateConnectionQuality()
        
        // Handle different message types
        if trimmedMessage.hasPrefix("UART:") {
            // Handle messages forwarded from ESP32-CAM
            let uartMessage = trimmedMessage.replacingOccurrences(of: "UART: ", with: "")
            handleUARTMessage(uartMessage)
        } else if trimmedMessage.hasPrefix("WARNING:") {
            handleWarningMessage(trimmedMessage)
        } else if trimmedMessage.hasPrefix("ERROR:") {
            handleErrorMessage(trimmedMessage)
        } else if trimmedMessage == "PONG" {
            handlePongMessage()
        } else {
            // Handle direct messages
            if trimmedMessage.hasPrefix("STATUS:") {
                handleStatusMessage(trimmedMessage)
            } else if trimmedMessage.hasPrefix("MOTOR:") {
                handleMotorMessage(trimmedMessage)
            }
        }
        
        Logger.shared.debug("Received message: \(trimmedMessage)")
    }
    
    private func handleUARTMessage(_ message: String) {
        // Handle messages from Arduino via ESP32-CAM
        if message.hasPrefix("Status:") {
            handleStatusMessage("STATUS: " + message.replacingOccurrences(of: "Status:", with: ""))
        } else if message.hasPrefix("OK") {
            Logger.shared.debug("Command acknowledged by Arduino")
        } else if message.hasPrefix("PONG") {
            handlePongMessage()
        }
    }
    
    private func handleWarningMessage(_ message: String) {
        let warning = message.replacingOccurrences(of: "WARNING:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        Logger.shared.warning("System warning: \(warning)")
        DispatchQueue.main.async {
            self.errorMessage = "Warning: \(warning)"
        }
    }
    
    private func handleStatusMessage(_ message: String) {
        let status = message.replacingOccurrences(of: "STATUS:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        deviceStatus = status
    }
    
    private func handleMotorMessage(_ message: String) {
        // Parse motor data and notify motor manager
        // This will be handled by the motor manager
        Logger.shared.debug("Motor message received: \(message)")
        
        // Notify any connected motor managers
        NotificationCenter.default.post(
            name: .motorDataReceived,
            object: nil,
            userInfo: ["message": message]
        )
    }
    
    private func handleErrorMessage(_ message: String) {
        let error = message.replacingOccurrences(of: "ERROR:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = error
        Logger.shared.error("Device error: \(error)")
    }
    
    private func handlePongMessage() {
        lastHeartbeat = Date()
    }
    
    // MARK: - Status Polling
    private func startStatusPollingTimer() {
        stopStatusPollingTimer()
        statusPollingTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.Network.statusPollingInterval, repeats: true) { [weak self] _ in
            self?.fetchStatus()
        }
    }
    
    private func stopStatusPollingTimer() {
        statusPollingTimer?.invalidate()
        statusPollingTimer = nil
    }
    
    private func fetchStatus() {
        sendCommand("STATUS")
    }
    
    // MARK: - Heartbeat
    private func startHeartbeatTimer() {
        stopHeartbeatTimer()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.Network.heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func stopHeartbeatTimer() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func sendHeartbeat() {
        sendCommand("PING")
    }
    
    // MARK: - Connection Quality
    private func updateConnectionQuality() {
        // Simple implementation - can be enhanced with actual metrics
        if let lastHeartbeat = lastHeartbeat {
            let timeSinceHeartbeat = Date().timeIntervalSince(lastHeartbeat)
            if timeSinceHeartbeat < 1.0 {
                connectionQuality = .excellent
            } else if timeSinceHeartbeat < 3.0 {
                connectionQuality = .good
            } else if timeSinceHeartbeat < 5.0 {
                connectionQuality = .fair
            } else {
                connectionQuality = .poor
            }
        }
    }
    
    // MARK: - Disconnection
    func disconnect() {
        Logger.shared.info("Disconnecting from \(host):\(port)")
        
        stopReconnectTimer()
        stopStatusPollingTimer()
        stopHeartbeatTimer()
        
        connection?.cancel()
        connection = nil
        
        // Clear command buffer
        messageQueue.async {
            self.commandBuffer.removeAll()
            self.isProcessingCommands = false
        }
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.state = .disconnected
            self.isReconnecting = false
            self.connectionQuality = .unknown
            self.messageBuffer = ""
        }
    }
    
    // MARK: - Utility Methods
    func clearError() {
        errorMessage = nil
    }
    
    func getConnectionInfo() -> String {
        return "\(host):\(port) - \(state.rawValue.capitalized)"
    }
    
    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        networkMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkPathUpdate(path)
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor?.start(queue: queue)
        
        // Also check current WiFi SSID
        updateCurrentWiFiSSID()
    }
    
    private func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        Logger.shared.info("Network path updated: \(path.status)")
        
        if path.status == .satisfied && path.usesInterfaceType(.wifi) {
            updateCurrentWiFiSSID()
            
            // Auto-connect if on target network and not already connected
            if isOnTargetNetwork && !isConnected && state != .connecting {
                Logger.shared.info("On target WiFi network, auto-connecting...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.connect()
                }
            }
        } else {
            currentWiFiSSID = "No WiFi"
            isOnTargetNetwork = false
            
            if isConnected {
                Logger.shared.warning("WiFi connection lost, disconnecting...")
                disconnect()
            }
        }
    }
    
    private func updateCurrentWiFiSSID() {
        // Note: This requires iOS 14+ and proper entitlements
        // For now, we'll use a simplified approach
        let targetSSIDs = ["ESP32-CAM", "UnLateBoard", "ESP32-CAM-AP"]
        
        // In a real implementation, you'd get the actual SSID
        // For now, we'll assume if we can connect to the default host, we're on the right network
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // Simple network check by attempting to reach the host
            let testConnection = NWConnection(host: NWEndpoint.Host(self.host), 
                                            port: NWEndpoint.Port(rawValue: self.port)!, 
                                            using: .tcp)
            
            testConnection.stateUpdateHandler = { state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self.currentWiFiSSID = "ESP32-CAM" // Assume we're on the right network
                        self.isOnTargetNetwork = true
                        testConnection.cancel()
                    case .failed, .cancelled:
                        self.currentWiFiSSID = "Unknown WiFi"
                        self.isOnTargetNetwork = false
                        testConnection.cancel()
                    default:
                        break
                    }
                }
            }
            
            testConnection.start(queue: DispatchQueue.global())
            
            // Cancel test connection after 2 seconds
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                testConnection.cancel()
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let motorDataReceived = Notification.Name("motorDataReceived")
    static let connectionStateChanged = Notification.Name("connectionStateChanged")
    static let deviceStatusUpdated = Notification.Name("deviceStatusUpdated")
} 
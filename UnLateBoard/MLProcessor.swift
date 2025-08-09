import SwiftUI
import Vision
import CoreML
import AVFoundation
import Network

// MARK: - ML Processor
class MLProcessor: ObservableObject {
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var isProcessing = false
    @Published var detectedObjects: [DetectedObject] = []
    @Published var connectionStatus = "Disconnected"
    @Published var errorMessage: String?
    @Published var frameCount = 0
    @Published var fps: Double = 0.0
    
    // Enhanced diagnostic properties
    @Published var connectionIP: String = AppConfig.Network.defaultHost
    @Published var connectionPort: UInt16 = AppConfig.Network.defaultPort
    @Published var lastFrameReceived: Date?
    @Published var processingTime: TimeInterval = 0.0
    @Published var bytesReceived: Int64 = 0
    @Published var connectionAttempts: Int = 0
    @Published var reconnectAttempts: Int = 0
    @Published var modelLoadStatus: String = "Not loaded"
    
    // MARK: - Private Properties
    private var model: VNCoreMLModel?
    private var connection: NWConnection?
    private var connectionManager: ConnectionManager?
    private var processingQueue = DispatchQueue(label: "ml.processing", qos: .userInitiated)
    private var connectionQueue = DispatchQueue(label: "ml.connection", qos: .userInitiated)
    private var isViewActive = false
    private var shouldContinueReceiving = false
    private var processingLock = NSLock()
    private var isProcessingFrame = false
    
    // Performance tracking
    private var lastFrameTime: TimeInterval = 0
    private var frameTimes: [TimeInterval] = []
    private var processingStartTime: TimeInterval = 0
    
    // Connection tracking
    private var connectionStartTime: TimeInterval = 0
    private var lastHeartbeatTime: TimeInterval = 0
    
    // MARK: - Data Structures
    struct DetectedObject: Identifiable {
        let id = UUID()
        let label: String
        let confidence: Float
        let boundingBox: CGRect
        let timestamp: Date
    }
    
    struct FrameHeader {
        let magic: UInt32
        let frameSize: UInt32
        let sequence: UInt32
        let timestamp: UInt32
        
        static let size = AppConfig.ML.frameHeaderSize
    }
    
    // MARK: - Initialization
    init() {
        initializeModel()
        Logger.shared.info("MLProcessor initialized")
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    func connectToManager(_ manager: ConnectionManager) {
        connectionManager = manager
        Logger.shared.info("MLProcessor connected to ConnectionManager")
    }
    
    // Use shared connection if no explicit manager provided
    private func getConnectionManager() -> ConnectionManager? {
        return connectionManager ?? ConnectionManager.shared
    }
    
    func startStreaming() {
        guard !isConnected else { 
            Logger.shared.warning("ML streaming already active")
            return 
        }
        
        isViewActive = true
        shouldContinueReceiving = true
        
        Logger.shared.info("Starting ML streaming")
        
        connectionQueue.async {
            self.establishConnection()
        }
    }
    
    func stopStreaming() {
        Logger.shared.info("Stopping ML streaming")
        isViewActive = false
        shouldContinueReceiving = false
        cleanup()
    }
    
    func clearDetections() {
        DispatchQueue.main.async {
            self.detectedObjects.removeAll()
        }
    }
    
    // MARK: - Private Methods
    private func initializeModel() {
        processingQueue.async {
            do {
                let model = try VNCoreMLModel(for: yolov5l().model)
                DispatchQueue.main.async {
                    self.model = model
                    self.modelLoadStatus = "Loaded successfully"
                    self.updateStatus("Model loaded successfully", isError: false)
                    Logger.shared.info("ML model loaded successfully")
                }
            } catch {
                DispatchQueue.main.async {
                    self.modelLoadStatus = "Failed to load"
                    self.updateStatus("Failed to load ML model: \(error.localizedDescription)", isError: true)
                    Logger.shared.error("Failed to load ML model: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func establishConnection() {
        guard shouldContinueReceiving else { return }
        
        connectionAttempts += 1
        connectionStartTime = Date().timeIntervalSince1970
        
        let host = NWEndpoint.Host(AppConfig.Network.defaultHost)
        let port = NWEndpoint.Port(rawValue: AppConfig.Network.defaultPort)!
        
        DispatchQueue.main.async {
            self.updateStatus("Attempting connection to \(AppConfig.Network.defaultHost):\(AppConfig.Network.defaultPort) (attempt \(self.connectionAttempts))", isError: false)
        }
        
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.noDelay = true
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 30
        tcpOptions.keepaliveInterval = 15
        tcpOptions.keepaliveCount = 3
        
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = true
        
        connection = NWConnection(host: host, port: port, using: parameters)
        
        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionStateChange(state)
        }
        
        connection?.start(queue: connectionQueue)
    }
    
    private func handleConnectionStateChange(_ state: NWConnection.State) {
        DispatchQueue.main.async {
            switch state {
            case .setup:
                self.updateStatus("Setting up connection...", isError: false)
                Logger.shared.debug("ML connection setup...")
                
            case .waiting(let error):
                self.updateStatus("Waiting: \(error.localizedDescription)", isError: true)
                Logger.shared.warning("ML connection waiting: \(error.localizedDescription)")
                
            case .preparing:
                self.updateStatus("Preparing connection...", isError: false)
                Logger.shared.debug("ML connection preparing...")
                
            case .ready:
                let connectionTime = Date().timeIntervalSince1970 - self.connectionStartTime
                self.updateStatus("Connected successfully in \(String(format: "%.2f", connectionTime))s", isError: false)
                self.isConnected = true
                self.lastHeartbeatTime = Date().timeIntervalSince1970
                Logger.shared.info("ML connection established in \(String(format: "%.2f", connectionTime))s")
                self.connectionQueue.async {
                    self.startFrameReception()
                }
                
            case .failed(let error):
                self.updateStatus("Connection failed: \(error.localizedDescription)", isError: true)
                Logger.shared.error("ML connection failed: \(error.localizedDescription)")
                self.handleConnectionFailure()
                
            case .cancelled:
                self.updateStatus("Connection cancelled", isError: false)
                self.isConnected = false
                Logger.shared.info("ML connection cancelled")
                
            @unknown default:
                self.updateStatus("Unknown connection state", isError: true)
                Logger.shared.warning("ML unknown connection state")
            }
        }
    }
    
    private func handleConnectionFailure() {
        shouldContinueReceiving = false
        isConnected = false
        reconnectAttempts += 1
        
        processingLock.lock()
        isProcessingFrame = false
        processingLock.unlock()
        
        connection?.cancel()
        connection = nil
        
        DispatchQueue.main.async {
            self.updateStatus("Connection failed, attempting reconnection (\(self.reconnectAttempts))", isError: true)
        }
        
        // Attempt reconnection after delay
        if isViewActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.Network.reconnectInterval) {
                if self.isViewActive {
                    self.shouldContinueReceiving = true
                    self.connectionQueue.async {
                        self.establishConnection()
                    }
                }
            }
        }
    }
    
    private func startFrameReception() {
        guard shouldContinueReceiving && isConnected && isViewActive else { return }
        
        receiveFrameHeader()
    }
    
    private func receiveFrameHeader() {
        guard shouldContinueReceiving && isConnected && isViewActive,
              let connection = connection else { return }
        
        // Check if already processing
        processingLock.lock()
        let currentlyProcessing = isProcessingFrame
        processingLock.unlock()
        
        if currentlyProcessing {
            // Schedule next attempt
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.ML.frameInterval) {
                self.receiveFrameHeader()
            }
            return
        }
        
        connection.receive(minimumIncompleteLength: FrameHeader.size, maximumLength: FrameHeader.size) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.updateStatus("Header error: \(error.localizedDescription)", isError: true)
                    Logger.shared.error("ML frame header error: \(error.localizedDescription)")
                    self.handleConnectionFailure()
                }
                return
            }
            
            guard let data = data, data.count == FrameHeader.size else {
                DispatchQueue.main.async {
                    self.updateStatus("Invalid header", isError: true)
                    Logger.shared.error("ML invalid frame header")
                    self.handleConnectionFailure()
                }
                return
            }
            
            let header = self.parseFrameHeader(data)
            guard header.magic == AppConfig.ML.expectedMagic,
                  header.frameSize > 0,
                  header.frameSize <= UInt32(AppConfig.ML.maxFrameSize) else {
                DispatchQueue.main.async {
                    self.updateStatus("Invalid frame header", isError: true)
                    Logger.shared.error("ML invalid frame header data")
                    self.handleConnectionFailure()
                }
                return
            }
            
            self.processingLock.lock()
            self.isProcessingFrame = true
            self.processingLock.unlock()
            
            self.receiveFrameData(expectedLength: Int(header.frameSize), sequence: header.sequence, timestamp: header.timestamp)
        }
    }
    
    private func parseFrameHeader(_ data: Data) -> FrameHeader {
        let magic = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt32.self).littleEndian }
        let frameSize = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self).littleEndian }
        let sequence = data.withUnsafeBytes { $0.load(fromByteOffset: 8, as: UInt32.self).littleEndian }
        let timestamp = data.withUnsafeBytes { $0.load(fromByteOffset: 12, as: UInt32.self).littleEndian }
        
        return FrameHeader(magic: magic, frameSize: frameSize, sequence: sequence, timestamp: timestamp)
    }
    
    private func receiveFrameData(expectedLength: Int, sequence: UInt32, timestamp: UInt32) {
        guard shouldContinueReceiving && isConnected && isViewActive,
              let connection = connection else {
            finishProcessingFrame()
            return
        }
        
        connection.receive(minimumIncompleteLength: expectedLength, maximumLength: expectedLength) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.updateStatus("Frame data error: \(error.localizedDescription)", isError: true)
                    Logger.shared.error("ML frame data error: \(error.localizedDescription)")
                    self.handleConnectionFailure()
                }
                return
            }
            
            guard let data = data, data.count == expectedLength else {
                DispatchQueue.main.async {
                    self.updateStatus("Incomplete frame data", isError: true)
                    Logger.shared.error("ML incomplete frame data")
                    self.handleConnectionFailure()
                }
                return
            }
            
            self.processingQueue.async {
                self.processImageData(data, sequence: sequence, timestamp: timestamp)
            }
        }
    }
    
    private func processImageData(_ data: Data, sequence: UInt32, timestamp: UInt32) {
        processingLock.lock()
        isProcessingFrame = true
        processingLock.unlock()
        
        processingStartTime = Date().timeIntervalSince1970
        
        DispatchQueue.main.async {
            self.isProcessing = true
            self.lastFrameReceived = Date()
            self.bytesReceived += Int64(data.count)
        }
        
        guard let image = UIImage(data: data) else {
            DispatchQueue.main.async {
                self.updateStatus("Failed to create image from data", isError: true)
                Logger.shared.error("ML failed to create image from data")
            }
            finishProcessingFrame()
            return
        }
        
        guard let pixelBuffer = image.pixelBuffer(width: Int(AppConfig.ML.modelInputSize.width), height: Int(AppConfig.ML.modelInputSize.height)) else {
            DispatchQueue.main.async {
                self.updateStatus("Failed to create pixel buffer", isError: true)
                Logger.shared.error("ML failed to create pixel buffer")
            }
            finishProcessingFrame()
            return
        }
        
        runModel(on: pixelBuffer, originalImage: image)
    }
    
    private func runModel(on pixelBuffer: CVPixelBuffer, originalImage: UIImage) {
        guard let model = model else {
            DispatchQueue.main.async {
                self.updateStatus("Model not loaded", isError: true)
                Logger.shared.error("ML model not loaded")
            }
            finishProcessingFrame()
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            
            let processingTime = Date().timeIntervalSince1970 - self.processingStartTime
            
            DispatchQueue.main.async {
                self.processingTime = processingTime
                
                if let error = error {
                    self.updateStatus("Model error: \(error.localizedDescription)", isError: true)
                    Logger.shared.error("ML model error: \(error.localizedDescription)")
                } else {
                    self.processDetections(request.results as? [VNRecognizedObjectObservation] ?? [], imageSize: originalImage.size)
                    Logger.shared.debug("ML processed frame in \(String(format: "%.3f", processingTime))s")
                }
                
                self.isProcessing = false
                self.finishProcessingFrame()
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        
        processingQueue.async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.updateStatus("Model execution error: \(error.localizedDescription)", isError: true)
                    Logger.shared.error("ML model execution error: \(error.localizedDescription)")
                    self.isProcessing = false
                    self.finishProcessingFrame()
                }
            }
        }
    }
    
    private func processDetections(_ observations: [VNRecognizedObjectObservation], imageSize: CGSize) {
        var newDetections: [DetectedObject] = []
        
        for observation in observations {
            guard let topLabel = observation.labels.first,
                  topLabel.confidence > AppConfig.ML.confidenceThreshold else { continue }
            
            let detectedObject = DetectedObject(
                label: topLabel.identifier,
                confidence: topLabel.confidence,
                boundingBox: observation.boundingBox,
                timestamp: Date()
            )
            
            newDetections.append(detectedObject)
        }
        
        // Update detections on main thread
        DispatchQueue.main.async {
            self.detectedObjects = newDetections
            if !newDetections.isEmpty {
                Logger.shared.debug("ML detected \(newDetections.count) objects")
            }
        }
    }
    
    private func finishProcessingFrame() {
        processingLock.lock()
        isProcessingFrame = false
        processingLock.unlock()
        
        // Update performance metrics
        let currentTime = Date().timeIntervalSince1970
        if lastFrameTime > 0 {
            let frameTime = currentTime - lastFrameTime
            frameTimes.append(frameTime)
            if frameTimes.count > 30 {
                frameTimes.removeFirst()
            }
            fps = 1.0 / (frameTimes.reduce(0, +) / Double(frameTimes.count))
        }
        lastFrameTime = currentTime
        
        DispatchQueue.main.async {
            self.frameCount += 1
        }
        
        // Continue receiving frames
        if shouldContinueReceiving && isConnected && isViewActive {
            receiveFrameHeader()
        }
    }
    
    private func updateStatus(_ message: String, isError: Bool) {
        DispatchQueue.main.async {
            self.connectionStatus = message
            if isError {
                self.errorMessage = message
            }
        }
    }
    
    private func cleanup() {
        isViewActive = false
        shouldContinueReceiving = false
        isConnected = false
        
        processingLock.lock()
        isProcessingFrame = false
        processingLock.unlock()
        
        connection?.cancel()
        connection = nil
        
        DispatchQueue.main.async {
            self.detectedObjects.removeAll()
            self.frameCount = 0
            self.fps = 0.0
            self.isProcessing = false
            self.processingTime = 0.0
            self.bytesReceived = 0
            self.lastFrameReceived = nil
            self.updateStatus("Streaming stopped", isError: false)
        }
        
        Logger.shared.info("MLProcessor cleanup completed")
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let pxBuffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pxBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pxBuffer, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pxBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pxBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return pxBuffer
    }
} 
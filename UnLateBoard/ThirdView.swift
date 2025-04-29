import SwiftUI
import Network

// MARK: - Shared Connection Manager
class ConnectionManager: ObservableObject {
    private var connection: NWConnection?
    private var host: String
    private var port: UInt16
    
    @Published var isConnected: Bool = false
    @Published var receivedMessage: String = ""
    @Published var errorMessage: String = ""
    
    // Singleton instance for sharing across views
    static let shared = ConnectionManager(host: "10.24.202.142", port: 8080)
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }
    
    func connect() {
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
        self.connection = connection
        
        connection.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready:
                DispatchQueue.main.async {
                    self?.isConnected = true
                    self?.errorMessage = ""
                }
            case .failed(let error):
                DispatchQueue.main.async {
                    self?.errorMessage = "Connection failed: \(error.localizedDescription)"
                    self?.isConnected = false
                }
            case .cancelled:
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
            default:
                break
            }
        }
        
        connection.start(queue: .global())
    }
    
    func send(message: String) {
        guard let connection = connection, isConnected else {
            self.errorMessage = "Cannot send: not connected"
            return
        }
        
        let data = message.data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Send error: \(error.localizedDescription)"
                }
                return
            }
            print("Message sent: \(message)")
        })
    }
    
    func receive() {
        guard let connection = connection, isConnected else { return }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, let response = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.receivedMessage = response
                }
                // Continue receiving
                self?.receive()
            } else if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Receive error: \(error.localizedDescription)"
                }
            }
            
            if isComplete {
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
            }
        }
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    // Update connection settings
    func updateConnection(host: String, port: UInt16) {
        disconnect()
        self.host = host
        self.port = port
    }
}

// MARK: - Loading Circle Animation
struct LoadingCircleAnimation: View {
    @Binding var isLoading: Bool
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.blue, lineWidth: 5)
            .frame(width: 50, height: 50)
            .rotationEffect(Angle(degrees: rotation))
            .onAppear {
                if isLoading {
                    withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
            .onChange(of: isLoading) { newValue in
                if newValue {
                    withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
    }
}

struct ThirdView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var connectionState: ConnectionState = .waiting
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var navigateToControlView: Bool = false
    @State private var connectionTime: Date? = nil
    
    @StateObject private var connectionManager = ConnectionManager.shared
    
    enum ConnectionState {
        case waiting, connecting, connected, failed
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Waiting for Board Connection...")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                
                Text("Please Ensure Board is On!")
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                Group {
                    switch connectionState {
                    case .waiting:
                        Text("Ready to connect")
                            .foregroundColor(.white)
                    case .connecting:
                        LoadingCircleAnimation(isLoading: $isLoading)
                            .frame(width: 50, height: 50)
                        Text("Attempting to connect...")
                            .foregroundColor(.white)
                    case .connected:
                        VStack {
                            CheckMarkAnimation()
                            
                            Text("Connected Successfully")
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                            
                            if let connectionTime = connectionTime {
                                let timeElapsed = Date().timeIntervalSince(connectionTime)
                                let timeRemaining = max(0, 5 - timeElapsed)
                                
                                Text("Navigating to control view in \(Int(timeRemaining)) seconds...")
                                    .foregroundColor(.white)
                                    .padding(.top, 10)
                            }
                            
                            // Navigation link
                            NavigationLink(destination: ControlView(connectionManager: connectionManager), isActive: $navigateToControlView) {
                                EmptyView()
                            }
                        }
                    case .failed:
                        VStack {
                            CrossAnimation()
                            Text("Connection Failed")
                                .foregroundColor(.red)
                                .fontWeight(.bold)
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        initiateConnection()
                    }) {
                        Text("Connect")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding()
                            .frame(width: 150)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .disabled(connectionState == .connecting)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Back")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 150)
                            .background(Color.gray)
                            .cornerRadius(10)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding()
        }
        .navigationBarHidden(true)
        .onAppear {
            isLoading = true
        }
        // This onReceive will check time elapsed since connection and navigate after 5 seconds
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            if connectionState == .connected,
               let connectionTime = connectionTime,
               Date().timeIntervalSince(connectionTime) >= 5 {
                navigateToControlView = true
            }
        }
        .onReceive(connectionManager.$isConnected) { connected in
            if connected {
                connectionState = .connected
                connectionTime = Date()
                isLoading = false
                
                // Start listening for incoming messages
                connectionManager.receive()
            }
        }
        .onReceive(connectionManager.$errorMessage) { error in
            if !error.isEmpty {
                connectionState = .failed
                errorMessage = error
                isLoading = false
            }
        }
    }
    
    func initiateConnection() {
        connectionState = .connecting
        isLoading = true
        connectionManager.connect()
        
        // Set timeout for connection attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if connectionState == .connecting {
                connectionState = .failed
                errorMessage = "Connection timed out. Please try again."
                isLoading = false
            }
        }
    }
}

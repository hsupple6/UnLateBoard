import SwiftUI
import Network

struct ThirdView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var connectionState: ConnectionState = .waiting
    @State private var receivedMessage: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var navigateToControlView: Bool = false
    @State private var connectionTime: Date? = nil
    
    @StateObject private var connectionManager = ConnectionManager(host: "10.24.202.142", port: 8080)
    
    enum ConnectionState {
        case waiting, connecting, connected, failed
    }
    
    var body: some View {
        ZStack {
            // Full black background
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
                
                // Connection status
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
                            NavigationLink(destination: ControlView(), isActive: $navigateToControlView) {
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
    }
    
    func initiateConnection() {
        connectionState = .connecting
        isLoading = true
        
        Task {
            await sendControlCommand(
                command: "START_MOTOR",
                updateState: { state in
                    connectionState = state
                    
                    // If we just connected, set the connection time
                    if state == .connected {
                        connectionTime = Date()
                    }
                },
                updateMessage: { message in
                    receivedMessage = message
                },
                updateError: { error in
                    errorMessage = error
                    isLoading = false
                }
            )
        }
    }
}

struct LoadingCircleAnimation: View {
    @Binding var isLoading: Bool
    
    @State private var whiteProgress: CGFloat = 0
    @State private var blackProgress: CGFloat = 0
    @State private var animationCycle = true
            
    var body: some View {
        ZStack {
            // White part of the circle
            Circle()
                .trim(from: 0, to: whiteProgress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))
            
            // Black part of the circle
            if whiteProgress >= 1 {
                Circle()
                    .trim(from: 0, to: blackProgress)
                    .stroke(Color.black, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
            }
        }
        .onAppear {
            if isLoading {
                animateCircle()
            }
        }
        .onChange(of: isLoading) { newValue in
            if newValue {
                animateCircle()
            } else {
                // Reset animation when stopped
                whiteProgress = 0
                blackProgress = 0
                animationCycle = false
            }
        }
    }

    func animateCircle() {
        // Don't continue if loading is false
        if !isLoading {
            return
        }
        
        animationCycle = true
        
        // Animate the white circle
        withAnimation(Animation.easeOut(duration: 1.2)) {
            whiteProgress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if animationCycle {
                withAnimation(Animation.easeOut(duration: 1.2)) {
                    blackProgress = 1.0
                }
            }
        }
        
        // Reset and loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if animationCycle && isLoading {
                whiteProgress = 0
                blackProgress = 0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if isLoading {
                        animateCircle() // Only restart if still loading
                    }
                }
            }
        }
    }
}

func sendControlCommand(
    command: String,
    host: String = "10.24.202.142",
    port: UInt16 = 8080,
    updateState: @escaping (ThirdView.ConnectionState) -> Void,
    updateMessage: @escaping (String) -> Void,
    updateError: @escaping (String) -> Void
) async {
    // Create a connection to the host
    let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
    
    // Create a semaphore to manage async operations
    let semaphore = DispatchSemaphore(value: 0)
    var didReceiveResponse = false
    var didTimeout = false
    
    // Update state to connecting on main thread
    DispatchQueue.main.async {
        updateState(.connecting)
    }
    
    // Set up state handler
    connection.stateUpdateHandler = { newState in
        switch newState {
        case .ready:
            print("Connection established, sending command")
            let data = command.data(using: .utf8)!
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("Error sending command: \(error)")
                    DispatchQueue.main.async {
                        updateError("Failed to send command: \(error.localizedDescription)")
                        updateState(.failed)
                    }
                    semaphore.signal()
                    return
                }
                print("Command '\(command)' sent successfully")
                // Start receiving response
                receiveResponse()
            })
            
        case .failed(let error):
            print("Connection failed: \(error)")
            DispatchQueue.main.async {
                updateError("Connection failed: \(error.localizedDescription)")
                updateState(.failed)
            }
            semaphore.signal()
            
        case .cancelled:
            print("Connection cancelled")
            if !didReceiveResponse && !didTimeout {
                DispatchQueue.main.async {
                    updateError("Connection cancelled")
                    updateState(.failed)
                }
            }
            semaphore.signal()
            
        default:
            break
        }
    }
    
    // Function to receive response data
    func receiveResponse() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data = data, let response = String(data: data, encoding: .utf8) {
                print("Received response: \(response)")
                didReceiveResponse = true
                DispatchQueue.main.async {
                    updateMessage(response)
                    updateState(.connected)
                }
                semaphore.signal()
            } else if let error = error {
                print("Error receiving response: \(error)")
                DispatchQueue.main.async {
                    updateError("Error receiving response: \(error.localizedDescription)")
                    updateState(.failed)
                }
                semaphore.signal()
            } else if isComplete {
                if !didReceiveResponse {
                    print("Connection closed without response")
                    DispatchQueue.main.async {
                        updateError("Connection closed without response")
                        updateState(.failed)
                    }
                }
                semaphore.signal()
            }
        }
    }
    
    // Start the connection
    connection.start(queue: .global())
    
    // Set a timeout
    DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
        if !didReceiveResponse {
            didTimeout = true
            print("Connection timed out")
            DispatchQueue.main.async {
                updateError("Connection timed out after 10 seconds")
                updateState(.failed)
            }
            connection.cancel()
            semaphore.signal()
        }
    }
    
    // Wait for the operation to complete
    semaphore.wait()
    
    // Close the connection when done
    if connection.state != .cancelled {
        connection.cancel()
    }
}

class ConnectionManager: ObservableObject {
    private var connection: NWConnection?
    private var host: String
    private var port: UInt16
    
    @Published var isConnected: Bool = false
    @Published var receivedMessage: String = ""
    @Published var errorMessage: String = ""
    
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
                }
            case .failed(let error):
                DispatchQueue.main.async {
                    self?.errorMessage = "Connection failed: \(error.localizedDescription)"
                    self?.isConnected = false
                }
            default:
                break
            }
        }
        
        connection.start(queue: .global())
    }
    
    func send(message: String) {
        guard let connection = connection else { return }
        let data = message.data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Send error: \(error.localizedDescription)"
                }
                return
            }
            print("Message sent: \(message)")
        })
    }
    
    func receive() {
        guard let connection = connection else { return }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, let response = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.receivedMessage = response
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Receive error: \(error.localizedDescription)"
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
}

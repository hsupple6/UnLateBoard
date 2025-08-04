import SwiftUI
import CoreBluetooth
import Network

// MARK: - UI Components

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
    @StateObject private var connectionManager = ConnectionManager()
    @State private var animate = false
    @State private var navigateToControlView = true // change to false!
    @State private var showConnectionDetails = false
    @State private var customHost = "192.168.4.1"
    @State private var customPort = "3333"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch connectionManager.state {
            case .connecting:
                connectingView
                
            case .connected:
                connectedView
                
            case .failed:
                failedView
                
            case .disconnected:
                disconnectedView
                
            case .reconnecting:
                connectingView
            }
        }
        
        .onReceive(connectionManager.$isConnected) { isConnected in
            if isConnected {
                navigateToControlView = true
            }
        }
        
        .onAppear {
            connectionManager.state = .connected
        }
    }
    
    // MARK: - View Components
    
    private var connectingView: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(Color.green)
                .frame(width: 100, height: 100)
                .scaleEffect(animate ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)
            
            Text("Connecting...")
                .foregroundColor(.white)
                .font(.title2)
                .bold()
            
            if let errorMessage = connectionManager.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.orange)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if connectionManager.isReconnecting {
                Text("Reconnect attempt \(connectionManager.connectionAttempts)/\(5)")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
            }
        }
        .onAppear {
            animate = true
            connectionManager.connect()
        }
    }
    
    private var connectedView: some View {
        ZStack {
            VStack(spacing: 20) {
                CheckMarkAnimation()
                
                Text("Connected!")
                    .foregroundColor(.white)
                    .font(.title2)
                    .bold()
                
                Text("Device Status: \(connectionManager.deviceStatus)")
                    .foregroundColor(.green)
                    .font(.subheadline)
            }
            
            NavigationLink(
                destination: ControlView(ConnectionManager: connectionManager, dir: .constant(false)),
                isActive: $navigateToControlView
            ) {
                EmptyView()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                navigateToControlView = true
            }
        }
    }
    
    private var failedView: some View {
        VStack(spacing: 20) {
            CrossAnimation()
            
            Text("Connection Failed")
                .foregroundColor(.white)
                .font(.title2)
                .bold()
                .padding()
            
            if let errorMessage = connectionManager.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                /*connectionManager.state = .connecting
                connectionManager.connect()*/  // REDO THIS SJHIT
                
                connectionManager.state = .connected

            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 250, height: 60)
                        .foregroundColor(.white)
                    
                    Text("Retry Connection")
                        .frame(width: 250, height: 60)
                        .foregroundColor(.black)
                        .font(.title3)
                        .bold()
                }
            }
            .padding(.bottom, 8)
             
        }
    }
    
    private var disconnectedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            Text("Disconnected")
                .foregroundColor(.white)
                .font(.title2)
                .bold()
                .padding()
            
            Button(action: {
                connectionManager.state = .connecting
                connectionManager.connect()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 250, height: 60)
                        .foregroundColor(.white)
                    
                    Text("Connect")
                        .frame(width: 250, height: 60)
                        .foregroundColor(.black)
                        .font(.title3)
                        .bold()
                }
            }
        }
    }
}

import SwiftUI
import AVFoundation
import Foundation
import MapKit

var place: MKMapItem? = nil

// MARK: - Live Data Bar Component
struct LiveDataBar: View {
    var title: String
    var value: Double
    var maxValue: Double
    var unit: String
    var color: Color
    var width: CGFloat = 40
    var height: CGFloat = 200
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: width/2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: width, height: height)
                
                // Fill
                RoundedRectangle(cornerRadius: width/2)
                    .fill(color)
                    .frame(
                        width: width,
                        height: max(width, height * CGFloat(value / maxValue))
                    )
            }
            
            VStack(spacing: 2) {
                Text("\(Int(value))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Turning Angle Display
struct TurningAngleDisplay: View {
    var angle: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Steering")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                // Angle indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 3, height: 25)
                    .offset(y: -12)
                    .rotationEffect(.degrees(angle))
            }
            
            Text("\(Int(angle))°")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Virtual Joystick
struct VirtualJoystick: View {
    @Binding var xValue: Double
    @Binding var yValue: Double
    let size: CGFloat = 200
    let knobSize: CGFloat = 60
    
    @State private var isDragging = false
    @State private var knobPosition = CGPoint.zero
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: size, height: size)
            
            // Inner guidelines
            Circle()
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                .frame(width: size * 0.6, height: size * 0.6)
            
            // Center lines
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 1, height: size)
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: size, height: 1)
            
            // Knob
            Circle()
                .fill(Color.white)
                .frame(width: knobSize, height: knobSize)
                .shadow(radius: 8)
                .offset(x: knobPosition.x, y: knobPosition.y)
                .animation(.spring(response: 0.3), value: knobPosition)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    let center = CGPoint.zero
                    let deltaX = value.location.x - size/2
                    let deltaY = value.location.y - size/2
                    let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
                    let maxRadius = (size - knobSize) / 2
                    
                    if distance <= maxRadius {
                        knobPosition = CGPoint(x: deltaX, y: deltaY)
                    } else {
                        let angle = atan2(deltaY, deltaX)
                        knobPosition = CGPoint(
                            x: cos(angle) * maxRadius,
                            y: sin(angle) * maxRadius
                        )
                    }
                    
                    // Convert to command values
                    xValue = (knobPosition.x / maxRadius) * 125
                    yValue = -(knobPosition.y / maxRadius) * 250 // Invert Y
                }
                .onEnded { _ in
                    isDragging = false
                    knobPosition = .zero
                    xValue = 0
                    yValue = 0
                }
        )
    }
}

// MARK: - Settings Dropdown
struct SettingsDropdown: View {
    @Binding var maxSpeed: Double
    @Binding var maxAcceleration: Double
    @State private var isExpanded = false
    
    let speedOptions = [10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 50.0]
    let accelOptions = [5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
    
    var body: some View {
        VStack {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white)
                    Text("Settings")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
            }
            
            if isExpanded {
                VStack(spacing: 15) {
                    // Max Speed
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Max Speed: \(Int(maxSpeed)) mph")
                            .foregroundColor(.white)
                            .font(.subheadline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                            ForEach(speedOptions, id: \.self) { speed in
                                Button("\(Int(speed))") {
                                    maxSpeed = speed
                                }
                                .foregroundColor(maxSpeed == speed ? .black : .white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(maxSpeed == speed ? Color.green : Color.gray.opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Max Acceleration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Max Acceleration: \(Int(maxAcceleration))")
                            .foregroundColor(.white)
                            .font(.subheadline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(accelOptions, id: \.self) { accel in
                                Button("\(Int(accel))") {
                                    maxAcceleration = accel
                                }
                                .foregroundColor(maxAcceleration == accel ? .black : .white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(maxAcceleration == accel ? Color.orange : Color.gray.opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(10)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

// MARK: - Updated Control View
struct ControlView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var ConnectionManager: ConnectionManager
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var navigationState: NavigationStateManager
    @EnvironmentObject var motorManager: MotorManagement
    @EnvironmentObject var mlProcessor: MLProcessor
    @StateObject private var locationHandler = LocationHandler()
    
    // Joystick values
    @State private var joystickX: Double = 0
    @State private var joystickY: Double = 0
    
    // Live data
    @State private var currentSpeed: Double = 0
    @State private var currentAcceleration: Double = 0
    @State private var turningAngle: Double = 0
    
    // Settings (frontend only)
    @State private var maxSpeed: Double = 25.0
    @State private var maxAcceleration: Double = 8.0
    
    // Control buttons
    @State private var isSet1: Bool = false
    @State private var isSet2: Bool = false
    @State private var isSet3: Bool = false
    @State private var isSet4: Bool = false
    @State private var isSet5: Bool = false
    @State private var isSet6: Bool = false
    @Binding var dir: Bool
    
    // Auto-kill flag
    @State private var autoKillEnabled: Bool = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 15) {
                    // Top Header with Settings Dropdown
                    VStack(spacing: 10) {
                        HStack {
                            // Connection Status
                            Circle()
                                .fill(ConnectionManager.isConnected ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            Text(ConnectionManager.isConnected ? "Connected" : "Disconnected")
                                .font(.caption)
                                .foregroundColor(ConnectionManager.isConnected ? .green : .red)
                            
                            Spacer()
                            
                            // Auto-kill indicator
                            HStack(spacing: 4) {
                                Image(systemName: autoKillEnabled ? "shield.checkered" : "shield.slash")
                                    .foregroundColor(autoKillEnabled ? .green : .orange)
                                Text("Auto-Kill")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Button("Back") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.white)
                            .font(.headline)
                        }
                        
                        // Settings Dropdown
                        SettingsDropdown(maxSpeed: $maxSpeed, maxAcceleration: $maxAcceleration)
                    }
                    .padding(.horizontal)
                    
                    // Navigation Banner
                    if navigationState.isNavigating {
                        DirectionsBanner()
                            .environmentObject(navigationState)
                    }
                    
                    // Main Control Section - Joystick at Top
                    VStack(spacing: 20) {
                        // Joystick with Side Data
                        HStack(spacing: 30) {
                            // Left Side - Current Acceleration
                            LiveDataBar(
                                title: "Accel",
                                value: currentAcceleration,
                                maxValue: maxAcceleration,
                                unit: "m/s²",
                                color: .orange
                            )
                            
                            // Center - Virtual Joystick
                            VStack(spacing: 15) {
                                Text("Manual Control")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                VirtualJoystick(xValue: $joystickX, yValue: $joystickY)
                                    .onChange(of: joystickX) { _ in sendJoystickCommand() }
                                    .onChange(of: joystickY) { _ in sendJoystickCommand() }
                                
                                // Turning Angle Display
                                TurningAngleDisplay(angle: turningAngle)
                            }
                            
                            // Right Side - Current Speed
                            LiveDataBar(
                                title: "Speed",
                                value: currentSpeed,
                                maxValue: maxSpeed,
                                unit: "mph",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                        
                        // Autopilot Section
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                
                                Text("AUTOPILOT")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Toggle("", isOn: $motorManager.isAutopilotEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .purple))
                                .scaleEffect(1.2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(motorManager.isAutopilotEnabled ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(motorManager.isAutopilotEnabled ? Color.purple : Color.gray, lineWidth: 2)
                                )
                        )
                        
                        if motorManager.isAutopilotEnabled {
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Autopilot Active - ML Processing Enabled")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // ML Processing Status
                            HStack {
                                Circle()
                                    .fill(mlProcessor.isConnected ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text("ML: \(mlProcessor.isConnected ? "Connected" : "Disconnected")")
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
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    // Remove old board info text

                    // Navigation Display Section
                    if navigationState.isNavigating {
                        NavigationDisplayView()
                            .environmentObject(navigationState)
                            .environmentObject(locationHandler)
                    }
                    
                    // Control Buttons Section
                    VStack(spacing: 20) {
                        Text("Control Functions")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                        // First Column
                        VStack(spacing: 40) {
                            // Light Button
                            ControlButton(isActive: isSet1) {
                                isSet1.toggle()
                                ConnectionManager.sendRawMessage(message: "FL \(isSet1 ? "1" : "0")\n")
                            } content: {
                                VStack {
                                    if (isSet1) {
                                        LightAnim()
                                    } else {
                                        HStack {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.white)
                                                .frame(width: 3, height: 20)
                                                .rotationEffect(Angle(degrees: -30))
                                            
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.white)
                                                .frame(width: 3, height: 20)
                                            
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.white)
                                                .frame(width: 3, height: 20)
                                                .rotationEffect(Angle(degrees: 30))
                                        }
                                    }
                                    
                                    ZStack {
                                        VStack(spacing: 0) {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white)
                                                .frame(width: 30, height: 5)
                                            
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.white)
                                                    .frame(width: 25, height: 5)
                                                
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.white)
                                                    .frame(width: 25, height: 5)
                                                    .offset(y: -2.5)
                                            }
                                            
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.white)
                                                    .frame(width: 15, height: 15)
                                                
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.white)
                                                    .frame(width: 15, height: 10)
                                                    .offset(y: -5.0)
                                            }
                                        }
                                        
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color.gray)
                                                .opacity(0.2)
                                                .frame(width: 5, height: 10)
                                            
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color.black)
                                                .frame(width: 4, height: 4)
                                                .offset(y: isSet1 ? -3 : 3)
                                        }
                                    }
                                }
                            }
                            
                            // Lock Button
                            ControlButton(isActive: isSet2) {
                                isSet2.toggle()
                                ConnectionManager.sendRawMessage(message: "LK \(isSet2 ? "1" : "0")\n")
                            } content: {
                                VStack {
                                    if (isSet2) {
                                        LockAnim()
                                    } else {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 20, height: 20)
                                                .offset(y: -7.5)
                                            
                                            Rectangle()
                                                .fill(Color.white)
                                                .frame(width: 20, height: 15)
                                            
                                            Circle()
                                                .fill(Color.black)
                                                .frame(width: 10, height: 10)
                                                .offset(y: -7.5)
                                            
                                            Rectangle()
                                                .fill(Color.black)
                                                .frame(width: 10, height: 15)
                                            
                                            Circle()
                                                .fill(Color.gray)
                                                .frame(width: 10, height: 10)
                                                .offset(y: -7.5)
                                                .opacity(0.2)
                                            
                                            Rectangle()
                                                .fill(Color.gray)
                                                .frame(width: 10, height: 15)
                                                .opacity(0.2)
                                        }
                                    }
                                    
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.white)
                                        .frame(width: 30, height: 20)
                                }
                            }
                        }
                        
                        // Second Column
                        VStack(spacing: 40) {
                            // Button 3
                            ControlButton(isActive: isSet3) {
                                isSet3.toggle()
                            } content: {
                                Text("3")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            ControlButton(isActive: isSet4) {
                                isSet4.toggle()
                            } content: {
                                Text("4")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            NavigationLink(
                                destination: LiveClassificationView(),
                                isActive: $isSet4
                            ) {
                                EmptyView()
                            }
                        }
                        
                        VStack(spacing: 40) {
                            ControlButton(isActive: isSet5) {
                                isSet5.toggle()
                            } content: {
                                    ZStack {
                                        Circle()
                                            .foregroundColor(.white)
                                            .frame(width: 60, height: 60)
                                        
                                        Circle()
                                            .foregroundColor(.black)
                                            .frame(width: 50, height: 50)
                                        
                                        ZStack {
                                            Circle()
                                                .foregroundColor(.white)
                                                .frame(width: 20, height: 20)
                                            
                                            Rectangle()
                                                .foregroundColor(.white)
                                                .frame(width: 55, height: 5)
                                            Rectangle()
                                                .foregroundColor(.white)
                                                .frame(width: 5, height: 30)
                                                .offset(y: 10)
                                        }
                                    }
                            }
                            
                            NavigationLink(
                                destination: MapsView()
                                    .environmentObject(navigationState), // Pass the navigation state
                                isActive: $isSet6
                            ) {
                                EmptyView()
                            }
                            
                            // Button 6 - Maps
                            ControlButton(isActive: isSet6) {
                                isSet6.toggle()
                            } content: {
                                Image(systemName: "map")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                if (navigationState.isNavigating && motorManager.heading != navigationState.startHeading && !dir) {
                    PointSkateboardView(dir: $dir)
                }
            }
            NavigationLink(destination: ManualView(ConnectionManager: ConnectionManager), isActive: $isSet5) {
                EmptyView()
            }
            .onAppear {
                requestCameraPermission()
            }
            .hidden()
            .navigationBarHidden(true)
        }
        .onReceive(ConnectionManager.$isConnected) { isConnected in
            // Auto-kill motor when disconnected
            if autoKillEnabled && !isConnected {
                sendEmergencyStop()
            }
        }
    }
    
    // MARK: - Helper Functions
    private func sendJoystickCommand() {
        guard ConnectionManager.isConnected else { return }
        let command = "X \(Int(joystickX)) Y \(Int(joystickY))"
        ConnectionManager.sendRawMessage(message: "\(command)\n")
        
        // Update live data displays
        turningAngle = joystickX / 2 // Updated calculation per your Arduino change
        // You can add more live data updates here based on feedback from Arduino
    }
    
    private func sendEmergencyStop() {
        ConnectionManager.sendRawMessage(message: "X 0 Y 0\n")
    }
}

struct PointSkateboardView: View {
    @StateObject private var locationManager = CompassLocationManager()
    
    // Simulated values - replace with actual NavigationParallel.startheading and motorControl.heading
    @State private var startheading: Double = 45.0 // Target heading
    @State private var motorControlHeading: Double = 0.0 // Current skateboard heading
    @Binding var dir: Bool
    
    private var headingDifference: Double {
        let diff = abs(startheading - locationManager.heading)
        return min(diff, 360 - diff)
    }
    
    private var isAligned: Bool {
        headingDifference < 5.0 // Within 5 degrees
    }
    
    private var alignmentColor: Color {
        if isAligned {
            return .green
        } else if headingDifference < 15.0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                colors: [
                    Color.black.opacity(0.8),
                    Color.black
                ],
                center: .center,
                startRadius: 100,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Title
                Text("SKATEBOARD COMPASS")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .opacity(0.9)
                
                // Main compass view
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [alignmentColor, alignmentColor.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                        .frame(width: 280, height: 280)
                        .shadow(color: alignmentColor.opacity(0.5), radius: 20)
                    
                    // Direction markers (N, E, S, W)
                    ForEach(0..<4) { index in
                        let angle = Double(index) * 90
                        let label = ["N", "E", "S", "W"][index]
                        
                        Text(label)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .offset(y: -120)
                            .rotationEffect(.degrees(angle))
                            .rotationEffect(.degrees(-angle)) // Counter-rotate text
                    }
                    
                    // Degree markers
                    ForEach(0..<36) { index in
                        let angle = Double(index) * 10
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 2, height: index % 3 == 0 ? 20 : 10)
                            .offset(y: -130)
                            .rotationEffect(.degrees(angle))
                    }
                    
                    // Target heading indicator (startheading)
                    ZStack {
                        // Target arrow
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan, radius: 10)
                            .offset(y: -100)
                            .rotationEffect(.degrees(startheading))
                        
                        // Target ring
                        Circle()
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 3)
                            .frame(width: 200, height: 200)
                    }
                    
                    // Current heading indicator (device/skateboard)
                    ZStack {
                        // Skateboard icon
                        Image(systemName: "skateboard")
                            .font(.system(size: 25))
                            .foregroundColor(alignmentColor)
                            .shadow(color: alignmentColor, radius: 8)
                            .offset(y: -80)
                            .rotationEffect(.degrees(locationManager.heading))
                        
                        // Current heading line
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [alignmentColor, alignmentColor.opacity(0.0)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 4, height: 80)
                            .offset(y: -40)
                            .rotationEffect(.degrees(locationManager.heading))
                    }
                    
                    // Center dot
                    Circle()
                        .fill(alignmentColor)
                        .frame(width: 12, height: 12)
                        .shadow(color: alignmentColor, radius: 8)
                }
                .rotationEffect(.degrees(-locationManager.heading)) // Rotate entire compass so north stays up
                
                // Status information
                VStack(spacing: 15) {
                    // Alignment status
                    HStack {
                        Image(systemName: isAligned ? "checkmark.circle.fill" : "location.circle")
                            .font(.system(size: 20))
                            .foregroundColor(alignmentColor)
                        
                        Text(isAligned ? "ALIGNED" : "ALIGN SKATEBOARD")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(alignmentColor)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(alignmentColor.opacity(0.5), lineWidth: 2)
                            )
                    )
                    
                    // Heading information
                    HStack(spacing: 40) {
                        VStack {
                            Text("TARGET")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(Int(startheading))°")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        
                        VStack {
                            Text("CURRENT")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(Int(locationManager.heading))°")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        VStack {
                            Text("DIFF")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(Int(headingDifference))°")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(alignmentColor)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.6))
                    )
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
    }
}

// Location Manager for compass functionality
class CompassLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var heading: Double = 0.0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy > 0 {
            DispatchQueue.main.async {
                self.heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            }
        }
    }
}

#Preview {
    PointSkateboardView(dir: .constant(false))
}

// MARK: - Navigation Display Component
struct NavigationDisplayView: View {
    @EnvironmentObject var navigationState: NavigationStateManager
    @EnvironmentObject var locationHandler: LocationHandler
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "location.north.fill")
                    .foregroundColor(.blue)
                Text("Navigation Active")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                
                Button("Stop") {
                    navigationState.stopNavigation()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            
            // Destination Info
            if let destination = navigationState.destination {
                HStack {
                    VStack(alignment: .leading) {
                        Text("To: \(destination.name ?? "Unknown")")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("ETA: \(navigationState.totalDuration)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("\(navigationState.currentDirections.count - navigationState.currentStepIndex) steps left")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
            }
            
            // Current Step
            if let currentStep = navigationState.currentStep {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: directionIcon(for: currentStep.instruction))
                            .foregroundColor(.blue)
                            .frame(width: 16)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentStep.instruction)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text(currentStep.distance)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(currentStep.duration)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
            } else if navigationState.currentStepIndex >= navigationState.currentDirections.count {
                Text("🎉 You have arrived!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
            }
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .padding(.horizontal)
        .onReceive(Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()) { _ in
            // Check if we're near the current step
            if let currentStep = navigationState.currentStep {
                if locationHandler.isNear(to: currentStep.coordinate, within: 50.0) {
                    navigationState.advanceToNextStep()
                }
            }
        }
    }
    
    private func directionIcon(for instruction: String) -> String {
        switch instruction.lowercased() {
        case let str where str.contains("left"):
            return "arrow.turn.up.left"
        case let str where str.contains("right"):
            return "arrow.turn.up.right"
        case let str where str.contains("straight"):
            return "arrow.up"
        default:
            return "location.fill"
        }
    }
}

// Directions Banner for navigation instructions
struct DirectionsBanner: View {
    @EnvironmentObject var navigationState: NavigationStateManager
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.north.fill")
                    .foregroundColor(.blue)
                Text("Navigation Active")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("Stop") {
                    navigationState.stopNavigation()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(.horizontal, 8)
            if let destination = navigationState.destination {
                HStack {
                    VStack(alignment: .leading) {
                        Text("To: \(destination.name ?? "Unknown")")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("ETA: \(navigationState.totalDuration)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("\(navigationState.currentDirections.count - navigationState.currentStepIndex) steps left")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
            }
            if let currentStep = navigationState.currentStep {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: directionIcon(for: currentStep.instruction))
                            .foregroundColor(.blue)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentStep.instruction)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            HStack {
                                Text(currentStep.distance)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(currentStep.duration)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                }
            } else if navigationState.currentStepIndex >= navigationState.currentDirections.count {
                Text("🎉 You have arrived!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
            }
        }
        .background(BlurView(style: .systemMaterialDark))
        .cornerRadius(12)
        .padding(.horizontal, 8)
        .padding(.top, 2)
    }
    func directionIcon(for instruction: String) -> String {
        switch instruction.lowercased() {
        case let str where str.contains("left"): return "arrow.turn.up.left"
        case let str where str.contains("right"): return "arrow.turn.up.right"
        case let str where str.contains("straight"): return "arrow.up"
        default: return "location.fill"
        }
    }
}

// Helper for blur effect
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct SteeringAnim: View {
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        
        ZStack {
            Circle()
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
            
            Circle()
                .foregroundColor(.black)
                .frame(width: 50, height: 50)
            

            ZStack {
                Circle()
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                
                Rectangle()
                    .foregroundColor(.white)
                    .frame(width: 55, height: 5)
                Rectangle()
                    .foregroundColor(.white)
                    .frame(width: 5, height: 30)
                    .offset(y: 10)
            }
                
        }
        .rotationEffect(Angle(degrees: animationProgress))
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animationProgress = 1.0
            }
        }
    }
}

struct LightAnim: View {
    @State private var animationProgress: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            HStack {
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 3, height: 20)
                    .rotationEffect(Angle(degrees: -30))
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 3, height: 20)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 3, height: 20)
                    .rotationEffect(Angle(degrees: 30))
                
                }
            
            HStack {
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.yellow)
                    .frame(width: 3, height: 20)
                    .rotationEffect(Angle(degrees: -30))
                    .opacity(opacity)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.yellow)
                    .frame(width: 3, height: 20)
                    .opacity(opacity)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.yellow)
                    .frame(width: 3, height: 20)
                    .rotationEffect(Angle(degrees: 30))
                    .opacity(opacity)

                }
        }
        
        .onAppear {
            withAnimation(Animation.easeIn(duration: 0.3)) {
                animationProgress = -130
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(Animation.easeIn(duration: 0.4)) {
                        animationProgress = 130
                    
                }
            }
        }
    }
}

struct LockAnim: View {
    @State private var animationProgress: CGFloat = 0
    @State private var height: Double = 0
    
    var body: some View {
        
        ZStack {
            
            VStack {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .offset(y: -7.5)
                    ZStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 20, height: 15)
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 20, height: 5)
                            .offset(y:5)
                            .opacity(animationProgress)
                    }

                    Circle()
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                        .offset(y: -7.5)

                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 10, height: 15)
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .offset(y: -7.5)
                        .opacity(0.75)

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 15)
                        .opacity(0.75)



                }
                
            }
            
        }
        .offset(y: height)
        
        .onAppear {
            withAnimation(Animation.easeIn(duration: 0.3)) {
                height = -2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(Animation.easeIn(duration: 0.4)) {
                        height = 12
                        animationProgress = 1
                    
                }
            }
        }
    }
}
    
struct ControlButton: View {
    var isActive: Bool
    var action: () -> Void
    var content: AnyView
    
    init(isActive: Bool, action: @escaping () -> Void, @ViewBuilder content: () -> some View) {
        self.isActive = isActive
        self.action = action
        self.content = AnyView(content())
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? Color.blue : Color.gray)
                    .frame(width: 75, height: 75)
                    .opacity(isActive ? 0.75 : 0.2)
                
                content
            }
        }
    }
}

struct ControlView_Previews: PreviewProvider {
    @State static var dirPreview = false

    static var previews: some View {
        ControlView(ConnectionManager: ConnectionManager.shared, dir: $dirPreview)
    }
}

func requestCameraPermission() {
    AVCaptureDevice.requestAccess(for: .video) { response in
    }
}

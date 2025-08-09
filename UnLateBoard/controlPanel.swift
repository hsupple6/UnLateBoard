import SwiftUI
import AVFoundation
import Foundation
import MapKit

var place: MKMapItem? = nil
// Separate component for the vertical slider
struct ThickVerticalSlider: View {
    var sliderWidth: CGFloat
    var sliderHeight: CGFloat
    var isDrag: Bool

    var range: ClosedRange<Double>
    var onEditingChanged: (Bool) -> Void = { _ in }
    
    // Customizable properties

    var thumbSize: CGFloat = 28
    var backgroundColor: Color = Color(.systemGray5)
    var fillColor: Color = .blue
    var thumbColor: Color = .white
    
    // Private state
    @Binding var value: Double
    @State var h: CGFloat = 0
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background track
                RoundedRectangle(cornerRadius: sliderWidth/2)
                    .fill(backgroundColor)
                    .frame(width: sliderWidth, height: sliderHeight)
                
                
                // Filled portion
                RoundedRectangle(cornerRadius: sliderWidth/2)
                    .fill(fillColor)
                    .frame(
                        width: sliderWidth,
                        height: (sliderHeight * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) >= sliderWidth ? sliderHeight * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) : sliderWidth)
                    )

            }
            .frame(width: sliderWidth, height: sliderHeight)
            .gesture(
                (isDrag ?
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        
                        // Calculate new value from drag position
                        let dragPosition = sliderHeight - gesture.location.y
                        let newValue = (Double(dragPosition) / Double(sliderHeight)) * (range.upperBound - range.lowerBound) + range.lowerBound
                        
                        // Clamp the value to the valid range
                        self.value = max(min(newValue, range.upperBound), range.lowerBound)
                        
                        onEditingChanged(true)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged(false)
                    }
                 : nil)
            )
        }
        .frame(width: sliderWidth, height: sliderHeight)
    }
}

// Joystick Component
struct JoystickView: View {
    @ObservedObject var ConnectionManager: ConnectionManager
    @State private var isDragging = false
    @State private var Xvalue: CGFloat = 125
    @State private var Yvalue: CGFloat = 125
    @State private var pX: CGFloat = 0
    @State private var pY: CGFloat = 0
    @State private var turningAngle: Double = 0
    @Binding var autoKillEnabled: Bool
    
    var body: some View {
        ZStack {
            // Joystick background
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                .fill(Color.black.opacity(0.2))
                .frame(width: 250, height: 250)
            
            // Center crosshair
            Group {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2, height: 250)
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 250, height: 2)
            }
            
            // Joystick knob
            Circle()
                .foregroundColor(.white)
                .opacity(0.8)
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                )
                .offset(x: Xvalue - 125, y: 125 - Yvalue)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            
                            // Calculate new position
                            let newX = gesture.location.x
                            let newY = gesture.location.y
                            
                            // Calculate distance from center
                            let centerX: CGFloat = 125
                            let centerY: CGFloat = 125
                            let deltaX = newX - centerX
                            let deltaY = newY - centerY
                            let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
                            
                            // Limit to circle boundary
                            let maxRadius: CGFloat = 95
                            if distance <= maxRadius {
                                Xvalue = newX
                                Yvalue = newY
                            } else {
                                let ratio = maxRadius / distance
                                Xvalue = centerX + deltaX * ratio
                                Yvalue = centerY + deltaY * ratio
                            }
                            
                            // Calculate control values
                            pX = Xvalue - 125  // -125 to +125
                            pY = 125 - Yvalue  // -125 to +125 (inverted Y)
                            
                                                         // Calculate turning angle
                             turningAngle = Double(pX) / 2.0  // Updated to match Arduino change
                             
                             // Send command if connected
                             if ConnectionManager.isConnected {
                                 ConnectionManager.sendRawMessage(message: "X \(Int(pX)) Y \(Int(pY))\n")
                             }
                             
                             // Update parent view
                             NotificationCenter.default.post(name: .joystickMoved, object: nil, userInfo: ["turningAngle": turningAngle])
                        }
                        .onEnded { _ in
                            isDragging = false
                            
                            // Return to center with animation
                            withAnimation(.easeOut(duration: 0.3)) {
                                Xvalue = 125
                                Yvalue = 125
                                pX = 0
                                pY = 0
                                turningAngle = 0
                            }
                            
                            // Send stop command
                            if ConnectionManager.isConnected {
                                ConnectionManager.sendRawMessage(message: "X 0 Y 0\n")
                            }
                        }
                )
        }
        .frame(width: 250, height: 250)
        .onChange(of: ConnectionManager.isConnected) { isConnected in
            // Auto-kill motor on disconnect
            if !isConnected && autoKillEnabled {
                ConnectionManager.sendRawMessage(message: "X 0 Y 0\n")
                withAnimation(.easeOut(duration: 0.3)) {
                    Xvalue = 125
                    Yvalue = 125
                    pX = 0
                    pY = 0
                    turningAngle = 0
                }
            }
        }
    }
}

// Live data bar component
struct LiveDataBar: View {
    let title: String
    let value: Double
    let maxValue: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
                .fontWeight(.semibold)
            
            // Progress bar
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 20, height: 80)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 20, height: CGFloat(abs(value) / maxValue) * 80)
            }
            
            VStack(spacing: 2) {
                Text("\(Int(abs(value)))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

// Main control view
struct ControlView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var ConnectionManager: ConnectionManager
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var navigationState: NavigationStateManager
    @EnvironmentObject var motorManager: MotorManagement
    @EnvironmentObject var mlProcessor: MLProcessor
    @StateObject private var locationHandler = LocationHandler()
    
    // Frontend-only settings (no commands sent)
    @State private var maxSpeedSetting: Double = 25.0
    @State private var maxAccelSetting: Double = 5.0
    @State private var autoKillEnabled: Bool = true
    @State private var currentSpeed: Double = 0
    @State private var currentAccel: Double = 0
    @State private var turningAngle: Double = 0
    
    @State private var navigate: Bool = false
    
    @State private var isSet1: Bool = false
    @State private var isSet2: Bool = false
    @State private var isSet3: Bool = false
    @State private var isSet4: Bool = false
    @State private var isSet5: Bool = false
    @State private var isSet6: Bool = false
    @Binding var dir: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top section with dropdowns
                    VStack(spacing: 10) {
                        // Top Banner: Connection Status + Settings
                        HStack(spacing: 12) {
                            // Connection Status
                            Circle()
                                .fill(ConnectionManager.isConnected ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            Text(ConnectionManager.isConnected ? "Connected" : "Disconnected")
                                .font(.caption)
                                .foregroundColor(ConnectionManager.isConnected ? .green : .red)
                            
                            Spacer()
                            
                            // Auto-kill toggle
                            HStack(spacing: 6) {
                                Image(systemName: autoKillEnabled ? "power" : "power.circle")
                                    .foregroundColor(autoKillEnabled ? .red : .gray)
                                Toggle("Auto-Kill", isOn: $autoKillEnabled)
                                    .labelsHidden()
                                    .scaleEffect(0.8)
                            }
                            
                            // Back Button
                            Button("Back") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.white)
                            .font(.headline)
                        }
                        
                        // Settings Dropdowns
                        HStack(spacing: 20) {
                            // Max Speed Dropdown
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Max Speed")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Menu {
                                    ForEach([10, 15, 20, 25, 30, 35, 40, 45, 50], id: \.self) { speed in
                                        Button("\(speed) MPH") {
                                            maxSpeedSetting = Double(speed)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("\(Int(maxSpeedSetting)) MPH")
                                            .foregroundColor(.white)
                                            .font(.system(size: 14, weight: .semibold))
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Spacer()
                            
                            // Max Acceleration Dropdown
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Max Acceleration")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Menu {
                                    ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], id: \.self) { accel in
                                        Button("\(accel) m/s²") {
                                            maxAccelSetting = Double(accel)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("\(Int(maxAccelSetting)) m/s²")
                                            .foregroundColor(.white)
                                            .font(.system(size: 14, weight: .semibold))
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 15)
                    .background(BlurView(style: .systemMaterialDark))
                    
                    // Directions Banner
                    if navigationState.isNavigating {
                        DirectionsBanner()
                            .environmentObject(navigationState)
                            .padding(.bottom, 4)
                    }
                    
                    // Title
                    Text("Control Panel")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    // Autopilot Switch
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

                    // Navigation Display Section
                    if navigationState.isNavigating {
                        NavigationDisplayView()
                            .environmentObject(navigationState)
                            .environmentObject(locationHandler)
                    }
                    
                    // Main Control Section - Joystick with live data
                    HStack(spacing: 30) {
                        // Left side - Acceleration data
                        LiveDataBar(
                            title: "ACCEL",
                            value: currentAccel,
                            maxValue: maxAccelSetting,
                            unit: "m/s²",
                            color: .orange
                        )
                        
                        // Center - Joystick with turning angle
                        VStack(spacing: 10) {
                            // Turning angle display
                            VStack(spacing: 4) {
                                Text("TURNING")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                HStack {
                                    Text("\(Int(turningAngle))°")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.cyan)
                                    Image(systemName: turningAngle > 0 ? "arrow.turn.right.up" : turningAngle < 0 ? "arrow.turn.left.up" : "arrow.up")
                                        .foregroundColor(.cyan)
                                }
                            }
                            
                                                         // Joystick
                             JoystickView(ConnectionManager: ConnectionManager, autoKillEnabled: $autoKillEnabled)
                                 .onReceive(NotificationCenter.default.publisher(for: .joystickMoved)) { notification in
                                     if let userInfo = notification.userInfo,
                                        let angle = userInfo["turningAngle"] as? Double {
                                         turningAngle = angle
                                     }
                                 }
                        }
                        
                        // Right side - Speed data
                        LiveDataBar(
                            title: "SPEED",
                            value: currentSpeed,
                            maxValue: maxSpeedSetting,
                            unit: "MPH",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)

                    // Control Buttons Section
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
                                                .frame(width: 15, height: 8)
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.white)
                                                .frame(width: 15, height: 8)
                                        }
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color.black)
                                                .frame(width: 4, height: 4)
                                                .offset(y: isSet1 ? -3 : 3)
                                        )
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
                                    .environmentObject(navigationState),
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
                
                // Simulate live data updates (replace with actual data)
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    // Simulate current speed and acceleration (replace with actual motor data)
                    currentSpeed = motorManager.currentSpeed
                    currentAccel = motorManager.currentAccel
                }
            }
            .hidden()
            .navigationBarHidden(true)
        }
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

// MARK: - Notification Extensions
extension Notification.Name {
    static let joystickMoved = Notification.Name("joystickMoved")
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

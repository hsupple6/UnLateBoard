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

// Main control view
// MARK: - Updated Control View
struct ControlView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var ConnectionManager: ConnectionManager
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var navigationState: NavigationStateManager // Add this
    @EnvironmentObject var motorManager: MotorManagement
    @EnvironmentObject var mlProcessor: MLProcessor
    @StateObject private var locationHandler = LocationHandler()
    
    @State private var speedValue: Double = 25.0
    @State private var accValue: Double = 5
    
    @State private var currSpeed: Double = 0;
    @State private var currAcc: Double = 0;
    
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
                    // Top Banner: ESP32 Connection Status + Directions
                    HStack(spacing: 12) {
                        // ESP32 Connection Status
                        Circle()
                            .fill(ConnectionManager.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(ConnectionManager.isConnected ? "ESP32 Connected" : "ESP32 Disconnected")
                            .font(.caption)
                            .foregroundColor(ConnectionManager.isConnected ? .green : .red)
                        Spacer()
                        // Back Button
                        Button("Back") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
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
                    // Remove old board info text

                    // Navigation Display Section
                    if navigationState.isNavigating {
                        NavigationDisplayView()
                            .environmentObject(navigationState)
                            .environmentObject(locationHandler)
                    }
                    
                    HStack(spacing: 20) {
                        VStack {
                            ThickVerticalSlider(
                                sliderWidth: 60.0,
                                sliderHeight: 250.0,
                                isDrag: true,
                                range: 0...50,
                                fillColor: .green,
                                value: $motorManager.maxVelo,
                            )
                            .onChange(of: motorManager.maxVelo) {
                                ConnectionManager.sendRawMessage(message: "SV \(motorManager.maxVelo)\n")
                            }
                            
                            VStack {
                                Text("Max Speed")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .fixedSize()
                                Text("\(Int(motorManager.maxVelo))")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                Text("MPH")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(width: 50)
                            }
                        }

                        Spacer()
                        
                        VStack {
                            ThickVerticalSlider(
                                sliderWidth: 30,
                                sliderHeight: 200,
                                isDrag: true,
                                range: 0...(speedValue < 40
                                            ? speedValue + 10
                                            : speedValue + Double(50 % max(1, Int(speedValue)))),
                                value: $speedValue,
                            )
                            .onChange(of: speedValue) {
                                ConnectionManager.sendRawMessage(message: "SPEED \(Int(speedValue))\n")
                            }
                            
                            VStack {
                                Text("Speed")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Text("\(Int(speedValue))")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                                Text("MPH")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(width: 50)
                            }
                        }

                        Spacer()
                        
                        VStack {
                            ThickVerticalSlider(
                                sliderWidth: 30,
                                sliderHeight: 200,
                                isDrag: true,
                                range: 1...4,
                                fillColor: .orange,
                                value: $motorManager.currentAccel,
                            )
                            .onChange(of: motorManager.currentAccel) {
                                ConnectionManager.sendRawMessage(message: "ACC \(Int(motorManager.currentAccel))\n")
                            }
                            
                            VStack {
                                Text("Acc")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Text("\(Int(motorManager.currentAccel))")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                Text("M/S²")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(width: 50)
                            }
                        }

                        Spacer()

                        VStack {
                            ThickVerticalSlider(
                                sliderWidth: 60,
                                sliderHeight: 250,
                                isDrag: true,
                                range: 1...10,
                                fillColor: .blue,
                                value: $motorManager.maxAccel,
                            )
                            .onChange(of: motorManager.maxAccel) {
                                ConnectionManager.sendRawMessage(message: "MAXACC \(Int(motorManager.maxAccel))\n")
                            }
                            VStack {
                                Text("Max Acc")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Text("\(Int(motorManager.maxAccel))")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                                Text("M/S²")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(width: 50)
                            }
                        }
                    }
                    .padding()

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

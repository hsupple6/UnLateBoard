import SwiftUI
import Foundation

// Separate component for the vertical slider
struct ThickVerticalSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var onEditingChanged: (Bool) -> Void = { _ in }
    
    // Customizable properties
    var sliderWidth: CGFloat = 60
    var sliderHeight: CGFloat = 250
    var thumbSize: CGFloat = 28
    var backgroundColor: Color = Color(.systemGray5)
    var fillColor: Color = .blue
    var thumbColor: Color = .white
    
    // Private state
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
                        height: sliderHeight * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                    )

            }
            .frame(width: sliderWidth, height: sliderHeight)
            .gesture(
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
            )
        }
        .frame(width: sliderWidth, height: sliderHeight)
    }
}

// Main control view
struct ControlView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var speedValue: Double = 25.0
    @State private var newVal: Double = 5
    @State private var navigate: Bool = false
    
    @State private var isSet1: Bool = false
    @State private var isSet2: Bool = false

    @State private var isSet3: Bool = false
    @State private var isSet4: Bool = false

    @State private var isSet5: Bool = false
    @State private var isSet6: Bool = false

    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Text("Control Panel")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    Text("Your Board: UnLate V1")
                        .foregroundColor(.white)
                        .padding()
                    
                    HStack {
                        VStack {
                            Text("Board Name: ")
                                .foregroundColor(.white)
                                .padding(.bottom, 10)
                            Text("My Board")
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                        }
                        VStack {
                            Text("Top Speed:")
                                .foregroundColor(.white)
                                .padding(.bottom, 10)
                            Text("50 mph")
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                        }
                        VStack {
                            Text("Board Hours:")
                                .foregroundColor(.white)
                                .padding(.bottom, 10)
                            Text("25")
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                        }
                    }
                    
                    HStack(spacing: 20) {
                        VStack {
                            ThickVerticalSlider(
                                value: $speedValue,
                                range: 0...50,
                                fillColor: .green
                            )
                            
                            VStack {
                                Text("Max Speed")
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
                                value: $newVal,
                                range: 1...10,
                                fillColor: .blue
                            )
                            
                            VStack {
                                Text("Max Acc")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Text("\(Int(newVal))")
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

                    HStack {
                        
                        VStack {
                            
                            Button (action: {
                                isSet1 = !isSet1
                            }) {
                                
                                ZStack {
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                            .fill(isSet1 ? Color.blue : Color.gray)
                                            .frame(width: 75, height: 75)
                                            .opacity(isSet1 ? 0.75 : 0.2)
                                    
                                    VStack {
                                        
                                        Spacer()
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
                                            VStack (spacing: 0){
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
                                                    .frame(width:5, height: 10)
                                                
                                                RoundedRectangle(cornerRadius: 5)
                                                    .fill(Color.black)
                                                    .frame(width: 4, height: 4)
                                                    .offset(y: isSet1 ? -3 : 3)
                                            
                                            }
                                        }
                                        Spacer()
                                        
                                    }
                                    
                                }
                                
                            }
                            .padding(.bottom, 30)
                            
                            Spacer()
                            
                            Button (action: {
                                isSet2 = !isSet2
                            }) {
                                
                                ZStack {
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isSet2 ? Color.blue : Color.gray)
                                        .frame(width: 75, height: 75)
                                        .opacity(isSet2 ? 0.75 : 0.2)
                                    
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
                            .padding(.bottom, 30)
                            
                        }
                        .padding()

                        VStack {
                            
                            Button (action: {
                                isSet3 = !isSet3
                            }) {
                                Text("")
                                    .frame(maxWidth: 75, maxHeight: 75)
                                    .background(isSet3 ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .opacity(isSet3 ? 0.75 : 0.2)
                                
                            }
                            .padding(.bottom, 30)
                            
                            Spacer()
                            
                            Button (action: {
                                isSet4 = !isSet4
                            }) {
                                Text("")
                                    .frame(maxWidth: 75, maxHeight: 75)
                                    .background(isSet4 ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .opacity(isSet4 ? 0.75 : 0.2)
                                
                            }
                            .padding(.bottom, 30)
                            
                        }
                        .padding()
                        
                        VStack {
                            
                            Button (action: {
                                isSet5 = !isSet5
                            }) {
                                Text("")
                                    .frame(maxWidth: 75, maxHeight: 75)
                                    .background(isSet5 ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .opacity(isSet5 ? 0.75 : 0.2)
                                
                            }
                            .padding(.bottom, 30)
                            
                            Spacer()
                            
                            Button (action: {
                                isSet6 = !isSet6
                            }) {
                                Text("")
                                    .frame(maxWidth: 75, maxHeight: 75)
                                    .background(isSet6 ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .opacity(isSet6 ? 0.75 : 0.2)
                                
                            }
                            .padding(.bottom, 30)
                            
                        }
                        .padding()
                        
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
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
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                opacity = 1.0
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

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView()
    }
}



//
//  ManualView.swift
//  UnLateBoard
//
//  Created by Hayden Supple on 5/10/25.
//
import SwiftUI

struct ManualView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var ConnectionManager: ConnectionManager
    
    @State private var speedValue: Double = 25
    @State private var accelValue: Double = 5
    @State private var ACC: Bool = true
    var body: some View {
        NavigationStack {
            VStack {
                // Header with Back Button
                HStack {
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                    
                    Spacer()
                    
                    Text("Manual Control")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder to balance the layout
                    Text("Back")
                        .foregroundColor(.clear)
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
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
                
                ZStack {
                    VStack {
                        Spacer()
                        HStack {
                            VStack {
                                ThickVerticalSlider(
                                    sliderWidth: 30,
                                    sliderHeight: 500,
                                    isDrag: true,
                                    range: 0...50,
                                    fillColor: .green,
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
                                    sliderHeight: 500,
                                    isDrag: true,
                                    range: 0...10,
                                    fillColor: .blue,
                                    value: $accelValue,
                                )
                                .onChange(of: accelValue) {
                                    ConnectionManager.sendRawMessage(message: "ACC \(Int(accelValue))\n")
                                }
                                
                                VStack {
                                    Text("Accel")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                    Text("\(Int(accelValue))")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("M/S²")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                }
                            }
                        }
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 35)
                            .frame(width: 250, height: 500)
                            .foregroundColor(.gray)
                            .opacity(0.2)
                        VStack {
                            
                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                                    .opacity(0.2)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.black)
                                    .offset(x: 5, y: 5)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                                    .opacity(0.2)
                                    .offset(x: 5, y: 5)
                                    .rotationEffect(Angle(degrees: 45))
                                
                            }
                            
                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                                    .opacity(0.2)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.black)
                                    .offset(x: 5, y: 5)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                                    .opacity(0.2)
                                    .offset(x: 5, y: 5)
                                    .rotationEffect(Angle(degrees: 45))
                                
                            }
                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                                    .opacity(0.2)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.black)
                                    .offset(x: 5, y: 5)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                                    .opacity(0.2)
                                    .offset(x: 5, y: 5)
                                    .rotationEffect(Angle(degrees: 45))
                                
                            }
                            
                            Spacer()
                            
                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                                    .opacity(0.2)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.black)
                                    .offset(x: -5, y: -5)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                                    .opacity(0.2)
                                    .offset(x: -5, y: -5)
                                    .rotationEffect(Angle(degrees: 45))
                                
                            }
                            .padding(.top)

                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                                    .opacity(0.2)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.black)
                                    .offset(x: -5, y: -5)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                                    .opacity(0.2)
                                    .offset(x: -5, y: -5)
                                    .rotationEffect(Angle(degrees: 45))
                                
                            }
                            .padding(.top)

                            
                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                                    .opacity(0.2)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.black)
                                    .offset(x: -5, y: -5)
                                    .rotationEffect(Angle(degrees: 45))
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                                    .opacity(0.2)
                                    .offset(x: -5, y: -5)
                                    .rotationEffect(Angle(degrees: 45))
                                
                            }
                            .padding(.top)
                        }
                        .frame(width: 250, height: 475)
                        
                        PosDragger(ConnectionManager: ConnectionManager)
                    }
                    Spacer()
                    
                }
                
            }
            Button(action: {
                ConnectionManager.sendRawMessage(message: "ACCM \(ACC ? 1 : 0)\n")
                ACC = !ACC
            }) {
                Text("ACC")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 100, height: 50)
                    .background(ACC ? Color.blue : Color.gray)
                    .opacity(ACC ? 0.75 : 0.2)
                    .cornerRadius(10)
            }
        }
        .navigationBarHidden(true)
    }
}

struct PosDragger: View {
    
    @ObservedObject var ConnectionManager: ConnectionManager

    var Yaxis: CGFloat = 250
    var Xaxis: CGFloat = 125
    
    @State var Yvalue: CGFloat = 250
    @State var Xvalue: CGFloat = 125
    
    @State var pX: CGFloat = 250
    @State var pY: CGFloat = 125
    
    @State var h: CGFloat = 0
    
    

    var onEditingChanged: (Bool) -> Void = { _ in }
    
    // Customizable properties

    var thumbSize: CGFloat = 28
    var backgroundColor: Color = Color(.systemGray5)
    var fillColor: Color = .blue
    var thumbColor: Color = .white
    
    // Private state
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            Circle()
                .foregroundColor(.white)
                .opacity(0.75)
                .frame(width: 100, height: 100)
                .offset(x: 200 - Xvalue, y: 450 - Yvalue)
            .gesture(
                
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        
                        // Calculate new value from drag position
                        let Yaxis = 500 - gesture.location.y
                        let Xaxis = 250 - gesture.location.x
                        if (((Yaxis - 250) >= pY + 5 || (Yaxis - 250) <= pY - 5) || ((Xaxis - 125) >= pX + 5 || (Xaxis - 125) <= pX - 5)){
                            if Xaxis > 0 && Xaxis < 250 {
                                pX = Xaxis - 125
                            }
                            
                            if Yaxis > 0 && Yaxis < 500 {
                                pY = Yaxis - 250
                            }
                            
                            ConnectionManager.sendRawMessage(message: "X \(pX) Y \(pY)\n")
                        }
                        // Clamp the value to the valid range
                        Yvalue = max(min(Yaxis, 500), 0)
                        Xvalue = max(min(Xaxis, 250), 0)

                        onEditingChanged(true)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged(false)
                        withAnimation(Animation.easeIn(duration: 0.1)) {
                            Xvalue = 125
                            Yvalue = 250
                        }
                    }
            )
        }
        .frame(width: 250, height: 500)
    }
    
    
}

struct ManualView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView(ConnectionManager: ConnectionManager(host: "", port: 0), dir: .constant(false))
    }
}

import SwiftUI
import Foundation

struct SecondView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var sliderValue1: Double = 50.0
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State public var passcount: Int = 0
    @State private var navigate: Bool = false
    
    public func incPass() {
        passcount += 1
    }
    
    var body: some View {
        NavigationStack { // 👈 Added this!
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Text("Congratulations!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                    
                    Text("You have successfully selected an option.")
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    ZStack {
                        HStack(spacing: 20) {
                            VStack(spacing: 40) {
                                TextField("Full Name", text: $name)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                
                                TextField("Email Address", text: $email)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                
                                TextField("Set Password", text: $password)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            VStack(spacing: 40) {
                                if name.isEmpty {
                                    CrossAnimation()
                                        .padding()
                                        .frame(width: 50, height: 50)
                                } else {
                                    CheckMarkAnimation()
                                        .padding()
                                        .frame(width: 50, height: 50)
                                }
                                
                                if !(email.contains("@") && email.contains(".com")) {
                                    CrossAnimation()
                                        .padding()
                                        .frame(width: 50, height: 50)
                                } else {
                                    CheckMarkAnimation()
                                        .padding()
                                        .frame(width: 50, height: 50)
                                }
                                
                                if !isPasswordValid(password) {
                                    CrossAnimation()
                                        .padding()
                                        .frame(width: 50, height: 50)
                                        .transition(.opacity)
                                        .animation(.easeInOut(duration: 0.5), value: passcount)
                                } else {
                                    CheckMarkAnimation()
                                        .padding()
                                        .frame(width: 50, height: 50)
                                }
                            }
                        }
                        .frame(height: 250, alignment: .top)
                        .padding()
                    }
                    
                    Text("Password Must Contain: 7+ Digits, a Number, Capital, and a Special Char!")
                        .font(.caption)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .opacity((!isPasswordValid(password) && passcount > 7) ? 1 : 0)
                        .animation(.easeInOut, value: (!isPasswordValid(password) && passcount > 6))
                    
                    Spacer()
                    
                    VStack {
                        Button(action: {
                            if isPasswordValid(password) && !name.isEmpty && email.contains("@") && email.contains(".com") {
                                navigate = true
                                writetoFile(name: name, email: email, password: password)
                            }
                        }) {
                            Text("Submit")
                                .font(.system(size: 30))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        
                        NavigationLink(destination: ThirdView(), isActive: $navigate) {
                            EmptyView()
                        }
                        .hidden() // Hide it so it doesn't show up
                    }
                }
                .navigationBarHidden(true)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .onChange(of: password) { _ in
                    if !isPasswordValid(password) {
                        incPass()
                    }
                }
            }
        }
    }
}


struct CheckMarkAnimation: View {
    @State private var animationProgress: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: animationProgress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(-90))
                .opacity(opacity)
            
            Path { path in
                // First point of the checkmark
                path.move(to: CGPoint(x: 12, y: 22))
                
                // Middle point with curve control
                path.addQuadCurve(
                    to: CGPoint(x: 18, y: 28),
                    control: CGPoint(x: 15, y: 25)
                )
                
                // End point with curve control
                path.addQuadCurve(
                    to: CGPoint(x: 30, y: 16),
                    control: CGPoint(x: 24, y: 22)
                )
            }
            .trim(from: 0, to: animationProgress)
            .stroke(Color.green, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .frame(width: 42, height: 42)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animationProgress = 1.0
            }
        }
    }
}

struct CrossAnimation: View {
    @State private var animationProgress1: CGFloat = 0
    @State private var animationProgress2: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: animationProgress1)
                .stroke(Color.red, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(-90))
                .opacity(opacity)
            
            // First line of the X
            Path { path in
                path.move(to: CGPoint(x: 12, y: 12))
                path.addQuadCurve(
                    to: CGPoint(x: 30, y: 30),
                    control: CGPoint(x: 21, y: 21)
                )
            }
            .trim(from: 0, to: animationProgress1)
            .stroke(Color.red, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 42, height: 42)
            .opacity(opacity)
            
            // Second line of the X
            Path { path in
                path.move(to: CGPoint(x: 30, y: 12))
                path.addQuadCurve(
                    to: CGPoint(x: 12, y: 30),
                    control: CGPoint(x: 21, y: 21)
                )
            }
            .trim(from: 0, to: animationProgress2)
            .stroke(Color.red, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 42, height: 42)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animationProgress1 = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                animationProgress2 = 1.0
            }
        }
    }
}

func isPasswordValid(_ password: String) -> Bool {
    var num = 0
    var capital = 0
    var specialchar = 0
    let passArray = Array(password)
    
    // Validate password
    for pass in passArray {
        if pass.isNumber {
            num += 1
        }
        if pass.isUppercase {
            capital += 1
        }
        if "!@#$%^&*.,".contains(pass) {
            specialchar += 1
        }
    }
    
    return num > 0 && capital > 0 && specialchar > 0 && passArray.count >= 7
}

func writetoFile(name: String, email: String, password: String) {
    let fileManager = FileManager.default
    let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentDirectory.appendingPathComponent("Login.txt")
    
    let newName = name.replacingOccurrences(of: " ", with: "/")
    let initialContent = "\(newName) \(email) \(password) false"
    
    do {
        try initialContent.write(to: fileURL, atomically: true, encoding: .utf8)
        print("Data Written: " + initialContent)
    } catch {
        print("Failed to create file: \(error.localizedDescription)")
    }
}

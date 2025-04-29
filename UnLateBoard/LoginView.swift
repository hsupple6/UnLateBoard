import Foundation
import SwiftUI

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var sliderValue1: Double = 50.0
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State public var passcount: Int = 0
    @State private var navigate: Bool = false
    @State private var isChecked = false
    
    public func incPass() {
        passcount += 1
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Text("Login")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                    
                    VStack(spacing: 40) {
                        TextField("Email Address", text: $email)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        
                        TextField("Password", text: $password)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Stay signed in option
                    HStack {
                        CheckmarkButton(
                            isChecked: $isChecked,
                            size: 24,
                            checkedColor: .blue,
                            uncheckedColor: .gray.opacity(0.8),
                            checkmarkColor: .white
                        )
                        
                        Text("Stay Signed In")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Let's Ride button
                    Button(action: {
                        if (isChecked) {
                            writeSaveLogin(email: email, password: password)
                        }
                        if isLogin(email: email, password: password) {
                            navigate = true // Set the navigate state to true
                        }
                    }) {
                        Text("Let's Ride!")
                            .font(.system(size: 22, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                    
                    NavigationLink(destination: ThirdView(), isActive: $navigate) {
                        EmptyView()
                    }
                    .hidden()
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

func isLogin(email: String, password: String) -> Bool {
    let fileName = "Login.txt"
    
    let fileManager = FileManager.default
    let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentDirectory.appendingPathComponent(fileName)

    do {
        let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
        let fileArr = fileContents.split(separator: " ")
        
        // Debug prints
        print("File contents: \(fileContents)")
        print("File array: \(fileArr)")
        print("Attempting to match - email: \(email), password: \(password)")
        
        // Check if we have enough components - adjust indices based on your actual file format
        if fileArr.count >= 3 {
            // Assuming format is: name email password
            let storedEmail = String(fileArr[1])
            let storedPassword = String(fileArr[2])
            
            print("Stored email: \(storedEmail)")
            print("Stored password: \(storedPassword)")
            
            if storedEmail == email && storedPassword == password {
                return true
            }
        }
        return false
    } catch {
        print("Error reading file: \(error.localizedDescription)")
        let initialContent = ""
        do {
            try initialContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File created at: \(fileURL.path)")
        } catch {
            print("Failed to create file: \(error.localizedDescription)")
        }
    }
    return false
}

func writeSaveLogin(email: String, password: String) -> Bool {
    let fileName = "Login.txt"
    
    let fileManager = FileManager.default
    let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentDirectory.appendingPathComponent(fileName)

    // Check if file exists
    if fileManager.fileExists(atPath: fileURL.path) {
        do {
            // Read existing content
            let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
            
            let username = email.split(separator: "@").first ?? "User"
            let updatedContent = "\(username) \(email) \(password) true"
            
            try updatedContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Error reading/writing file: \(error.localizedDescription)")
            return false
        }
    } else {
        // Create file with initial login
        do {
            // Format: "Username email password"
            let username = email.split(separator: "@").first ?? "User"
            let initialContent = "\(username) \(email) \(password)"
            try initialContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File created at: \(fileURL.path)")
            return true
        } catch {
            print("Failed to create file: \(error.localizedDescription)")
            return false
        }
    }
}
    

struct CheckmarkButton: View {
    @Binding var isChecked: Bool
    var onToggle: ((Bool) -> Void)? = nil
    
    // Customizable properties
    var size: CGFloat = 24
    var checkedColor: Color = .green
    var uncheckedColor: Color = .gray
    var checkmarkColor: Color = .white
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
            onToggle?(isChecked)
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isChecked ? checkedColor : Color.clear)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(isChecked ? checkedColor : uncheckedColor, lineWidth: 2)
                    )
                
                // Checkmark
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.6, weight: .bold))
                        .foregroundColor(checkmarkColor)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

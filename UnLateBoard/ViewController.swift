import SwiftUI
import Foundation


// First View (ContentView - Welcome Screen)
struct ContentView: View {
    @State private var textOpacity = 0.0  // To control the appearance of the text
    @State private var textScale = 0.5    // For scaling animation
    @State private var navigateToFirstView = false  // To trigger navigation
    
    var body: some View {
        NavigationView {
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    // Text with enhanced animation effect for "Welcome"
                    Text("Welcome to UnLateBoard")
                        .font(.system(size: 35))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(textOpacity)     // Controls fade in/out
                        .scaleEffect(textScale)   // Controls size in/out
                        .onAppear {
                            // Animate text to fade in and scale up
                            withAnimation(.easeIn(duration: 1.5)) {
                                textOpacity = 1.0
                            }
                            
                            // After a delay, animate text to fade out and scale down
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeOut(duration: 1.5)) {
                                    textOpacity = 0.0
                                }
                            }
                        }

                    // Text with enhanced animation effect for "Ride Safe!"
                    Text("Ride Safe!")
                        .font(.system(size: 65))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(textOpacity)     // Controls fade in/out
                        .scaleEffect(textScale)   // Controls size in/out
                        .onAppear {
                            // After a delay, animate text to fade in and scale up
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeIn(duration: 1.5)) {
                                    textOpacity = 1.0
                                }
                            }
                            
                            // After a delay, animate text to fade out and scale down
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeOut(duration: 1.5)) {
                                    textOpacity = 0.0
                                }
                            }
                            
                            // After animations complete, trigger navigation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                navigateToFirstView = true
                            }
                        }
                }

                // NavigationLink triggered after the animation completes
                NavigationLink(destination: FirstView(), isActive: $navigateToFirstView) {
                    EmptyView()
                }
            }
            .navigationBarHidden(true) // Hide navigation bar on welcome screen
            .preferredColorScheme(.dark) // Ensure the system UI uses dark mode
        }
    }
}



// Second View
struct FirstView: View {
    @State private var isNavigationActive = false    // Trigger navigation to second view
    
    var body: some View {
        NavigationView {
            ZStack {
                // Full black background
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    // Submit Button
                    Button(action: {
                        // If the option is selected, trigger navigation
                        isNavigationActive = true
                        
                    }) {
                        Text("Get Started!")
                            .font(.system(size: 30))
                            .fontWeight(.bold)
                            .padding(.horizontal, 70)  // Increase horizontal padding
                            .padding(.vertical, 20)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .padding()
                    // Navigation link
                    
                    if (!readFile()){
                        NavigationLink(destination: SecondView(), isActive: $isNavigationActive) {
                            EmptyView()
                        }
                    } else {
                        if (isSaved()) {
                            NavigationLink(destination: ThirdView(), isActive: $isNavigationActive) {
                                EmptyView()
                            }
                        } else {
                            NavigationLink(destination: LoginView(), isActive: $isNavigationActive) {
                                EmptyView()
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .navigationBarTitle("Welcome to UnLateBoard", displayMode: .inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .accentColor(.white) // For navigation bar text/items color
        .preferredColorScheme(.dark) // Ensures system UI like status bar is in dark mode
        .navigationBarHidden(true)
    }
}

public func readFile() -> Bool {
    
    let fileName = "Login.txt"
    
    let fileManager = FileManager.default
    let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentDirectory.appendingPathComponent(fileName)

    do {
        let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
        print("File contents: \(fileContents)")
        if fileContents.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            return true
        }
    } catch {
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

public func isSaved() -> Bool {
    
    let fileName = "Login.txt"
    
    let fileManager = FileManager.default
    let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentDirectory.appendingPathComponent(fileName)

    // File exists, read contents
    do {
        let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
        
        // If file is empty, return false
        if fileContents.isEmpty {
            return false
        }
        
        let fileArr = fileContents.split(separator: " ")
        
        // Fixed syntax error: removed { before condition
        if fileArr.count >= 3 && fileArr[3].lowercased() == "true" {
            return true
        }
    } catch {
        print("Error reading file: \(error.localizedDescription)")
    }
    
    return false
}

import SwiftUI

struct LiveClassificationView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    // Header with Back Button
                    HStack {
                        Button("Back") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        
                        Spacer()
                        
                        Text("Live Classification")
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
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Live Classification View")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Text("Real-time object detection and classification")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct LiveClassificationView_Previews: PreviewProvider {
    static var previews: some View {
        LiveClassificationView()
    }
} 
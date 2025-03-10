import SwiftUI
import AVFAudio


struct ContactanosView: View {
    @State private var isAnimating = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Background Image
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .center, spacing: 20) {
                // Info Text
                Text("For questions, comments and/or suggestions kindly press the icon below to contact us via WhatsApp. We will try to fix it. Thanks for the support.")
                    .font(.system(size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 160)
                
                // WhatsApp Button
                Button(action: {
                    SoundManager.shared.playTransitionSound()
                    if let url = URL(string: "https://wa.me/240222780886") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image("whatsapp")
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150.0, height: 150.0)
                        .cornerRadius(150)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
                
                // Return Button
                Button(action: {
                    SoundManager.shared.playTransitionSound()
                    print("RETURN button tapped")
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("RETURN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 300, height: 75)
                        .background(Color(red: 163/255, green: 177/255, blue: 138/255))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 3))
                }
                
                // Logo Image
                Image("logoelebi")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.top, 80)
                    .padding(.leading, 180)
            }
        }
        .onAppear {
            // Start the animation when the view appears
            isAnimating = true
        }
    }
}

    struct ContactanosView_Previews: PreviewProvider {
        static var previews: some View {
            ContactanosView()
        }
    }

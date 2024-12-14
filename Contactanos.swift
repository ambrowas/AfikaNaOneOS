import SwiftUI
import AVFAudio

struct ContactanosView: View {
    @Environment(\.dismiss) var dismiss // Use dismiss for fullScreenCover
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background Image
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .center, spacing: 20) { // Adjust spacing as needed
                // Info Text
                Text("For questions, comments, suggestions, proposals, corrections, complaints, insults, intimidations and or grievances kindly press the icon below to contact us via WhatsApp. We will try to fix it. Thanks for the support.")
                    .font(.system(size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // WhatsApp Button
                Button(action: {
                    SoundManager.shared.playTransitionSound()
                    if let url = URL(string: "https://wa.me/240222780886") {
                        UIApplication.shared.open(url)
                    }
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isAnimating.toggle()
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
                    print("RETURN button tapped") // Debugging log
                    dismiss() // Correctly dismisses this view
                }) {
                    Text("RETURN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 300, height: 75)
                        .background(Color(hue: 1.0, saturation: 0.984, brightness: 0.699)) // Original color
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
            }
            .padding(.vertical, 10) // Adjusts spacing for the entire VStack
        }
        .onAppear {
            withAnimation {
                isAnimating.toggle()
            }
        }
    }
}

struct ContactanosView_Previews: PreviewProvider {
    static var previews: some View {
        ContactanosView()
    }
}

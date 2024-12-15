import SwiftUI
import AVFoundation


struct ResultadoView: View {
    let aciertos: Int
    let puntuacion: Int
    let errores: Int
    @State private var imageName = "placeholder-image"
    @State private var textFieldText = "Welcome to the Quiz!"
    @State private var isShowingImage = false
    @State private var isAnimating = false
    @State private var forceRefresh = false // To force view updates

    var body: some View {
        ZStack {
            // Background
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Image Section
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 250)
                    .padding(.top, -100)
                    .opacity(isShowingImage ? 1 : 0)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.5)) {
                            isShowingImage = true
                        }
                        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    }
                
                // Dynamic Text
                Text(textFieldText)
                    .id(forceRefresh)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .font(.headline)
                    .padding(.top, 10)
                
                // Score Boxes
                scoreBox(title: "CORRECT ANSWERS", value: aciertos)
                scoreBox(title: "WRONG ANSWERS", value: errores)
                scoreBox(title: "SCORE", value: puntuacion)
                
                // Buttons Section
                HStack {
                    Button("PLAY") {
                        print("Play button tapped")
                    }
                    .buttonStyle(GameButtonStyle(color: Color(hue: 0.69, saturation: 0.89, brightness: 0.706)))
                    
                    Button("EXIT") {
                        print("Exit button tapped")
                    }
                    .buttonStyle(GameButtonStyle(color: Color(hue: 1.0, saturation: 0.984, brightness: 0.699)))
                }
                .padding(.top, 30)
            }
        }
        .onAppear {
            handleAciertos()
        }
    }

    // MARK: - Helper Methods
    private func handleAciertos() {
        var updatedImageName = ""
        var updatedTextFieldText = ""

        if aciertos >= 9 {
            updatedImageName = "expert"
            updatedTextFieldText = "FANTASTIC. WE NEED MORE (PAN)AFRICANS LIKE YOU"
        } else if aciertos >= 5 {
            updatedImageName = "average"
            updatedTextFieldText = "NOT BAD, BUT YOU COULD DO BETTER FOR THE CONTINENT"
        } else {
            updatedImageName = "beginer"
            updatedTextFieldText = "IT'S PEOPLE LIKE YOU HOLDING AFRICA BACK"
        }

        DispatchQueue.main.async {
            self.imageName = updatedImageName
            self.textFieldText = updatedTextFieldText
            self.forceRefresh.toggle()
        }
    }

    // MARK: - Reusable Score Box
    private func scoreBox(title: String, value: Int) -> some View {
        let textColor: Color
        switch title {
        case "CORRECT ANSWERS":
            textColor = Color(hue: 0.617, saturation: 0.831, brightness: 0.591) // Blue
        case "WRONG ANSWERS":
            textColor = Color(hue: 0.994, saturation: 0.963, brightness: 0.695) // Red
        case "SCORE":
            textColor = Color(hue: 0.404, saturation: 0.934, brightness: 0.334) // Green
        default:
            textColor = .black
        }
        
        return Text("\(title): \(value)")
            .font(.headline)
            .foregroundColor(textColor) // Apply the correct color
            .padding()
            .frame(width: 300, height: 65)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 3)
            )
            .cornerRadius(10)
            .padding(.top, 10)
    }
}

// MARK: - Custom Button Style
struct GameButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 180, height: 60)
            .background(color)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 3)
            )
            .shadow(radius: 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview
struct ResultadoView_Previews: PreviewProvider {
    static var previews: some View {
        ResultadoView(aciertos: 8, puntuacion: 4000, errores: 2)
            .previewLayout(.sizeThatFits)
    }
}

import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
   
    
    var data: Data
    
    var body: some View {
        Image(uiImage: generateQRCodeImage())
            .interpolation(.none)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 200, maxHeight: 200)
            .border(Color.black, width: 3)
    }
    
    func generateQRCodeImage() -> UIImage {
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        
        filter.setValue(data, forKey: "inputMessage")
        
        if let qrCodeImage = filter.outputImage?.transformed(by: transform),
           let cgImage = context.createCGImage(qrCodeImage, from: qrCodeImage.extent) {
            return UIImage(cgImage: cgImage)
        } else {
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }
    }
      }

struct CodigoQR: View {
    @StateObject var userViewModel = UserViewModel()
    @State var qrData: Data?
    @State var qrCodeKey = ""
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var isGuardarButtonDisabled = false
    @State private var cooldownTimer: Timer?
    @State private var shouldNavigateToMenuPrincipal = false
    
    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                if let qrData = qrData {
                    QRCodeView(data: qrData)
                } else {
                    Text("Generating QRCode...")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                
                Text(qrCodeKey)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                VStack(spacing: 10) {
                    Button(action: {
                        SoundManager.shared.playTransitionSound() // ✅ Play sound first
                        guardarButtonPressed() // ✅ Then perform the save action
                    }) {
                        Text("SAVE")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 55)
                            .background(Color(red: 121/255, green: 125/255, blue: 98/255)) // Olive Green
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                    }
                    
                }
            }
            .onAppear {
                setupQRCodeData()
            }
            .alert(isPresented: $isShowingAlert) {
                            Alert(
                                title: Text(""),
                                message: Text(alertMessage),
                                dismissButton: .default(Text("OK")) {
                                    if alertMessage == "QRCode saved. Go get your money." {
                                        SoundManager.shared.playTransitionSound()
                                        shouldNavigateToMenuPrincipal = true // ✅ Trigger navigation
                                    }
                                }
                            )
                        }
                        .fullScreenCover(isPresented: $shouldNavigateToMenuPrincipal) {
                            MenuPrincipal(player: .constant(nil)) // ✅ Navigate to MenuPrincipal
                        }
                    }
                }
    
    func generateQRCodeKey() -> String {
        let allowedCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let length = 18
        
        var randomKey = ""
        
        for _ in 0..<length {
            let randomIndex = allowedCharacters.index(allowedCharacters.startIndex, offsetBy: Int.random(in: 0..<allowedCharacters.count))
            let character = allowedCharacters[randomIndex]
            randomKey.append(character)
        }
        
        return randomKey
    }
            
    func setupQRCodeData() {
        self.userViewModel.fetchUserData { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self.qrCodeKey = self.generateQRCodeKey()
                    self.qrData = self.generateQRCodeData()
                    
                    // ✅ Ensure sound plays once QR code is generated
                    if self.qrData != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            SoundManager.shared.playMagicalSound()
                        }
                    }
                case .failure(let error):
                    print("Error fetching user data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func generateQRCodeData() -> Data? {
        guard let userId = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        let qrCodeData: [String: Any] = [
            "base64QRCode": "iVBORw0KGgoAAAANSUhEUgAA",
            "lastGamePuntuacion": userViewModel.currentGamePuntuacion,
            "lastGameScore": userViewModel.currentGameAciertos,
            "qrCodeKey": qrCodeKey,
            "timestamp": generateCurrentTimestamp(),
            "userId": userId,
            "fullname": userViewModel.fullname,
            "email": userViewModel.email
        ]
        
        if let qrCodeDataString = try? JSONSerialization.data(withJSONObject: qrCodeData) {
            return "\(qrCodeKey),\(String(data: qrCodeDataString, encoding: .utf8) ?? "")".data(using: .utf8)
        } else {
            return nil
        }
    }
    
    
    
    func guardarButtonPressed() {
        if isGuardarButtonDisabled {
            SoundManager.shared.playWarningSound()
            isShowingAlert = true
            alertMessage = "This code has already been saved."
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user ID found.")
            return
        }
        
        let qrCodeData: [String: Any] = [
            "base64QRCode": "iVBORw0KGgoAAAANSUhEUgAA",
            "lastGamePuntuacion": userViewModel.currentGamePuntuacion,
            "lastGameScore": userViewModel.currentGameAciertos,
            "qrCodeKey": qrCodeKey,
            "timestamp": generateCurrentTimestamp(),
            "userId": userId,
            "fullname": userViewModel.fullname,
            "email": userViewModel.email
        ]
        
        let ref = Database.database().reference(withPath: "qrCodes").child(userId)
        ref.setValue(qrCodeData) { error, _ in
            if error == nil {
                SoundManager.shared.playMagicalSound()
                alertMessage = "QRCode saved. Go get your money."
            } else {
                SoundManager.shared.playWarningSound()
                alertMessage = "Error while saving QR Code. Try again."
            }
            
            isShowingAlert = true
            startCooldown()
        }
    }
    
        func startCooldown() {
            isGuardarButtonDisabled = true

            cooldownTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: false) { timer in
                isGuardarButtonDisabled = false
                cooldownTimer?.invalidate()
                cooldownTimer = nil
            }
        }
        
        func generateCurrentTimestamp() -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
            return dateFormatter.string(from: Date())
        }
            }
        
        struct CodigoQR_Previews: PreviewProvider {
            static var previews: some View {
                CodigoQR()
            }
        }
        
    


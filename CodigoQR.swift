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
                }
                
                Text(qrCodeKey)
                    .foregroundColor(.black)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                VStack(spacing: 10) {
                    Button(action:
                            guardarButtonPressed) {
                        Text("SAVE")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 55)
                            .background(Color(hue: 0.315, saturation: 0.953, brightness: 0.335))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                    }
                    
                    Button {
                        SoundManager.shared.playTransitionSound()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("RETURN")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 55)
                            .background(Color(hue: 0.69, saturation: 0.89, brightness: 0.706))
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
                Alert(title: Text(""),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
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
                    // Handle successful fetch and update relevant properties or UI here:
                    // e.g., generate QR code based on fetched user data:
                    self.qrCodeKey = self.generateQRCodeKey()
                    self.qrData = self.generateQRCodeData()
                case .failure(let error):
                    // Handle error - could be due to no user being logged in or an error fetching data
                    print("Error fetching user data: \(error.localizedDescription)")
                    // Handle the error, possibly by updating the UI to reflect that the data could not be fetched
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
                   isShowingAlert = true
                   alertMessage = "This code has already been saved."
                   return
               }
        
        
        guard let userId = Auth.auth().currentUser?.uid else {
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
                isShowingAlert = true
                SoundManager.shared.playTransitionSound()
                alertMessage = "QRCode saved. Go get your money."
            } else {
                isShowingAlert = true
                alertMessage = "Error while saving QR Code. Try again"
            }
            
            // Start the cooldown timer irrespective of whether there was an error
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
        
    


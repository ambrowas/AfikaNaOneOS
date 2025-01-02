import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseStorage

struct NuevoUsuario: View {
    @StateObject private var viewModel = NuevoUsuarioViewModel()
    @State private var shouldPresentProfile = false
    @State private var scale: CGFloat = 1.0
    @State private var glowColor = Color.blue
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isShowingProfile = false
    @State private var isShowingMenuModoCompeticion = false
    @State private var showCountryPicker = false
    @StateObject private var userData = UserData()
    @StateObject private var menuModoCompeticionViewModel = MenuModoCompeticionViewModel()

    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                
                Text("CREATE NEW USER")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 0)
                    .padding(.bottom, 20)
                
                InputFieldsView(
                    fullname: $viewModel.fullname,
                    email: $viewModel.email,
                    password: $viewModel.password,
                    telefono: $viewModel.telefono,
                    ciudad: $viewModel.ciudad,
                    selectedCountry: $viewModel.selectedCountry,
                    selectedDevice: $viewModel.selectedDevice,
                    viewModel: viewModel
                )
                
                Button(action: {
                    viewModel.crearUsuario()
                    
                }) {
                    Text("REGISTER")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 75)
                        .background(Color(hue: 0.69, saturation: 0.89, brightness: 0.706))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                .fullScreenCover(isPresented: $isShowingProfile) {
                    Profile(profileViewModel: ProfileViewModel.shared)
                }
                .padding(.bottom, 5)
                .padding(.top, 25)
                
                Button(action: {
                    SoundManager.shared.playTransitionSound()
                    isShowingMenuModoCompeticion.toggle()
                }) {
                    Text("RETURN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 300, height: 75)
                        .background(Color(hue: 1.0, saturation: 0.984, brightness: 0.699))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 3)
                        )
                }
                .fullScreenCover(isPresented: $isShowingMenuModoCompeticion) {
                    MenuModoCompeticion(userId: "DummyuserId", userData: userData, viewModel: menuModoCompeticionViewModel)
                }
                .padding(.top, 2)
            }
        }
        .alert(item: $viewModel.alertaTipo) { alertaTipo in
            switch alertaTipo {
            case .exito(let message):
                return Alert(
                    title: Text("Success"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"), action: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            SoundManager.shared.playTransitionSound()
                            isShowingProfile = true
                        }
                    })
                )
            case .error(let message):
               // SoundManager.shared.playWarningSound()
                return Alert(
                    title: Text("Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct NuevoUsuario_Previews: PreviewProvider {
    static var previews: some View {
        NuevoUsuario()
            .environmentObject(UserData()) // Pass mock environment objects if needed
            .environmentObject(MenuModoCompeticionViewModel())
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
    }
}

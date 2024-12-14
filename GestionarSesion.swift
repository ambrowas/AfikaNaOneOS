import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

struct GestionarSesion: View {
    @StateObject var viewModel = GestionarSesionViewModel()
    @State private var correoelectronico: String = ""
    @State private var contrasena: String = ""
    @State private var navegarMenuModoCompeticion = false
    @State private var isShowingNuevoUsuario = false
    @State private var isShowingVolver = false // New state variable for VOLVER button
    @State private var scale: CGFloat = 1.0
    @State private var glowColor = Color.blue
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Image("neon")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 10) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 150)
                    .shadow(color: glowColor.opacity(0.8), radius: 10, x: 0.0, y: 0.0)
                    .onAppear {
                        scale = 1.01
                    }
                    .onReceive(timer) { _ in
                        switch glowColor {
                        case Color.blue:
                            glowColor = .green
                        case Color.green:
                            glowColor = .red
                        case Color.red:
                            glowColor = .white
                        default:
                            glowColor = .blue
                        }
                    }
                    .padding(.bottom, 10)

                TextField("Email", text: $correoelectronico, onCommit: {
                    self.correoelectronico = self.correoelectronico.lowercased()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.black, lineWidth: 3)
                )

                SecureField("Password", text: $contrasena, onCommit: {})
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .padding(.bottom, 10)

                VStack(spacing: 10) {
                    Button(action: {
                       
                        viewModel.loginUsuario(correoElectronico: correoelectronico, contrasena: contrasena)
                    }) {
                        Text("LOG IN")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 75)
                            .background(Color(hue: 0.315, saturation: 0.953, brightness: 0.335))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                    }

                    // Button to show NuevoUsuario view
                    Button(action: {
                        SoundManager.shared.playTransitionSound()
                        self.isShowingNuevoUsuario = true
                    }) {
                        Text("CREATE NEW USER")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 75)
                            .background(Color(hue: 0.664, saturation: 0.935, brightness: 0.604))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                    }
                    .fullScreenCover(isPresented: $isShowingNuevoUsuario) {
                        NuevoUsuario()
                    }

                    // Button to show VOLVER view
                    Button(action: {
                        SoundManager.shared.playTransitionSound()
                        self.navegarMenuModoCompeticion = true 
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
                    .fullScreenCover(isPresented: $navegarMenuModoCompeticion) {
                        MenuModoCompeticion(userId: "DummyuserId", userData: UserData(), viewModel: MenuModoCompeticionViewModel())
                    }

                }
            }
            .environment(\.colorScheme, .light)
        }
        .alert(isPresented: $viewModel.muestraAlerta) {
            switch viewModel.alert {
            case .success(let message):
                return Alert(title: Text("Success"), message: Text(message), dismissButton: .default(Text("OK"), action: {
                    if viewModel.estaAutenticado {
                        SoundManager.shared.playTransitionSound()
                        navegarMenuModoCompeticion = true
                    }
                }))
            case .mistake(let message):
                return Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
            case .none:
                return Alert(title: Text("Unknown"))
            }
        }
        .onChange(of: viewModel.muestraAlerta) { newValue in
            if !newValue && viewModel.estaAutenticado {
                navegarMenuModoCompeticion = true
            }
        }
    }
}

struct GestionarSesion_Previews: PreviewProvider {
    static var previews: some View {
        GestionarSesion()
    }
}

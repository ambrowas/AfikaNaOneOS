import SwiftUI
import AVFoundation



struct InputFieldsView: View {
    @Binding var fullname: String
    @Binding var email: String
    @Binding var password: String
    @Binding var telefono: String
    @Binding var ciudad: String
    @Binding var selectedCountry: String
    @Binding var selectedDevice: String

    @State private var isPresentingCountryPicker = false
    @State private var isFlashing = false
    @State private var countrySearchTerm = ""

    @ObservedObject var viewModel: NuevoUsuarioViewModel

    let countries = [
        "Algeria", "Angola", "Benin", "Botswana", "Burkina Faso", "Burundi",
        "Cabo Verde", "Cameroon", "Central African Republic", "Chad", "Comoros",
        "Democratic Republic of the Congo", "Republic of the Congo", "Côte d'Ivoire",
        "Djibouti", "Egypt", "Equatorial Guinea", "Eritrea", "Eswatini", "Ethiopia",
        "Gabon", "Gambia", "Ghana", "Guinea", "Guinea-Bissau", "Kenya", "Lesotho",
        "Liberia", "Libya", "Madagascar", "Malawi", "Mali", "Mauritania", "Mauritius",
        "Morocco", "Mozambique", "Namibia", "Niger", "Nigeria", "Rwanda",
        "Sao Tome and Principe", "Senegal", "Seychelles", "Sierra Leone", "Somalia",
        "South Africa", "South Sudan", "Sudan", "Tanzania", "Togo", "Tunisia",
        "Uganda", "Zambia", "Zimbabwe", "United States", "Canada", "Brazil", "China",
        "India", "United Kingdom", "Germany", "France", "Japan", "Australia",
        "European Union", "Haiti", "Jamaica", "Cuba", "Trinidad and Tobago",
        "Barbados", "Bahamas", "Guyana", "Suriname", "Dominican Republic",
        "Antigua and Barbuda", "Other"
    ]

    let devices = ["Android", "iOS"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Full Name Input
            SingleInputFieldView(text: $fullname, placeholder: "Full Name")
                .styledInput()

            // Email Input
            SingleInputFieldView(text: $email, placeholder: "Email")
                .styledInput(contentType: .emailAddress, keyboardType: .emailAddress)

            // Password Input
            SecureInputFieldView(text: $password, placeholder: "Password")
                .styledInput()

            // Phone Input
            SingleInputFieldView(text: $telefono, placeholder: "Phone")
                .styledInput()

            // City and State/Province
            HStack(spacing: 16) {
                SingleInputFieldView(text: $ciudad, placeholder: "City")
                    .styledInput()
            }

            // Country and Device Picker
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    // Flashing "Country" Label
                    Text("Country:")
                        .font(.headline)
                        .foregroundColor(isFlashing ? .red : .white)
                        .fixedSize()
                        .onAppear {
                            withAnimation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                                isFlashing.toggle()
                            }
                        }

                    // Selected Country
                    Button(action: {
                        AudioManager.shared.playSwooshSound() // Play sound when opening picker
                        isPresentingCountryPicker = true
                    }) {
                        Text(selectedCountry.isEmpty ? "Select Country" : selectedCountry)
                            .foregroundColor(.black)
                            .frame(width: 160, height: 30)
                            .background(Color.white)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .fixedSize(horizontal: true, vertical: true)
                    }
                    .sheet(isPresented: $isPresentingCountryPicker, onDismiss: {
                        AudioManager.shared.playSwooshSound() // Play sound when closing picker
                    }) {
                        CountryPickerView(
                            selectedCountry: $selectedCountry,
                            countrySearchTerm: $countrySearchTerm,
                            countries: countries
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Device:")
                        .font(.headline)
                        .foregroundColor(.white)

                    // Custom Segment Control for Device Picker
                    HStack(spacing: 10) {
                        ForEach(devices, id: \.self) { device in
                            Text(device)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(selectedDevice == device ? Color(hue: 0.315, saturation: 0.953, brightness: 0.335) : Color.clear)
                                .foregroundColor(selectedDevice == device ? .white : .black)
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedDevice = device
                                    AudioManager.shared.playSwooshSound() // Play sound when selecting a device
                                }
                        }
                    }
                    .frame(width: 200)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
    }
}
       struct SingleInputFieldView: View {
           @Binding var text: String
           var placeholder: String
           
           var body: some View {
               TextField(placeholder, text: $text)
                   .textFieldStyle(RoundedBorderTextFieldStyle())
           }
       }

       struct SecureInputFieldView: View {
           @Binding var text: String
           var placeholder: String
           
           var body: some View {
               SecureField(placeholder, text: $text)
                   .textFieldStyle(RoundedBorderTextFieldStyle())
           }
       }

       struct CountryPickerView: View {
           @Binding var selectedCountry: String
           @Binding var countrySearchTerm: String
           let countries: [String]
           
           @Environment(\.presentationMode) var presentationMode
           
           var filteredCountries: [String] {
               if countrySearchTerm.isEmpty {
                   return countries
               } else {
                   return countries.filter { $0.localizedCaseInsensitiveContains(countrySearchTerm) }
               }
           }
           
           var body: some View {
               NavigationView {
                   List(filteredCountries, id: \.self) { country in
                       Text(country)
                           .onTapGesture {
                               selectedCountry = country
                               presentationMode.wrappedValue.dismiss()
                           }
                   }
                   .searchable(text: $countrySearchTerm, prompt: "Search countries")
                   .navigationBarTitle("Select Country", displayMode: .inline)
               }
           }
       }

       extension View {
           func styledInput(contentType: UITextContentType? = nil, keyboardType: UIKeyboardType = .default) -> some View {
               self
                   .padding(10)
                   .background(Color.white)
                   .cornerRadius(5)
                   .border(Color.black, width: 2)
                   .keyboardType(keyboardType)
           }
       }

       struct InputFieldsView_Previews: PreviewProvider {
           static var previews: some View {
               InputFieldsView(
                   fullname: .constant("John Doe"),
                   email: .constant("johndoe@example.com"),
                   password: .constant("password123"),
                   telefono: .constant("123-456-7890"),
                   ciudad: .constant("Los Angeles"),
                   selectedCountry: .constant("United States"),
                   selectedDevice: .constant("Android"),
                   viewModel: NuevoUsuarioViewModel()
               )
               .previewLayout(.sizeThatFits)
               .padding()
           }
      
       }

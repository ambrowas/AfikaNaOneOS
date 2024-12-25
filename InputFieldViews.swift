import SwiftUI
import SwiftUI

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
           "Afghanistan", "Albania", "Germany", "Andorra", "Angola",
           "Antigua and Barbuda", "Saudi Arabia", "Algeria", "Argentina", "Armenia",
           "Australia", "Austria", "Azerbaijan", "Bahamas", "Bangladesh",
           "Barbados", "Bahrain", "Belgium", "Belize", "Benin",
           "Belarus", "Myanmar", "Bolivia", "Bosnia and Herzegovina", "Botswana",
           "Brazil", "Brunei", "Bulgaria", "Burkina Faso", "Burundi",
           "Bhutan", "Cape Verde", "Cambodia", "Cameroon", "Canada",
           "Qatar", "Chad", "Chile", "China", "Cyprus",
           "Vatican City", "Colombia", "Comoros", "North Korea", "South Korea",
           "Ivory Coast", "Costa Rica", "Croatia", "Cuba", "Denmark",
           "Dominica", "Ecuador", "Egypt", "El Salvador", "United Arab Emirates",
           "Eritrea", "Slovakia", "Slovenia", "Spain", "United States",
           "Estonia", "Ethiopia", "Philippines", "Finland", "Fiji",
           "France", "Gabon", "Gambia", "Georgia", "Ghana",
           "Grenada", "Greece", "Guatemala", "Guinea", "Guinea-Bissau",
           "Equatorial Guinea", "Guyana", "Haiti", "Honduras", "Hungary",
           "India", "Indonesia", "Iraq", "Iran", "Ireland",
           "Iceland", "Marshall Islands", "Solomon Islands", "Israel", "Italy",
           "Jamaica", "Japan", "Jordan", "Kazakhstan", "Kenya",
           "Kyrgyzstan", "Kiribati", "Kuwait", "Laos", "Lesotho",
           "Latvia", "Lebanon", "Liberia", "Libya", "Liechtenstein",
           "Lithuania", "Luxembourg", "North Macedonia", "Madagascar", "Malaysia",
           "Malawi", "Maldives", "Mali", "Malta", "Morocco",
           "Mauritius", "Mauritania", "Mexico", "Micronesia", "Moldova",
           "Monaco", "Mongolia", "Montenegro", "Mozambique", "Namibia",
           "Nauru", "Nepal", "Nicaragua", "Niger", "Nigeria",
           "Norway", "New Zealand", "Oman", "Netherlands", "Pakistan",
           "Palau", "Palestine", "Panama", "Papua New Guinea", "Paraguay",
           "Peru", "Poland", "Portugal", "United Kingdom", "Central African Republic",
           "Czech Republic", "Republic of the Congo", "Democratic Republic of the Congo", "Dominican Republic", "Rwanda",
           "Romania", "Russia", "Samoa", "Saint Kitts and Nevis", "San Marino",
           "Saint Vincent and the Grenadines", "Saint Lucia", "Sao Tome and Principe", "Senegal", "Serbia",
           "Seychelles", "Sierra Leone", "Singapore", "Syria", "Somalia",
           "Sri Lanka", "Eswatini", "South Africa", "Sudan", "South Sudan",
           "Sweden", "Switzerland", "Suriname", "Thailand", "Tanzania",
           "Tajikistan", "East Timor", "Togo", "Tonga", "Trinidad and Tobago",
           "Tunisia", "Turkmenistan", "Turkey", "Tuvalu", "Ukraine",
           "Uganda", "Uruguay", "Uzbekistan", "Vanuatu", "Venezuela",
           "Vietnam", "Yemen", "Djibouti", "Zambia", "Zimbabwe"
       
       ]
    
    let devices = ["Android", "Apple"]
    
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
                                      .onAppear {
                                          withAnimation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                                              isFlashing.toggle()
                                          }
                                      }

                                  // Selected Country
                                  Button(action: { isPresentingCountryPicker = true }) {
                                      Text(selectedCountry.isEmpty ? "Select Country" : selectedCountry)
                                          .foregroundColor(.black)
                                          .frame(width: 160, height: 30)
                                          .background(Color.white)
                                          .cornerRadius(5)
                                          .overlay(
                                              RoundedRectangle(cornerRadius: 5)
                                                  .stroke(Color.black, lineWidth: 2)
                                          )
                                          .fixedSize(horizontal: true, vertical: true) // Prevent resizing
                                  }
                                  .sheet(isPresented: $isPresentingCountryPicker) {
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

                                  Picker("Device", selection: $selectedDevice) {
                                      ForEach(devices, id: \.self) { device in
                                          Text(device)
                                              .foregroundColor(.white)
                                              .frame(maxWidth: .infinity)
                                              .background(device == selectedDevice ? Color.green : Color.white)
                                              .cornerRadius(5)
                                      }
                                  }
                                  .pickerStyle(SegmentedPickerStyle())
                                  .frame(width: 160)
                                  .background(Color.white)
                                  .border(Color.black, width: 2)
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

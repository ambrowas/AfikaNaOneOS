import SwiftUI


struct SearchablePickerView: View {
    let countries = [
        "Afghanistan", "Albania", "Germany", "Andorra", "Angola",
        "Antigua and Barbuda", "Saudi Arabia", "Algeria", "Argentina", "Armenia",
        "Australia", "Austria", "Azerbaijan", "Bahamas", "Bangladesh",
        "Barbados", "Bahrain", "Belgium", "Belize", "Benin",
        "Belarus", "Burma", "Bolivia", "Bosnia and Herzegovina", "Botswana",
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
    
    @Binding var selectedCountry: String
    @Binding var isPresented: Bool
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(countries.filter { searchText.isEmpty || $0.localizedCaseInsensitiveContains(searchText) }, id: \.self) { country in
                    Text(country).onTapGesture {
                        selectedCountry = country
                        isPresented = false
                    }
                }
            }
            .navigationTitle("Selecciona un país")
            .searchable(text: $searchText)
            .toolbar {
                Button("Cancelar") {
                    isPresented = false
                }
            }
        }
    }
}

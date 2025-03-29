import SwiftUI

struct SettingsView: View {
    // MARK: - App Storage Defaults
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("hideBalances") private var hideBalances = false
    @AppStorage("language") private var language = "English"
    @AppStorage("selectedCurrency") private var selectedCurrency = "USD"
    
    // New state to present AddHoldingView
    @State private var showAddHoldingSheet = false
    
    // Assume PortfolioViewModel is provided via EnvironmentObject
    @EnvironmentObject var portfolioViewModel: PortfolioViewModel
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Profile Header
                Section {
                    ProfileHeaderView()
                }
                .listRowInsets(EdgeInsets()) // Full-width header
                .listRowSeparator(.hidden)
                
                // MARK: - Account
                Section {
                    NavigationLink(destination: ProfileView()) {
                        SettingsRow(icon: "person.crop.circle",
                                    title: "Profile & Personal Info")
                    }
                    NavigationLink(destination: PaymentMethodsView()) {
                        SettingsRow(icon: "creditcard",
                                    title: "Payment Methods")
                    }
                } header: {
                    Text("ACCOUNT")
                }
                
                // MARK: - Security
                Section {
                    NavigationLink(destination: SecuritySettingsView()) {
                        SettingsRow(icon: "lock.shield",
                                    title: "Security & Login")
                    }
                } header: {
                    Text("SECURITY")
                }
                
                // MARK: - Appearance
                Section {
                    Toggle(isOn: $isDarkMode) {
                        SettingsRow(icon: "moon.fill",
                                    title: "Dark Mode",
                                    showChevron: false)
                    }
                    Toggle(isOn: $hideBalances) {
                        SettingsRow(icon: "eye.slash",
                                    title: "Privacy Mode (Hide Balances)",
                                    showChevron: false)
                    }
                } header: {
                    Text("APPEARANCE")
                }
                
                // MARK: - Preferences
                Section {
                    NavigationLink(destination: LanguageSettingsView(selectedLanguage: $language)) {
                        HStack {
                            SettingsRow(icon: "globe", title: "Language", showChevron: false)
                            Spacer()
                            Text(language)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink(destination: CurrencySettingsView(selectedCurrency: $selectedCurrency)) {
                        HStack {
                            SettingsRow(icon: "dollarsign.circle", title: "Display Currency", showChevron: false)
                            Spacer()
                            Text(selectedCurrency)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("PREFERENCES")
                }
                
                // MARK: - Connected Accounts
                Section {
                    NavigationLink(destination: ConnectedAccountsView()) {
                        SettingsRow(icon: "link",
                                    title: "Manage Connected Accounts")
                    }
                } header: {
                    Text("CONNECTED ACCOUNTS")
                }
                
                // MARK: - Portfolio Management
                Section {
                    Button(action: {
                        showAddHoldingSheet = true
                    }) {
                        SettingsRow(icon: "plus.circle",
                                    title: "Add Holdings",
                                    showChevron: false)
                    }
                } header: {
                    Text("PORTFOLIO MANAGEMENT")
                }
                
                // MARK: - About & Support
                Section {
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(icon: "info.circle",
                                    title: "About CryptoSage AI")
                    }
                    NavigationLink(destination: HelpView()) {
                        SettingsRow(icon: "questionmark.circle",
                                    title: "Help & Support")
                    }
                } header: {
                    Text("ABOUT & SUPPORT")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            // Present AddHoldingView when showAddHoldingSheet is true.
            .sheet(isPresented: $showAddHoldingSheet) {
                AddTransactionView(viewModel: portfolioViewModel)
            }
        }
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .frame(height: 140)
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.white)
                Text("John Doe")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("john.doe@example.com")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
        }
    }
}

// MARK: - Custom Row
struct SettingsRow: View {
    let icon: String
    let title: String
    var showChevron: Bool = true
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Security & Login View
struct SecuritySettingsView: View {
    @AppStorage("isPasscodeEnabled") private var isPasscodeEnabled = false
    @AppStorage("enableBiometric") private var enableBiometric = false
    @AppStorage("enable2FA") private var enable2FA = false
    
    var body: some View {
        Form {
            Section(header: Text("App Protection")) {
                Toggle("Enable Passcode", isOn: $isPasscodeEnabled)
                Toggle("Enable Biometric (Face ID / Touch ID)", isOn: $enableBiometric)
            }
            Section(header: Text("Two-Factor Authentication")) {
                Toggle("Enable 2FA", isOn: $enable2FA)
                NavigationLink("Trusted Devices", destination: TrustedDevicesView())
            }
            Section(header: Text("Password Management")) {
                NavigationLink("Change Password", destination: ChangePasswordView())
            }
        }
        .navigationTitle("Security & Login")
    }
}

struct TrustedDevicesView: View {
    var body: some View {
        Text("Manage your trusted devices here.")
            .navigationTitle("Trusted Devices")
    }
}

struct ChangePasswordView: View {
    var body: some View {
        Text("Change your password here.")
            .navigationTitle("Change Password")
    }
}

// MARK: - Stub Destination Views
struct ProfileView: View {
    var body: some View {
        Text("Profile & Personal Info Settings")
            .navigationTitle("Profile")
    }
}

struct PaymentMethodsView: View {
    var body: some View {
        Text("Manage your linked payment methods here.")
            .navigationTitle("Payment Methods")
    }
}

struct ConnectedAccountsView: View {
    var body: some View {
        Text("Link or disconnect exchange/wallet accounts here.")
            .navigationTitle("Connected Accounts")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CryptoSage AI")
                .font(.title)
            Text("Version 1.0.0")
                .foregroundColor(.gray)
            Text("CryptoSage AI is your personal crypto assistant ...")
            Spacer()
        }
        .padding()
        .navigationTitle("About")
    }
}

struct HelpView: View {
    var body: some View {
        Text("Help & Support")
            .navigationTitle("Help & Support")
    }
}

struct LanguageSettingsView: View {
    @Binding var selectedLanguage: String
    
    var body: some View {
        Form {
            Picker("Language", selection: $selectedLanguage) {
                Text("English").tag("English")
                Text("Spanish").tag("Spanish")
                Text("French").tag("French")
            }
        }
        .navigationTitle("Language")
    }
}

struct CurrencySettingsView: View {
    @Binding var selectedCurrency: String
    
    var body: some View {
        Form {
            Picker("Display Currency", selection: $selectedCurrency) {
                Text("USD").tag("USD")
                Text("EUR").tag("EUR")
                Text("GBP").tag("GBP")
            }
        }
        .navigationTitle("Display Currency")
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(PortfolioViewModel())
    }
}

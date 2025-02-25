import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: Binding(
                        get: { authManager.userProfile.darkModeEnabled },
                        set: { authManager.userProfile.darkModeEnabled = $0 }
                    ))
                }
                
                Section("Profile") {
                    TextField("Name", text: Binding(
                        get: { authManager.userProfile.name },
                        set: { authManager.userProfile.name = $0 }
                    ))
                    
                    TextField("Email", text: Binding(
                        get: { authManager.userProfile.email },
                        set: { authManager.userProfile.email = $0 }
                    ))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                }
                
                Section("Preferences") {
                    Picker("Weather Preference", selection: Binding(
                        get: { authManager.userProfile.weatherPreference },
                        set: { authManager.userProfile.weatherPreference = $0 }
                    )) {
                        Text("Tropic").tag("Tropic")
                        Text("Cold").tag("Cold")
                        Text("Sunny").tag("Sunny")
                    }
                }
                
                Section("Connected Accounts") {
                    if authManager.isAppleConnected {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Apple ID")
                            Spacer()
                            Button("Disconnect") {
                                authManager.disconnectApple()
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    if authManager.isPinterestConnected {
                        HStack {
                            Image("pinterest.logo") // Add this asset
                            Text("Pinterest")
                            Spacer()
                            Button("Disconnect") {
                                authManager.disconnectPinterest()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        // Reset user profile
                        authManager.userProfile = UserProfile()
                        dismiss()
                    } label: {
                        Text("Reset Preferences")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
} 
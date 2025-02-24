struct AccountView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var showingAccountSheet: Bool
    let onSignOut: () -> Void
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading) {
                        Text(authManager.userProfile.name)
                            .font(.headline)
                        Text(authManager.userProfile.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Toggle("Dark Mode", isOn: $authManager.userProfile.darkModeEnabled)
                Button(action: {
                    // Immediately sign out without confirmation
                    onSignOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Account")
    }
} 
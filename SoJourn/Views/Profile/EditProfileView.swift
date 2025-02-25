import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var email: String
    
    init() {
        // Initialize state with current values
        _name = State(initialValue: "")
        _email = State(initialValue: "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Profile Information")) {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            Section {
                Button("Save Changes") {
                    // Update profile
                    authManager.userProfile.name = name
                    authManager.userProfile.email = email
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
                
                Button("Cancel") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            // Load current values
            name = authManager.userProfile.name
            email = authManager.userProfile.email
        }
    }
} 
import SwiftUI

struct LandingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSignIn = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("SoJourn")
                .font(.system(size: 40, weight: .bold))
            
            Text("Plan your perfect trip with AI")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    authManager.isNewUser = true
                    authManager.signInWithPinterest()
                }) {
                    HStack {
                        Image("pinterest-logo") // Add this to assets
                        Text("Continue with Pinterest")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    authManager.isNewUser = true
                    authManager.signInWithApple()
                }) {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Continue with Apple")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showSignIn = true
                }) {
                    Text("Sign in with Email")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .sheet(isPresented: $showSignIn) {
            EmailSignInView()
        }
    }
}

struct EmailSignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                
                Button(action: {
                    authManager.signInWithEmail(email: email, password: password)
                    dismiss()
                }) {
                    Text("Sign In")
                }
                
                Button(action: {
                    // Handle sign up
                }) {
                    Text("Create Account")
                }
            }
            .navigationTitle("Sign In")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
} 
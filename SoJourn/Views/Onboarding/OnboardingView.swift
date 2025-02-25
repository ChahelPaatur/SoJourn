import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showSignIn = false
    @State private var showQuiz = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Title Section
            VStack(spacing: 16) {
                Text("Planning trips")
                    .font(.system(size: 40, weight: .bold))
                Text("made easy")
                    .font(.system(size: 40, weight: .bold))
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                Button {
                    showQuiz = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button("Already have an account? Sign in") {
                    showSignIn = true
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
        }
        .fullScreenCover(isPresented: $showQuiz) {
            PreferenceQuizView()
        }
    }
}

struct SignInView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("SoJourn")
                    .font(.largeTitle)
                    .bold()
                
                Text("Login")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Forgot Password?") {
                        // Handle forgot password
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                }
                .padding(.vertical)
                
                VStack(spacing: 16) {
                    Button {
                        authManager.signInWithApple()
                    } label: {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Continue with Apple")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    
                    Button {
                        authManager.signInWithPinterest()
                    } label: {
                        HStack {
                            Image("pinterest.logo")
                            Text("Continue with Pinterest")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
} 
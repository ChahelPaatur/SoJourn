import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showSignIn = false
    @State private var showQuiz = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Logo or Icon
            Image(systemName: "airplane.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            // Title
            Text("SoJourn")
                .font(.system(size: 40, weight: .bold))
            
            // Tagline
            Text("Planning trips made easy")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Sign In Options
            VStack(spacing: 16) {
                // Apple Sign In
                Button {
                    authManager.signInWithApple()
                    showQuiz = true
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Continue with Apple")
                            .font(.headline)
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
                
                // Pinterest Sign In
                Button {
                    authManager.signInWithPinterest()
                    showQuiz = true
                } label: {
                    HStack {
                        Image("pinterest.logo") // Add this to assets
                        Text("Continue with Pinterest")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Email Sign In
                Button {
                    showSignIn = true
                } label: {
                    Text("Sign in with Email")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            
            // Sign In Link
            Button("Already have an account? Sign in") {
                showSignIn = true
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.bottom)
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
        }
        .fullScreenCover(isPresented: $showQuiz) {
            PreferenceQuizView()
        }
    }
} 
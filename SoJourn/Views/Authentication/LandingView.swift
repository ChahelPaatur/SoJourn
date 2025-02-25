import SwiftUI
import AuthenticationServices

struct LandingView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingSignIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Main landing content
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Planning trips")
                        .font(.system(size: 40, weight: .bold))
                    
                    Text("made easy")
                        .font(.system(size: 40, weight: .bold))
                }
                
                Button {
                    authManager.showWelcomeScreen = true
                    authManager.isAuthenticated = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.black)
                        .cornerRadius(25)
                }
                .padding(.top, 30)
                
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    
                    Button("Sign in") {
                        withAnimation(.spring()) {
                            showingSignIn = true
                        }
                    }
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            
            // Sign in overlay
            if showingSignIn {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showingSignIn = false
                        }
                    }
                
                GeometryReader { geometry in
                    VStack(spacing: 20) {
                        Text("SoJourn")
                            .font(.largeTitle)
                            .bold()
                            .padding(.top, 30)
                        
                        Text("Login")
                            .font(.title2)
                            .padding(.top, 10)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Enter your email", text: $email)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                            
                            Text("Password")
                                .padding(.top, 10)
                            
                            SecureField("Enter your password", text: $password)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Button("Forgot Password?") {
                                // Handle forgot password
                            }
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 15) {
                            Button {
                                authManager.signIn(email: email, password: password)
                                withAnimation(.spring()) {
                                    showingSignIn = false
                                }
                            } label: {
                                Text("Continue with Apple")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black)
                                    .cornerRadius(25)
                            }
                            
                            Button {
                                authManager.signInWithPinterest()
                                withAnimation(.spring()) {
                                    showingSignIn = false
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "p.circle.fill")
                                        .foregroundColor(.white)
                                    Text("Continue with Pinterest")
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(25)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding()
                    .shadow(radius: 10)
                    .offset(y: showingSignIn ? 0 : geometry.size.height)
                    .animation(.spring(), value: showingSignIn)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(AuthenticationManager.shared)
} 
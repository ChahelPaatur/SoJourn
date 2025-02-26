import SwiftUI

struct GetStartedQuizView: View {
    @State private var currentStep = 0
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingPassword = false
    @State private var agreedToTerms = false
    
    // Add the missing variable for number of steps
    private let numberOfSteps = 4 // Adjust this based on your actual quiz length
    
    var body: some View {
        VStack {
            // Quiz content section - Add your actual quiz content here
            if currentStep == 0 {
                // First quiz screen
                VStack(spacing: 20) {
                    Text("Welcome to SoJourn")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Let's personalize your travel experience")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Add your first question content here
                }
                .padding()
            } else if currentStep == 1 {
                // Second quiz screen
                VStack(spacing: 20) {
                    Text("Travel Preferences")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Add your second question content here
                }
                .padding()
            } else if currentStep == 2 {
                // Third quiz screen
                VStack(spacing: 20) {
                    Text("Accommodation Style")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Add your third question content here
                }
                .padding()
            }
            
            // Final step with signup form instead of "Enter Home" button
            if currentStep == numberOfSteps - 1 {
                VStack(spacing: 20) {
                    Text("Create Your Account")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Name field
                    TextField("Full Name", text: $name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.words)
                    
                    // Email field
                    TextField("Email Address", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    // Password field
                    HStack {
                        if showingPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        
                        Button {
                            showingPassword.toggle()
                        } label: {
                            Image(systemName: showingPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Confirm password field
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    // Terms agreement
                    HStack {
                        Button {
                            agreedToTerms.toggle()
                        } label: {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(agreedToTerms ? .blue : .gray)
                        }
                        
                        Text("I agree to the Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Sign Up button (replaces "Enter Home" button)
                    Button {
                        // Handle signup
                        createAccount()
                    } label: {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                    
                    // Optional: Add a sign in link for existing users
                    Button {
                        // Handle navigation to sign in
                    } label: {
                        Text("Already have an account? Sign In")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            } else {
                // Navigation buttons
                HStack {
                    Button("Back") {
                        if currentStep > 0 {
                            currentStep -= 1
                        }
                    }
                    .opacity(currentStep > 0 ? 1 : 0)
                    
                    Spacer()
                    
                    Button("Next") {
                        if currentStep < numberOfSteps - 1 {
                            currentStep += 1
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // Form validation
    var isFormValid: Bool {
        !name.isEmpty && 
        !email.isEmpty && email.contains("@") &&
        password.count >= 6 && 
        password == confirmPassword &&
        agreedToTerms
    }
    
    // Account creation
    func createAccount() {
        // Implement your account creation logic here
        // This would typically involve:
        // 1. Validating the input
        // 2. Creating the user in your authentication system
        // 3. Saving user preferences from the quiz
        // 4. Navigating to the home screen
    }
} 
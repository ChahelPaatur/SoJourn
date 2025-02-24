import SwiftUI

struct PreferenceQuizView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentStep = 0
    @State private var userData = UserData()
    @State private var showThankYou = false
    @State private var slideOffset: CGFloat = 0
    @State private var opacity: Double = 1
    
    let genderOptions = ["Male", "Female", "Prefer not to say"]
    let weatherOptions = ["Cold", "Sunny", "Other"]
    let referralOptions = ["Instagram", "TikTok", "Friends", "Other"]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.black.opacity(0.1))
                            .frame(width: geometry.size.width * 0.8, height: 5) // 80% of screen width
                        
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: (geometry.size.width * 0.8) * CGFloat(currentStep + 1) / 7, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 5)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                if showThankYou {
                    thankYouView
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                } else {
                    // Question Title
                    Text(getQuestionTitle())
                        .font(.custom("SF Pro Display", size: 28))
                        .fontWeight(.bold)
                        .padding(.top, 40)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    
                    // Content
                    Group {
                        switch currentStep {
                        case 0:
                            nameInputView
                        case 1:
                            genderSelectionView
                        case 2:
                            weatherPreferenceView
                        case 3:
                            pinterestAccessView
                        case 4:
                            contactsAccessView
                        case 5:
                            birthdateView
                        case 6:
                            referralSourceView
                        default:
                            EmptyView()
                        }
                    }
                    .offset(x: slideOffset)
                    .opacity(opacity)
                    
                    Spacer()
                    
                    // Navigation
                    HStack(spacing: 12) {
                        if currentStep > 0 {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    slideOffset = 50
                                    opacity = 0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    currentStep -= 1
                                    slideOffset = -50
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        slideOffset = 0
                                        opacity = 1
                                    }
                                }
                            }) {
                                Text("← Back")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .cornerRadius(25)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                        
                        Button(action: {
                            animateToNextStep()
                        }) {
                            Text(currentStep == 6 ? "Submit →" : "Next →")
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                        }
                        .disabled(currentStep == 0 && (userData.firstName.isEmpty || userData.lastName.isEmpty))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var nameInputView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("First Name")
                    .foregroundColor(.gray)
                TextField("First Name", text: $userData.firstName)
                    .textFieldStyle(ModernTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Last Name")
                    .foregroundColor(.gray)
                TextField("Last Name", text: $userData.lastName)
                    .textFieldStyle(ModernTextFieldStyle())
            }
        }
        .padding(.horizontal)
    }
    
    private var genderSelectionView: some View {
        VStack(spacing: 20) { // Increased spacing
            ForEach(genderOptions, id: \.self) { option in
                QuizOptionButton(
                    title: option,
                    isSelected: userData.gender == option,
                    action: { userData.gender = option }
                )
            }
        }
        .padding(.top, 20) // Add top padding
    }
    
    private var weatherPreferenceView: some View {
        VStack(spacing: 15) {
            Text("Preferred weather?")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(weatherOptions, id: \.self) { option in
                    QuizOptionButton(
                        title: option,
                        isSelected: userData.preferredWeather == option,
                        action: { userData.preferredWeather = option }
                    )
                }
            }
        }
    }
    
    private func getQuestionTitle() -> String {
        switch currentStep {
        case 0:
            return "Get Started"
        case 1:
            return "What Is Your Gender?"
        case 2:
            return "Preferred Weather?"
        case 3:
            return "Can we have access to your Pinterest?"
        case 4:
            return "Allow contacts for trip sharing/planning?"
        case 5:
            return "How old are you?"
        case 6:
            return "How did you hear about us?"
        default:
            return ""
        }
    }
    
    private var pinterestAccessView: some View {
        VStack(spacing: 12) {
            ForEach(["Yes", "No"], id: \.self) { option in
                QuizOptionButton(
                    title: option,
                    isSelected: (option == "Yes") ? userData.allowPinterest : !userData.allowPinterest,
                    action: { userData.allowPinterest = (option == "Yes") }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var contactsAccessView: some View {
        VStack(spacing: 12) {
            ForEach(["Yes", "No"], id: \.self) { option in
                QuizOptionButton(
                    title: option,
                    isSelected: (option == "Yes") ? userData.allowContacts : !userData.allowContacts,
                    action: { userData.allowContacts = (option == "Yes") }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var birthdateView: some View {
        VStack {
            DatePicker("", selection: $userData.birthDate, displayedComponents: [.date])
                .datePickerStyle(.wheel)
                .labelsHidden()
        }
        .padding(.horizontal)
    }
    
    private var referralSourceView: some View {
        VStack(spacing: 12) {
            ForEach(referralOptions, id: \.self) { option in
                QuizOptionButton(
                    title: option,
                    isSelected: userData.referralSource == option,
                    action: { userData.referralSource = option }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var thankYouView: some View {
        VStack(alignment: .center, spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Thank You")
                    .font(.system(size: 40, weight: .bold))
                
                Text(userData.firstName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.gray)
                
                Text("For using our app")
                    .font(.system(size: 24, weight: .medium))
            }
            
            Spacer()
            
            Button(action: {
                authManager.hasCompletedQuiz = true
            }) {
                Text("Continue →")
                    .font(.system(size: 18, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private func animateToNextStep() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            slideOffset = -50
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if currentStep == 6 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showThankYou = true
                }
            } else {
                currentStep += 1
                slideOffset = 50
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    slideOffset = 0
                    opacity = 1
                }
            }
        }
    }
}

struct QuizOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Radio circle
                Circle()
                    .strokeBorder(isSelected ? Color.white : Color.black.opacity(0.2), lineWidth: 1)
                    .frame(width: 24, height: 24) // Slightly larger
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.white : Color.clear)
                            .frame(width: 12, height: 12)
                    )
                
                Text(title)
                    .font(.system(size: 18, weight: .regular)) // Larger font
                    .foregroundColor(isSelected ? .white : .black)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16) // Taller buttons
            .background(isSelected ? Color.black : Color.white)
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.black.opacity(0.1), lineWidth: isSelected ? 0 : 1)
            )
        }
        .padding(.horizontal, 24)
    }
}

struct ModernDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 18, weight: .regular)) // Larger font
            .padding(.vertical, 16) // Taller text fields
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
    }
}

#Preview {
    PreferenceQuizView()
        .environmentObject(AuthenticationManager())
} 
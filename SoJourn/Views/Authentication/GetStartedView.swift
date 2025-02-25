import SwiftUI

struct GetStartedView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var currentStep = 0
    @State private var age = 25.0
    @State private var selectedGender: String?
    @State private var selectedWeather: String?
    @State private var allowPinterestAccess = false
    @State private var allowContacts = false
    @State private var howDidYouHear: String?
    
    // Options for each question
    let genderOptions = ["Male", "Female", "Prefer not to say"]
    let weatherOptions = ["Tropic", "Cold", "Sunny", "Other"]
    let yesNoOptions = ["Yes", "No"]
    let hearAboutUsOptions = ["Instagram", "TikTok", "Friends", "Other"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(height: 4)
                    .foregroundColor(Color.gray.opacity(0.3))
                
                Rectangle()
                    .frame(width: getProgressWidth(), height: 4)
                    .foregroundColor(.black)
            }
            .padding(.top)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Logo/icon at top
                    HStack {
                        Image(systemName: "sun.max")
                            .font(.title)
                        Spacer()
                    }
                    .padding(.top, 30)
                    
                    // Question content
                    switch currentStep {
                    case 0:
                        genderView
                    case 1:
                        weatherView
                    case 2:
                        pinterestAccessView
                    case 3:
                        contactsView
                    case 4:
                        ageView
                    case 5:
                        hearAboutUsView
                    case 6:
                        thankYouView
                    default:
                        EmptyView()
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Navigation buttons
                    if currentStep < 6 {
                        HStack {
                            if currentStep > 0 {
                                Button(action: {
                                    withAnimation {
                                        currentStep -= 1
                                    }
                                }) {
                                    HStack {
                                        Text("Back")
                                            .fontWeight(.medium)
                                    }
                                    .frame(width: 80, height: 36)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    if currentStep == 5 {
                                        currentStep += 1
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            completeOnboarding()
                                        }
                                    } else {
                                        currentStep += 1
                                    }
                                }
                            }) {
                                HStack {
                                    Text(currentStep == 5 ? "Submit" : "Next")
                                        .fontWeight(.medium)
                                    if currentStep != 5 {
                                        Image(systemName: "chevron.right")
                                            .font(.footnote)
                                    }
                                }
                                .frame(width: 80, height: 36)
                                .background(isNextButtonDisabled ? Color.gray.opacity(0.2) : Color.black)
                                .foregroundColor(isNextButtonDisabled ? .gray : .white)
                                .cornerRadius(8)
                            }
                            .disabled(isNextButtonDisabled)
                        }
                        .padding(.bottom, 30)
                    } else {
                        Button("Enter Home") {
                            completeOnboarding()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom, 30)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var isNextButtonDisabled: Bool {
        switch currentStep {
        case 0: return selectedGender == nil
        case 1: return selectedWeather == nil
        case 2: return false // Yes/No question always has a selection
        case 3: return false // Yes/No question always has a selection
        case 4: return false // Age slider always has a value
        case 5: return howDidYouHear == nil
        default: return false
        }
    }
    
    private func getProgressWidth() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let progress = CGFloat(currentStep) / 6.0
        return screenWidth * progress
    }
    
    // MARK: - Question Views
    
    private var genderView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What Is Your Gender?")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(genderOptions, id: \.self) { option in
                    Button {
                        selectedGender = option
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray, lineWidth: 1)
                                    .frame(width: 24, height: 24)
                                
                                if selectedGender == option {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 16, height: 16)
                                }
                            }
                            
                            Text(option)
                                .foregroundColor(.black)
                                .padding(.leading, 8)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(selectedGender == option ? Color.black.opacity(0.1) : Color.white)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var weatherView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preferred Weather?")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(weatherOptions, id: \.self) { option in
                    Button {
                        selectedWeather = option
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray, lineWidth: 1)
                                    .frame(width: 24, height: 24)
                                
                                if selectedWeather == option {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 16, height: 16)
                                }
                            }
                            
                            Text(option)
                                .foregroundColor(.black)
                                .padding(.leading, 8)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(selectedWeather == option ? Color.black.opacity(0.1) : Color.white)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var pinterestAccessView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Can we have access to your Pinterest?")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(yesNoOptions, id: \.self) { option in
                    Button {
                        allowPinterestAccess = option == "Yes"
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray, lineWidth: 1)
                                    .frame(width: 24, height: 24)
                                
                                if (option == "Yes" && allowPinterestAccess) || 
                                   (option == "No" && !allowPinterestAccess) {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 16, height: 16)
                                }
                            }
                            
                            Text(option)
                                .foregroundColor(.black)
                                .padding(.leading, 8)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background((option == "Yes" && allowPinterestAccess) || 
                                           (option == "No" && !allowPinterestAccess) ? 
                                           Color.black.opacity(0.1) : Color.white)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var contactsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Allow contacts for trip sharing/planning?")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(yesNoOptions, id: \.self) { option in
                    Button {
                        allowContacts = option == "Yes"
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray, lineWidth: 1)
                                    .frame(width: 24, height: 24)
                                
                                if (option == "Yes" && allowContacts) || 
                                   (option == "No" && !allowContacts) {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 16, height: 16)
                                }
                            }
                            
                            Text(option)
                                .foregroundColor(.black)
                                .padding(.leading, 8)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background((option == "Yes" && allowContacts) || 
                                           (option == "No" && !allowContacts) ? 
                                           Color.black.opacity(0.1) : Color.white)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var ageView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How old are you?")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("DRAG THE SLIDER TO SELECT YOUR AGE")
                .font(.caption)
                .foregroundColor(.gray)
            
            VStack {
                Slider(value: $age, in: 18...100, step: 1)
                    .accentColor(.black)
                
                Text("\(Int(age))")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 10)
            }
            .padding(.top, 20)
        }
    }
    
    private var hearAboutUsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How did you hear about us?")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(hearAboutUsOptions, id: \.self) { option in
                    Button {
                        howDidYouHear = option
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray, lineWidth: 1)
                                    .frame(width: 24, height: 24)
                                
                                if howDidYouHear == option {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 16, height: 16)
                                }
                            }
                            
                            Text(option)
                                .foregroundColor(.black)
                                .padding(.leading, 8)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(howDidYouHear == option ? Color.black.opacity(0.1) : Color.white)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var thankYouView: some View {
        VStack(spacing: 30) {
            Text("Thank You")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("For using our app")
                .font(.title2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func completeOnboarding() {
        // Save user preferences
        authManager.userProfile.age = Int(age)
        authManager.userProfile.gender = selectedGender ?? ""
        authManager.userProfile.weatherPreference = selectedWeather ?? ""
        authManager.userProfile.pinterestConnected = allowPinterestAccess
        
        // Complete onboarding
        authManager.showWelcomeScreen = false
        authManager.isAuthenticated = true
    }
}

#Preview {
    GetStartedView()
        .environmentObject(AuthenticationManager.shared)
} 
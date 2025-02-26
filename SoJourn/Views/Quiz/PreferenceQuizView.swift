import SwiftUI

struct PreferenceQuizView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestionIndex = 0
    @State private var selectedGender = ""
    @State private var selectedWeather = ""
    @State private var allowContacts = false
    @State private var age = ""
    @State private var pinterestAccess = false
    @State private var discoverySource = ""
    @State private var showingInfo = false
    @State private var currentInfoType: InfoType? = nil
    @State private var isValid = false
    
    private let questions = [
        "What Is Your Gender?",
        "Preferred Weather?",
        "Allow contacts for trip sharing/planning?",
        "How old are you?",
        "Can we have access to your Pinterest?",
        "How did you hear about us?"
    ]
    
    enum InfoType: String, Identifiable {
        case weather = "Weather Preference"
        case pinterest = "Pinterest Access"
        case budget = "Budget Planning"
        case duration = "Trip Duration"
        case interests = "Your Interests"
        case transportation = "Transportation"
        case accommodation = "Accommodation"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .weather: return "thermometer"
            case .pinterest: return "link"
            case .budget: return "dollarsign.circle"
            case .duration: return "calendar"
            case .interests: return "heart"
            case .transportation: return "car"
            case .accommodation: return "house"
            }
        }
        
        var description: String {
            switch self {
            case .weather:
                return "We use your weather preference to suggest destinations and activities that match your comfort level."
            case .pinterest:
                return "Connecting your Pinterest allows us to personalize your trip suggestions based on your saved pins and boards."
            case .budget:
                return "Help us understand your budget range to recommend suitable accommodations and activities."
            case .duration:
                return "Let us know your preferred trip duration to better plan your itinerary."
            case .interests:
                return "Share your interests so we can customize your travel experiences."
            case .transportation:
                return "Tell us how you prefer to travel between destinations."
            case .accommodation:
                return "Let us know your accommodation preferences for better recommendations."
            }
        }
    }
    
    private func validateCurrentQuestion() -> Bool {
        switch currentQuestionIndex {
        case 0: // Gender
            return !selectedGender.isEmpty
        case 1: // Weather
            return !selectedWeather.isEmpty
        case 2: // Contacts
            return true // Always valid since it's a toggle
        case 3: // Age
            guard let ageInt = Int(age) else { return false }
            return ageInt >= 13 && ageInt <= 120
        case 4: // Pinterest
            return true // Always valid since it's a toggle
        case 5: // Discovery
            return !discoverySource.isEmpty
        default:
            return false
        }
    }
    
    private func moveToNextQuestion() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        
        withAnimation {
            if currentQuestionIndex < questions.count - 1 {
                currentQuestionIndex += 1
                generator.impactOccurred()
            } else {
                // Complete quiz
                generator.impactOccurred(intensity: 1.0)
                authManager.isAuthenticated = true
            }
        }
    }
    
    private func moveToPreviousQuestion() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        
        withAnimation {
            if currentQuestionIndex > 0 {
                currentQuestionIndex -= 1
                generator.impactOccurred()
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 2)
                    .overlay(
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * (CGFloat(currentQuestionIndex) / CGFloat(questions.count - 1)))
                            .animation(.easeInOut, value: currentQuestionIndex)
                    )
            }
            .frame(height: 2)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Sun Icon
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                        .padding(.top, 40)
                    
                    // Question
                    Text(questions[currentQuestionIndex])
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    // Options
                    VStack(spacing: 12) {
                        switch currentQuestionIndex {
                        case 0: // Gender
                            ForEach(["Male", "Female", "Prefer not to say"], id: \.self) { option in
                                Button(action: {
                                    selectedGender = option
                                }) {
                                    Text(option)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(selectedGender == option ? Color.selectedOption : Color.clear)
                                        .foregroundColor(
                                            selectedGender == option ?
                                            Color(UIColor { traitCollection in
                                                return traitCollection.userInterfaceStyle == .dark ? .black : .black
                                            }) :
                                            .foreground
                                        )
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.cardBorder, lineWidth: 1)
                                        )
                                }
                            }
                            
                        case 1: // Weather
                            ForEach(["Tropic", "Cold", "Sunny", "Other"], id: \.self) { option in
                                Button(action: {
                                    selectedWeather = option
                                }) {
                                    Text(option)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(selectedWeather == option ? Color.selectedOption : Color.clear)
                                        .foregroundColor(
                                            selectedWeather == option ?
                                            Color(UIColor { traitCollection in
                                                return traitCollection.userInterfaceStyle == .dark ? .black : .black
                                            }) :
                                            .foreground
                                        )
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.cardBorder, lineWidth: 1)
                                        )
                                }
                            }
                            
                            Button("Why?") {
                                currentInfoType = .weather
                            }
                            .font(.footnote)
                            .foregroundColor(.blue)
                            .padding(.top, 8)
                            
                        case 2: // Contacts
                            OptionButton(title: "Yes", isSelected: allowContacts) {
                                allowContacts = true
                            }
                            OptionButton(title: "No", isSelected: !allowContacts) {
                                allowContacts = false
                            }
                            
                        case 3: // Age
                            TextField("Enter your age", text: $age)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal, 24)
                            
                        case 4: // Pinterest
                            OptionButton(title: "Yes", isSelected: pinterestAccess) {
                                pinterestAccess = true
                            }
                            OptionButton(title: "No", isSelected: !pinterestAccess) {
                                pinterestAccess = false
                            }
                            
                            Button("Why?") {
                                currentInfoType = .pinterest
                            }
                            .font(.footnote)
                            .foregroundColor(.blue)
                            .padding(.top, 8)
                            
                        case 5: // Discovery
                            ForEach(["Instagram", "TikTok", "Friends", "Other"], id: \.self) { option in
                                Button(action: {
                                    discoverySource = option
                                }) {
                                    Text(option)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(discoverySource == option ? Color.selectedOption : Color.clear)
                                        .foregroundColor(
                                            discoverySource == option ?
                                            Color(UIColor { traitCollection in
                                                return traitCollection.userInterfaceStyle == .dark ? .black : .black
                                            }) :
                                            .foreground
                                        )
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.cardBorder, lineWidth: 1)
                                        )
                                }
                            }
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Navigation Buttons
            HStack(spacing: 12) {
                if currentQuestionIndex > 0 {
                    Button {
                        moveToPreviousQuestion()
                    } label: {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                }
                
                Button {
                    if validateCurrentQuestion() {
                        moveToNextQuestion()
                    } else {
                        // Show error feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    }
                } label: {
                    Text(currentQuestionIndex == questions.count - 1 ? "Submit" : "Next")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(validateCurrentQuestion() ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!validateCurrentQuestion())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
        }
        .onChange(of: currentQuestionIndex) { _ in
            isValid = validateCurrentQuestion()
        }
        .sheet(item: $currentInfoType) { type in
            InfoSheetView(type: type)
        }
    }
}

struct OptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 1.5)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.clear)
                            .frame(width: 16, height: 16)
                    )
                
                Text(title)
                    .font(.body)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoSheetView: View {
    let type: PreferenceQuizView.InfoType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Image(systemName: type.icon)
                    .font(.title)
                    .foregroundColor(.blue)
                Text(type.rawValue)
                    .font(.title2.bold())
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            // Content
            Text(type.description)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }
} 
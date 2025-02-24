import SwiftUI
import MapKit

struct NewTripView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingDiscardAlert = false
    @State private var showingNamePrompt = false
    @State private var tripName = ""
    @State private var currentStep = 0
    @State private var showMap = false
    
    // Trip parameters
    @State private var budget: Double = 1000
    @State private var location = ""
    @State private var travelDistance = 100.0
    @State private var travelers = 2
    @State private var transportMethod = "Car"
    @State private var weatherPreference = "Any"
    @State private var foodPreference = "Local"
    
    let transportOptions = ["Car", "Uber", "Train", "Flight"]
    let weatherOptions = ["Warm", "Cold", "Rainy", "Any"]
    let foodOptions = ["Local", "Vegan", "Fast Food", "Fine Dining"]
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            if !showMap {
                // Trip creation form
                VStack(spacing: 24) {
                    // Progress indicator
                    HStack {
                        ForEach(0..<6) { step in
                            Capsule()
                                .fill(step <= currentStep ? 
                                      (authManager.userProfile.darkModeEnabled ? Color.yellow : Color.black) : 
                                      Color.gray.opacity(0.3))
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            switch currentStep {
                            case 0:
                                budgetSection
                            case 1:
                                locationSection
                            case 2:
                                travelersSection
                            case 3:
                                transportSection
                            case 4:
                                weatherSection
                            case 5:
                                foodSection
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                    
                    // Navigation buttons
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .buttonStyle(RoundedButtonStyle(filled: false))
                        }
                        
                        Button(currentStep == 5 ? "Generate Plan" : "Next") {
                            withAnimation {
                                if currentStep == 5 {
                                    showMap = true
                                } else {
                                    currentStep += 1
                                }
                            }
                        }
                        .buttonStyle(RoundedButtonStyle(filled: true))
                    }
                    .padding()
                }
                .background(authManager.userProfile.darkModeEnabled ? Color.black : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 20)
                .padding()
            } else {
                // Map view
                TripMapView(
                    tripName: $tripName,
                    showingNamePrompt: $showingNamePrompt,
                    showingDiscardAlert: $showingDiscardAlert,
                    onPublish: {
                        showingNamePrompt = true
                    },
                    onDismiss: {
                        showingDiscardAlert = true
                    }
                )
            }
        }
        .alert("Name Your Trip", isPresented: $showingNamePrompt) {
            TextField("Trip Name", text: $tripName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                // Save trip logic
                dismiss()
            }
        } message: {
            Text("Give your trip a memorable name")
        }
        .alert("Discard Trip?", isPresented: $showingDiscardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Save to Drafts") {
                showingNamePrompt = true
                // Save to drafts logic
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Would you like to save this trip to drafts or discard it?")
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled() // Prevent accidental dismissal
    }
    
    // Form sections...
    var budgetSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("What's your budget?")
                .font(.title2)
                .bold()
            
            Slider(value: $budget, in: 100...10000, step: 100)
                .tint(authManager.userProfile.darkModeEnabled ? .yellow : .black)
            
            Text("$\(Int(budget))")
                .font(.system(.title3, design: .rounded))
                .bold()
        }
    }
    
    var locationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Where would you like to go?")
                .font(.title2)
                .bold()
            
            TextField("Enter destination", text: $location)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            Slider(value: $travelDistance, in: 10...1000, step: 10)
                .tint(authManager.userProfile.darkModeEnabled ? .yellow : .black)
            
            Text("Within \(Int(travelDistance)) miles")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.gray)
        }
    }
    
    var travelersSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("How many travelers?")
                .font(.title2)
                .bold()
            
            Stepper(value: $travelers, in: 1...10) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(authManager.userProfile.darkModeEnabled ? .yellow : .black)
                    Text("\(travelers) \(travelers == 1 ? "Person" : "People")")
                        .font(.system(.title3, design: .rounded))
                }
            }
        }
    }
    
    var transportSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Preferred transportation?")
                .font(.title2)
                .bold()
            
            ForEach(transportOptions, id: \.self) { option in
                Button(action: {
                    transportMethod = option
                }) {
                    HStack {
                        Image(systemName: transportIcon(for: option))
                            .foregroundColor(transportMethod == option ?
                                (authManager.userProfile.darkModeEnabled ? .yellow : .black) :
                                .gray)
                        
                        Text(option)
                            .foregroundColor(transportMethod == option ?
                                (authManager.userProfile.darkModeEnabled ? .white : .black) :
                                .gray)
                        
                        Spacer()
                        
                        if transportMethod == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(authManager.userProfile.darkModeEnabled ? .yellow : .black)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(transportMethod == option ?
                                  (authManager.userProfile.darkModeEnabled ? Color.black.opacity(0.5) : Color.gray.opacity(0.1)) :
                                  Color.clear)
                    )
                }
            }
        }
    }
    
    var weatherSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weather preference?")
                .font(.title2)
                .bold()
            
            ForEach(weatherOptions, id: \.self) { option in
                Button(action: {
                    weatherPreference = option
                }) {
                    HStack {
                        Image(systemName: weatherIcon(for: option))
                            .foregroundColor(weatherPreference == option ?
                                (authManager.userProfile.darkModeEnabled ? .yellow : .black) :
                                .gray)
                        
                        Text(option)
                            .foregroundColor(weatherPreference == option ?
                                (authManager.userProfile.darkModeEnabled ? .white : .black) :
                                .gray)
                        
                        Spacer()
                        
                        if weatherPreference == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(authManager.userProfile.darkModeEnabled ? .yellow : .black)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(weatherPreference == option ?
                                  (authManager.userProfile.darkModeEnabled ? Color.black.opacity(0.5) : Color.gray.opacity(0.1)) :
                                  Color.clear)
                    )
                }
            }
        }
    }
    
    var foodSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Food preference?")
                .font(.title2)
                .bold()
            
            ForEach(foodOptions, id: \.self) { option in
                Button(action: {
                    foodPreference = option
                }) {
                    HStack {
                        Image(systemName: foodIcon(for: option))
                            .foregroundColor(foodPreference == option ?
                                (authManager.userProfile.darkModeEnabled ? .yellow : .black) :
                                .gray)
                        
                        Text(option)
                            .foregroundColor(foodPreference == option ?
                                (authManager.userProfile.darkModeEnabled ? .white : .black) :
                                .gray)
                        
                        Spacer()
                        
                        if foodPreference == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(authManager.userProfile.darkModeEnabled ? .yellow : .black)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(foodPreference == option ?
                                  (authManager.userProfile.darkModeEnabled ? Color.black.opacity(0.5) : Color.gray.opacity(0.1)) :
                                  Color.clear)
                    )
                }
            }
        }
    }
    
    // Helper functions for icons
    private func transportIcon(for option: String) -> String {
        switch option {
        case "Car": return "car.fill"
        case "Uber": return "car.circle.fill"
        case "Train": return "tram.fill"
        case "Flight": return "airplane"
        default: return "questionmark.circle"
        }
    }
    
    private func weatherIcon(for option: String) -> String {
        switch option {
        case "Warm": return "sun.max.fill"
        case "Cold": return "snowflake"
        case "Rainy": return "cloud.rain.fill"
        case "Any": return "sparkles"
        default: return "questionmark.circle"
        }
    }
    
    private func foodIcon(for option: String) -> String {
        switch option {
        case "Local": return "house.fill"
        case "Vegan": return "leaf.fill"
        case "Fast Food": return "bolt.fill"
        case "Fine Dining": return "star.fill"
        default: return "questionmark.circle"
        }
    }
}

struct RoundedButtonStyle: ButtonStyle {
    let filled: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(
                filled ? 
                    (authManager.userProfile.darkModeEnabled ? Color.yellow : Color.black) :
                    Color.clear
            )
            .foregroundColor(
                filled ?
                    (authManager.userProfile.darkModeEnabled ? .black : .white) :
                    (authManager.userProfile.darkModeEnabled ? .white : .black)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        authManager.userProfile.darkModeEnabled ? Color.yellow : Color.black,
                        lineWidth: filled ? 0 : 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
} 
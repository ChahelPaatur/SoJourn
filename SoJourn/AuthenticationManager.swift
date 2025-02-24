import SwiftUI
import PhotosUI

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isNewUser = false
    @Published var hasCompletedQuiz = false
    @Published var hasPinterestAuth = false
    @Published var userProfile = UserProfile()
    
    init() {
        checkExistingCredentials()
    }
    
    private func checkExistingCredentials() {
        // Check UserDefaults or Keychain for existing credentials
        if let savedEmail = UserDefaults.standard.string(forKey: "userEmail") {
            // Auto sign in
            isAuthenticated = true
            isNewUser = false
            hasCompletedQuiz = true
            // Load user profile
            loadUserProfile()
        }
    }
    
    private func loadUserProfile() {
        // Load saved profile data
        if let savedProfile = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: savedProfile) {
            userProfile = profile
        }
    }
    
    func signInWithPinterest() {
        // Pinterest API integration will go here
        isAuthenticated = true
        hasPinterestAuth = true
    }
    
    func signInWithApple() {
        // Apple Sign In integration will go here
        isAuthenticated = true
    }
    
    func signInWithEmail(email: String, password: String) {
        // Email authentication will go here
        isAuthenticated = true
    }
    
    func signOut() {
        isAuthenticated = false
        hasPinterestAuth = false
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userProfile")
    }
}

struct UserProfile: Codable {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var notificationsEnabled = true
    var emailNotificationsEnabled = true
    var darkModeEnabled = false
    // Profile picture will be handled separately since it's not Codable
} 
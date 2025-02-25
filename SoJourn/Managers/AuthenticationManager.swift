import SwiftUI
import AuthenticationServices
import Foundation

class AuthenticationManager: ObservableObject {
    @Published var userProfile: UserProfile {
        didSet {
            saveProfile()
        }
    }
    @Published var showWelcomeScreen: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var isNewUser: Bool = true
    @Published var isPinterestConnected: Bool = false
    @Published var isAppleConnected: Bool = false
    @Published var currentUser: User?
    
    static let shared = AuthenticationManager()
    
    init() {
        // Load from UserDefaults or use default values
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = profile
            self.isAuthenticated = !profile.name.isEmpty
            self.isNewUser = false
        } else {
            self.userProfile = UserProfile()
        }
    }
    
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
    }
    
    func signIn(email: String, password: String) {
        // TODO: Implement actual authentication
        isAuthenticated = true
        currentUser = User(id: "1", name: "Test User", email: email)
        isNewUser = false
        userProfile.email = email
        saveProfile()
    }
    
    func signInWithPinterest() {
        // Here you would implement actual Pinterest OAuth
        isPinterestConnected = true
        isAuthenticated = true
        isNewUser = false
        
        // For now, just set some dummy data
        userProfile.name = "Pinterest User"
        userProfile.email = "pinterest@example.com"
        saveProfile()
    }
    
    func signInWithApple() {
        // Here you would implement actual Apple Sign In
        isAppleConnected = true
        isAuthenticated = true
        isNewUser = false
        
        // For now, just set some dummy data
        userProfile.name = "Apple User"
        userProfile.email = "apple@example.com"
        saveProfile()
    }
    
    func signOut() {
        isAuthenticated = false
        isNewUser = true
        isPinterestConnected = false
        isAppleConnected = false
        userProfile = UserProfile()
        currentUser = nil
        saveProfile()
    }
    
    func disconnectPinterest() {
        isPinterestConnected = false
        saveProfile()
    }
    
    func disconnectApple() {
        isAppleConnected = false
        saveProfile()
    }
}

struct User: Identifiable {
    let id: String
    let name: String
    let email: String
} 
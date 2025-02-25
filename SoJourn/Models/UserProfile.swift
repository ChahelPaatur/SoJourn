import Foundation

struct UserProfile: Codable {
    var darkModeEnabled: Bool = false
    var name: String = ""
    var gender: String = ""
    var age: Int = 0
    var email: String = ""
    var weatherPreference: String = ""
    var notificationsEnabled: Bool = true
    var emailNotificationsEnabled: Bool = true
    var pinterestConnected: Bool = false
    var pinterestUsername: String = ""
    var profileImageURL: String = ""
    var preferredClimate: String = ""
    var preferredTripType: String = ""
    var budget: String = ""
    var preferredActivities: [String] = []
} 
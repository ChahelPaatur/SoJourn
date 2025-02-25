import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Form {
            Section {
                Toggle("Push Notifications", isOn: Binding(
                    get: { authManager.userProfile.notificationsEnabled },
                    set: { authManager.userProfile.notificationsEnabled = $0 }
                ))
                
                Toggle("Email Notifications", isOn: Binding(
                    get: { authManager.userProfile.emailNotificationsEnabled },
                    set: { authManager.userProfile.emailNotificationsEnabled = $0 }
                ))
            } header: {
                Text("Notification Preferences")
            } footer: {
                Text("Control how you want to receive updates about your trips and account.")
            }
        }
        .navigationTitle("Notifications")
    }
} 
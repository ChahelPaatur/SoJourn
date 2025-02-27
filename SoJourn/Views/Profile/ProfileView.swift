import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var showingLogoutAlert = false
    
    // Break down the view into smaller components
    private var profileHeader: some View {
        // Header content
        VStack {
            HStack(spacing: 16) {
                // Profile Image
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(authManager.userProfile.darkModeEnabled ? .white : .black)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authManager.userProfile.name)
                        .font(.system(size: 20, weight: .semibold))
                    Text(authManager.userProfile.email)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 12)
        }
    }
    
    private var preferencesSection: some View {
        Section {
            Toggle("Dark Mode", isOn: $authManager.userProfile.darkModeEnabled)
                .tint(authManager.userProfile.darkModeEnabled ? Color.yellow : .black)
            NavigationLink {
                PrivacySettingsView()
            } label: {
                Text("Privacy Settings")
            }
            NavigationLink {
                HelpSupportView()
            } label: {
                Text("Help & Support")
            }
        } header: {
            Text("Preferences")
                .font(.system(size: 16, weight: .semibold))
        }
    }
    
    private var notificationsSection: some View {
        Section {
            Toggle("Notifications", isOn: $authManager.userProfile.notificationsEnabled)
                .tint(authManager.userProfile.notificationsEnabled ? Color.blue : .black)
            Toggle("Email Notifications", isOn: $authManager.userProfile.emailNotificationsEnabled)
                .tint(authManager.userProfile.emailNotificationsEnabled ? Color.blue : .black)
        } header: {
            Text("Notifications")
                .font(.system(size: 16, weight: .semibold))
        }
    }
    
    private var accountActionsSection: some View {
        Section {
            NavigationLink("Edit Profile") {
                EditProfileView()
            }
            Button("Sign Out") {
                showingLogoutAlert = true
            }
            .foregroundColor(.red)
            
            Button("Delete Account") {
                // Implement delete account functionality
            }
            .foregroundColor(.red)
        } header: {
            Text("Account")
                .font(.system(size: 16, weight: .semibold))
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                profileHeader
                preferencesSection
                notificationsSection
                accountActionsSection
            }
            .navigationTitle("Profile")
            .preferredColorScheme(authManager.userProfile.darkModeEnabled ? .dark : .light)
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onChange(of: selectedImage, { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    profileImage = Image(uiImage: uiImage)
                }
            }
        })
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
} 

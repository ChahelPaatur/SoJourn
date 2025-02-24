import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
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
                            Text("\(authManager.userProfile.firstName) \(authManager.userProfile.lastName)")
                                .font(.system(size: 20, weight: .semibold))
                            Text(authManager.userProfile.email)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 12)
                }
                
                // Notifications Section
                Section {
                    Toggle("Push Notifications", isOn: $authManager.userProfile.notificationsEnabled)
                        .tint(authManager.userProfile.darkModeEnabled ? Color.yellow : .black)
                    Toggle("Email Notifications", isOn: $authManager.userProfile.emailNotificationsEnabled)
                        .tint(authManager.userProfile.darkModeEnabled ? Color.yellow : .black)
                } header: {
                    Text("Notifications")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                // Preferences Section
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
                
                // Account Actions Section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
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
        .onChange(of: selectedImage) { _ in
            Task {
                if let data = try? await selectedImage?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    profileImage = Image(uiImage: uiImage)
                    // Save profile image to storage
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
} 
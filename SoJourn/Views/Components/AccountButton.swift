import SwiftUI

struct AccountButton: View {
    @State private var showingQuickSettings = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button {
            showingQuickSettings = true
        } label: {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(Color(UIColor.label))
                .padding(6)
        }
        .popover(isPresented: $showingQuickSettings) {
            QuickSettingsView()
        }
    }
}

struct QuickSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingProfileSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Settings")
                .font(.headline)
                .padding(.bottom, 8)
            
            Toggle("Dark Mode", isOn: $isDarkMode)
                .onChange(of: isDarkMode) { _ in
                    // This would handle system-wide dark mode toggle if you implement it
                }
            
            Button {
                showingProfileSettings = true
            } label: {
                Label("Profile Settings", systemImage: "person.fill")
                    .foregroundColor(Color(UIColor.label))
            }
            
            Button {
                // Handle sign out
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 220)
        .sheet(isPresented: $showingProfileSettings) {
            Text("Profile Settings View")
                .padding()
                // Replace with your actual profile settings view
        }
    }
} 
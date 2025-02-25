import SwiftUI

struct PrivacySettingsView: View {
    @State private var locationEnabled = true
    @State private var analyticsEnabled = true
    @State private var personalizationEnabled = true
    
    var body: some View {
        List {
            Section {
                Toggle("Location Services", isOn: $locationEnabled)
                Toggle("Analytics", isOn: $analyticsEnabled)
                Toggle("Personalization", isOn: $personalizationEnabled)
            } header: {
                Text("Privacy Options")
            } footer: {
                Text("These settings control how SoJourn uses your data to provide services and improve your experience.")
            }
            
            Section {
                Button("Export My Data") {
                    // Implement data export
                }
                Button("Delete All Data") {
                    // Implement data deletion
                }
                .foregroundColor(.red)
            } header: {
                Text("Your Data")
            }
        }
        .navigationTitle("Privacy")
    }
} 
import SwiftUI

struct HelpSupportView: View {
    var body: some View {
        List {
            Section(header: Text("Help")) {
                NavigationLink("FAQs") {
                    Text("Frequently Asked Questions")
                }
                NavigationLink("Contact Support") {
                    Text("Support Contact Information")
                }
            }
            
            Section(header: Text("About")) {
                NavigationLink("Terms of Service") {
                    Text("Terms of Service Content")
                }
                NavigationLink("Privacy Policy") {
                    Text("Privacy Policy Content")
                }
            }
        }
        .navigationTitle("Help & Support")
    }
} 
import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                    
                    Text("SoJourn")
                        .font(.title)
                        .bold()
                    
                    Text("Version 1.0.0")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section {
                Link("Terms of Service", destination: URL(string: "https://sojourn.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://sojourn.app/privacy")!)
                Link("Website", destination: URL(string: "https://sojourn.app")!)
            }
            
            Section {
                HStack {
                    Text("Made with ❤️ in")
                    Text("San Francisco")
                        .bold()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("About")
    }
} 
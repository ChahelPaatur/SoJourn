import SwiftUI

struct TripSharingView: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share Your Trip")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Share '\(trip.title)' with your friends and family.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Sample sharing options
                VStack(spacing: 16) {
                    ShareButton(title: "Via Messages", icon: "message.fill") {
                        // Messages sharing action
                        dismiss()
                    }
                    
                    ShareButton(title: "Via Email", icon: "envelope.fill") {
                        // Email sharing action
                        dismiss()
                    }
                    
                    ShareButton(title: "Copy Link", icon: "link") {
                        // Copy link action
                        dismiss()
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitle("Share Trip", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct ShareButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)
            .foregroundColor(.primary)
        }
    }
}

#Preview {
    TripSharingView(trip: Trip.example)
} 
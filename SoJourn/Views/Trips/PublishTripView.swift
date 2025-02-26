import SwiftUI

struct PublishTripView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tripTitle = ""
    @State private var isPublic = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Modal content
            Text("Publish Trip")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 8)
            
            // Form fields
            TextField("Trip Title", text: $tripTitle)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)
            
            Toggle("Make Trip Public", isOn: $isPublic)
                .foregroundColor(.white)
            
            // Action buttons
            HStack(spacing: 20) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Color.sojourYellow)
                .padding()
                
                Button("Publish") {
                    // Publish action
                    dismiss()
                }
                .foregroundColor(.black)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color.sojourYellow)
                .cornerRadius(8)
            }
        }
        .padding(24)
        .background(Color.black)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}

#Preview {
    PublishTripView()
} 
import SwiftUI

struct TripCardView: View {
    let trip: Trip 
    @State private var tripProperties: [String] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder image 
            Color.gray.opacity(0.2)
                .frame(height: 140)
                .overlay(
                    Image(systemName: "airplane.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.foreground.opacity(0.7))
                )
                .cornerRadius(8, corners: [.topLeft, .topRight])
            
            // Trip details - dark gray with white text in dark mode
            VStack(alignment: .leading, spacing: 6) {
                Text(trip.destination)
                    .font(.headline)
                    .foregroundColor(Color(UIColor { traitCollection in
                        return traitCollection.userInterfaceStyle == .dark ? .white : .black
                    }))
                
                // Non-optional date handling
                Text("\(formatDate(trip.startDate)) - \(formatDate(trip.endDate))")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor { traitCollection in
                        return traitCollection.userInterfaceStyle == .dark ? .white : .black
                    }).opacity(0.7))
                
                // Debug section to list all Trip properties
                Text("Available Trip Properties:")
                    .font(.caption)
                    .foregroundColor(.red)
                    .fontWeight(.bold)
                
                Text(tripProperties.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(4)
                
                if trip.isShared {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(Color.buttonBackground)
                        
                        Text("Shared Trip")
                            .font(.caption)
                            .foregroundColor(Color.buttonBackground)
                    }
                }
                
                // Removed tags section since Trip doesn't have tags property
            }
            .padding(12)
        }
        .background(Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 1.0) : .white
        }))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
        .onAppear {
            // Print all Trip model properties to console AND save for display
            let propertyNames = Mirror(reflecting: trip).children.compactMap { $0.label }
            tripProperties = propertyNames
            
            print("Trip model properties: \(propertyNames)")
            print("Trip model values: \(Mirror(reflecting: trip).children.map { ($0.label ?? "unknown", String(describing: $0.value)) })")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
} 
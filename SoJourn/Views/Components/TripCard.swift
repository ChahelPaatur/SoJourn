import SwiftUI

struct TripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(12)
                
                Text(trip.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(8)
            }
            
            // Trip details
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(.headline)
                
                Text(trip.destination)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(dateRangeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom)
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return "\(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))"
    }
    
    private var statusColor: Color {
        switch trip.status {
        case .upcoming: return .blue
        case .active: return .green
        case .completed: return .gray
        }
    }
}

#Preview {
    TripCard(trip: Trip.example)
} 
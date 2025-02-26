import SwiftUI

struct TripCardComponent: View {
    let trip: Trip
    @EnvironmentObject private var tripManager: TripManager
    @State private var showingOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image - different style for drafts
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(trip.isDraft ? Color.gray.opacity(0.2) : Color.gray.opacity(0.3))
                    .aspectRatio(trip.isDraft ? 3/1 : 16/9, contentMode: .fit) // Shorter for drafts
                    .cornerRadius(12)
                
                // Menu button
                Button {
                    showingOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .foregroundColor(.black)
                }
                .padding(8)
                .confirmationDialog("Trip Options", isPresented: $showingOptions, titleVisibility: .visible) {
                    Button("Edit Trip") {
                        tripManager.editTrip(trip.id)
                    }
                    
                    Button("Postpone Trip") {
                        tripManager.postponeTrip(trip.id, by: 7)
                    }
                    
                    Button("Archive Trip") {
                        tripManager.archiveTrip(trip.id)
                    }
                    
                    Button("Delete Trip", role: .destructive) {
                        tripManager.deleteTrip(trip.id)
                    }
                    
                    Button("Cancel", role: .cancel) {}
                }
                
                if trip.isDraft {
                    Text("DRAFT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(8)
                        .padding(.trailing, 30)
                } else {
                    Text(trip.status.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(8)
                        .padding(.trailing, 30) // Make room for menu button
                }
            }
            
            // Trip details
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(trip.isDraft ? .subheadline : .headline)
                
                Text(trip.destination)
                    .font(trip.isDraft ? .caption : .subheadline)
                    .foregroundColor(.secondary)
                
                if !trip.isDraft {
                    Text(dateRangeText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.bottom, trip.isDraft ? 4 : 8)
        .opacity(trip.isDraft ? 0.8 : 1.0)
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return "\(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))"
    }
    
    private var statusColor: Color {
        switch trip.status {
        case .upcoming: return .black
        case .active: return .green
        case .completed: return .gray
        }
    }
}

#Preview {
    TripCardComponent(trip: Trip.example)
        .environmentObject(TripManager.shared)
} 
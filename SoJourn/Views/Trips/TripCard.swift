import SwiftUI
import Foundation

struct TripCard: View {
    let trip: Trip
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                // Image area at the top
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 140)
                    .cornerRadius(12, corners: [.topLeft, .topRight])
                    .overlay(
                        Image("trip_placeholder1") // Use actual image if available
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .cornerRadius(12, corners: [.topLeft, .topRight])
                            .clipped()
                    )
                
                // Trip details below image
                VStack(alignment: .leading, spacing: 12) {
                    // Trip header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(trip.destination)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Date range
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(formattedDateRange)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Price/activities count
                            Text("$750 • \(trip.activities.count) activities")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Status tags - all positioned at top left
            Group {
                if trip.isArchived {
                    statusTag(text: "ARCHIVED", color: .gray)
                } else if trip.isDraft {
                    statusTag(text: "DRAFT", color: .black)
                } else if trip.status == .upcoming {
                    statusTag(text: "UPCOMING", color: Color(red: 0.4, green: 0.6, blue: 0.9)) // Pastel blue
                } else if trip.status == .completed {
                    statusTag(text: "COMPLETED", color: Color(red: 0.2, green: 0.6, blue: 0.3)) // Green
                }
            }
            .padding(12)
        }
    }
    
    // Helper function for consistent tag styling
    private func statusTag(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color)
            )
    }
    
    private var formattedDateRange: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        let startStr = dateFormatter.string(from: trip.startDate)
        let endStr = dateFormatter.string(from: trip.endDate)
        
        return "\(startStr) - \(endStr)"
    }
}

// Removed duplicate RoundedCorner implementation & extension
// The project already has this in Extensions/RoundedCorner.swift 
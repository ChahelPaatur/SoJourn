import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @EnvironmentObject private var tripManager: TripManager
    @State private var showingDeleteConfirmation = false
    @State private var showingShareSheet = false
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero image
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(12)
                
                // Trip details
                VStack(alignment: .leading, spacing: 16) {
                    Text(trip.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.black)
                        Text(trip.destination)
                            .font(.headline)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.black)
                        Text(dateRangeText)
                            .font(.subheadline)
                    }
                    
                    if !trip.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            Text(trip.notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                
                // Weather Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weather Forecast")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Extract coordinates from destination (in a real app, you'd use geocoding)
                    // For this example, we'll use approximate coordinates for the destination
                    let coordinates = getCoordinatesForDestination(trip.destination)
                    
                    TripWeatherView(
                        tripId: trip.id.uuidString,
                        location: trip.destination,
                        latitude: coordinates.latitude,
                        longitude: coordinates.longitude,
                        startDate: trip.startDate,
                        endDate: trip.endDate
                    )
                    .padding(.horizontal, 8)
                }
                
                // Itinerary
                if !trip.activities.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Itinerary")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ForEach(trip.activities.sorted(by: { $0.date < $1.date })) { activity in
                            activityRow(activity)
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit Trip", systemImage: "pencil")
                    }
                    
                    if !trip.isShared {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share Trip", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    if trip.isArchived {
                        Button {
                            // Unarchive
                            tripManager.unarchiveTrip(trip.id)
                        } label: {
                            Label("Unarchive Trip", systemImage: "archivebox")
                        }
                    } else {
                        Button {
                            // Archive
                            tripManager.archiveTrip(trip.id)
                        } label: {
                            Label("Archive Trip", systemImage: "archivebox.fill")
                        }
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Trip", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Trip", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                tripManager.deleteTrip(trip.id)
            }
        } message: {
            Text("Are you sure you want to delete this trip? This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            TripSharingView(trip: trip)
        }
        .sheet(isPresented: $isEditing) {
            EditTripView(trip: trip)
        }
    }
    
    // Helper function to get coordinates for a destination
    private func getCoordinatesForDestination(_ destination: String) -> (latitude: Double, longitude: Double) {
        // In a real app, you'd use geocoding to get actual coordinates
        // For this example, we'll use some predefined coordinates for common destinations
        
        let lowercasedDestination = destination.lowercased()
        
        if lowercasedDestination.contains("hawaii") {
            return (21.3069, -157.8583) // Honolulu
        } else if lowercasedDestination.contains("new york") {
            return (40.7128, -74.0060)
        } else if lowercasedDestination.contains("paris") {
            return (48.8566, 2.3522)
        } else if lowercasedDestination.contains("tokyo") {
            return (35.6762, 139.6503)
        } else if lowercasedDestination.contains("london") {
            return (51.5074, -0.1278)
        } else if lowercasedDestination.contains("san francisco") {
            return (37.7749, -122.4194)
        } else if lowercasedDestination.contains("los angeles") {
            return (34.0522, -118.2437)
        } else if lowercasedDestination.contains("bali") {
            return (-8.3405, 115.0920)
        }
        
        // Default to San Francisco if no match
        return (37.7749, -122.4194)
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return "\(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))"
    }
    
    private func activityRow(_ activity: Activity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formattedDate(activity.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formattedTime(activity.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(activity.title)
                .font(.headline)
            
            if !activity.notes.isEmpty {
                Text(activity.notes)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        TripDetailView(trip: Trip.example)
            .environmentObject(TripManager.shared)
    }
} 
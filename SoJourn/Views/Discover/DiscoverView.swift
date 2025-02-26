import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var tripManager: TripManager
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom search bar
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.tabBackground)
                        .frame(height: 44)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search destinations, experiences...", text: $searchText)
                            .foregroundColor(.foreground)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Search results (only show when searching)
                        if !searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Search Results")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.foreground)
                                    .padding(.horizontal)
                                
                                ForEach(searchResults, id: \.self) { result in
                                    SearchResultRow(result: result)
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            // Popular Destinations
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Popular Destinations")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.foreground)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(popularDestinations, id: \.self) { destination in
                                            DestinationCard(name: destination)
                                                .frame(width: 150, height: 200)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Based on Your Interests section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Based on Your Interests")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.foreground)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(recommendedTrips) { trip in
                                            RecommendedTripCard(trip: trip)
                                                .frame(width: 180, height: 240)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Trending Experiences
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Trending Experiences")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.foreground)
                                    .padding(.horizontal)
                                
                                LazyVStack(spacing: 16) {
                                    ForEach(trendingExperiences, id: \.self) { experience in
                                        ExperienceCard(title: experience)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Discover")
            // Remove the built-in searchable modifier since we have a custom search bar
        }
    }
    
    // Search results based on searchText
    private var searchResults: [String] {
        if searchText.isEmpty {
            return []
        }
        
        let allItems = popularDestinations + trendingExperiences
        return allItems.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Sample data
    private var popularDestinations: [String] {
        ["Paris", "Tokyo", "New York", "Barcelona", "Sydney", "Bangkok"]
    }
    
    // Recommended trips based on user interests
    private var recommendedTrips: [Trip] {
        // In a real app, this would use the user's preferences to show relevant trips
        // For demo purposes, return a subset of trips or generate some recommendations
        return Array(tripManager.trips.prefix(4))
    }
    
    private var trendingExperiences: [String] {
        ["Wine tasting in Tuscany", "Northern Lights in Iceland", "Desert safari in Dubai", "Cherry blossoms in Japan"]
    }
}

// New component for search results
struct SearchResultRow: View {
    let result: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.trailing, 8)
            
            Text(result)
                .foregroundColor(.foreground)
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .foregroundColor(.accent)
                .font(.caption)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(10)
    }
}

// Sample card for destinations
struct DestinationCard: View {
    let name: String
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.gray.opacity(0.3)
                .cornerRadius(12)
            
            Text(name)
                .font(.headline)
                .foregroundColor(.white)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
    }
}

// Sample card for experiences
struct ExperienceCard: View {
    let title: String
    
    var body: some View {
        HStack {
            Color.gray.opacity(0.3)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.foreground)
                
                Text("Experience the magic of travel")
                    .font(.subheadline)
                    .foregroundColor(.foreground.opacity(0.7))
                    .lineLimit(2)
            }
            .padding(.leading, 8)
            
            Spacer()
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }
}

// Make sure to add the RecommendedTripCard struct from TripsHomeView

#Preview {
    DiscoverView()
        .environmentObject(TripManager.shared)
}

struct RecommendedTripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            Color.gray.opacity(0.2)
                .frame(height: 120)
                .overlay(
                    Image(systemName: "airplane.circle")
                        .font(.system(size: 30))
                        .foregroundColor(.foreground.opacity(0.7))
                )
                .cornerRadius(8)
            
            Text(trip.destination)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.cardText)
                .lineLimit(1)
            
            Text("\(formatDate(trip.startDate)) - \(formatDate(trip.endDate))")
                .font(.caption)
                .foregroundColor(.cardText.opacity(0.8))
                .lineLimit(1)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
} 
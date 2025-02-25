import SwiftUI

struct TripsHomeView: View {
    @EnvironmentObject private var tripManager: TripManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var searchText = ""
    @State private var selectedFilter: TripFilter = .all
    
    enum TripFilter {
        case all
        case upcoming
        case drafted
        case archived
        
        var title: String {
            switch self {
            case .all: return "All"
            case .upcoming: return "Upcoming Trips"
            case .drafted: return "Drafted Trips"
            case .archived: return "Archived Trips"
            }
        }
    }
    
    private var filteredTrips: [Trip] {
        let trips = tripManager.trips
        
        let filtered = trips.filter { trip in
            switch selectedFilter {
            case .all: return true
            case .upcoming: return trip.status == .upcoming
            case .drafted: return trip.isDraft
            case .archived: return trip.isArchived
            }
        }
        
        if searchText.isEmpty {
            return filtered
        }
        
        return filtered.filter { trip in
            trip.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach([TripFilter.all, .upcoming, .drafted, .archived], id: \.title) { filter in
                            Button {
                                selectedFilter = filter
                            } label: {
                                Text(filter.title)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? Color.black : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedFilter == filter ? .white : .black)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding()
                }
                
                // Trip list
                List(filteredTrips) { trip in
                    TripCard(trip: trip)
                }
                .listStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search trips")
            .navigationTitle("My Trips")
        }
        .accentColor(.black)
    }
}

#Preview {
    TripsHomeView()
        .environmentObject(TripManager.shared)
        .environmentObject(AuthenticationManager.shared)
} 
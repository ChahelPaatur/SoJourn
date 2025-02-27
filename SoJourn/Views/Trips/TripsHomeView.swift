import SwiftUI

struct TripsHomeView: View {
    @EnvironmentObject private var tripManager: TripManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var searchText = ""
    @State private var selectedFilter: TripFilter = .all
    @State private var showingNewTripView = false
    
    enum TripFilter {
        case all
        case upcoming
        case drafted
        case archived
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Filter tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            FilterButton(title: "All", isSelected: selectedFilter == .all) {
                                selectedFilter = .all
                            }
                            
                            FilterButton(title: "Upcoming", isSelected: selectedFilter == .upcoming) {
                                selectedFilter = .upcoming
                            }
                            
                            FilterButton(title: "Drafts", isSelected: selectedFilter == .drafted) {
                                selectedFilter = .drafted
                            }
                            
                            FilterButton(title: "Archived", isSelected: selectedFilter == .archived) {
                                selectedFilter = .archived
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    
                    // Trip list with dynamic filtering
                    VStack(alignment: .leading) {
                        Text("Your Trips")
                            .font(.headline)
                            .foregroundColor(.foreground)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 16) {
                            ForEach(filteredTrips) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    TripCard(trip: trip)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("My Trips")
            .navigationBarItems(trailing: AccountButton())
            .searchable(text: $searchText, prompt: "Search trips")
        }
    }
    
    private var filteredTrips: [Trip] {
        let trips = tripManager.trips.filter { trip in
            if searchText.isEmpty {
                return true
            } else {
                return trip.title.localizedCaseInsensitiveContains(searchText) ||
                    trip.destination.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch selectedFilter {
        case .all:
            return trips.filter { !$0.isArchived }
        case .upcoming:
            return trips.filter { $0.status == .upcoming && !$0.isArchived && !$0.isDraft }
        case .drafted:
            return trips.filter { $0.isDraft && !$0.isArchived }
        case .archived:
            return trips.filter { $0.isArchived }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color(UIColor.label) : Color.clear)
                .foregroundColor(isSelected ? Color(UIColor.systemBackground) : Color(UIColor.label) )
                .cornerRadius(20)
        }
    }
}

#Preview {
    TripsHomeView()
        .environmentObject(TripManager.shared)
        .environmentObject(AuthenticationManager.shared)
} 
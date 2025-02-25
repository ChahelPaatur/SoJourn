import SwiftUI

struct TripsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var selectedFilter: String
    let filters: [String]
    @Binding var trips: [Trip]
    @Binding var showNewTripSheet: Bool
    @Binding var showingAccountSheet: Bool
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            FilterPillsView(selectedFilter: $selectedFilter, filters: filters)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(trips) { trip in
                        TripCard(trip: trip)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Your Trips")
    }
} 
struct TripListView: View {
    let selectedFilter: String
    @Binding var trips: [Trip]
    let onArchive: (Trip) -> Void
    let onDelete: (Trip) -> Void
    
    var filteredTrips: [Trip] {
        switch selectedFilter {
        case "Archived":
            return trips.filter { $0.isArchived }
        case "Drafts":
            return trips.filter { $0.isDraft }
        default:
            return trips.filter { !$0.isArchived && !$0.isDraft }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(filteredTrips) { trip in
                    SwipeableCard(
                        trip: trip,
                        onArchive: onArchive,
                        onDelete: onDelete
                    )
                }
            }
            .padding()
        }
    }
} 
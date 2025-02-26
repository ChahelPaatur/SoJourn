import Foundation

class TripManager: ObservableObject {
    @Published private(set) var trips: [Trip] = []
    @Published var tripToEdit: UUID?
    @Published var isEditingTrip = false
    
    static let shared = TripManager()
    private let tripsKey = "savedTrips"
    
    init() {
        loadTrips()
    }
    
    func addTrip(_ trip: Trip) {
        trips.append(trip)
        saveTrips()
    }
    
    func updateTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
            saveTrips()
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
        saveTrips()
    }
    
    func postponeTrip(_ id: UUID, by days: Int) {
        if let index = trips.firstIndex(where: { $0.id == id }) {
            let trip = trips[index]
            
            let calendar = Calendar.current
            let newStartDate = calendar.date(byAdding: .day, value: days, to: trip.startDate) ?? trip.startDate
            let newEndDate = calendar.date(byAdding: .day, value: days, to: trip.endDate) ?? trip.endDate
            
            let updatedTrip = Trip(
                id: trip.id,
                title: trip.title,
                destination: trip.destination,
                startDate: newStartDate,
                endDate: newEndDate,
                notes: trip.notes,
                status: trip.status,
                isArchived: trip.isArchived,
                isDraft: trip.isDraft,
                isShared: trip.isShared,
                activities: trip.activities
            )
            
            trips[index] = updatedTrip
            saveTrips()
        }
    }
    
    func archiveTrip(_ id: UUID) {
        if let index = trips.firstIndex(where: { $0.id == id }) {
            var trip = trips[index]
            trip.isArchived = true
            trips[index] = trip
            saveTrips()
        }
    }
    
    func deleteTrip(_ id: UUID) {
        trips.removeAll { $0.id == id }
        saveTrips()
    }
    
    func unarchiveTrip(_ id: UUID) {
        if let index = trips.firstIndex(where: { $0.id == id }) {
            var trip = trips[index]
            trip.isArchived = false
            trips[index] = trip
            saveTrips()
        }
    }
    
    func editTrip(_ tripId: UUID) {
        self.tripToEdit = tripId
        self.isEditingTrip = true
    }
    
    // Persistence methods
    private func saveTrips() {
        do {
            let encodedData = try JSONEncoder().encode(trips)
            UserDefaults.standard.set(encodedData, forKey: tripsKey)
        } catch {
            print("Error saving trips: \(error.localizedDescription)")
        }
    }
    
    private func loadTrips() {
        guard let data = UserDefaults.standard.data(forKey: tripsKey) else {
            // If no saved data, initialize with empty array
            trips = []
            return
        }
        
        do {
            trips = try JSONDecoder().decode([Trip].self, from: data)
        } catch {
            print("Error loading trips: \(error.localizedDescription)")
            trips = []
        }
    }
} 
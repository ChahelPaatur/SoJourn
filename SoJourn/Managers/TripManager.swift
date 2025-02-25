import Foundation

class TripManager: ObservableObject {
    @Published private(set) var trips: [Trip] = []
    
    static let shared = TripManager()
    
    init() {}
    
    func addTrip(_ trip: Trip) {
        trips.append(trip)
    }
    
    func updateTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
    }
} 
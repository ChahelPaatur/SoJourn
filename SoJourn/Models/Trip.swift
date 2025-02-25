import Foundation
import SwiftUI

struct Trip: Identifiable, Codable {
    var id = UUID()
    var title: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var notes: String
    var status: TripStatus
    var isArchived: Bool
    var isDraft: Bool
    var isShared: Bool
    var activities: [Activity]
    
    enum TripStatus: String, Codable {
        case upcoming
        case active
        case completed
    }
    
    static let example = Trip(
        title: "Summer Vacation",
        destination: "Hawaii",
        startDate: Date().addingTimeInterval(60*60*24*30),
        endDate: Date().addingTimeInterval(60*60*24*37),
        notes: "Remember to pack sunscreen!",
        status: .upcoming,
        isArchived: false,
        isDraft: false,
        isShared: false,
        activities: [
            Activity(title: "Beach Day", date: Date().addingTimeInterval(60*60*24*31), notes: "Waikiki Beach"),
            Activity(title: "Hiking", date: Date().addingTimeInterval(60*60*24*32), notes: "Diamond Head Trail")
        ]
    )
}

struct Activity: Identifiable, Codable {
    var id = UUID()
    var title: String
    var date: Date
    var notes: String
} 
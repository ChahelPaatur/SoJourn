import SwiftUI
import MapKit

struct EditTripView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tripManager: TripManager
    
    var trip: Trip
    
    @State private var title: String
    @State private var destination: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var activities: [Activity]
    @State private var showingMap = false
    @State private var selectedActivity: Activity? = nil
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    init(trip: Trip) {
        self.trip = trip
        _title = State(initialValue: trip.title)
        _destination = State(initialValue: trip.destination)
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
        _notes = State(initialValue: trip.notes)
        _activities = State(initialValue: trip.activities)
        
        // Set initial map region based on first activity location if available
        if let firstActivity = trip.activities.first, 
           let location = firstActivity.location {
            _region = State(initialValue: MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section(header: Text("Trip Details")) {
                        TextField("Trip Name", text: $title)
                        TextField("Destination", text: $destination)
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                    
                    Section(header: Text("Notes")) {
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                    }
                    
                    Section(header: 
                        HStack {
                            Text("Itinerary")
                            Spacer()
                            Button("Edit on Map") {
                                showingMap = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    ) {
                        if activities.isEmpty {
                            Text("No activities planned yet")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            // Create a sorted array for display
                            let sortedActivities = activities.sorted(by: { $0.date < $1.date })
                            
                            ForEach(sortedActivities) { activity in
                                activityRow(activity)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            // Delete the specific activity by ID instead of by index
                                            deleteSpecificActivity(activity)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        
                        Button("Add Activity") {
                            addEmptyActivity()
                        }
                    }
                }
                
                if showingMap {
                    ZStack(alignment: .bottom) {
                        // Map view covering the bottom half
                        Map(coordinateRegion: $region, annotationItems: activities.filter { $0.location != nil }) { activity in
                            MapAnnotation(coordinate: activity.location!) {
                                VStack {
                                    Text(activity.title)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(4)
                                    
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.red)
                                }
                                .onTapGesture {
                                    selectedActivity = activity
                                }
                            }
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.6)
                        .ignoresSafeArea(edges: .bottom)
                        
                        // Controls overlay
                        VStack {
                            HStack {
                                Button {
                                    showingMap = false
                                } label: {
                                    Text("Done")
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                
                                Spacer()
                                
                                Button {
                                    addActivityAtCurrentLocation()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.black)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                            }
                            .padding()
                            
                            if let activity = selectedActivity {
                                editActivityPanel(activity)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                }
            )
        }
    }
    
    private func activityRow(_ activity: Activity) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(activity.title)
                .font(.headline)
            
            Text(formattedDateTime(activity.date))
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !activity.notes.isEmpty {
                Text(activity.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func editActivityPanel(_ activity: Activity) -> some View {
        VStack(spacing: 12) {
            // Find and edit the activity in our activities array
            let index = activities.firstIndex(where: { $0.id == activity.id })
            let binding = Binding(
                get: { 
                    if let idx = index {
                        return activities[idx]
                    }
                    return activity
                },
                set: { newValue in
                    if let idx = index {
                        activities[idx] = newValue
                    }
                }
            )
            
            TextField("Activity title", text: Binding(
                get: { binding.wrappedValue.title },
                set: { binding.wrappedValue.title = $0 }
            ))
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            
            DatePicker("Time", selection: Binding(
                get: { binding.wrappedValue.date },
                set: { binding.wrappedValue.date = $0 }
            ))
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            
            TextField("Notes", text: Binding(
                get: { binding.wrappedValue.notes },
                set: { binding.wrappedValue.notes = $0 }
            ))
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            
            HStack {
                Button("Delete") {
                    if let idx = index {
                        activities.remove(at: idx)
                    }
                    selectedActivity = nil
                }
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(8)
                
                Button("Done") {
                    selectedActivity = nil
                }
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding()
    }
    
    private func deleteSpecificActivity(_ activity: Activity) {
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities.remove(at: index)
        }
    }
    
    private func addEmptyActivity() {
        let newActivity = Activity(
            id: UUID(),
            title: "New Activity",
            date: Calendar.current.date(byAdding: .hour, value: activities.count, to: startDate) ?? startDate,
            notes: ""
        )
        activities.append(newActivity)
    }
    
    private func addActivityAtCurrentLocation() {
        let newActivity = Activity(
            id: UUID(),
            title: "New Activity",
            date: Calendar.current.date(byAdding: .hour, value: activities.count, to: startDate) ?? startDate,
            notes: ""
        )
        // Set location after creation
        var mutableActivity = newActivity
        mutableActivity.location = region.center
        activities.append(mutableActivity)
        selectedActivity = mutableActivity
    }
    
    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func saveChanges() {
        // Create updated trip with edited values
        let updatedTrip = Trip(
            id: trip.id,
            title: title,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            status: trip.status,
            isArchived: trip.isArchived,
            isDraft: trip.isDraft,
            isShared: trip.isShared,
            activities: activities
        )
        
        // Update trip in manager
        tripManager.updateTrip(updatedTrip)
        dismiss()
    }
}

// Extension to add location to Activity model
extension Activity {
    // Create a computed property for location using notes field temporarily
    // Format: "LOCATION:lat,lng\nUser visible notes"
    var location: CLLocationCoordinate2D? {
        get {
            // Extract location from notes if it starts with the LOCATION: prefix
            let lines = notes.split(separator: "\n")
            if let firstLine = lines.first, 
               firstLine.hasPrefix("LOCATION:") {
                let coordString = firstLine.dropFirst("LOCATION:".count)
                let coords = coordString.split(separator: ",")
                if coords.count == 2,
                   let lat = Double(coords[0]),
                   let lng = Double(coords[1]) {
                    return CLLocationCoordinate2D(latitude: lat, longitude: lng)
                }
            }
            return nil
        }
        set {
            if let newValue = newValue {
                // Preserve existing notes after the location prefix line
                let existingNotes = notes.split(separator: "\n").dropFirst().joined(separator: "\n")
                notes = "LOCATION:\(newValue.latitude),\(newValue.longitude)\n\(existingNotes)"
            }
        }
    }
} 
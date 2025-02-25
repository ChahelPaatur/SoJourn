import SwiftUI

struct NewTripView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tripManager: TripManager
    
    @State private var title = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(60*60*24*7) // One week later
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Title", text: $title)
                    TextField("Destination", text: $destination)
                }
                
                Section(header: Text("Dates")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trip = Trip(
                            id: UUID(),
                            title: title,
                            destination: destination,
                            startDate: startDate,
                            endDate: endDate,
                            notes: notes,
                            status: .upcoming,
                            isArchived: false,
                            isDraft: false,
                            isShared: false,
                            activities: []
                        )
                        
                        tripManager.addTrip(trip)
                        dismiss()
                    }
                    .disabled(title.isEmpty || destination.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NewTripView()
        .environmentObject(TripManager.shared)
} 
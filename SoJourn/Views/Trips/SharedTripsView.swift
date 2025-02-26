import SwiftUI

struct SharedTripsView: View {
    @EnvironmentObject private var tripManager: TripManager
    @State private var selectedTrip: Trip?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if tripManager.trips.filter({ $0.isShared }).isEmpty {
                    VStack {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 70))
                            .foregroundColor(.gray)
                        
                        Text("No Shared Trips")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Trips shared with you will appear here")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(tripManager.trips.filter { $0.isShared }) { trip in
                        Button {
                            selectedTrip = trip
                            showingShareSheet = true
                        } label: {
                            TripCard(trip: trip)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Shared Trips")
            .sheet(isPresented: $showingShareSheet, content: {
                if let trip = selectedTrip {
                    TripSharingView(trip: trip)
                }
            })
        }
        .accentColor(.black)
    }
}

#Preview {
    SharedTripsView()
        .environmentObject(TripManager.shared)
} 
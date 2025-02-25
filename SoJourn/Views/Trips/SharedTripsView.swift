import SwiftUI

struct SharedTripsView: View {
    @EnvironmentObject private var tripManager: TripManager
    
    var body: some View {
        NavigationView {
            VStack {
                if tripManager.trips.filter({ $0.isShared }).isEmpty {
                    VStack(spacing: 20) {
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
                        TripCard(trip: trip)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Shared Trips")
        }
        .accentColor(.black)
    }
}

#Preview {
    SharedTripsView()
        .environmentObject(TripManager.shared)
} 
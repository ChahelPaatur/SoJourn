import SwiftUI

struct CompletedTripsView: View {
    @EnvironmentObject private var tripManager: TripManager
    
    var body: some View {
        NavigationView {
            VStack {
                if tripManager.trips.filter({ $0.status == .completed }).isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 70))
                            .foregroundColor(.gray)
                        
                        Text("No Past Trips")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Your completed trips will appear here")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(tripManager.trips.filter { $0.status == .completed }) { trip in
                        TripCard(trip: trip)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Past Trips")
        }
        .accentColor(.black)
    }
}

#Preview {
    CompletedTripsView()
        .environmentObject(TripManager.shared)
} 
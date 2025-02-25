import SwiftUI

struct DiscoverView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Featured destinations
                        VStack(alignment: .leading) {
                            Text("Popular Destinations")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(["Paris", "Tokyo", "New York", "Bali", "London"], id: \.self) { destination in
                                        destinationCard(destination)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Trending experiences
                        VStack(alignment: .leading) {
                            Text("Trending Experiences")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(["Hiking", "Beach", "Food Tour", "Museums", "Shopping"], id: \.self) { experience in
                                        experienceCard(experience)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Discover")
            .searchable(text: $searchText, prompt: "Search destinations")
        }
        .accentColor(.black)
    }
    
    private func destinationCard(_ name: String) -> some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 160, height: 120)
                .cornerRadius(12)
            
            Text(name)
                .font(.headline)
                .padding(.top, 4)
        }
        .frame(width: 160)
    }
    
    private func experienceCard(_ name: String) -> some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 140, height: 100)
                .cornerRadius(12)
            
            Text(name)
                .font(.headline)
                .padding(.top, 4)
        }
        .frame(width: 140)
    }
}

#Preview {
    DiscoverView()
} 
import SwiftUI

struct TripTabView: View {
    @Binding var selectedTab: Int
    let tabs: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    Text(tabs[index])
                        .fontWeight(selectedTab == index ? .semibold : .regular)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedTab == index ? 
                            Color.selectedTabBackground : Color.tabBackground
                        )
                        .foregroundColor(Color.foreground)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 4)
            }
        }
        .padding(8)
        .background(Color.tabBackground.opacity(0.7))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct TripTabView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TripTabView(
                selectedTab: .constant(0), 
                tabs: ["Upcoming", "Drafts", "Archived"]
            )
        }
        .preferredColorScheme(.light)
        
        VStack {
            TripTabView(
                selectedTab: .constant(0), 
                tabs: ["Upcoming", "Drafts", "Archived"]
            )
        }
        .preferredColorScheme(.dark)
    }
} 
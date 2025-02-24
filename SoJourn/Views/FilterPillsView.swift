struct FilterPillsView: View {
    @Binding var selectedFilter: String
    let filters: [String]
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.easeInOut) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedFilter == filter ? 
                                (authManager.userProfile.darkModeEnabled ? .black : .white) :
                                (authManager.userProfile.darkModeEnabled ? .white : .black))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ?
                                        (authManager.userProfile.darkModeEnabled ? Color.yellow : Color.black) :
                                        Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(authManager.userProfile.darkModeEnabled ? Color.yellow : Color.black,
                                            lineWidth: selectedFilter == filter ? 0 : 1)
                            )
                    }
                }
            }
            .padding()
        }
    }
} 
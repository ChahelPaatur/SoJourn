import SwiftUI

struct FilterPillsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedFilter: String
    let filters: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.spring()) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? 
                                      (colorScheme == .dark ? Color.yellow : Color.black) : 
                                      Color.clear)
                            .foregroundColor(selectedFilter == filter ? 
                                           (colorScheme == .dark ? .black : .white) : 
                                           Color.sojourn.adaptiveText(for: colorScheme))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.sojourn.secondary.opacity(0.3), 
                                           lineWidth: selectedFilter == filter ? 0 : 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.sojourn.adaptiveBackground(for: colorScheme))
    }
} 
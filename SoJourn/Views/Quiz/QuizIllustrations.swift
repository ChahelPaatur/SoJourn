import SwiftUI

struct QuizIllustrations {
    struct AgeVerification: View {
        var body: some View {
            ZStack {
                // Car illustration
                Image(systemName: "car.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                // Person
                Image(systemName: "person.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.black)
                    .offset(x: -20, y: -15)
            }
        }
    }
    
    struct WeatherPreference: View {
        var body: some View {
            ZStack {
                // Trees
                HStack(spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    struct PinterestIntegration: View {
        var body: some View {
            ZStack {
                // Map background
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.brown.opacity(0.3))
                
                // Travel elements
                VStack(spacing: 5) {
                    Image(systemName: "airplane")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                    
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(-30))
                }
            }
        }
    }
} 
import SwiftUI

struct WeatherView: View {
    var temperature: Double?
    var temperatureMin: Double?
    var temperatureMax: Double?
    var condition: String?
    var precipitationProbability: Double?
    var humidity: Double?
    var windSpeed: Double?
    var windDirection: String?
    var sunrise: String?
    var sunset: String?
    
    @State private var isLoading = false
    @State private var hasError = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if hasError {
                errorView
            } else {
                weatherContent
            }
        }
        .onAppear {
            // This would be replaced with actual API call in a real implementation
            isLoading = false
        }
    }
    
    // MARK: - Content Views
    
    private var weatherContent: some View {
        VStack(spacing: 0) {
            // Main weather card
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        gradient: getGradientForCondition(condition),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 16) {
                    // Top row with condition and temperature
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(formattedCondition)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text("Feels like \(Int((temperature ?? 0).rounded()))")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Text("\(Int((temperature ?? 0).rounded()))°")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Middle row with weather icon
                    HStack {
                        Spacer()
                        
                        Image(systemName: getWeatherIconName(condition))
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    // Bottom row with high/low
                    HStack {
                        Spacer()
                        
                        Text("H: \(Int((temperatureMax ?? 0).rounded()))°")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("L: \(Int((temperatureMin ?? 0).rounded()))°")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.leading, 8)
                        
                        Spacer()
                    }
                }
                .padding(20)
            }
            .frame(height: 200)
            .padding(.horizontal)
            
            // Weather details
            VStack(spacing: 8) {
                Text("Weather Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                
                detailsGridView
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var detailsGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            weatherDetailItem(
                icon: "drop.fill",
                title: "Precipitation",
                value: "\(Int((precipitationProbability ?? 0).rounded()))%"
            )
            
            weatherDetailItem(
                icon: "humidity.fill",
                title: "Humidity",
                value: "\(Int((humidity ?? 0).rounded()))%"
            )
            
            weatherDetailItem(
                icon: "wind",
                title: "Wind",
                value: "\(Int((windSpeed ?? 0).rounded())) km/h"
            )
            
            weatherDetailItem(
                icon: "sun.max.fill",
                title: "UV Index",
                value: getUVIndexCategory(from: condition)
            )
            
            weatherDetailItem(
                icon: "sunrise.fill",
                title: "Sunrise",
                value: sunrise ?? "Unknown"
            )
            
            weatherDetailItem(
                icon: "sunset.fill",
                title: "Sunset",
                value: sunset ?? "Unknown"
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func weatherDetailItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(getIconColor(for: icon))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundColor(.orange)
            
            Text("Couldn't load weather information")
                .font(.headline)
            
            Text("Please check your internet connection and try again")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                // Retry logic would go here
                hasError = false
                isLoading = true
                
                // Simulate API call
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isLoading = false
                }
            }) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading weather data...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
    }
    
    // MARK: - Helper Methods
    
    private func getWeatherIconName(_ condition: String?) -> String {
        guard let condition = condition else { return "cloud.fill" }
        
        switch condition {
        case "clear":
            return "sun.max.fill"
        case "partlyCloudy":
            return "cloud.sun.fill"
        case "cloudy":
            return "cloud.fill"
        case "mostlyCloudy":
            return "smoke.fill"
        case "fog":
            return "cloud.fog.fill"
        case "rain":
            return "cloud.rain.fill"
        case "drizzle":
            return "cloud.drizzle.fill"
        case "snow":
            return "cloud.snow.fill"
        case "sleet":
            return "cloud.sleet.fill"
        case "thunderstorms":
            return "cloud.bolt.rain.fill"
        case "sunShowers":
            return "cloud.sun.rain.fill"
        case "sunFlurries":
            return "cloud.sun.snow.fill"
        default:
            return "cloud.fill"
        }
    }
    
    private func getGradientForCondition(_ condition: String?) -> Gradient {
        guard let condition = condition else {
            return Gradient(colors: [Color.blue, Color.blue.opacity(0.7)])
        }
        
        switch condition {
        case "clear":
            return Gradient(colors: [Color.blue, Color(hex: "87CEEB")])
        case "partlyCloudy", "mostlyCloudy", "cloudy":
            return Gradient(colors: [Color(hex: "4682B4"), Color(hex: "87CEEB")])
        case "fog":
            return Gradient(colors: [Color(hex: "708090"), Color(hex: "B0C4DE")])
        case "rain", "drizzle", "sunShowers":
            return Gradient(colors: [Color(hex: "4682B4"), Color(hex: "778899")])
        case "thunderstorms":
            return Gradient(colors: [Color(hex: "4B0082"), Color(hex: "483D8B")])
        case "snow", "sunFlurries", "sleet":
            return Gradient(colors: [Color(hex: "708090"), Color(hex: "B0C4DE")])
        default:
            return Gradient(colors: [Color.blue, Color.blue.opacity(0.7)])
        }
    }
    
    private func getIconColor(for icon: String) -> Color {
        switch icon {
        case "drop.fill":
            return Color.blue
        case "humidity.fill":
            return Color(hex: "3CB371")
        case "wind":
            return Color(hex: "20B2AA")
        case "sun.max.fill":
            return Color.orange
        case "sunrise.fill":
            return Color.orange
        case "sunset.fill":
            return Color(hex: "FF6347")
        default:
            return Color.blue
        }
    }
    
    private func getUVIndexCategory(from condition: String?) -> String {
        guard let condition = condition else { return "Low" }
        
        switch condition {
        case "clear":
            return "High"
        case "partlyCloudy":
            return "Moderate"
        case "cloudy", "mostlyCloudy", "fog", "rain", "drizzle", "thunderstorms":
            return "Low"
        default:
            return "Low"
        }
    }
    
    private var formattedCondition: String {
        guard let condition = condition else { return "Unknown" }
        
        switch condition {
        case "clear":
            return "Clear"
        case "partlyCloudy":
            return "Partly Cloudy"
        case "cloudy":
            return "Cloudy"
        case "mostlyCloudy":
            return "Mostly Cloudy"
        case "fog":
            return "Foggy"
        case "rain":
            return "Rain"
        case "drizzle":
            return "Drizzle"
        case "snow":
            return "Snow"
        case "sleet":
            return "Sleet"
        case "thunderstorms":
            return "Thunderstorms"
        case "sunShowers":
            return "Sun Showers"
        case "sunFlurries":
            return "Sun Flurries"
        default:
            return condition.capitalized
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                WeatherView(
                    temperature: 23.5,
                    temperatureMin: 19.2,
                    temperatureMax: 26.7,
                    condition: "partlyCloudy",
                    precipitationProbability: 30,
                    humidity: 65,
                    windSpeed: 12,
                    windDirection: "NW",
                    sunrise: "06:30 AM",
                    sunset: "07:45 PM"
                )
                
                Divider()
                    .padding(.vertical)
                
                WeatherView(
                    temperature: 12.3,
                    temperatureMin: 8.5,
                    temperatureMax: 14.2,
                    condition: "rain",
                    precipitationProbability: 80,
                    humidity: 85,
                    windSpeed: 18,
                    windDirection: "SE",
                    sunrise: "07:15 AM",
                    sunset: "06:30 PM"
                )
                
                Divider()
                    .padding(.vertical)
                
                // Error state preview
                WeatherView(isLoading: false, hasError: true)
                
                Divider()
                    .padding(.vertical)
                
                // Loading state preview
                WeatherView(isLoading: true, hasError: false)
            }
            .padding(.vertical)
        }
    }
    
    // Helper initializer for showing error/loading states
    fileprivate static func WeatherView(isLoading: Bool, hasError: Bool) -> WeatherView {
        var view = WeatherView(
            temperature: nil,
            temperatureMin: nil,
            temperatureMax: nil,
            condition: nil,
            precipitationProbability: nil,
            humidity: nil,
            windSpeed: nil,
            windDirection: nil,
            sunrise: nil,
            sunset: nil
        )
        view.isLoading = isLoading
        view.hasError = hasError
        return view
    }
} 
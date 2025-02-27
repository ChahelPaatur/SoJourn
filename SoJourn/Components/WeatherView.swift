import SwiftUI

struct WeatherView: View {
    var location: String
    var days: [WeatherManager.WeatherResponse.DayForecast]
    var isLoading: Bool
    var errorMessage: String?
    
    // SF Symbol mapping for weather conditions
    private func symbolName(for condition: String) -> String {
        let lowercased = condition.lowercased()
        
        switch lowercased {
        case _ where lowercased.contains("sunny"):
            return "sun.max.fill"
        case _ where lowercased.contains("clear"):
            return "sun.max.fill"
        case _ where lowercased.contains("cloudy"), _ where lowercased.contains("overcast"):
            return "cloud.fill"
        case _ where lowercased.contains("partly cloudy"):
            return "cloud.sun.fill"
        case _ where lowercased.contains("rain"), _ where lowercased.contains("drizzle"):
            return "cloud.rain.fill"
        case _ where lowercased.contains("thunder"), _ where lowercased.contains("lightning"):
            return "cloud.bolt.rain.fill"
        case _ where lowercased.contains("snow"), _ where lowercased.contains("blizzard"):
            return "cloud.snow.fill"
        case _ where lowercased.contains("sleet"):
            return "cloud.sleet.fill"
        case _ where lowercased.contains("fog"), _ where lowercased.contains("mist"):
            return "cloud.fog.fill"
        case _ where lowercased.contains("hail"):
            return "cloud.hail.fill"
        case _ where lowercased.contains("wind"):
            return "wind"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    // Background color based on weather condition
    private func backgroundColor(for condition: String, opacity: Double = 1.0) -> Color {
        let lowercased = condition.lowercased()
        
        if lowercased.contains("sunny") || lowercased.contains("clear") {
            return Color.blue.opacity(opacity)
        } else if lowercased.contains("cloudy") || lowercased.contains("overcast") {
            return Color.gray.opacity(opacity)
        } else if lowercased.contains("rain") || lowercased.contains("drizzle") {
            return Color(red: 0.4, green: 0.5, blue: 0.6).opacity(opacity)
        } else if lowercased.contains("thunder") {
            return Color(red: 0.3, green: 0.3, blue: 0.4).opacity(opacity)
        } else if lowercased.contains("snow") {
            return Color(red: 0.8, green: 0.8, blue: 0.9).opacity(opacity)
        } else if lowercased.contains("fog") || lowercased.contains("mist") {
            return Color(red: 0.7, green: 0.7, blue: 0.7).opacity(opacity)
        } else {
            return Color.blue.opacity(opacity)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(message: error)
            } else if days.isEmpty {
                emptyStateView
            } else {
                weatherContentView
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Content Views
    
    private var weatherContentView: some View {
        VStack(spacing: 0) {
            // Current weather header
            if let today = days.first {
                ZStack {
                    backgroundColor(for: today.condition)
                        .ignoresSafeArea()
                    
                    VStack {
                        Text(location)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 16) {
                            Image(systemName: symbolName(for: today.condition))
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 56))
                            
                            VStack(alignment: .leading) {
                                Text("\(Int(today.temperature.max))°")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(today.condition)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        HStack(spacing: 24) {
                            WeatherDetailItem(
                                icon: "humidity.fill",
                                value: "\(Int(today.humidity))%",
                                label: "Humidity"
                            )
                            
                            WeatherDetailItem(
                                icon: "wind",
                                value: "\(Int(today.wind.speed)) mph",
                                label: "Wind"
                            )
                            
                            WeatherDetailItem(
                                icon: "drop.fill",
                                value: "\(Int(today.precipitation.probability))%",
                                label: "Rain"
                            )
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.vertical, 24)
                }
            }
            
            // Forecast section
            VStack(spacing: 0) {
                Text("Daily Forecast")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Divider()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(days.indices, id: \.self) { index in
                            let day = days[index]
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            
                            let date = dateFormatter.date(from: day.date) ?? Date()
                            dateFormatter.dateFormat = index == 0 ? "Today" : "E"
                            let dayName = dateFormatter.string(from: date)
                            
                            DailyForecastItem(
                                day: dayName,
                                condition: day.condition,
                                highTemp: day.temperature.max,
                                lowTemp: day.temperature.min,
                                symbolName: symbolName(for: day.condition)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                Divider()
                
                if let today = days.first {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's Details")
                                .font(.headline)
                            
                            Text(location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack {
                            VStack(alignment: .trailing) {
                                Text("\(Int(today.temperature.max))°")
                                    .font(.body)
                                Text("High")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .trailing) {
                                Text("\(Int(today.temperature.min))°")
                                    .font(.body)
                                Text("Low")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    VStack(spacing: 16) {
                        HourlyForecastView(
                            morning: today.temperature.morning ?? today.temperature.min,
                            afternoon: today.temperature.afternoon ?? today.temperature.max,
                            evening: today.temperature.evening ?? today.temperature.max,
                            overnight: today.temperature.overnight ?? today.temperature.min,
                            condition: today.condition
                        )
                        
                        HStack {
                            InfoRow(
                                title: "Sunrise",
                                value: today.sunrise,
                                icon: "sunrise.fill"
                            )
                            
                            Divider()
                            
                            InfoRow(
                                title: "Sunset",
                                value: today.sunset,
                                icon: "sunset.fill"
                            )
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            InfoRow(
                                title: "Chance of Rain",
                                value: "\(Int(today.precipitation.probability))%",
                                icon: "cloud.rain.fill"
                            )
                            
                            Divider()
                            
                            InfoRow(
                                title: "Precipitation",
                                value: "\(today.precipitation.amount) mm",
                                icon: "drop.fill"
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .offset(y: -20)
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading weather data...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Weather data unavailable")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                // Add refresh action if needed
            }) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(height: 300)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Weather Data")
                .font(.headline)
            
            Text("Weather information for this location is not available.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(height: 300)
    }
}

// MARK: - Supporting Views

struct WeatherDetailItem: View {
    var icon: String
    var value: String
    var label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct DailyForecastItem: View {
    var day: String
    var condition: String
    var highTemp: Double
    var lowTemp: Double
    var symbolName: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(day)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
            
            Image(systemName: symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 24))
            
            Text("\(Int(highTemp))°")
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
            
            Text("\(Int(lowTemp))°")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(width: 60)
    }
}

struct HourlyForecastView: View {
    var morning: Double
    var afternoon: Double
    var evening: Double
    var overnight: Double
    var condition: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    TimeOfDayItem(
                        time: "Morning",
                        temperature: morning,
                        icon: "sunrise.fill"
                    )
                    
                    TimeOfDayItem(
                        time: "Afternoon",
                        temperature: afternoon,
                        icon: "sun.max.fill"
                    )
                    
                    TimeOfDayItem(
                        time: "Evening",
                        temperature: evening,
                        icon: "sunset.fill"
                    )
                    
                    TimeOfDayItem(
                        time: "Overnight",
                        temperature: overnight,
                        icon: "moon.stars.fill"
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TimeOfDayItem: View {
    var time: String
    var temperature: Double
    var icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(time)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
            
            Image(systemName: icon)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 24))
            
            Text("\(Int(temperature))°")
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
        }
    }
}

struct InfoRow: View {
    var title: String
    var value: String
    var icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 20))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        let mockDayForecast = WeatherManager.WeatherResponse.DayForecast(
            date: "2023-08-01",
            temperature: .init(
                min: 68,
                max: 82,
                morning: 70,
                afternoon: 82,
                evening: 75,
                overnight: 68
            ),
            condition: "Partly cloudy",
            precipitation: .init(probability: 30, amount: 0.5),
            humidity: 65,
            wind: .init(speed: 10, direction: 180),
            sunrise: "6:05 AM",
            sunset: "8:31 PM"
        )
        
        let days = [mockDayForecast]
        
        return VStack {
            WeatherView(
                location: "San Francisco, CA",
                days: days,
                isLoading: false,
                errorMessage: nil
            )
            
            Spacer()
        }
        .edgesIgnoringSafeArea(.top)
    }
} 
import SwiftUI

struct TripWeatherView: View {
    @ObservedObject private var weatherManager = WeatherManager.shared
    @State private var weatherResponse: WeatherManager.WeatherResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var tripId: String
    var location: String
    var latitude: Double
    var longitude: Double
    var startDate: Date
    var endDate: Date
    
    var body: some View {
        VStack {
            if isLoading {
                WeatherView(
                    location: location,
                    days: [],
                    isLoading: true,
                    errorMessage: nil
                )
            } else if let error = errorMessage {
                WeatherView(
                    location: location,
                    days: [],
                    isLoading: false,
                    errorMessage: error
                )
            } else if let response = weatherResponse {
                WeatherView(
                    location: response.location.name,
                    days: response.days,
                    isLoading: false,
                    errorMessage: nil
                )
            } else {
                WeatherView(
                    location: location,
                    days: [],
                    isLoading: true,
                    errorMessage: nil
                )
                .onAppear {
                    fetchWeatherData()
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private func fetchWeatherData() {
        isLoading = true
        errorMessage = nil
        
        weatherManager.fetchWeatherForecast(
            latitude: latitude,
            longitude: longitude,
            startDate: startDate,
            endDate: endDate
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let response):
                weatherResponse = response
            case .failure(let error):
                errorMessage = error.localizedDescription
                print("Weather error: \(error)")
            }
        }
    }
}

// MARK: - Preview
struct TripWeatherView_Previews: PreviewProvider {
    static var previews: some View {
        TripWeatherView(
            tripId: "123",
            location: "San Francisco, CA",
            latitude: 37.7749,
            longitude: -122.4194,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        )
        .previewLayout(.sizeThatFits)
    }
} 
import Foundation
import Combine

class WeatherManager: ObservableObject {
    static let shared = WeatherManager()
    
    private let baseURL = "http://localhost:8000/api"
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // Weather data models to match our backend
    struct WeatherResponse: Codable {
        let location: Location
        let days: [DayForecast]
        let note: String?
        
        struct Location: Codable {
            let latitude: Double
            let longitude: Double
            let name: String
        }
        
        struct DayForecast: Codable {
            let date: String
            let temperature: Temperature
            let condition: String
            let precipitation: Precipitation
            let humidity: Double
            let wind: Wind
            let sunrise: String
            let sunset: String
            
            struct Temperature: Codable {
                let min: Double
                let max: Double
                let morning: Double?
                let afternoon: Double?
                let evening: Double?
                let overnight: Double?
            }
            
            struct Precipitation: Codable {
                let probability: Double
                let amount: Double
            }
            
            struct Wind: Codable {
                let speed: Double
                let direction: Double
            }
        }
    }
    
    struct WeatherData: Codable {
        let temperature: Double?
        let temperatureMin: Double?
        let temperatureMax: Double?
        let condition: String?
        let precipitationProbability: Double?
        let humidity: Double?
        let windSpeed: Double?
        let windDirection: String?
        let cloudCover: Double?
        let sunrise: String?
        let sunset: String?
        let forecastTimestamp: String?
        
        enum CodingKeys: String, CodingKey {
            case temperature
            case temperatureMin = "temperature_min"
            case temperatureMax = "temperature_max"
            case condition
            case precipitationProbability = "precipitation_probability"
            case humidity
            case windSpeed = "wind_speed"
            case windDirection = "wind_direction"
            case cloudCover = "cloud_cover"
            case sunrise
            case sunset
            case forecastTimestamp = "forecast_timestamp"
        }
    }
    
    // MARK: - Public methods
    
    func fetchWeatherForecast(
        latitude: Double,
        longitude: Double,
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<WeatherResponse, Error>) -> Void
    ) {
        isLoading = true
        errorMessage = nil
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        guard var urlComponents = URLComponents(string: "\(baseURL)/weather/forecast") else {
            completion(.failure(NetworkError.invalidURL))
            isLoading = false
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "start_date", value: startDateString),
            URLQueryItem(name: "end_date", value: endDateString)
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NetworkError.invalidURL))
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token here if needed
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionStatus in
                self?.isLoading = false
                switch completionStatus {
                case .finished:
                    break
                case .failure(let error):
                    self?.handleNetworkError(error: error)
                    completion(.failure(error))
                }
            } receiveValue: { response in
                completion(.success(response))
            }
            .store(in: &cancellables)
    }
    
    func fetchWeatherForActivity(
        latitude: Double,
        longitude: Double,
        date: Date,
        completion: @escaping (Result<WeatherData, Error>) -> Void
    ) {
        isLoading = true
        errorMessage = nil
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        guard var urlComponents = URLComponents(string: "\(baseURL)/weather/activity") else {
            completion(.failure(NetworkError.invalidURL))
            isLoading = false
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "date", value: dateString)
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NetworkError.invalidURL))
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token here if needed
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: WeatherData.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionStatus in
                self?.isLoading = false
                switch completionStatus {
                case .finished:
                    break
                case .failure(let error):
                    self?.handleNetworkError(error: error)
                    completion(.failure(error))
                }
            } receiveValue: { response in
                completion(.success(response))
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private methods
    
    private func handleNetworkError(error: Error) {
        print("Weather API Error: \(error.localizedDescription)")
        
        // You could add more sophisticated error handling here
        // For now, we're just setting the error message
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                errorMessage = "No internet connection. Please check your network settings."
            case .timedOut:
                errorMessage = "Request timed out. Please try again."
            default:
                errorMessage = "Network error: \(urlError.localizedDescription)"
            }
        } else {
            errorMessage = "Error fetching weather data: \(error.localizedDescription)"
        }
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(String)
    case authError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Could not decode the response"
        case .serverError(let message):
            return "Server error: \(message)"
        case .authError:
            return "Authentication error"
        }
    }
} 
import Foundation
import CoreLocation

struct WeatherResponse: Codable {
    let main: Main
    let weather: [Weather]
    let visibility: Int
    let wind: Wind
    let name: String
    
    struct Main: Codable {
        let temp: Double
    }
    
    struct Weather: Codable {
        let main: String
        let description: String
    }
    
    struct Wind: Codable {
        let speed: Double
    }
}

class WeatherService {
    private let apiKey = "ff7674a8cc3e9d8d621946216f3f76d9"
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    func fetchWeather(location: CLLocation) async throws -> WeatherData {
        print("WeatherService: Starting weather loading for coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Format URL with rounded coordinates to 4 decimal places for better stability
        let lat = String(format: "%.4f", location.coordinate.latitude)
        let lon = String(format: "%.4f", location.coordinate.longitude)
        let urlString = "\(baseURL)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        
        print("WeatherService: Request URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("WeatherService: Error - invalid URL")
            throw URLError(.badURL)
        }
        
        print("WeatherService: Sending request...")
        let (data, response) = try await URLSession.shared.data(from: url)
        print("WeatherService: Response received from server")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("WeatherService: Error - invalid server response")
            throw URLError(.badServerResponse)
        }
        
        print("WeatherService: Server response code: \(httpResponse.statusCode)")
        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("WeatherService: Server error with code \(httpResponse.statusCode). Response body: \(responseString)")
            }
            throw URLError(.badServerResponse)
        }
        
        do {
            let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
            print("WeatherService: Response successfully decoded: \(weatherResponse)")
            
            let weatherMain = weatherResponse.weather.first?.main ?? "Unknown"
            let weatherType = WeatherType.fromString(weatherMain)
            
            let result = WeatherData(
                temperature: weatherResponse.main.temp,
                windSpeed: weatherResponse.wind.speed,
                weatherType: weatherType,
                description: weatherResponse.weather.first?.description ?? "",
                visibility: "\(weatherResponse.visibility / 1000)+ Km",
                cityName: weatherResponse.name
            )
            
            print("WeatherService: Weather data created: temperature \(result.temperature)°C, type \(result.weatherType.rawValue), city \(result.cityName)")
            return result
        } catch {
            print("WeatherService: JSON decoding error: \(error.localizedDescription)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("WeatherService: Response body: \(responseString)")
            }
            throw error
        }
    }
} 
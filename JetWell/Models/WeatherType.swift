import SwiftUI

enum WeatherType: String, CaseIterable {
    case clear = "Clear"
    case clouds = "Clouds"
    case rain = "Rain"
    case drizzle = "Drizzle"
    case thunderstorm = "Thunderstorm"
    case snow = "Snow"
    case mist = "Mist"
    case smoke = "Smoke"
    case haze = "Haze"
    case dust = "Dust"
    case fog = "Fog"
    case sand = "Sand"
    case ash = "Ash"
    case squall = "Squall"
    case tornado = "Tornado"
    case unknown = "Unknown"
    
    var systemIconName: String {
        switch self {
        case .clear:
            return "sun.max.fill"
        case .clouds:
            return "cloud.fill"
        case .rain:
            return "cloud.rain.fill"
        case .drizzle:
            return "cloud.drizzle.fill"
        case .thunderstorm:
            return "cloud.bolt.fill"
        case .snow:
            return "cloud.snow.fill"
        case .mist, .smoke, .haze, .fog:
            return "cloud.fog.fill"
        case .dust, .sand, .ash:
            return "sun.dust.fill"
        case .squall:
            return "wind"
        case .tornado:
            return "tornado"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .clear:
            return "Clear"
        case .clouds:
            return "Cloudy"
        case .rain:
            return "Rain"
        case .drizzle:
            return "Drizzle"
        case .thunderstorm:
            return "Thunderstorm"
        case .snow:
            return "Snow"
        case .mist:
            return "Mist"
        case .smoke:
            return "Smoke"
        case .haze:
            return "Haze"
        case .dust:
            return "Dust"
        case .fog:
            return "Fog"
        case .sand:
            return "Sandstorm"
        case .ash:
            return "Volcanic Ash"
        case .squall:
            return "Squall"
        case .tornado:
            return "Tornado"
        case .unknown:
            return "Unknown"
        }
    }
    
    static func fromString(_ string: String) -> WeatherType {
        return WeatherType.allCases.first { $0.rawValue == string } ?? .unknown
    }
} 
import Foundation

/// Weather conditions derived from WMO weather interpretation codes.
/// Used to drive visual effects on the grass island background.
enum WeatherCondition: String, CaseIterable {
    case sunny
    case partlyCloudy
    case cloudy
    case foggy
    case rainy
    case snowy
    case thunderstorm

    /// Whether the sky is considered dark enough for dimmed visuals.
    var isDark: Bool {
        switch self {
        case .thunderstorm: return true
        default: return false
        }
    }

    /// Display name with emoji for UI.
    var displayName: String {
        switch self {
        case .sunny:        return "☀️ Sunny"
        case .partlyCloudy: return "⛅ Partly Cloudy"
        case .cloudy:       return "☁️ Cloudy"
        case .foggy:        return "🌫️ Foggy"
        case .rainy:        return "🌧️ Rainy"
        case .snowy:        return "❄️ Snowy"
        case .thunderstorm: return "⛈️ Thunderstorm"
        }
    }

    /// Map a WMO weather code + day/night flag to a `WeatherCondition`.
    /// Reference: https://open-meteo.com/en/docs#weathervariables
    static func from(wmoCode: Int, isDay: Bool) -> (condition: WeatherCondition, isNight: Bool) {
        let condition: WeatherCondition
        switch wmoCode {
        case 0, 1:
            condition = .sunny
        case 2:
            condition = .partlyCloudy
        case 3:
            condition = .cloudy
        case 45, 48:
            condition = .foggy
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82:
            condition = .rainy
        case 71, 73, 75, 77, 85, 86:
            condition = .snowy
        case 95, 96, 99:
            condition = .thunderstorm
        default:
            condition = .sunny
        }
        return (condition, !isDay)
    }

    /// Grass tint color overlay for each weather.
    var grassTintColor: (red: Double, green: Double, blue: Double, opacity: Double) {
        switch self {
        case .sunny:        return (1.0, 0.95, 0.6, 0.15)
        case .partlyCloudy: return (0.7, 0.8, 0.9, 0.12)
        case .cloudy:       return (0.45, 0.5, 0.6, 0.25)
        case .foggy:        return (0.75, 0.75, 0.8, 0.3)
        case .rainy:        return (0.2, 0.3, 0.55, 0.3)
        case .snowy:        return (0.8, 0.85, 1.0, 0.35)
        case .thunderstorm: return (0.15, 0.1, 0.3, 0.35)
        }
    }

    /// Night overlay tint (deep blue).
    static var nightTint: (red: Double, green: Double, blue: Double, opacity: Double) {
        (0.05, 0.05, 0.25, 0.4)
    }
}

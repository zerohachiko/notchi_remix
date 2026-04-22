import CoreLocation
import Foundation
import os.log

private let logger = Logger(subsystem: "com.zerohachiko.notchi-remix", category: "WeatherService")

/// Fetches weather data from Open-Meteo (free, no API key) using Core Location.
/// Polls every hour and exposes the current weather condition.
@MainActor @Observable
final class WeatherService: NSObject {
    static let shared = WeatherService()

    private(set) var condition: WeatherCondition = .sunny
    private(set) var isNight: Bool = false
    private(set) var lastUpdated: Date?

    /// When true, real weather updates are ignored in favor of manual overrides.
    private(set) var isDebugMode: Bool = false

    private let locationManager = CLLocationManager()
    private var pollTimer: Timer?
    private var lastLocation: CLLocation?
    private var isRequestingLocation = false

    private static let pollInterval: TimeInterval = 3600 // 1 hour

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func startPolling() {
        requestLocationAndFetch()

        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.requestLocationAndFetch()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    /// Force an immediate refresh.
    func refresh() {
        requestLocationAndFetch()
    }

    /// Set a debug override. Pass nil to clear.
    func setDebugOverride(condition: WeatherCondition, isNight: Bool) {
        isDebugMode = true
        self.condition = condition
        self.isNight = isNight
    }

    /// Clear the debug override and resume real weather.
    func clearDebugOverride() {
        isDebugMode = false
        refresh()
    }

    // MARK: - Private

    private func requestLocationAndFetch() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorized:
            requestCurrentLocation()
        case .denied, .restricted:
            logger.info("Location permission denied, using IP-based geolocation fallback")
            fetchWeatherViaIPGeolocation()
        @unknown default:
            fetchWeatherViaIPGeolocation()
        }
    }

    private func requestCurrentLocation() {
        guard !isRequestingLocation else { return }
        isRequestingLocation = true
        locationManager.requestLocation()
    }

    private func fetchWeather(latitude: Double, longitude: Double) {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=weather_code,is_day&timezone=auto"
        guard let url = URL(string: urlString) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
                let result = WeatherCondition.from(
                    wmoCode: response.current.weatherCode,
                    isDay: response.current.isDay == 1
                )
                await MainActor.run {
                    guard !self.isDebugMode else { return }
                    self.condition = result.condition
                    self.isNight = result.isNight
                    self.lastUpdated = Date()
                    logger.info("Weather updated: \(result.condition.rawValue, privacy: .public), isNight=\(result.isNight)")
                }
            } catch {
                logger.error("Failed to fetch weather: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func fetchWeatherViaIPGeolocation() {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: URL(string: "http://ip-api.com/json/?fields=lat,lon")!)
                let geo = try JSONDecoder().decode(IPGeoResponse.self, from: data)
                fetchWeather(latitude: geo.lat, longitude: geo.lon)
            } catch {
                logger.error("IP geolocation failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.isRequestingLocation = false
            self.lastLocation = location
            self.fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isRequestingLocation = false
            logger.warning("Location error: \(error.localizedDescription, privacy: .public), falling back to IP geolocation")
            self.fetchWeatherViaIPGeolocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            if status == .authorizedAlways || status == .authorized {
                self.requestCurrentLocation()
            } else if status == .denied || status == .restricted {
                self.fetchWeatherViaIPGeolocation()
            }
        }
    }
}

// MARK: - API Response Models

private struct OpenMeteoResponse: Decodable {
    let current: CurrentWeather

    struct CurrentWeather: Decodable {
        let weatherCode: Int
        let isDay: Int

        enum CodingKeys: String, CodingKey {
            case weatherCode = "weather_code"
            case isDay = "is_day"
        }
    }
}

private struct IPGeoResponse: Decodable {
    let lat: Double
    let lon: Double
}

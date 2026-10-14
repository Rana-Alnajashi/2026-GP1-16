import Foundation
import Combine
import CoreLocation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var weatherTitle: LocalizedStringKey = "weather_loading_title"
        @Published var parentAdvice: LocalizedStringKey = "weather_locating_advice"
    @Published var temperatureText: String = "--°C"
    @Published var weatherIcon: String = "location.magnifyingglass"
    @Published var isLoading: Bool = false
    
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    var greetingKey: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "home_good_morning"
        case 12..<18: return "home_good_afternoon"
        default: return "home_good_evening"
        }
    }
    
    init() {
        // Listen for successful GPS coordinates
        locationManager.$location
            .compactMap { $0 }
            .first()
            .sink { [weak self] coordinate in
                Task { await self?.fetchWeatherForLocation(lat: coordinate.latitude, lon: coordinate.longitude) }
            }
            .store(in: &cancellables)
            
        // Listen if permission was outright denied in iOS settings
        locationManager.$permissionDenied
            .filter { $0 == true }
            .sink { [weak self] _ in
                Task { await self?.fetchWeatherForLocation(lat: 24.7136, lon: 46.6753) } // Fallback to Riyadh
            }
            .store(in: &cancellables)
    }
    
    func loadLiveWeather() {
        isLoading = true
        locationManager.requestLocation()
        
        // 3-Second Timeout Safety Net
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if self.weatherTitle == "Loading..." {
                print("GPS Timeout: Falling back to default coordinates")
                await self.fetchWeatherForLocation(lat: 24.7136, lon: 46.6753)
            }
        }
    }
    
    private func fetchWeatherForLocation(lat: Double, lon: Double) async {
            do {
                let res = try await WeatherService.shared.fetchAsthmaWeather(lat: lat, lon: lon)
                self.weatherTitle = res.title
                self.parentAdvice = res.advice
                self.temperatureText = "\(res.temperatureC)°C"
                self.weatherIcon = res.icon
            } catch {
                print("🚨 WeatherKit Error: \(error)")
                self.weatherTitle = "weather_unavailable_title"
                self.parentAdvice = "weather_error_advice"
                self.temperatureText = "--°C"
                self.weatherIcon = "exclamationmark.triangle"
            }
            self.isLoading = false
        }
}

//
//  WeatherService.swift
//  Nafas
//
//  Created by Rana Alngashy on 05/10/2026.
//
import Foundation
import CoreLocation
import WeatherKit
import Combine
import SwiftUI

// MARK: - Minimal Weather Model
struct SimpleWeatherCardData {
    let title: LocalizedStringKey
    let temperatureC: Int
    let icon: String
    let advice: LocalizedStringKey
}

class WeatherService {
    static let shared = WeatherService()
    
    func fetchAsthmaWeather(lat: Double, lon: Double) async throws -> SimpleWeatherCardData {
        let location = CLLocation(latitude: lat, longitude: lon)
        
        // Call Apple's native WeatherKit (disambiguated from your own class name)
        let weather = try await WeatherKit.WeatherService.shared.weather(for: location)
        
        let current = weather.currentWeather
        let tempC = Int(current.temperature.converted(to: .celsius).value)
        
        // Map native WeatherKit conditions to asthma advice
        // Map native WeatherKit conditions to asthma advice keys
                switch current.condition {
                case .windy, .breezy:
                    return SimpleWeatherCardData(title: "weather_windy_title", temperatureC: tempC, icon: "wind", advice: "weather_windy_advice")
                    
                case .clear, .mostlyClear:
                    if tempC > 38 {
                        return SimpleWeatherCardData(title: "weather_hot_title", temperatureC: tempC, icon: "thermometer.sun", advice: "weather_hot_advice")
                    } else {
                        return SimpleWeatherCardData(title: "weather_clear_title", temperatureC: tempC, icon: "sun.max", advice: "weather_clear_advice")
                    }
                    
                case .rain, .heavyRain, .drizzle, .sunFlurries, .snow:
                    return SimpleWeatherCardData(title: "weather_rainy_title", temperatureC: tempC, icon: "cloud.rain", advice: "weather_rainy_advice")
                    
                case .haze, .smoky, .blowingDust, .foggy:
                    return SimpleWeatherCardData(title: "weather_poor_air_title", temperatureC: tempC, icon: "smoke", advice: "weather_poor_air_advice")
                    
                default:
                    return SimpleWeatherCardData(title: "weather_cloudy_title", temperatureC: tempC, icon: "cloud", advice: "weather_cloudy_advice")
                }
    }
}

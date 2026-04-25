import Foundation

struct WeatherInfo {
    var condition: LocalizedStringResource
    var advice: LocalizedStringResource
    var windKmh: Int
    var aqi: Int
    var aqiLabel: String
    var humidityPercent: Int
    var sfSymbol: String
}

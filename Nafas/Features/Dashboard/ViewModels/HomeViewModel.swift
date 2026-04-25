import Foundation
import Combine
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var weather = WeatherInfo(
        condition:LocalizedStringResource("Weather_Today"),
        advice: LocalizedStringResource("Weather_Advice"),
        windKmh: 28, aqi: 42, aqiLabel: "Good",
        humidityPercent: 65, sfSymbol: "wind"
    )
    
    var greetingKey: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "home_good_morning"
        case 12..<18: return "home_good_afternoon"
        default: return "home_good_evening"
        }
    }
}

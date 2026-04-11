//
//  Models.swift
//  Nafas
//  Single source of truth for all data models
//

import Foundation
import SwiftUI

// MARK: - Child Model
struct ChildModel: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var birthDate: Date
    var height: Int?
    var weight: Int?
    var gender: Gender
    var isConnected: Bool
    var deviceID: String?
    var condition: String?
    var avatarColor: String
    var guardianRelationship: GuardianRelationship
    var avatarImageData: Data?
    var emergencyPhoneNumbers: [String]

    // MARK: - Gender
    enum Gender: String, Codable, CaseIterable {
        // Raw values are Codable storage keys — do NOT change them.
        case male   = "Male"
        case female = "Female"

        /// Locale-aware display label — use this in all UI, never rawValue.
        var localizedLabel: String {
            switch self {
            case .male:   return NSLocalizedString("gender_male",   comment: "Display label for male gender")
            case .female: return NSLocalizedString("gender_female", comment: "Display label for female gender")
            }
        }
    }

    // MARK: - Guardian Relationship
    enum GuardianRelationship: String, Codable, CaseIterable {
        // Raw values are Codable storage keys — do NOT change them.
        case mother      = "Mother"
        case father      = "Father"
        case sibling     = "Sibling"
        case grandparent = "Grandparent"
        case other       = "Other"

        /// Locale-aware display label — use this in all UI, never rawValue.
        var localizedLabel: String {
            switch self {
            case .mother:      return NSLocalizedString("guardian_mother",      comment: "Guardian relationship: mother")
            case .father:      return NSLocalizedString("guardian_father",      comment: "Guardian relationship: father")
            case .sibling:     return NSLocalizedString("guardian_sibling",     comment: "Guardian relationship: sibling")
            case .grandparent: return NSLocalizedString("guardian_grandparent", comment: "Guardian relationship: grandparent")
            case .other:       return NSLocalizedString("guardian_other",       comment: "Guardian relationship: other")
            }
        }
    }

    var age: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 0
    }

    var storeKey: String {
        id.uuidString
    }

    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ChildModel, rhs: ChildModel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Vital Models
struct VitalSnapshot {
    var bp: String
    var spO2: Int
    var iaq: Int
    var peakFlow: Int
    var bpStatus: VitalStatus
    var spO2Status: VitalStatus
    var iaqStatus: IAQStatus
    var peakZone: PeakZone
    var lastSync: String
    var deviceID: String?

    enum VitalStatus { case normal, low, high }
    enum IAQStatus   { case good, moderate, poor }
    enum PeakZone    { case green, yellow, red }
}

// MARK: - History Entry (Only for attacks)
struct HistoryEntry: Identifiable {
    let id = UUID()
    var date: String
    var time: String
    var bp: String?
    var spO2: Int?
    var iaq: Int?
    var peakFlow: Int?
    var alertLevel: AlertLevel = .danger

    enum AlertLevel { case danger }
}

// MARK: - Peak Flow Entry
struct PeakFlowEntry: Identifiable {
    let id = UUID()
    var value: Int
    var date: String
    var time: String
    var note: String
}

// MARK: - Weather Model
struct WeatherInfo {
    var condition: LocalizedStringResource
    var advice: LocalizedStringResource
    var windKmh: Int
    var aqi: Int
    var aqiLabel: String
    var humidityPercent: Int
    var sfSymbol: String
}

// MARK: - Bluetooth Device Model
struct BluetoothDevice: Identifiable {
    let id = UUID()
    let name: String
    let rssi: Int
    let deviceID: String
}

// MARK: - Menu Sheet
enum MenuSheet: Identifiable {
    case editProfile, support, faq
    var id: Int { hashValue }
}

// MARK: - Connection Status
enum ConnectionStatus {
    case idle
    case scanning
    case connecting
    case connected
    case failed(String)
}

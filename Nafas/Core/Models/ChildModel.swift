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
    var avatarImageData: Data?  // This is Codable by default
    var emergencyContacts: [EmergencyContact]
    
    
    enum Gender: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
    }
    
    enum GuardianRelationship: String, Codable, CaseIterable {
        case mother = "Mother"
        case father = "Father"
        case sibling = "Sibling"
        case grandparent = "Grandparent"
        case other = "Other"
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
struct PeakFlowEntry: Identifiable,Codable {
    let id = UUID()
    var value: Int
    var date: String
    var time: String
    var note: String
}

// MARK: - Bluetooth Device Model
struct BluetoothDevice: Identifiable {
    let id = UUID()
    let name: String
    let rssi: Int
    let deviceID: String
    var batteryLevel: Int = 0
    var shortID: String {
        let hex = deviceID.replacingOccurrences(of: "-", with: "").prefix(6).uppercased()
        guard hex.count >= 4 else { return String(hex) }
        return "NF-\(hex.suffix(4))"
    }

    var signalStrength: Int {
        let clamped = max(-90, min(-30, rssi))
        return Int(Double(clamped + 90) / 60.0 * 100)
    }

    var signalBars: Int {
        switch signalStrength {
        case 0..<30:  return 1
        case 30..<60: return 2
        case 60..<80: return 3
        default:      return 4
        }
    }
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
// MARK: - EmergencyContact
struct EmergencyContact: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var phoneNumber: String
}

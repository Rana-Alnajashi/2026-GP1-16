import Foundation
import Combine
import UserNotifications
@MainActor
final class ChildDetailViewModel: ObservableObject {
    @Published var child: ChildModel
    @Published var peakFlows: [PeakFlowEntry] = []
    @Published var dismissedAlerts: Set<String> = []
    
    private let store = NafasStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(child: ChildModel) {
        self.child = child
        setupBindings()
    }
    // ChildDetailViewModel.swift: Subscribing to the central store using Combine
    @Published var vitals: VitalSnapshot?
    
    private func setupBindings() {
        store.$latestVitals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] vitalsDict in
                guard let self = self else { return }
                // Reactive update triggers UI redraw
                self.vitals = vitalsDict["TEST"] ?? vitalsDict[self.child.id.uuidString]
            }
            .store(in: &cancellables)
        
        store.$peakFlowLogs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logsDict in
                guard let self = self else { return }
                self.peakFlows = logsDict[self.child.id.uuidString] ?? []
            }
            .store(in: &cancellables)
        
        store.$children
            .receive(on: DispatchQueue.main)
            .sink { [weak self] childrenList in
                guard let self = self else { return }
                if let updatedChild = childrenList.first(where: { $0.id == self.child.id }) {
                    self.child = updatedChild
                }
            }
            .store(in: &cancellables)
    }
    
    var latestPeak: PeakFlowEntry? { peakFlows.first }
    
    var spO2AlertId: String { "spo2_\(child.id)" }
    var peakAlertId: String { "peak_\(child.id)" }
    
    var hasActiveAlert: Bool {
        let spO2Alert = vitals?.spO2Status == .low && !dismissedAlerts.contains(spO2AlertId)
        let peakAlert = vitals?.peakZone == .red  && !dismissedAlerts.contains(peakAlertId)
        return spO2Alert || peakAlert
    }
    
    func connectMQTT() {
        NafasMQTTManager.shared.connect(for: child.id.uuidString, deviceID: child.deviceID ?? "Test_Device")
    }
    
    func disconnectMQTT() {
        NafasMQTTManager.shared.disconnect()
    }
    
    func dismissAlert(_ alertId: String) {
        dismissedAlerts.insert(alertId)
    }
    
    func deleteChild() {
        store.deleteChild(child.id.uuidString)
    }
}
// ---------------------------simulation

enum SimulationScenario {
    case highRisk
    case moderateRisk
    case lowRisk
    case dustyEnvironment
}


extension ChildDetailViewModel {
    
    func runSimulation(scenario: SimulationScenario) {
        let childId = child.id.uuidString
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("EEE, d MMM yyyy")
        let todayDate = df.string(from: Date())
        
        df.dateFormat = "HH:mm"
        let currentTime = df.string(from: Date())
        
        var mockVitals: VitalSnapshot
        var mqttKeyword = ""
        var shouldLogHistory = false
        var mockHistoryEntry: HistoryEntry?
        var shouldPush = false
        var alertTitle = ""
        var alertBody = ""
        
        switch scenario {
        case .highRisk:
            // High Risk: Critical vitals + Poor IAQ
            mockVitals = VitalSnapshot(
                bp: "140", spO2: 85, iaq: 180, peakFlow: 400,
                bpStatus: .high, spO2Status: .low, iaqStatus: .poor, peakZone: .green,
                lastSync: "Just now", deviceID: child.deviceID
            )
            mqttKeyword = "High"
            shouldLogHistory = true
            shouldPush = true
            alertTitle = "⚠️ High Risk Alert"
            alertBody = "\(child.name)'s SpO2 dropped to 85%. Immediate attention required!"
            
            mockHistoryEntry = HistoryEntry(
                date: todayDate, time: currentTime, bp: "140", spO2: 85, iaq: 180, alertLevel: .danger
            )
            
        case .moderateRisk:
            // Moderate Risk: Now triggers a notification as requested
            mockVitals = VitalSnapshot(
                bp: "115", spO2: 92, iaq: 50, peakFlow: 400,
                bpStatus: .normal, spO2Status: .normal, iaqStatus: .good, peakZone: .green,
                lastSync: "Just now", deviceID: child.deviceID
            )
            mqttKeyword = "moderate"
            shouldPush = true
            alertTitle = "Notice: Moderate Risk"
            alertBody = "\(child.name) is showing early signs of respiratory distress."
            
        case .lowRisk:
            mockVitals = VitalSnapshot(
                bp: "95", spO2: 96, iaq: 50, peakFlow: 400,
                bpStatus: .normal, spO2Status: .normal, iaqStatus: .good, peakZone: .green,
                lastSync: "Just now", deviceID: child.deviceID
            )
            mqttKeyword = "low"
            
        case .dustyEnvironment:
            // Dusty/Smoke: High IAQ, normal physical vitals
            mockVitals = VitalSnapshot(
                bp: "85", spO2: 98, iaq: 250, peakFlow: 260,
                bpStatus: .normal, spO2Status: .normal, iaqStatus: .poor, peakZone: .green,
                lastSync: "Just now", deviceID: child.deviceID
            )
            mqttKeyword = "iaq"
        }
        
        // 1. Update the Store
        NafasStore.shared.latestVitals[childId] = mockVitals
        
        // 2. Trigger Push if applicable
        if shouldPush {
            // This calls the helper function below
            triggerLocalPushNotification(title: alertTitle, body: alertBody)
        }
        
        // 3. Publish to MQTT
        if !mqttKeyword.isEmpty {
            let jsonPayload = """
            {
                "command": "\(mqttKeyword)",
                "send_push_notification": \(shouldPush ? "true" : "false")
            }
            """
            NafasMQTTManager.shared.publish(topic: "nafas/wristband_1/command", message: jsonPayload)
        }
        
        // 4. Log History for high risk
        if shouldLogHistory, let entry = mockHistoryEntry {
            var currentHistory = NafasStore.shared.historyEntries[childId] ?? []
            currentHistory.insert(entry, at: 0)
            NafasStore.shared.historyEntries[childId] = currentHistory
        }
    }
    
    // MARK: - 🚀 Push Notification Helper
    // This is the missing function that fixes your error!
    private func triggerLocalPushNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                center.add(request) { error in
                    if let err = error {
                        print("❌ [Push] Failed to trigger notification: \(err.localizedDescription)")
                    } else {
                        print("✅ [Push] Notification successfully triggered!")
                    }
                }
            }
        }
    }
}
// ---------------------------simulation

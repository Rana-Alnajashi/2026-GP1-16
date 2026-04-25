import Foundation
import Combine

@MainActor
final class ChildDetailViewModel: ObservableObject {
    @Published var child: ChildModel
    @Published var vitals: VitalSnapshot?
    @Published var peakFlows: [PeakFlowEntry] = []
    @Published var dismissedAlerts: Set<String> = []
    
    private let store = NafasStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(child: ChildModel) {
        self.child = child
        setupBindings()
    }
    
    private func setupBindings() {
        store.$latestVitals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] vitalsDict in
                guard let self = self else { return }
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

import Foundation
import CocoaMQTT
import Combine
import Security

class NafasMQTTManager: ObservableObject {
    static let shared = NafasMQTTManager()
    
    private var mqttClient: CocoaMQTT?
    private var currentChildID: String?
    
    func connect(for childID: String, deviceID: String) {
        self.currentChildID = childID
        let clientID = "NafasBand-iOS-\(UUID().uuidString.prefix(4))"
        
        mqttClient = CocoaMQTT(clientID: clientID, host: "a29m1l790wtzg-ats.iot.eu-central-1.amazonaws.com", port: 8883)
        mqttClient?.enableSSL = true
        
        // ---------------------------------------------------------
        // AWS SECURITY: LOAD THE .P12 CERTIFICATE
        // ---------------------------------------------------------
        if let path = Bundle.main.path(forResource: "ios_cert", ofType: "p12") {
            if let certData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                
                // ⚠️ PUT YOUR FRIEND's PASSWORD HERE ⚠️
                let options: [String: Any] = [kSecImportExportPassphrase as String: "nafas"]
                var rawItems: CFArray?
                let status = SecPKCS12Import(certData as CFData, options as CFDictionary, &rawItems)
                
                if status == errSecSuccess, let items = rawItems as? [[String: Any]], let firstItem = items.first {
                    if let identityObj = firstItem[kSecImportItemIdentity as String] {
                        // We use 'as!' instead of 'as?' to satisfy Xcode's strict rules
                        let identity = identityObj as! SecIdentity
                        mqttClient?.sslSettings = [
                            kCFStreamSSLCertificates as String: [identity] as NSArray
                        ]
                        print("[MQTT Security] VIP Pass (.p12) loaded successfully!")
                    }
                } else {
                    print("[MQTT Security] ❌ ERROR: Wrong password or corrupted .p12 file.")
                }
            }
        } else {
            print("[MQTT Security] ❌ ERROR: .p12 file not found in Xcode! Check Target Membership.")
        }
        // ---------------------------------------------------------

        mqttClient?.didConnectAck = { mqtt, ack in
            if ack == .accept {
                print("[MQTT] ✅ Connected to AWS IoT Core!")
                mqtt.subscribe("nafas/wristband_1/vitals", qos: .qos1)
            } else {
                print("[MQTT] ❌ Connection Refused by AWS. Ack: \(ack)")
            }
        }
        
        mqttClient?.didReceiveMessage = { [weak self] mqtt, message, id in
            print("[MQTT] 📥 RECEIVED DATA: \(message.string ?? "")")
            self?.handleIncomingData(message.string, for: childID, deviceID: deviceID)
        }
        
        mqttClient?.connect()
    }
    
    func disconnect() {
        mqttClient?.disconnect()
        mqttClient = nil
        print("[MQTT] Disconnected")
    }
    
    private func handleIncomingData(_ payload: String?, for childID: String, deviceID: String) {
        guard let payload = payload, let data = payload.data(using: .utf8) else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                DispatchQueue.main.async {
                    let bpm = json["bpm"] as? Int ?? 0
                    let spo2 = json["spo2"] as? Int ?? 0
                    let iaq = json["iaq"] as? Double ?? 0.0
                    
                    let bpStatus: VitalSnapshot.VitalStatus = (bpm < 60 || bpm > 120) ? .high : .normal
                    let spo2Status: VitalSnapshot.VitalStatus = spo2 < 95 ? .low : .normal
                    let iaqStatus: VitalSnapshot.IAQStatus = iaq > 150 ? .poor : (iaq > 100 ? .moderate : .good)
                    
                    let existingVitals = NafasStore.shared.latestVitals[childID]
                    
                    let newSnapshot = VitalSnapshot(
                        bp: "\(bpm)",
                        spO2: spo2,
                        iaq: Int(iaq),
                        peakFlow: existingVitals?.peakFlow ?? 0,
                        bpStatus: bpStatus,
                        spO2Status: spo2Status,
                        iaqStatus: iaqStatus,
                        peakZone: existingVitals?.peakZone ?? .green,
                        lastSync: self.getCurrentTime(),
                        deviceID: deviceID
                    )
                    
                    // Only update the specific child that this wristband belongs to
                    NafasStore.shared.latestVitals[childID] = newSnapshot
                }
            }
        } catch {
            print("[MQTT] JSON Parsing error: \(error)")
        }
    }
    
    private func getCurrentTime() -> String {
        let df = DateFormatter()
        df.dateFormat = "hh:mm a"
        return df.string(from: Date())
    }
}

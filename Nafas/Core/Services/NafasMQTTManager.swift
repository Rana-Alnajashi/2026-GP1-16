import Foundation
import CocoaMQTT
import Combine
import Security

// 1. Define the struct to match your AWS Lambda JSON payload exactly
struct NafasAlertPayload: Codable {
    let userId: String
    let status: String
    let prediction: Int      // Changed to Int
    let metrics: Metrics
    
    struct Metrics: Codable {
        let heartRate: Double // Changed to Double
        let spo2: Double      // Changed to Double
        let activityValue: Double // Changed to Double
        let latestPefr: Double    // Changed to Double
        
        enum CodingKeys: String, CodingKey {
            case heartRate = "heart_rate"
            case spo2
            case activityValue = "activity_value"
            case latestPefr = "latest_pefr"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
        case prediction
        case metrics
    }
}

class NafasMQTTManager: ObservableObject {
    static let shared = NafasMQTTManager()
    
    private var mqttClient: CocoaMQTT?
    private var currentChildID: String?
    
    // 2. Add a Published property so the SwiftUI View updates instantly
    @Published var latestMLAlert: NafasAlertPayload?
    
    func connect(for childID: String, deviceID: String) {
        self.currentChildID = childID
        let clientID = "NafasBand-iOS-\(UUID().uuidString.prefix(4))"
        
        mqttClient = CocoaMQTT(clientID: clientID, host: "a3pvlg4bqgjvl6-ats.iot.us-east-1.amazonaws.com", port: 8883)
        mqttClient?.enableSSL = true
        
        // ---------------------------------------------------------
        // AWS SECURITY: LOAD THE .P12 CERTIFICATE
        // ---------------------------------------------------------
        if let path = Bundle.main.path(forResource: "cer_nafas", ofType: "p12") {
            if let certData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                
                // ⚠️ PUT YOUR FRIEND's PASSWORD HERE ⚠️
                let options: [String: Any] = [kSecImportExportPassphrase as String: "123"]
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
                // 3. Subscribe to the new AWS Lambda Alert Topic
                mqtt.subscribe("nafas/alerts", qos: .qos1)
            } else {
                print("[MQTT] ❌ Connection Refused by AWS. Ack: \(ack)")
            }
        }
        
        mqttClient?.didReceiveMessage = { [weak self] mqtt, message, id in
            // 4. Route the incoming message based on the topic
            if message.topic == "nafas/alerts" {
                print("[MQTT] 🚨 ML ALERT RECEIVED: \(message.string ?? "")")
                self?.handleIncomingAlert(message.string)
            } else {
                print("[MQTT] 📥 RECEIVED DATA: \(message.string ?? "")")
                self?.handleIncomingData(message.string, for: childID, deviceID: deviceID)
            }
        }
        
        mqttClient?.connect()
    }
    
    func disconnect() {
        mqttClient?.disconnect()
        mqttClient = nil
        print("[MQTT] Disconnected")
    }
    
    // MARK: - Publishing to AWS Broker simulation ###
    func publish(topic: String, message: String) {
        // 1. Ensure the client is actually connected before trying to send
        guard let client = mqttClient, client.connState == .connected else {
            print("[MQTT] ❌ Cannot publish. Client is not connected to AWS.")
            return
        }
        
        // 2. Publish the message to the specific topic
        client.publish(topic, withString: message, qos: .qos1)
        
        // 3. Print success so you can see it working in Xcode!
        print("[MQTT] 🚀 Published to topic '\(topic)': \(message)")
    }
    // simulation ###
    
    // 5. Decode the XGBoost JSON and publish it to the UI
    private func handleIncomingAlert(_ payload: String?) {
        guard let payload = payload, let data = payload.data(using: .utf8) else { return }
        do {
            let decodedAlert = try JSONDecoder().decode(NafasAlertPayload.self, from: data)
            DispatchQueue.main.async {
                self.latestMLAlert = decodedAlert
            }
        } catch {
            print("[MQTT] ❌ Failed to decode ML Alert: \(error)")
        }
    }
    
    // NafasMQTTManager.swift: Handling incoming telemetry and updating the store
    private func handleIncomingData(_ payload: String?, for childID: String, deviceID: String) {
        guard let payload = payload, let data = payload.data(using: .utf8) else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                DispatchQueue.main.async {
                    // ... JSON parsing ...
                    let bpm = json["bpm"] as? Int ?? 0
                    let spo2 = json["spo2"] as? Int ?? 0
                    let iaq = json["iaq"] as? Double ?? 0.0
                    // Evaluate thresholds
                    let bpStatus: VitalSnapshot.VitalStatus = bpm < 70 ? .low : (bpm > 110 ? .high : .normal)
                    let spo2Status: VitalSnapshot.VitalStatus = spo2 < 92 ? .low : .normal
                    let iaqStatus: VitalSnapshot.IAQStatus = iaq > 101 ? .poor : (iaq <= 100 ? .moderate : .good) // check
                    
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
                    
                    // Push to central NafasStore
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

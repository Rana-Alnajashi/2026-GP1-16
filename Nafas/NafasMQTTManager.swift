//
//  NafasMQTTManager.swift
//  Nafas
//
//  Created by Raghad Alhulwah on 18/04/2026.
//
import Foundation
import CocoaMQTT
import Combine

class NafasMQTTManager: ObservableObject {
    static let shared = NafasMQTTManager() // Singleton so the whole app can use it
    
    private var mqttClient: CocoaMQTT?
    private var currentChildID: String?
    
    func connect(for childID: String, deviceID: String) {
        self.currentChildID = childID
        
        let clientID = "NafasBand-iOS-\(UUID().uuidString.prefix(4))"
        
        // ⚠️ REPLACE THIS with your AWS Endpoint from config.h
        mqttClient = CocoaMQTT(clientID: clientID, host: "a29m1l790wtzg-ats.iot.eu-central-1.amazonaws.com", port: 8883)
        
        mqttClient?.enableSSL = true
        mqttClient?.allowUntrustCACertificate = true
        
        mqttClient?.didConnectAck = { mqtt, ack in
            if ack == .accept {
                print("[MQTT] Connected to AWS IoT Core!")
                // Subscribe to the exact topic the ESP32 is publishing to
                mqtt.subscribe("nafas/wristband_1/vitals", qos: .qos1)
            }
        }
        
        mqttClient?.didReceiveMessage = { [weak self] mqtt, message, id in
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
                    // Extract the data from the ESP32 JSON
                    let bpm = json["bpm"] as? Int ?? 0
                    let spo2 = json["spo2"] as? Int ?? 0
                    let iaq = json["iaq"] as? Double ?? 0.0
                    
                    // Calculate Statuses for the UI (Red/Yellow/Green circles)
                    let bpStatus: VitalSnapshot.VitalStatus = (bpm < 60 || bpm > 120) ? .high : .normal
                    let spo2Status: VitalSnapshot.VitalStatus = spo2 < 95 ? .low : .normal
                    let iaqStatus: VitalSnapshot.IAQStatus = iaq > 150 ? .poor : (iaq > 100 ? .moderate : .good)
                    
                    // Grab the existing peak flow so we don't overwrite it
                    let existingVitals = NafasStore.shared.latestVitals[childID]
                    
                    // Create the new snapshot
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
                    
                    // 🪄 THE MAGIC: Inject directly into the store.
                    // Your ChildDetailView will automatically redraw!
                    // THE HACK: Update EVERY child in the database at the same time
                                        for child in NafasStore.shared.children {
                                            // HACK: Save incoming data into the universal "TEST" mailbox
                                                NafasStore.shared.latestVitals["TEST"] = newSnapshot
                                        }
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

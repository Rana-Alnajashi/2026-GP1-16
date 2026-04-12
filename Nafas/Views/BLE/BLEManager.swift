//
//  BLEManager.swift
//  Nafas
//  CoreBluetooth manager for ESP32 Nafas Wristband WiFi provisioning.
//

import Foundation
import CoreBluetooth
import Combine

// MARK: - BLE Configuration
struct BLEConfig {
    static let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    static let ssidCharUUID     = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    static let passwordCharUUID = CBUUID(string: "1c95d5e3-d8f7-413a-bf3d-7a2e5d7be87e")
    static let statusCharUUID   = CBUUID(string: "d1a7e84c-5ef2-4d9a-b9c3-f8a6b3c21e07")
    static let batteryServiceUUID = CBUUID(string: "180F")
    static let batteryLevelUUID   = CBUUID(string: "2A19")
    static let deviceName = "NAFAS WRISTBAND"
    static let scanTimeout: TimeInterval = 15
}

struct WiFiCredentials: Equatable {
    let ssid: String
    let password: String
}

enum BLEConnectionState: Equatable {
    case idle
    case scanning
    case devicesFound
    case connecting
    case connected
    case sendingWiFi
    case success
    case failed(String)

    var isActive: Bool {
        if case .idle = self { return false }
        return true
    }
}

final class BLEManager: NSObject, ObservableObject {

    @Published var state: BLEConnectionState = .idle
    @Published var discoveredDevices: [BluetoothDevice] = []
    @Published var connectionProgress: Double = 0.0

    private var central: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var targetPeripheral: CBPeripheral?

    private var ssidChar: CBCharacteristic?
    private var passwordChar: CBCharacteristic?
    private var statusChar: CBCharacteristic?

    private var scanTimer: Timer?
    private var connectionTimer: Timer?
    private var pendingCredentials: WiFiCredentials?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func startScanning() {
        discoveredDevices.removeAll()
        connectionProgress = 0
        state = .scanning

        // Check if radio is ready. If not, the delegate (didUpdateState)
        // will trigger the actual scan once it reaches .poweredOn.
        if central.state == .poweredOn {
            performActualScan()
        } else if central.state != .unknown && central.state != .resetting {
            // If it's explicitly off or unauthorized, fail immediately.
            state = .failed(bleStateMessage(central.state))
        }
    }
    
    private func performActualScan() {
        central.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        scheduleScanTimeout()
    }

    func stopScanning() {
        central.stopScan()
        scanTimer?.invalidate()
        guard case .scanning = state else { return }
        state = discoveredDevices.isEmpty ? .failed("ble_no_devices_found") : .devicesFound
    }

    func connectToDevice(_ device: BluetoothDevice) {
        guard let uuid = UUID(uuidString: device.deviceID),
              let peripheral = central.retrievePeripherals(withIdentifiers: [uuid]).first else {
            state = .failed("ble_device_not_found")
            return
        }
        state = .connecting
        targetPeripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
        
        // Start a 10-second connection timeout timer
        connectionTimer?.invalidate()
        connectionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // If we are still "connecting" after 10s, kill the attempt.
            if case .connecting = self.state {
                self.central.cancelPeripheralConnection(peripheral)
                self.state = .failed("ble_connection_timeout")
            }
        }
    }

    func sendWiFiCredentials(_ credentials: WiFiCredentials) {
        guard let peripheral = connectedPeripheral,
              let ssid = ssidChar,
              let pwd = passwordChar else {
            state = .failed("ble_not_connected")
            return
        }
        guard let ssidData = credentials.ssid.data(using: .utf8),
              let pwdData  = credentials.password.data(using: .utf8) else {
            state = .failed("ble_invalid_credentials")
            return
        }

        state = .sendingWiFi
        connectionProgress = 0.4
        pendingCredentials = credentials

        peripheral.writeValue(ssidData, for: ssid, type: .withResponse)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            peripheral.writeValue(pwdData, for: pwd, type: .withResponse)
            self.connectionProgress = 0.6
        }
    }

    func disconnect() {
        if let p = connectedPeripheral { central.cancelPeripheralConnection(p) }
        central.stopScan()
        scanTimer?.invalidate()
        connectionTimer?.invalidate()
        state = .idle
        connectedPeripheral = nil
        targetPeripheral = nil
        pendingCredentials = nil
        resetCharacteristics()
    }

    private func scheduleScanTimeout() {
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(
            withTimeInterval: BLEConfig.scanTimeout, repeats: false
        ) { [weak self] _ in
            self?.stopScanning()
        }
    }

    private func resetCharacteristics() {
        ssidChar = nil
        passwordChar = nil
        statusChar = nil
    }

    private func bleStateMessage(_ s: CBManagerState) -> String {
        switch s {
        case .poweredOff:  return "ble_powered_off"
        case .unauthorized: return "ble_unauthorized"
        case .unsupported:  return "ble_unsupported"
        default:           return "ble_unavailable"
        }
    }

    private func parseBatteryLevel(from advertisementData: [String: Any]) -> Int {
        if let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
           mfgData.count >= 2 {
            if mfgData.count >= 3 {
                let level = Int(mfgData[2])
                if level > 0 && level <= 100 { return level }
            }
        }
        return 0
    }
}

extension BLEManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // If the UI is already in 'scanning' state, start the hardware scan now.
            if state == .scanning {
                performActualScan()
            }
        case .poweredOff:   state = .failed("ble_powered_off")
        case .unauthorized: state = .failed("ble_unauthorized")
        case .unsupported:  state = .failed("ble_unsupported")
        case .unknown, .resetting: break
        default:            state = .failed("ble_unavailable")
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? ""
        guard name.uppercased().contains("NAFAS") ||
              name.uppercased().contains("WRISTBAND") else { return }

        let uuid = peripheral.identifier.uuidString
        guard !discoveredDevices.contains(where: { $0.deviceID == uuid }) else { return }

        let battery = parseBatteryLevel(from: advertisementData)
        let device = BluetoothDevice(
            name: name.isEmpty ? "NAFAS WRISTBAND" : name,
            rssi: RSSI.intValue,
            deviceID: uuid,
            batteryLevel: battery
        )
        discoveredDevices.append(device)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Do NOT invalidate the connectionTimer here.
        // We must wait for Phase 2 (Service Discovery) to finish successfully.
        connectedPeripheral = peripheral
        connectionProgress = 0.3
        
        peripheral.discoverServices([BLEConfig.serviceUUID, BLEConfig.batteryServiceUUID])
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        connectionTimer?.invalidate() // Cancel timeout timer upon failure
        state = .failed("ble_connection_failed")
        resetCharacteristics()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        connectionTimer?.invalidate() // Cancel timeout timer upon disconnect
        
        guard connectedPeripheral?.identifier == peripheral.identifier else { return }
        connectedPeripheral = nil
        resetCharacteristics()

        if case .sendingWiFi = state {
            state = .failed("ble_disconnected")
        } else if case .connecting = state {
            state = .failed("ble_connection_failed")
        } else if case .connected = state {
            // Catch for silent drops while on the WiFi entry screen.
            state = .failed("ble_disconnected")
        }
    }
}

extension BLEManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            state = .failed("ble_service_discovery_failed")
            return
        }

        for service in services {
            if service.uuid == BLEConfig.serviceUUID {
                peripheral.discoverCharacteristics(
                    [BLEConfig.ssidCharUUID, BLEConfig.passwordCharUUID, BLEConfig.statusCharUUID],
                    for: service
                )
            } else if service.uuid == BLEConfig.batteryServiceUUID {
                peripheral.discoverCharacteristics([BLEConfig.batteryLevelUUID], for: service)
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil, let chars = service.characteristics else { return }

        for char in chars {
            switch char.uuid {
            case BLEConfig.ssidCharUUID:
                ssidChar = char
            case BLEConfig.passwordCharUUID:
                passwordChar = char
            case BLEConfig.statusCharUUID:
                statusChar = char
                if char.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: char)
                }
            case BLEConfig.batteryLevelUUID:
                peripheral.readValue(for: char)
            default:
                break
            }
        }

        // Only trigger .connected state when Phase 2 is completely successful
        if ssidChar != nil && passwordChar != nil {
            connectionTimer?.invalidate() // Phase 2 complete: Safe to stop the timer!
            
            connectionProgress = 0.7
            if state != .connected {
                state = .connected
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil, let data = characteristic.value else { return }

        if characteristic.uuid == BLEConfig.statusCharUUID,
           let text = String(data: data, encoding: .utf8) {
            handleStatusNotification(text)
        } else if characteristic.uuid == BLEConfig.batteryLevelUUID,
                  data.count >= 1 {
            let level = Int(data[0])
            if let idx = discoveredDevices.firstIndex(where: {
                $0.deviceID == peripheral.identifier.uuidString
            }) {
                discoveredDevices[idx].batteryLevel = level
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            state = .failed(error.localizedDescription)
            return
        }
        if characteristic.uuid == BLEConfig.passwordCharUUID {
            connectionProgress = 0.8
        }
    }

    private func handleStatusNotification(_ text: String) {
        let upper = text.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if upper.contains("CONNECTED") || upper.contains("SUCCESS") {
            connectionProgress = 1.0
            state = .success
        } else if upper.contains("CONNECTING") {
            connectionProgress = 0.85
        } else if upper.contains("FAILED") || upper.contains("ERROR") {
            state = .failed("ble_device_connection_failed")
        }
    }
}

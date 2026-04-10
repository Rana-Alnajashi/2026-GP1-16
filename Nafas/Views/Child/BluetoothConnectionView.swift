//
//  BluetoothConnectionView.swift
//  Nafas
//

import SwiftUI
import CoreBluetooth
import Combine

// MARK: - Bluetooth Manager
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var discoveredDevices: [BluetoothDevice] = []
    @Published var isScanning = false
    @Published var connectionState: ConnectionState = .disconnected
    
    enum ConnectionState {
        case disconnected
        case scanning
        case connecting
        case connected
        case failed(String)
    }
    
    private var centralManager: CBCentralManager!
    private var onDeviceFound: ((BluetoothDevice) -> Void)?
    private var onConnectionComplete: ((Bool) -> Void)?
    private var connectingPeripheral: CBPeripheral?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func startScanning(onDeviceFound: @escaping (BluetoothDevice) -> Void) {
        self.onDeviceFound = onDeviceFound
        discoveredDevices.removeAll()
        isScanning = true
        connectionState = .scanning
        
        guard centralManager.state == .poweredOn else {
            let message = getBluetoothStateMessage(centralManager.state)
            connectionState = .failed(message)
            isScanning = false
            return
        }
        
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        
        // Auto-stop scanning after 15 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            if self?.isScanning == true {
                self?.stopScanning()
                if self?.discoveredDevices.isEmpty == true {
                    self?.connectionState = .failed("No devices found. Make sure the wristband is nearby and charged.")
                }
            }
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        if case .scanning = connectionState {
            connectionState = .disconnected
        }
    }
    
    func connectToDevice(_ device: BluetoothDevice, completion: @escaping (Bool) -> Void) {
        self.onConnectionComplete = completion
        connectionState = .connecting
        
        guard let uuid = UUID(uuidString: device.deviceID) else {
            connectionState = .failed("Invalid device identifier")
            completion(false)
            return
        }
        
        let peripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
        if let peripheral = peripherals.first {
            connectingPeripheral = peripheral
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
        } else {
            connectionState = .failed("Device not found. Please scan again.")
            completion(false)
        }
    }
    
    func cancelConnection() {
        if let peripheral = connectingPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        stopScanning()
        connectionState = .disconnected
        connectingPeripheral = nil
    }
    
    private func getBluetoothStateMessage(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOff:
            return "Bluetooth is turned off. Please enable Bluetooth in Settings."
        case .unauthorized:
            return "Nafas doesn't have permission to use Bluetooth. Please grant permission in Settings."
        case .unsupported:
            return "This device does not support Bluetooth Low Energy."
        default:
            return "Bluetooth is not available. Please check your device settings."
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch central.state {
            case .poweredOn:
                print("Bluetooth is powered on")
            case .poweredOff:
                self.isScanning = false
                self.connectionState = .failed("Bluetooth is turned off")
            default:
                break
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "Unknown"
        let isNafasDevice = name.lowercased().contains("nafas") ||
                            name.lowercased().contains("asthma") ||
                            name.lowercased().contains("health")
        
        guard isNafasDevice else { return }
        
        let device = BluetoothDevice(
            name: name,
            rssi: RSSI.intValue,
            deviceID: peripheral.identifier.uuidString
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.discoveredDevices.contains(where: { $0.deviceID == device.deviceID }) {
                self.discoveredDevices.append(device)
                self.onDeviceFound?(device)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .connected
            self?.stopScanning()
            self?.onConnectionComplete?(true)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            let message = error?.localizedDescription ?? "Failed to connect to device"
            self?.connectionState = .failed(message)
            self?.onConnectionComplete?(false)
            self?.connectingPeripheral = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .disconnected
            self?.connectingPeripheral = nil
        }
    }
}

// MARK: - Bluetooth Connection View
struct BluetoothConnectionView: View {
    let child: ChildModel
    let isNewChild: Bool
    @Environment(\.dismiss) var dismiss
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var autoScanStarted = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // Header with child info
                VStack(spacing: 12) {
                    ZStack {
                        if let avatarData = child.avatarImageData,
                           let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: child.avatarColor))
                                .frame(width: 80, height: 80)
                            Text(String(child.name.prefix(1)))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    Text(child.name)
                        .font(.title2.bold())
                    Text(LocalizedStringKey("Connect your Nafas wristband"))
                        .font(.subheadline)
                        .foregroundStyle(Color.nafasTextMuted)
                }
                .padding(.top, 20)
                
                // Connection Steps
                VStack(alignment: .leading, spacing: 16) {
                    ConnectionStep(
                        number: 1,
                        title: NSLocalizedString("bt_step1_title", comment: ""),
                        description: NSLocalizedString("bt_step1_desc", comment: ""),
                        icon: "battery.100"
                    )
                    
                    ConnectionStep(
                        number: 2,
                        title: NSLocalizedString("bt_step2_title", comment: ""),
                        description: NSLocalizedString("bt_step2_desc", comment: ""),
                        icon: "iphone.radiowaves.left.and.right"
                    )
                    
                    ConnectionStep(
                        number: 3,
                        title: NSLocalizedString("bt_step3_title", comment: ""),
                        description: NSLocalizedString("bt_step3_desc", comment: ""),
                        icon: "bluetooth"
                    )
                }
                .padding(20)
                .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
                
                Spacer()
                
                // Connection Status View
                VStack(spacing: 16) {
                    switch bluetoothManager.connectionState {
                    case .scanning:
                        scanningContent
                    case .connecting:
                        connectingContent
                    case .connected:
                        connectedContent
                    case .failed(let message):
                        failedContent(message: message)
                    case .disconnected:
                        disconnectedContent
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .background(Color.nafasBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("Connect Wristband"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("bt_cancel_button", comment: "")) {
                        bluetoothManager.stopScanning()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if !autoScanStarted {
                    autoScanStarted = true
                    startScanning()
                }
            }
        }
    }
    
    // MARK: - Content Views
    private var disconnectedContent: some View {
            VStack(spacing: 16) {
                Image(systemName: "sensor.tag.radiowaves.forward.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.nafasPrimary)
                
                Text(LocalizedStringKey("Tap 'Scan' to find your wristband"))
                    .font(.headline)
                
                Button {
                    startScanning()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sensor.tag.radiowaves.forward.fill")
                        Text(LocalizedStringKey("Scan for Wristband"))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 16))
                }
                
                // Updated: This now correctly dismisses the view to show the Home View
                Button {
                    dismiss()
                } label: {
                    Text(LocalizedStringKey("Skip for now"))
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.nafasTextMuted)
            }
            .padding()
        }
    
    private var scanningContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.nafasPrimary)
            
            Text(LocalizedStringKey("Scanning for devices..."))
                .font(.headline)
            
            Text(LocalizedStringKey("Looking for Nafas wristbands via Bluetooth"))
                .font(.caption)
                .foregroundStyle(Color.nafasTextMuted)
            
            if !bluetoothManager.discoveredDevices.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Devices Found"))
                        .font(.subheadline.bold())
                        .padding(.top, 20)
                    
                    ForEach(bluetoothManager.discoveredDevices) { device in
                        Button {
                            connectToDevice(device)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(device.name)
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(String(format: NSLocalizedString("RSSI: %lld dBm", comment: ""), device.rssi))
                                        .font(.caption)
                                        .foregroundStyle(Color.nafasTextMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.nafasTextMuted)
                            }
                            .padding()
                            .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Button(NSLocalizedString("Cancel Scan", comment: "")) {
                bluetoothManager.stopScanning()
            }
            .foregroundStyle(Color.nafasDanger)
            .padding(.top, 20)
        }
        .padding()
    }
    
    private var connectingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.nafasPrimary)
            
            Text(LocalizedStringKey("Connecting to wristband..."))
                .font(.headline)
            
            Text(LocalizedStringKey("This may take a few seconds"))
                .font(.caption)
                .foregroundStyle(Color.nafasTextMuted)
            
            Button(NSLocalizedString("bt_cancel_button", comment: "")) {
                bluetoothManager.cancelConnection()
            }
            .foregroundStyle(Color.nafasDanger)
            .padding(.top, 20)
        }
        .padding()
    }
    
    private var connectedContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.nafasSuccess)
            
            Text(LocalizedStringKey("Connected Successfully!"))
                .font(.headline)
                .foregroundStyle(Color.nafasSuccess)
            
            Text(String(format: NSLocalizedString("%@'s wristband is now paired", comment: ""), child.name))
                .font(.caption)
                .foregroundStyle(Color.nafasTextMuted)
            
            Button {
                var updatedChild = child
                updatedChild.isConnected = true
                NafasStore.shared.updateChild(updatedChild)
                dismiss()
            } label: {
                Text(LocalizedStringKey("Continue"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    private func failedContent(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.nafasDanger)
            
            Text(LocalizedStringKey("Connection Failed"))
                .font(.headline)
                .foregroundStyle(Color.nafasDanger)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(Color.nafasTextMuted)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button(NSLocalizedString("Skip", comment: "")) {
                    dismiss()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.nafasTextMuted)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 10))
                
                Button {
                    startScanning()
                } label: {
                    Text(LocalizedStringKey("Try Again"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    private func startScanning() {
        bluetoothManager.startScanning { device in
            // Device found - auto update
        }
    }
    
    private func connectToDevice(_ device: BluetoothDevice) {
        bluetoothManager.connectToDevice(device) { success in
            // Handle connection result
        }
    }
}

// MARK: - Connection Step Component
struct ConnectionStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.nafasPrimaryLight)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.nafasPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.nafasTextMuted)
            }
            
            Spacer()
            
            Text("\(number)")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.nafasTextMuted)
        }
    }
}

import Foundation
import Combine

final class BLEViewModel: ObservableObject {

    // MARK: - Published (UI state)
    @Published var state: BLEConnectionState = .idle
    @Published var discoveredDevices: [BluetoothDevice] = []
    @Published var selectedDevice: BluetoothDevice?
    @Published var wifiSSID: String = ""
    @Published var wifiPassword: String = ""
    @Published var showPassword: Bool = false
    @Published var connectionProgress: Double = 0.0
    @Published var errorMessage: String = ""

    /// The name of the child being set up – used for personalised strings in the UI.
    var childName: String = ""

    /// SSID that was actually sent to the device (shown on success screen).
    private(set) var sentSSID: String = ""

    // MARK: - Private
    private let bleManager: BLEManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        bleManager = BLEManager()
        bindManager()
    }

    // MARK: - Bindings

    private func bindManager() {
        bleManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.state = newState
                if case .failed(let msg) = newState {
                    self?.errorMessage = msg
                }
            }
            .store(in: &cancellables)

        bleManager.$discoveredDevices
            .receive(on: DispatchQueue.main)
            .assign(to: &$discoveredDevices)

        bleManager.$connectionProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionProgress)
    }

    // MARK: - Scanning

    func startScanning() {
        errorMessage = ""
        selectedDevice = nil
        bleManager.startScanning()
    }

    func stopScanning() {
        bleManager.stopScanning()
    }

    // MARK: - Connection

    func selectDevice(_ device: BluetoothDevice) {
        selectedDevice = device
    }

    func connectToSelectedDevice() {
        guard let device = selectedDevice else { return }
        bleManager.connectToDevice(device)
    }

    // MARK: - WiFi Provisioning

    var isWiFiFormValid: Bool {
        !wifiSSID.trimmingCharacters(in: .whitespaces).isEmpty &&
        !wifiPassword.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func sendWiFiCredentials() {
        let ssid = wifiSSID.trimmingCharacters(in: .whitespaces)
        let pwd  = wifiPassword.trimmingCharacters(in: .whitespaces)

        guard !ssid.isEmpty, !pwd.isEmpty else {
            errorMessage = "ble_invalid_wifi_credentials"
            return
        }

        sentSSID = ssid
        errorMessage = ""
        bleManager.sendWiFiCredentials(WiFiCredentials(ssid: ssid, password: pwd))
    }

    // MARK: - Disconnect / Reset

    func disconnect() {
        bleManager.disconnect()
        resetForm()
    }

    func resetForm() {
        wifiSSID = ""
        wifiPassword = ""
        showPassword = false
        selectedDevice = nil
        errorMessage = ""
        sentSSID = ""
    }

    // MARK: - Computed helpers

    var isConnected:  Bool { state == .connected }
    var isConnecting: Bool { state == .connecting }
    var isScanning:   Bool { state == .scanning }
    var isSendingWifi:Bool {
        if case .sendingWiFi = state { return true }
        return false
    }
    var hasError: Bool {
        if case .failed = state { return true }
        return false
    }
    var hasSucceeded: Bool { state == .success }
}

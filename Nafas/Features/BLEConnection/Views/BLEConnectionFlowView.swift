import SwiftUI
import Combine

// MARK: - Flow Steps
enum BLEFlowStep {
    case instructions
    case scanning
    case connecting
    case wifiInput
    case success
}

// MARK: - BLEConnectionFlowView
struct BLEConnectionFlowView: View {
    let child: ChildModel
    let isNewChild: Bool

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BLEViewModel()
    @State private var currentStep: BLEFlowStep = .instructions
    @State private var selectedDevice: BluetoothDevice?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nafasBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Header ──────────────────────────────────────────────
                    headerBar

                    // ── Progress bar ─────────────────────────────────────
                    ProgressView(value: stepProgress)
                        .tint(Color.nafasPrimary)
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                        .background(Color.nafasSurface)

                    // ── Step content ─────────────────────────────────────
                    ScrollView(showsIndicators: false) {
                        Group {
                            switch currentStep {
                            case .instructions:
                                BLEInstructionsView(
                                    child: child,
                                    onConnect: beginScan,
                                    onSkip: skipBLE
                                )

                            case .scanning:
                                BLEScanningView(
                                    viewModel: viewModel,
                                    childName: child.name,
                                    onPairDevice: { device in
                                        selectedDevice = device
                                        viewModel.selectDevice(device)
                                        viewModel.connectToSelectedDevice()
                                        currentStep = .connecting
                                    },
                                    onCancel: {
                                        viewModel.stopScanning()
                                        currentStep = .instructions
                                    },
                                    onSkip: skipBLE
                                )
                                .onChange(of: viewModel.state) { _, newState in
                                    if case .failed = newState { /* stays on scanning */ }
                                }

                            case .connecting:
                                BLEConnectingView(
                                    device: selectedDevice,
                                    state: viewModel.state,
                                    onRetry: {
                                        viewModel.disconnect()
                                        viewModel.startScanning()
                                        currentStep = .scanning
                                    },
                                    onSkip: skipBLE
                                )
                                .onChange(of: viewModel.state) { _, newState in
                                    if newState == .connected {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            currentStep = .wifiInput
                                        }
                                    } else if case .failed = newState {
                                        // Stays on connecting screen; retry visible
                                    }
                                }

                            case .wifiInput:
                                BLEWiFiInputView(
                                    viewModel: viewModel,
                                    device: selectedDevice,
                                    onSubmit: { viewModel.sendWiFiCredentials() },
                                    onBack: {
                                        viewModel.disconnect()
                                        viewModel.startScanning()
                                        currentStep = .scanning
                                    },
                                    onSkip: skipBLE
                                )
                                .onChange(of: viewModel.state) { _, newState in
                                    if newState == .success {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            currentStep = .success
                                        }
                                    }
                                }

                            case .success:
                                BLESuccessView(
                                    child: child,
                                    device: selectedDevice,
                                    wifiSSID: viewModel.sentSSID,
                                    onContinue: completeAndDismiss
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            viewModel.childName = child.name
        }
    }

    // MARK: - Header bar

    private var headerBar: some View {
        HStack {
            Button(action: handleBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.nafasTextPrimary)
            }

            Spacer()

            Text(stepTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.nafasTextPrimary)

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.nafasTextMuted)
            }
        }
        .padding()
        .background(Color.nafasSurface)
    }

    // MARK: - Step metadata

    private var stepTitle: String {
        switch currentStep {
        case .instructions: return NSLocalizedString("ble_connect_title", comment: "")
        case .scanning:     return NSLocalizedString("ble_scanning_title", comment: "")
        case .connecting:   return NSLocalizedString("ble_connecting_title", comment: "")
        case .wifiInput:    return NSLocalizedString("ble_wifi_title", comment: "")
        case .success:      return NSLocalizedString("ble_success_title", comment: "")
        }
    }

    private var stepProgress: Double {
        switch currentStep {
        case .instructions: return 0.05
        case .scanning:     return 0.30
        case .connecting:   return 0.55
        case .wifiInput:    return 0.75
        case .success:      return 1.0
        }
    }

    // MARK: - Actions

    private func beginScan() {
        currentStep = .scanning
        viewModel.startScanning()
    }

    private func skipBLE() {
        // Mark child as not connected (or keep existing state) and dismiss
        var updated = child
        if !isNewChild {
            updated.isConnected = false
        }
        NafasStore.shared.updateChild(updated)
        dismiss()
    }

    private func completeAndDismiss() {
        var updated = child
        if let device = selectedDevice {
            updated.isConnected = true
            updated.deviceID = device.deviceID
        }
        NafasStore.shared.updateChild(updated)
        dismiss()
    }

    private func handleBack() {
        switch currentStep {
        case .instructions:
            dismiss()
        case .scanning:
            viewModel.stopScanning()
            currentStep = .instructions
        case .connecting:
            viewModel.disconnect()
            viewModel.startScanning()
            currentStep = .scanning
        case .wifiInput:
            viewModel.disconnect()
            viewModel.startScanning()
            currentStep = .scanning
        case .success:
            break // no going back from success
        }
    }
}

// MARK: - Typealias for backward compatibility
// ChildDetailView.swift references BluetoothConnectionView
typealias BluetoothConnectionView = BLEConnectionFlowView

// MARK: - Instructions Screen
struct BLEInstructionsView: View {
    let child: ChildModel
    let onConnect: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 28) {
            
            // ── Child avatar ──────────────────────────────────────────
            VStack(spacing: 10) {
                ZStack {
                    if let data = child.avatarImageData, let img = UIImage(data: data) {
                        Image(uiImage: img)
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
                
                Text(String(format: NSLocalizedString("ble_connect_child_title", comment: ""),
                            child.name))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.nafasTextPrimary)
                .multilineTextAlignment(.center)
                
                Text(LocalizedStringKey("ble_connect_wristband"))
                    .font(.subheadline)
                    .foregroundStyle(Color.nafasTextMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)
            
            // ── Steps ─────────────────────────────────────────────────
            VStack(spacing: 12) {
                BLEConnectionStep(
                    icon: "battery.75",
                    iconColor: .nafasSuccess,
                    title: NSLocalizedString("bt_step1_title", comment: ""),
                    description: NSLocalizedString("bt_step1_desc", comment: "")
                )
                BLEConnectionStep(
                    icon: "dot.radiowaves.left.and.right",
                    iconColor: .nafasWarning,
                    title: NSLocalizedString("bt_step2_title", comment: ""),
                    description: NSLocalizedString("bt_step2_desc", comment: "")
                )
                BLEConnectionStep(
                    icon: "switch.2",
                    iconColor: .nafasPrimary,
                    title: NSLocalizedString("bt_step3_title", comment: ""),
                    description: NSLocalizedString("bt_step3_desc", comment: "")
                )
            }
            
            // ── Actions ───────────────────────────────────────────────
            VStack(spacing: 12) {
                Button(action: onConnect) {
                    Label(
                        NSLocalizedString("ble_scan_for_wristband", comment: ""),
                        systemImage: "antenna.radiowaves.left.and.right"
                    )
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 14))
                }

                // Restored the missing skip button!
                Button(action: onSkip) {
                    Text(LocalizedStringKey("ble_skip_for_now"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.nafasTextMuted)
                }
            }
        }
    }
} // <- THIS bracket was missing!

// MARK: - Connecting Overlay Screen
struct BLEConnectingView: View {
    let device: BluetoothDevice?
    let state: BLEConnectionState
    let onRetry: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            if case .connecting = state {
                connectingContent
            } else if case .failed(let msg) = state {
                failedContent(msg)
            }
            
            Spacer()
            
            if case .failed = state {
                VStack(spacing: 12) {
                    Button(action: onRetry) {
                        Text(LocalizedStringKey("ble_try_again"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 14))
                    }
                    Button(action: onSkip) {
                        Text(LocalizedStringKey("ble_skip"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.nafasTextMuted)
                    }
                }
            }
        }
    }
    
    private var connectingContent: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.nafasPrimary.opacity(0.12), lineWidth: 10)
                    .frame(width: 100, height: 100)
                ProgressView()
                    .scaleEffect(2.2)
                    .tint(Color.nafasPrimary)
            }
            VStack(spacing: 6) {
                Text(LocalizedStringKey("ble_connecting_title"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.nafasTextPrimary)
                if let device {
                    Text(device.name)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.nafasTextMuted)
                }
                Text(LocalizedStringKey("ble_connecting_subtitle"))
                    .font(.caption)
                    .foregroundStyle(Color.nafasTextMuted)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func failedContent(_ locKey: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.nafasDanger)
            Text(LocalizedStringKey("ble_connection_failed"))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.nafasTextPrimary)
            Text(LocalizedStringKey(locKey))
                .font(.caption)
                .foregroundStyle(Color.nafasTextMuted)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Step indicator component
struct BLEConnectionStep: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.nafasTextPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.nafasTextMuted)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.nafasSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

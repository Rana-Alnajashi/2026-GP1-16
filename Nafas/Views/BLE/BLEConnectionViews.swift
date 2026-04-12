//
//  BLEConnectionViews.swift
//  Nafas
//  Individual BLE screens: Scan, Device list, WiFi input, Success.
//  Designed to match the provided Figma mockups exactly.
//

import SwiftUI
import Combine

// MARK: - BLEScanningView
// Two visual states controlled by viewModel:
//   scanning + no devices  → animated Bluetooth icon + dots + Cancel
//   has devices            → devices list + "Pair & Continue"
struct BLEScanningView: View {
    @ObservedObject var viewModel: BLEViewModel
    let childName: String
    let onPairDevice: (BluetoothDevice) -> Void
    let onCancel: () -> Void
    let onSkip: () -> Void

    @State private var dotPhase: Int = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var localSelected: BluetoothDevice?

    private var showDeviceList: Bool { !viewModel.discoveredDevices.isEmpty }

    private let dotTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            if showDeviceList {
                deviceListContent
            } else {
                scanningContent
            }
        }
        .onAppear { localSelected = nil }
        .onReceive(dotTimer) { _ in
            guard !showDeviceList else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                dotPhase = (dotPhase + 1) % 3
            }
        }
    }

    // MARK: Scanning animation screen

    private var scanningContent: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated pulsing bluetooth icon
            ZStack {
                // Outer pulse ring
                Circle()
                    .stroke(Color.nafasPrimary.opacity(0.08), lineWidth: 1)
                    .frame(width: 180, height: 180)
                    .scaleEffect(pulseScale)
                    .animation(
                        Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                        value: pulseScale
                    )

                // Mid ring
                Circle()
                    .stroke(Color.nafasPrimary.opacity(0.15), lineWidth: 1.5)
                    .frame(width: 140, height: 140)

                // Inner circle
                Circle()
                    .fill(Color.nafasPrimary.opacity(0.10))
                    .frame(width: 104, height: 104)

                // Bluetooth icon
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(Color.nafasPrimary)

                // Scanning arc overlay
                ScanArc()
                    .stroke(Color.nafasPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 118, height: 118)
                    .rotationEffect(.degrees(-90))
            }
            .onAppear { pulseScale = 1.12 }

            // Text
            VStack(spacing: 8) {
                Text(LocalizedStringKey("ble_scanning_nearby"))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.nafasTextPrimary)

                Text(LocalizedStringKey("ble_scanning_subtitle"))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nafasTextMuted)
                    .multilineTextAlignment(.center)

                // Animated dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(dotPhase == i ? Color.nafasPrimary : Color.nafasPrimary.opacity(0.25))
                            .frame(width: 8, height: 8)
                            .scaleEffect(dotPhase == i ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: dotPhase)
                    }
                }
                .padding(.top, 4)
            }

            Spacer()

            // Error state (e.g. no devices found after timeout)
            if case .failed(let msg) = viewModel.state {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.nafasDanger)
                    Text(LocalizedStringKey(msg))
                        .font(.caption)
                        .foregroundStyle(Color.nafasTextMuted)
                    Spacer()
                }
                .padding(12)
                .background(Color.nafasDanger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Cancel / Scan again
            VStack(spacing: 10) {
                if case .failed = viewModel.state {
                    Button {
                        viewModel.startScanning()
                    } label: {
                        Text(LocalizedStringKey("ble_scan_again"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 14))
                    }
                }

                Button(action: onCancel) {
                    Text(LocalizedStringKey("ble_cancel"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.nafasTextMuted)
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: Device list screen

    private var deviceListContent: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey("ble_devices_found"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.nafasTextPrimary)

                Text(String(format: NSLocalizedString("ble_select_device_for_child", comment: ""),
                            childName))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nafasTextMuted)
            }

            // Device rows
            VStack(spacing: 10) {
                ForEach(viewModel.discoveredDevices) { device in
                    BLEDeviceRow(
                        device: device,
                        isSelected: localSelected?.id == device.id,
                        childName: childName,
                        action: { localSelected = device }
                    )
                }
            }

            // "Don't see your device?" footer
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.nafasTextMuted)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("ble_dont_see_device"))
                        .font(.caption)
                        .foregroundStyle(Color.nafasTextMuted)
                    Button {
                        localSelected = nil
                        viewModel.startScanning()
                    } label: {
                        Text(LocalizedStringKey("ble_scan_again"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.nafasPrimary)
                    }
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .foregroundStyle(Color.nafasDivider)
            )

            Spacer(minLength: 16)

            // Pair & Continue button
            Button {
                if let device = localSelected {
                    onPairDevice(device)
                }
            } label: {
                Text(LocalizedStringKey("ble_pair_and_continue"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(
                        localSelected != nil ? Color.nafasPrimary : Color.nafasPrimary.opacity(0.45),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .disabled(localSelected == nil)
        }
    }

}

// MARK: - Scanning arc shape (partial circle)
private struct ScanArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        return p
    }
}

// MARK: - BLEDeviceRow
struct BLEDeviceRow: View {
    let device: BluetoothDevice
    let isSelected: Bool
    let childName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Device icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.nafasPrimary : Color.nafasPrimaryLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: "applewatch")
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? Color.white : Color.nafasPrimary)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    // Name: "Nafas Band · childName" for first device
                    let displayName = device.name.uppercased().contains("NAFAS")
                        ? "Nafas Band · \(childName)"
                        : device.name
                    Text(displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.nafasTextPrimary)

                    HStack(spacing: 10) {
                        // Signal bars + RSSI
                        HStack(spacing: 3) {
                            ForEach(1...4, id: \.self) { bar in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(bar <= device.signalBars
                                          ? signalColor : Color.nafasDivider)
                                    .frame(width: 4, height: CGFloat(4 + bar * 3))
                            }
                        }
                        Text("\(device.rssi) dBm")
                            .font(.caption)
                            .foregroundStyle(Color.nafasTextMuted)

                        // Battery
                        if device.batteryLevel > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: batteryIcon)
                                    .font(.caption)
                                    .foregroundStyle(batteryColor)
                                Text("\(device.batteryLevel)%")
                                    .font(.caption)
                                    .foregroundStyle(batteryColor)
                            }
                        }
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "record.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.nafasPrimary)
                } else {
                    Circle()
                        .strokeBorder(Color.nafasDivider, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(14)
            .background(
                isSelected ? Color.nafasPrimaryLight.opacity(0.25) : Color.nafasSurface,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? Color.nafasPrimary : Color.nafasDivider,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var signalColor: Color {
        switch device.signalBars {
        case 1: return .nafasDanger
        case 2: return .nafasWarning
        default: return .nafasSuccess
        }
    }

    private var batteryIcon: String {
        switch device.batteryLevel {
        case 0..<20:  return "battery.0"
        case 20..<50: return "battery.25"
        case 50..<80: return "battery.50"
        default:      return "battery.100"
        }
    }

    private var batteryColor: Color {
        device.batteryLevel < 20 ? .nafasDanger : .nafasSuccess
    }
}

// MARK: - BLEWiFiInputView
struct BLEWiFiInputView: View {
    @ObservedObject var viewModel: BLEViewModel
    let device: BluetoothDevice?
    let onSubmit: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    @FocusState private var focused: Field?
    enum Field { case ssid, password }

    var body: some View {
        VStack(spacing: 20) {

            // ── Connected device card ─────────────────────────────────
            if let device {
                connectedDeviceCard(device)
            }

            // ── Form ─────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey("ble_wifi_share_title"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.nafasTextPrimary)
                Text(LocalizedStringKey("ble_wifi_subtitle"))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nafasTextMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 14) {
                // SSID
                wifiField(
                    labelKey: "ble_wifi_ssid_label",
                    text: $viewModel.wifiSSID,
                    isSecure: false,
                    leadingIcon: "wifi",
                    fieldTag: .ssid
                )

                // Password
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey("ble_wifi_password_label"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.nafasTextPrimary)

                    HStack(spacing: 10) {
                        Image(systemName: "lock")
                            .foregroundStyle(Color.nafasTextMuted)
                            .frame(width: 18)

                        if viewModel.showPassword {
                            TextField("", text: $viewModel.wifiPassword,
                                      prompt: Text(LocalizedStringKey("ble_wifi_password_placeholder"))
                                                  .foregroundColor(Color.nafasTextMuted))
                                .font(.nafasBody())
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($focused, equals: .password)
                        } else {
                            SecureField("", text: $viewModel.wifiPassword,
                                        prompt: Text(LocalizedStringKey("ble_wifi_password_placeholder"))
                                                    .foregroundColor(Color.nafasTextMuted))
                                .font(.nafasBody())
                                .focused($focused, equals: .password)
                        }

                        Spacer()

                        // Eye toggle
                        Button {
                            viewModel.showPassword.toggle()
                        } label: {
                            Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(Color.nafasTextMuted)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.nafasBackground)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(focused == .password ? Color.nafasPrimary : Color.nafasDivider,
                                              lineWidth: 1))
                    )
                }
            }

            // ── Security note ─────────────────────────────────────────
            HStack(alignment: .top, spacing: 10) {
                Text("🔒")
                Text(LocalizedStringKey("ble_wifi_security_note"))
                    .font(.caption)
                    .foregroundStyle(Color.nafasTextMuted)
                Spacer()
            }
            .padding(12)
            .background(Color.nafasPrimary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // ── Error ─────────────────────────────────────────────────
            if !viewModel.errorMessage.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.nafasDanger)
                    Text(LocalizedStringKey(viewModel.errorMessage))
                        .font(.caption)
                        .foregroundStyle(Color.nafasTextMuted)
                    Spacer()
                }
                .padding(10)
                .background(Color.nafasDanger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer(minLength: 8)

            // ── Submit button ─────────────────────────────────────────
            Button(action: onSubmit) {
                Group {
                    if viewModel.isSendingWifi {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.85).tint(.white)
                            Text(LocalizedStringKey("ble_sending"))
                        }
                    } else {
                        Label(NSLocalizedString("ble_send_to_wristband", comment: ""),
                              systemImage: "wifi")
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(
                    viewModel.isWiFiFormValid && !viewModel.isSendingWifi
                        ? Color.nafasPrimary : Color.nafasPrimary.opacity(0.45),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
            .disabled(!viewModel.isWiFiFormValid || viewModel.isSendingWifi)

            // ── Back link ─────────────────────────────────────────────
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 12))
                    Text(LocalizedStringKey("ble_back_to_device_list"))
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Color.nafasTextMuted)
            }
        }
    }

    // MARK: Sub-views

    private func connectedDeviceCard(_ device: BluetoothDevice) -> some View {
        let displayName = device.name.uppercased().contains("NAFAS")
            ? "Nafas Band · \(viewModel.childName)"
            : device.name

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "applewatch")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Label(device.shortID, systemImage: "link")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.white.opacity(0.2), in: Capsule())

                    Label(NSLocalizedString("ble_paired_via_bt", comment: ""),
                          systemImage: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.white.opacity(0.2), in: Capsule())
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 24))
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func wifiField(
        labelKey: String,
        text: Binding<String>,
        isSecure: Bool,
        leadingIcon: String,
        fieldTag: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.nafasTextPrimary)

            HStack(spacing: 10) {
                Image(systemName: leadingIcon)
                    .foregroundStyle(Color.nafasTextMuted)
                    .frame(width: 18)

                if isSecure {
                    SecureField("",
                                text: text,
                                prompt: Text(LocalizedStringKey("ble_wifi_\(fieldTag == .ssid ? "ssid" : "password")_placeholder"))
                                            .foregroundColor(Color.nafasTextMuted))
                        .font(.nafasBody())
                        .autocorrectionDisabled()
                        .focused($focused, equals: fieldTag)
                } else {
                    TextField("",
                              text: text,
                              prompt: Text(LocalizedStringKey("ble_wifi_ssid_placeholder"))
                                          .foregroundColor(Color.nafasTextMuted))
                        .font(.nafasBody())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focused, equals: fieldTag)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.nafasBackground)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(focused == fieldTag ? Color.nafasPrimary : Color.nafasDivider,
                                      lineWidth: 1))
            )
        }
    }
}

// MARK: - BLESuccessView
struct BLESuccessView: View {
    let child: ChildModel
    let device: BluetoothDevice?
    let wifiSSID: String
    let onContinue: () -> Void

    @State private var ring1Scale: CGFloat = 1.0
    @State private var ring2Scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // ── Animated checkmark ────────────────────────────────────
            ZStack {
                Circle()
                    .fill(Color.nafasSuccess.opacity(0.06))
                    .frame(width: 160, height: 160)
                    .scaleEffect(ring1Scale)
                    .animation(
                        Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                        value: ring1Scale
                    )

                Circle()
                    .fill(Color.nafasSuccess.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .scaleEffect(ring2Scale)
                    .animation(
                        Animation.easeInOut(duration: 1.6).delay(0.4).repeatForever(autoreverses: true),
                        value: ring2Scale
                    )

                Circle()
                    .fill(Color.nafasSuccess)
                    .frame(width: 84, height: 84)

                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }
            .onAppear {
                ring1Scale = 1.15
                ring2Scale = 1.12
            }

            // ── Title ─────────────────────────────────────────────────
            VStack(spacing: 8) {
                Text(LocalizedStringKey("ble_success_all_set"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.nafasTextPrimary)

                Text(String(format: NSLocalizedString("ble_success_body", comment: ""),
                            child.name))
                    .font(.system(size: 15))
                    .foregroundStyle(Color.nafasTextMuted)
                    .multilineTextAlignment(.center)
            }

            // ── Status rows ───────────────────────────────────────────
            VStack(spacing: 10) {
                // Bluetooth
                statusRow(
                    icon: "antenna.radiowaves.left.and.right",
                    iconBg: Color.nafasPrimary,
                    category: NSLocalizedString("ble_status_bluetooth", comment: ""),
                    value: "\(device?.shortID ?? "–") · \(NSLocalizedString("ble_status_paired", comment: ""))"
                )

                // WiFi
                statusRow(
                    icon: "wifi",
                    iconBg: Color.nafasPrimary,
                    category: NSLocalizedString("ble_status_wifi", comment: ""),
                    value: wifiSSID.isEmpty ? "–" : wifiSSID
                )

                // Wristband
                let bandName = device.map { d -> String in
                    let base = d.name.uppercased().contains("NAFAS")
                        ? "Nafas Band · \(child.name)"
                        : d.name
                    if d.batteryLevel > 0 { return "\(base) · 🔋 \(d.batteryLevel)%" }
                    return base
                } ?? "–"

                statusRow(
                    icon: "applewatch",
                    iconBg: Color.nafasPrimary,
                    category: NSLocalizedString("ble_status_wristband", comment: ""),
                    value: bandName
                )
            }

            Spacer()

            // ── CTA button ────────────────────────────────────────────
            Button(action: onContinue) {
                Text(String(format: NSLocalizedString("ble_go_to_dashboard_child", comment: ""),
                            child.name))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Color.nafasSuccess, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func statusRow(
        icon: String,
        iconBg: Color,
        category: String,
        value: String
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBg.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconBg)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.caption)
                    .foregroundStyle(Color.nafasTextMuted)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.nafasTextPrimary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.nafasSuccess)
                .font(.system(size: 20))
        }
        .padding(12)
        .background(Color.nafasSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Color.nafasDivider, lineWidth: 1))
    }
}

// MARK: - Custom placeholder helper (kept for any callers)
extension View {
    func placeholder<C: View>(
        when show: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> C
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(show ? 1 : 0)
            self
        }
    }
}

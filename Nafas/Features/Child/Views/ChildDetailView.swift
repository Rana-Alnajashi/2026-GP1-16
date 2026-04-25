import SwiftUI

// MARK: - ChildDetailView

struct ChildDetailView: View {
    let child: ChildModel
    @ObservedObject private var store = NafasStore.shared
    @State private var showHealthHistory = false
    @State private var showAddPeakFlow = false
    @State private var showEditChild = false
    @State private var showBluetoothConnection = false
    @State private var showDeleteAlert = false
    @State private var dismissedAlerts: Set<String> = []
    @State private var menuOpen = false
    @Environment(\.dismiss) var dismiss
    
    //  Language toggle & helper function
    @AppStorage("nafas_language") private var language = "English"
    
    private func loc(_ key: String) -> String {
        let langCode = language == "Arabic" ? "ar" : "en"
        if let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
           let bundle = Bundle(path: path) { return NSLocalizedString(key, bundle: bundle, comment: "") }
        return NSLocalizedString(key, comment: "")
    }
    
    private var currentChild: ChildModel {
        store.children.first(where: { $0.id == child.id }) ?? child
    }
    private var vitals: VitalSnapshot? {
            store.latestVitals[child.id.uuidString]
        }
    private var peakFlows: [PeakFlowEntry] {
        store.peakFlowLogs[child.id.uuidString] ?? []
    }
    private var latestPeak: PeakFlowEntry? { peakFlows.first }

    private var spO2AlertId: String { "spo2_\(child.id)" }
    private var peakAlertId: String { "peak_\(child.id)" }
    private var hasActiveAlert: Bool {
        let spO2Alert = vitals?.spO2Status == .low && !dismissedAlerts.contains(spO2AlertId)
        let peakAlert = vitals?.peakZone == .red  && !dismissedAlerts.contains(peakAlertId)
        return spO2Alert || peakAlert
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Main content
            Group {
                if vitals != nil {
                    connectedView
                } else {
                    disconnectedView
                }
            }
            .navigationTitle(child.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { toggleMenu() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 21, weight: .medium))
                            .foregroundStyle(Color.nafasTextPrimary)
                    }
                }
            }
            if menuOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { toggleMenu() }
            }

            ChildSideMenuView(
                child: currentChild,
                isOpen: $menuOpen,
                onAddPeakFlow: { showAddPeakFlow = true },
                onEditChild: { showEditChild = true },
                onHealthHistory: { showHealthHistory = true },
                onDeleteChild: { showDeleteAlert = true }
            )
            .frame(width: UIScreen.main.bounds.width * 0.82)
            .offset(x: menuOpen ? 0 : UIScreen.main.bounds.width)
            .animation(.spring(response: 0.38, dampingFraction: 0.88), value: menuOpen)
        }
        .environment(\.layoutDirection, language == "Arabic" ? .rightToLeft : .leftToRight)
        .sheet(isPresented: $showHealthHistory) { HealthHistoryView(child: currentChild) }
        .sheet(isPresented: $showAddPeakFlow)   { AddPeakFlowView(child: currentChild) }
        .sheet(isPresented: $showEditChild)      { EditChildView(child: currentChild) }
        .sheet(isPresented: $showBluetoothConnection) {
            BluetoothConnectionView(child: child, isNewChild: false)
        }
        .alert(
            String(format: loc("child_delete_title"), child.name),
            isPresented: $showDeleteAlert
        ) {
            Button(loc("child_delete_cancel"), role: .cancel) { }
            Button(loc("child_delete_confirm"), role: .destructive) {
                store.deleteChild(child.id.uuidString)
                dismiss()
            }
        } message: {
            Text(LocalizedStringKey("child_delete_message"))
        }
        .onAppear {
            if child.isConnected, let deviceID = child.deviceID {
                NafasMQTTManager.shared.connect(for: child.id.uuidString, deviceID: deviceID)
            }
        }
        .onChange(of: child.isConnected) { oldValue, newValue in
            if newValue, let deviceID = child.deviceID {
                NafasMQTTManager.shared.connect(for: child.id.uuidString, deviceID: deviceID)
            } else {
                NafasMQTTManager.shared.disconnect()
            }
        }
        .onDisappear {
            NafasMQTTManager.shared.disconnect()
        }
    }

    private func toggleMenu() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            menuOpen.toggle()
        }
    }

    // MARK: - Connected View
    private var connectedView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                if let v = vitals, v.spO2Status == .low, !dismissedAlerts.contains(spO2AlertId) {
                    alertBanner(
                        message: String(format: loc("alert_spo2_dropped"), v.spO2, child.name),
                        alertId: spO2AlertId
                    )
                }
                if let v = vitals, v.peakZone == .red, !dismissedAlerts.contains(peakAlertId) {
                    alertBanner(
                        message: String(format: loc("alert_peak_red_zone"), v.peakFlow),
                        alertId: peakAlertId
                    )
                }

                if let v = vitals {
                    wristbandCard(lastSync: v.lastSync)
                }

                if hasActiveAlert && !currentChild.emergencyPhoneNumbers.isEmpty {
                    emergencyCallCard
                }

                HStack {
                    Text(LocalizedStringKey("vital_live_vitals"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.nafasTextPrimary)
                    Spacer()
                    Text(LocalizedStringKey("vital_updated_just_now"))
                        .font(.nafasCaption())
                        .foregroundStyle(Color.nafasTextMuted)
                }

                if let v = vitals {
                    HStack(spacing: 12) {
                        vitalCard(
                            icon: "heart.fill", iconColor: .red, iconBg: Color.red.opacity(0.12),
                            title: "Heart Rate",
                            value: v.bp,
                            unit: "bpm",
                            status: bpStatusLabel(v.bpStatus),
                            statusColor: statusColor(v.bpStatus)
                        )
                        vitalCard(
                            icon: "drop.fill", iconColor: Color.nafasPrimary, iconBg: Color.nafasPrimary.opacity(0.12),
                            title: "SpO2",
                            value: "\(v.spO2)%",
                            unit: loc("vital_oxygen_unit"),
                            status: spO2StatusLabel(v.spO2Status),
                            statusColor: statusColor(v.spO2Status)
                        )
                    }
                    iaqCard(v)
                } else {
                    emptyVitalsView
                }

                peakFlowSection
                todaySummarySection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color.nafasBackground.ignoresSafeArea())
    }

    // MARK: - Disconnected View
    private var disconnectedView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                Button {
                    showBluetoothConnection = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sensor.tag.radiowaves.forward.fill")
                        Text(LocalizedStringKey("detail_connect_wristband"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text(LocalizedStringKey("vital_live_vitals"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.nafasTextPrimary)

                    Text(LocalizedStringKey("vital_no_device_connected"))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.nafasTextMuted)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.red)
                                Text(LocalizedStringKey("Heart Rate"))
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.nafasTextMuted)
                            }
                            Text("---")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.nafasTextMuted)
                            Text(LocalizedStringKey("bpm"))
                                .font(.system(size: 12))
                                .foregroundStyle(Color.nafasTextMuted)
                            Text(LocalizedStringKey("disconnected_no_data"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.nafasTextMuted)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1), in: Capsule())
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.nafasPrimary)
                                Text(LocalizedStringKey("disconnected_spo2_title"))
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.nafasTextMuted)
                            }
                            Text("---")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.nafasTextMuted)
                            Text(LocalizedStringKey("disconnected_spo2_unit"))
                                .font(.system(size: 12))
                                .foregroundStyle(Color.nafasTextMuted)
                            Text(LocalizedStringKey("disconnected_no_data"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.nafasTextMuted)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1), in: Capsule())
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "wind")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.orange)
                                Text(LocalizedStringKey("disconnected_iaq_title"))
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.nafasTextMuted)
                            }
                            Spacer()
                            Text(LocalizedStringKey("disconnected_no_data"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.nafasTextMuted)
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(Color.gray.opacity(0.1), in: Capsule())
                        }
                        Text("---")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.nafasTextMuted)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.nafasDivider).frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3)).frame(width: 0, height: 8)
                            }
                        }
                        .frame(height: 8)
                        HStack {
                            Text(LocalizedStringKey("iaq_scale_good"))
                            Spacer()
                            Text(LocalizedStringKey("iaq_scale_moderate"))
                            Spacer()
                            Text(LocalizedStringKey("iaq_scale_poor"))
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(Color.nafasTextMuted)
                    }
                    .padding(16)
                    .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
                }

                peakFlowSection
                todaySummarySection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color.nafasBackground.ignoresSafeArea())
    }

    private var emptyVitalsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                emptyVitalCard(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    unit: "bpm"
                )
                emptyVitalCard(
                    icon: "drop.fill",
                    title: loc("disconnected_spo2_title"),
                    unit: loc("disconnected_spo2_unit")
                )
            }
            emptyIAQCard()
        }
    }

    @ViewBuilder
    private func emptyVitalCard(icon: String, title: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(icon == "heart.fill" ? .red : Color.nafasPrimary)
                Text(LocalizedStringKey(title))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.nafasTextMuted)
            }
            Text("---")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.nafasTextMuted)
            Text(LocalizedStringKey(unit))
                .font(.system(size: 12))
                .foregroundStyle(Color.nafasTextMuted)
            Text(loc("disconnected_no_data"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.nafasTextMuted)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.gray.opacity(0.1), in: Capsule())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func emptyIAQCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "wind")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.orange)
                    Text(LocalizedStringKey("disconnected_iaq_title"))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.nafasTextMuted)
                }
                Spacer()
                Text(LocalizedStringKey("disconnected_no_data"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.nafasTextMuted)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(Color.gray.opacity(0.1), in: Capsule())
            }
            Text("---")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.nafasTextMuted)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.nafasDivider).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3)).frame(width: 0, height: 8)
                }
            }
            .frame(height: 8)
            HStack {
                Text(LocalizedStringKey("iaq_scale_good"))
                Spacer()
                Text(LocalizedStringKey("iaq_scale_moderate"))
                Spacer()
                Text(LocalizedStringKey("iaq_scale_poor"))
            }
            .font(.system(size: 11))
            .foregroundStyle(Color.nafasTextMuted)
        }
        .padding(16)
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Peak Flow Section
    private var peakFlowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("vital_peak_flow"))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.nafasTextPrimary)

            if let latest = latestPeak {
                let zoneColor: Color = latest.value >= 240 ? .nafasSuccess : (latest.value >= 160 ? .nafasWarning : .nafasDanger)

                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(zoneColor.opacity(0.12)).frame(width: 52, height: 52)
                        Image(systemName: "waveform.path.ecg").font(.system(size: 22)).foregroundStyle(zoneColor)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: loc("peak_last_reading"), latest.value))
                            .font(.system(size: 16, weight: .bold)).foregroundStyle(Color.nafasTextPrimary)
                        Text(String(format: loc("%@ at %@"), latest.date, latest.time))
                            .font(.nafasCaption()).foregroundStyle(Color.nafasTextMuted)
                        if !latest.note.isEmpty {
                            Text(latest.note)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.nafasTextMuted)
                                .italic()
                        }
                    }
                    Spacer()
                    Button { showAddPeakFlow = true } label: {
                        Text(LocalizedStringKey("peak_add_button"))
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color.nafasPrimary, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(16)
                .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
            } else {
                Button { showAddPeakFlow = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle").font(.system(size: 16, weight: .semibold))
                        Text(LocalizedStringKey("peak_record_first"))
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color.nafasPrimary)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .foregroundStyle(Color.nafasPrimary.opacity(0.5))
                    )
                }
            }
        }
    }

    // MARK: - Helper Views
    @ViewBuilder
    private func alertBanner(message: String, alertId: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle").foregroundStyle(Color.nafasDanger)
            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.nafasDanger)
                .multilineTextAlignment(.leading)
            Spacer()
            Button { _ = dismissedAlerts.insert(alertId) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.nafasDanger)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.nafasDanger.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.nafasDanger.opacity(0.5), lineWidth: 1.5))
        )
    }

    // MARK: - Emergency Call Card
    private var emergencyCallCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "phone.fill").foregroundStyle(Color.nafasDanger)
                Text(LocalizedStringKey("emergency_call_title"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.nafasTextPrimary)
            }
            ForEach(currentChild.emergencyPhoneNumbers.filter { !$0.isEmpty }, id: \.self) { phone in
                Button {
                    let cleanPhone = phone.filter { "0123456789+".contains($0) }
                    if let url = URL(string: "tel://\(cleanPhone)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "phone.arrow.up.right")
                            .font(.system(size: 15, weight: .semibold))
                        Text(phone)
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text(LocalizedStringKey("emergency_call_button"))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(Color.nafasDanger, in: Capsule())
                    }
                    .foregroundStyle(Color.nafasDanger)
                    .padding(12)
                    .background(Color.nafasDanger.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.nafasDanger.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(14)
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.nafasDanger.opacity(0.1), radius: 6, y: 2)
    }

    private func wristbandCard(lastSync: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.nafasSuccess.opacity(0.12)).frame(width: 52, height: 52)
                Image(systemName: "sensor.tag.radiowaves.forward.fill")
                    .font(.system(size: 22)).foregroundStyle(Color.nafasSuccess)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey("wristband_connected_title"))
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.nafasTextPrimary)
                Text(String(
                    format: loc("wristband_device_sync"),
                    child.deviceID ?? loc("device_id_unknown"),
                    String(format: loc("wristband_last_sync"), lastSync)
                ))
                .font(.nafasCaption()).foregroundStyle(Color.nafasTextMuted)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                Text(LocalizedStringKey("wristband_on_label")).font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.nafasSuccess)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color.nafasSuccess.opacity(0.12), in: Capsule())
        }
        .padding(16)
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func vitalCard(icon: String, iconColor: Color, iconBg: Color,
                           title: String, value: String, unit: String,
                           status: String, statusColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(iconColor)
                Text(LocalizedStringKey(title)).font(.system(size: 13)).foregroundStyle(Color.nafasTextMuted)
            }
            Text(value).font(.system(size: 28, weight: .bold)).foregroundStyle(Color.nafasTextPrimary)
            Text(LocalizedStringKey(unit)).font(.system(size: 12)).foregroundStyle(Color.nafasTextMuted)
            HStack(spacing: 4) {
                Circle().fill(statusColor).frame(width: 7, height: 7)
                Text(LocalizedStringKey(status)).font(.system(size: 12, weight: .semibold)).foregroundStyle(statusColor)
            }
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(statusColor.opacity(0.10), in: Capsule())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func iaqCard(_ v: VitalSnapshot) -> some View {
        let iaqColor: Color = v.iaqStatus == .good ? .nafasSuccess : v.iaqStatus == .moderate ? .nafasWarning : .nafasDanger
        let iaqLabel = v.iaqStatus == .good
            ? loc("iaq_good")
            : v.iaqStatus == .moderate
                ? loc("iaq_moderate")
                : loc("iaq_poor")
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "wind").font(.system(size: 18)).foregroundStyle(Color.orange)
                    Text(LocalizedStringKey("vital_indoor_air_quality"))
                        .font(.system(size: 13)).foregroundStyle(Color.nafasTextMuted)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(iaqColor).frame(width: 7, height: 7)
                    Text(iaqLabel).font(.system(size: 13, weight: .semibold)).foregroundStyle(iaqColor)
                }
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(iaqColor.opacity(0.10), in: Capsule())
            }
            Text(String(format: loc("iaq_value_format"), v.iaq))
                .font(.system(size: 24, weight: .bold)).foregroundStyle(Color.nafasTextPrimary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.nafasDivider).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(iaqColor)
                        .frame(width: geo.size.width * CGFloat(min(v.iaq, 150)) / 150, height: 8)
                }
            }.frame(height: 8)
            HStack {
                Text(LocalizedStringKey("iaq_scale_good"))
                Spacer()
                Text(LocalizedStringKey("iaq_scale_moderate"))
                Spacer()
                Text(LocalizedStringKey("iaq_scale_poor"))
            }
            .font(.system(size: 11)).foregroundStyle(Color.nafasTextMuted)
        }
        .padding(16)
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Today's Summary Section
    private var todaySummarySection: some View {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("EEE, d MMM")
        let todayString = df.string(from: Date())

        let history = store.historyEntries[child.id.uuidString] ?? []
        let peaks   = store.peakFlowLogs[child.id.uuidString]  ?? []

        let todayHistory = history.filter { $0.date == todayString }
        let todayPeaks   = peaks.filter   { $0.date == todayString }

        let totalReadings   = todayHistory.count + todayPeaks.count
        let latestPeakValue = todayPeaks.first?.value ?? 0

        let validSpO2 = todayHistory.compactMap { $0.spO2 }
        let avgSpO2   = validSpO2.isEmpty ? 0 : validSpO2.reduce(0, +) / validSpO2.count

        return VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("summary_today"))
                .font(.system(size: 20, weight: .bold)).foregroundStyle(Color.nafasTextPrimary)

            HStack(spacing: 12) {
                summaryTile(value: "\(totalReadings)",                        label: LocalizedStringKey("summary_readings"))
                summaryTile(value: avgSpO2 > 0 ? "\(avgSpO2)%" : "—",        label: LocalizedStringKey("summary_avg_spo2"),  color: Color.nafasPrimary)
                summaryTile(value: latestPeakValue > 0 ? "\(latestPeakValue)" : "—", label: LocalizedStringKey("summary_peak_lm"), color: Color.nafasPrimary)
            }

            Button { showHealthHistory = true } label: {
                Text(LocalizedStringKey("summary_health_history_button"))
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.nafasPrimary)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.nafasPrimaryLight, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private func summaryTile(value: String, label: LocalizedStringKey, color: Color = Color.nafasTextPrimary) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 22, weight: .bold)).foregroundStyle(color)
            Text(label).font(.nafasCaption()).foregroundStyle(Color.nafasTextMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func statusColor(_ s: VitalSnapshot.VitalStatus) -> Color {
        s == .normal ? .nafasSuccess : s == .low ? .nafasDanger : .nafasWarning
    }
    private func bpStatusLabel(_ s: VitalSnapshot.VitalStatus) -> String {
        s == .normal ? "status_normal" :
        s == .low    ? "status_low" :
                       "status_high"
    }
    private func spO2StatusLabel(_ s: VitalSnapshot.VitalStatus) -> String {
        s == .normal ? "status_normal" :
        s == .low    ? "status_low_warning" :
                       "status_high"
    }
}

// MARK: - Child Side Menu View
struct ChildSideMenuView: View {
    let child: ChildModel
    @Binding var isOpen: Bool
    let onAddPeakFlow: () -> Void
    let onEditChild: () -> Void
    let onHealthHistory: () -> Void
    let onDeleteChild: () -> Void

    @ObservedObject var userManager = UserProfileManager.shared
    @AppStorage("nafas_dark_mode") private var darkMode = false
    @AppStorage("nafas_language") private var language = "English"
    
    private func loc(_ key: String) -> String {
        let langCode = language == "Arabic" ? "ar" : "en"
        if let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
           let bundle = Bundle(path: path) { return NSLocalizedString(key, bundle: bundle, comment: "") }
        return NSLocalizedString(key, comment: "")
    }

    private var userName: String { userManager.displayName ?? child.name }
    private var initial: String  { String(userName.prefix(1)).uppercased() }

    private var localizedLanguageLabel: String {
        language == "English" ? loc("English") : loc("Arabic")
    }

    private func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { isOpen = false }
    }

    private func toggleLanguage() {
        language = (language == "English") ? "Arabic" : "English"
        close()
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color.nafasSurface
                .clipShape(MenuPanelShape(radius: 28))
                .shadow(color: .black.opacity(0.14), radius: 24, x: -4, y: 0)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        if let avatarData = child.avatarImageData,
                           let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: child.avatarColor))
                                .frame(width: 56, height: 56)
                            Text(String(child.name.prefix(1)))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(child.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.nafasTextPrimary)
                        Text(ageLabel(child.age))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.nafasPrimary)
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .background(Color.nafasPrimaryLight, in: Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)

                Divider().padding(.horizontal, 24)

                VStack(spacing: 6) {
                    if !child.emergencyPhoneNumbers.isEmpty {
                        row(icon: "phone.fill", labelKey: "menu_emergency_call") {
                            close()
                            if let phone = child.emergencyPhoneNumbers.first {
                                let cleanPhone = phone.filter { "0123456789+".contains($0) }
                                if let url = URL(string: "tel://\(cleanPhone)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                    row(icon: "pencil",    labelKey: "child_menu_edit_info")      { close(); onEditChild() }
                    row(icon: "calendar",  labelKey: "child_menu_health_history") { close(); onHealthHistory() }
                    toggleRow(icon: "moon",  labelKey: "menu_dark_mode", binding: $darkMode)
                    valueRow(icon: "globe", labelKey: "menu_language", value: localizedLanguageLabel, action: toggleLanguage)

                    Divider().padding(.vertical, 8)

                    destructiveRow(icon: "trash", labelKey: "child_menu_delete") {
                        close(); onDeleteChild()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                Spacer()

                Text(loc("Nafas v1.0.0"))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.nafasTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 36)
            }
        }
    }

    @ViewBuilder
    private func row(icon: String, labelKey: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBox(icon)
                Text(LocalizedStringKey(labelKey))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.nafasTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.nafasTextMuted)
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func destructiveRow(icon: String, labelKey: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBox(icon)
                Text(LocalizedStringKey(labelKey))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.nafasDanger)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.nafasDanger.opacity(0.7))
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func toggleRow(icon: String, labelKey: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            iconBox(icon)
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.nafasTextPrimary)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(Color.nafasPrimary)
                .scaleEffect(0.85)
        }
        .padding(.horizontal, 14).padding(.vertical, 13)
        .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func valueRow(icon: String, labelKey: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBox(icon)
                Text(LocalizedStringKey(labelKey))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.nafasTextPrimary)
                Spacer()
                Text(value)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.nafasTextMuted)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.nafasTextMuted)
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func iconBox(_ systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.nafasPrimary.opacity(0.10))
                .frame(width: 38, height: 38)
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.nafasPrimary)
        }
    }
    // MARK: - 🚀 Perfect Arabic Plural Helper
        private func ageLabel(_ age: Int) -> String {
            if language == "Arabic" {
                switch age {
                case 0: return "أقل من سنة"
                case 1: return "سنة واحدة"
                case 2: return "سنتان"
                case 3...10: return "\(age) سنوات"
                default: return "\(age) سنة"
                }
            } else {
                return "\(age) years old"
            }
        }
}

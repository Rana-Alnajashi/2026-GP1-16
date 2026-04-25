import SwiftUI

struct AddPeakFlowView: View {
    let child: ChildModel
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = NafasStore.shared
    
    @State private var peakValue = ""
    @State private var note = ""
    @State private var isSaving = false
    @State private var showSuccess = false
    
    private var intValue: Int { Int(peakValue) ?? 0 }
    private var zone: PeakZone {
        if intValue >= 240 { return .green }
        if intValue >= 160 { return .yellow }
        return intValue > 0 ? .red : .none
    }
    
    private enum PeakZone { case green, yellow, red, none }
    
    private var zoneColor: Color {
        switch zone {
        case .green:  return .nafasSuccess
        case .yellow: return .nafasWarning
        case .red:    return .nafasDanger
        case .none:   return .nafasTextMuted
        }
    }
    
    // 🚀 FIX 1: Return the raw keys instead of NSLocalizedString
    private var zoneLabelKey: String {
        switch zone {
        case .green:  return "peak_zone_green_label"
        case .yellow: return "peak_zone_yellow_label"
        case .red:    return "peak_zone_red_label"
        case .none:   return "peak_zone_none_label"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 8)
                    
                    // Icon
                    ZStack {
                        Circle().fill(zoneColor.opacity(0.12)).frame(width: 90, height: 90)
                        Image(systemName: "lungs.fill")
                            .font(.system(size: 40)).foregroundStyle(zoneColor)
                    }
                    
                    // Value input
                    VStack(spacing: 8) {
                        Text(LocalizedStringKey("peak_flow_reading_label"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.nafasTextPrimary)
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            TextField("000", text: $peakValue)
                                .font(.system(size: 64, weight: .bold))
                                .foregroundStyle(zoneColor)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 160)
                            Text(LocalizedStringKey("L/min")) // 🚀 Wrapped unit
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.nafasTextMuted)
                        }
                        // Zone indicator
                        if intValue > 0 {
                            HStack(spacing: 6) {
                                Circle().fill(zoneColor).frame(width: 8, height: 8)
                                // 🚀 Wrapped dynamic label
                                Text(LocalizedStringKey(zoneLabelKey))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(zoneColor)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(zoneColor.opacity(0.10), in: Capsule())
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 20))
                    
                    // Zone reference guide
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStringKey("peak_zone_reference_label"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.nafasTextPrimary)
                        
                        // 🚀 FIX 2: Passing raw keys to the updated function
                        zoneGuideRow(color: .nafasSuccess, zoneKey: "peak_zone_green", descriptionKey: "peak_zone_green_desc")
                        zoneGuideRow(color: .nafasWarning, zoneKey: "peak_zone_yellow", descriptionKey: "peak_zone_yellow_desc")
                        zoneGuideRow(color: .nafasDanger,  zoneKey: "peak_zone_red", descriptionKey: "peak_zone_red_desc")
                    }
                    .padding(16)
                    .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Optional note
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey("peak_note_label"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.nafasTextPrimary)
                        
                        // 🚀 FIX 3: LocalizedStringKey for TextField Placeholder
                        TextField(LocalizedStringKey("peak_note_placeholder"), text: $note, axis: .vertical)
                            .font(.nafasBody())
                            .lineLimit(3, reservesSpace: true)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.nafasBackground)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.nafasDivider, lineWidth: 1))
                            )
                    }
                    
                    Button {
                        saveReading()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(LocalizedStringKey("peak_save_button"))
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .disabled(intValue == 0 || isSaving)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(intValue > 0 && !isSaving ? Color.nafasPrimary : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
            .background(Color.nafasBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("add_peak_flow_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(Color.nafasTextPrimary)
                    }
                }
            }
            .alert(LocalizedStringKey("peak_reading_saved_title"), isPresented: $showSuccess) {
                Button(LocalizedStringKey("peak_reading_saved_done")) { dismiss() }
            } message: {
                Text(String(format: NSLocalizedString("peak_reading_saved_message", comment: ""), intValue, child.name))
            }
        }
    }
    
    // 🚀 FIX 4: Function now accepts Keys and uses LocalizedStringKey
    private func zoneGuideRow(color: Color, zoneKey: String, descriptionKey: String) -> some View {
        HStack(spacing: 12) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(zoneKey)).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextPrimary)
                Text(LocalizedStringKey(descriptionKey)).font(.system(size: 12)).foregroundStyle(Color.nafasTextMuted)
            }
        }
    }
    
    private func saveReading() {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let now = Date()
            let df = DateFormatter()
            df.dateFormat = "EEE, d MMM"
            let tf = DateFormatter()
            tf.dateFormat = "hh:mm a"
            let entry = PeakFlowEntry(
                value: intValue,
                date: df.string(from: now),
                time: tf.string(from: now),
                note: note
            )
            store.addPeakFlow(childID: child.id.uuidString, entry: entry)
            isSaving = false
            showSuccess = true
        }
    }
}

//
//  NafasStore.swift
//  Nafas
//
//  Created by ghalia alkhaldi on 20/10/1447 AH.
//  Single source of truth for all data
//

import Foundation
import Combine

final class NafasStore: ObservableObject {
    static let shared = NafasStore()
    
    // MARK: - Published Properties
    @Published var children: [ChildModel] = []
    @Published var latestVitals: [String: VitalSnapshot] = [:]
    @Published var historyEntries: [String: [HistoryEntry]] = [:]
    @Published var peakFlowLogs: [String: [PeakFlowEntry]] = [:]
    
    // MARK: - Private Init
    private init() {
        loadMockData()
    }
    
    // MARK: - Mock Data (for development)
    private func loadMockData() {
        let calendar = Calendar.current
        let today = Date()
        
        // ── Locale-aware formatters ───────────────────────────────────────────
        // History rows: "Wed, 8 Apr 2026"  →  "الأربعاء، ٨ أبريل ٢٠٢٦" in AR
        let historyDateFmt = DateFormatter()
        historyDateFmt.setLocalizedDateFormatFromTemplate("EEE, d MMM yyyy")

        // Peak flow rows: "Wed, 8 Apr"  →  "الأربعاء، ٨ أبريل" in AR
        let shortDateFmt = DateFormatter()
        shortDateFmt.setLocalizedDateFormatFromTemplate("EEE, d MMM")

        // Time: "07:30 AM"  →  "٧:٣٠ ص" in AR
        let timeFmt = DateFormatter()
        timeFmt.timeStyle = .short
        timeFmt.dateStyle = .none

        // ── Mock dates ────────────────────────────────────────────────────────
        let mock1 = calendar.date(from: DateComponents(
            year: 2026, month: 4, day: 8, hour: 7, minute: 30))!
        let mock2 = calendar.date(from: DateComponents(
            year: 2026, month: 4, day: 8, hour: 5, minute: 45))!

        let histDate1 = historyDateFmt.string(from: mock1)   // e.g. "Wed, 8 Apr 2026"
        let histDate2 = historyDateFmt.string(from: mock2)
        let shortDate  = shortDateFmt.string(from: mock1)    // e.g. "Wed, 8 Apr"
        let time1      = timeFmt.string(from: mock1)          // e.g. "7:30 AM"
        let time2      = timeFmt.string(from: mock2)          // e.g. "5:45 AM"

        // ── Localized mock strings ────────────────────────────────────────────
        let lastSync = NSLocalizedString(
            "mock_last_sync_5min",
            comment: "Mock last-sync label shown in wristband connection detail")

        let noteLowInhaler = NSLocalizedString(
            "mock_peak_note_low_inhaler",
            comment: "Mock peak flow note — low reading, inhaler used")

        let noteNighttime = NSLocalizedString(
            "mock_peak_note_nighttime",
            comment: "Mock peak flow note — nighttime asthma episode")

        // ── Children ──────────────────────────────────────────────────────────
        // Single default account — Nora showing an asthma attack risk scenario
        children = [
            ChildModel(
                id: UUID(uuidString: "11111111-0000-0000-0000-000000000002")!,
                name: "Nora Al-Harbi",
                birthDate: calendar.date(byAdding: .year, value: -5, to: today)!,
                height: 110,
                weight: 18,
                gender: .female,
                isConnected: true,
                deviceID: "NF-7C4D",
                condition: nil,
                avatarColor: "#E0478A",
                guardianRelationship: .mother,
                avatarImageData: nil,
                emergencyPhoneNumbers: ["501234567"]
            )
        ]

        // ── Latest Vitals ─────────────────────────────────────────────────────
        latestVitals = [
            "11111111-0000-0000-0000-000000000002": VitalSnapshot(
                bp: "108/70",
                spO2: 91,
                iaq: 62,
                peakFlow: 195,
                bpStatus: .normal,
                spO2Status: .low,
                iaqStatus: .moderate,
                peakZone: .red,
                lastSync: lastSync,          // ← localized "5 min ago"
                deviceID: "NF-7C4D"
            )
        ]

        // ── History Entries ───────────────────────────────────────────────────
        historyEntries = [
            "11111111-0000-0000-0000-000000000002": [
                HistoryEntry(
                    date: histDate1, time: time1,  // ← locale-formatted
                    bp: "108/70", spO2: 91, iaq: 62, peakFlow: 195,
                    alertLevel: .danger
                ),
                HistoryEntry(
                    date: histDate2, time: time2,  // ← locale-formatted
                    bp: "106/68", spO2: 89, iaq: 70, peakFlow: 180,
                    alertLevel: .danger
                )
            ]
        ]

        // ── Peak Flow Logs ────────────────────────────────────────────────────
        peakFlowLogs = [
            "11111111-0000-0000-0000-000000000002": [
                PeakFlowEntry(
                    value: 195,
                    date: shortDate,           // ← locale-formatted
                    time: time1,               // ← locale-formatted
                    note: noteLowInhaler       // ← localized
                ),
                PeakFlowEntry(
                    value: 180,
                    date: shortDate,           // ← locale-formatted
                    time: time2,               // ← locale-formatted
                    note: noteNighttime        // ← localized
                )
            ]
        ]
    }
    
    // MARK: - CRUD Operations
    func addChild(_ child: ChildModel) {
        children.append(child)
    }
    
    func updateChild(_ child: ChildModel) {
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index] = child
        }
    }
    
    func deleteChild(_ childId: String) {
        children.removeAll { $0.id.uuidString == childId }
        latestVitals.removeValue(forKey: childId)
        historyEntries.removeValue(forKey: childId)
        peakFlowLogs.removeValue(forKey: childId)
    }
    
    func addPeakFlow(childID: String, entry: PeakFlowEntry) {
        // 1. Reassign the array to force the @Published dictionary to trigger a UI update
        var logs = peakFlowLogs[childID] ?? []
        logs.insert(entry, at: 0)
        peakFlowLogs[childID] = logs
        
        // 2. Update vitals for immediate UI refresh
        if var v = latestVitals[childID] {
            v.peakFlow = entry.value
            v.peakZone = entry.value >= 240 ? .green : entry.value >= 160 ? .yellow : .red
            latestVitals[childID] = v
        }
    }
    
    func addHistoryEntry(childID: String, entry: HistoryEntry) {
        if historyEntries[childID] == nil {
            historyEntries[childID] = []
        }
        historyEntries[childID]!.insert(entry, at: 0)
    }
    
    // MARK: - Helpers
    func vitals(for childID: String) -> VitalSnapshot? {
        latestVitals[childID]
    }
    
    func history(for childID: String) -> [HistoryEntry] {
        historyEntries[childID] ?? []
    }
    
    func peakFlows(for childID: String) -> [PeakFlowEntry] {
        peakFlowLogs[childID] ?? []
    }
}

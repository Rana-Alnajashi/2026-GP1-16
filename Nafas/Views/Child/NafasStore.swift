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
                emergencyPhoneNumbers: ["920000911", "0501234567"]
            )
        ]
        
        // Latest Vitals — Nora only
        latestVitals = [
            "11111111-0000-0000-0000-000000000002": VitalSnapshot(
                bp: "108/70", spO2: 91, iaq: 62, peakFlow: 195,
                bpStatus: .normal, spO2Status: .low, iaqStatus: .moderate,
                peakZone: .red, lastSync: "5 min ago", deviceID: "NF-7C4D"
            )
        ]
        
        // History Entries — Nora's attack history only
        historyEntries = [
            "11111111-0000-0000-0000-000000000002": [
                HistoryEntry(date: "Wed, 8 Apr 2026", time: "07:30 AM", bp: "108/70", spO2: 91, iaq: 62, peakFlow: 195, alertLevel: .danger),
                HistoryEntry(date: "Wed, 8 Apr 2026", time: "05:45 AM", bp: "106/68", spO2: 89, iaq: 70, peakFlow: 180, alertLevel: .danger),
            ]
        ]
        
        // Peak Flow Logs — Nora only
        peakFlowLogs = [
            "11111111-0000-0000-0000-000000000002": [
                PeakFlowEntry(value: 195, date: "Wed, 8 Apr", time: "07:30 AM", note: "Low — used inhaler"),
                PeakFlowEntry(value: 180, date: "Wed, 8 Apr", time: "05:45 AM", note: "Nighttime episode"),
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

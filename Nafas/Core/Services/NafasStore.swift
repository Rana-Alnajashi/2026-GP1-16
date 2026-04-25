import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class NafasStore: ObservableObject {
    static let shared = NafasStore()
    
    // MARK: - Published Properties
    @Published var children: [ChildModel] = []
    @Published var latestVitals: [String: VitalSnapshot] = [:]
    @Published var historyEntries: [String: [HistoryEntry]] = [:]
    @Published var peakFlowLogs: [String: [PeakFlowEntry]] = [:]
    
    private let db = Firestore.firestore(database: "nafas")
    
    // MARK: - Private Init
    private init() {
        // If a user is already logged in when the app starts, load their data!
        if Auth.auth().currentUser != nil {
            loadDataFromFirestore()
        }
    }
    
    // MARK: - Load Data from Firestore
    func loadDataFromFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // 1. Fetch Children
        db.collection("parents").document(uid).collection("children").addSnapshotListener { [weak self] snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            // Automatically decode Firestore data into our ChildModel
            self?.children = documents.compactMap { doc -> ChildModel? in
                return try? doc.data(as: ChildModel.self)
            }
        }
        
        // NOTE: For Phase 2, we will add listeners here to download PeakFlows and History as well!
    }
    
    // MARK: - CRUD Operations (Saving to Cloud)
    
    func addChild(_ child: ChildModel) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            // Save to Firestore
            try db.collection("parents").document(uid).collection("children").document(child.id.uuidString).setData(from: child)
            
            // Update UI immediately
            if !children.contains(where: { $0.id == child.id }) {
                children.append(child)
            }
        } catch {
            print("Error saving child to Firestore: \(error)")
        }
    }
    
    func updateChild(_ child: ChildModel) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try db.collection("parents").document(uid).collection("children").document(child.id.uuidString).setData(from: child)
            if let index = children.firstIndex(where: { $0.id == child.id }) {
                children[index] = child
            }
        } catch {
            print("Error updating child: \(error)")
        }
    }
    
    func deleteChild(_ childId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Delete from Firestore
        db.collection("parents").document(uid).collection("children").document(childId).delete()
        
        // Remove from UI
        children.removeAll { $0.id.uuidString == childId }
        latestVitals.removeValue(forKey: childId)
        historyEntries.removeValue(forKey: childId)
        peakFlowLogs.removeValue(forKey: childId)
    }
    
    func addPeakFlow(childID: String, entry: PeakFlowEntry) {
            // 1. Get the current parent's ID
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            // 2. Push to Firestore
            do {
                try db.collection("parents").document(uid)
                      .collection("children").document(childID)
                      .collection("peakFlows").document(entry.id.uuidString)
                      .setData(from: entry)
            } catch {
                print("Error saving Peak Flow to Firestore: \(error)")
            }
            
            // 3. Update the UI locally so the app still feels instantly fast
            var logs = peakFlowLogs[childID] ?? []
            logs.insert(entry, at: 0)
            peakFlowLogs[childID] = logs
            
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

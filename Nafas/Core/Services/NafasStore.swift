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
    private var historyListeners: [String: ListenerRegistration] = [:]
    private var peakFlowListeners: [String: ListenerRegistration] = [:] // 🚀 1. Added peak flow listeners tracker
    
    // MARK: - Private Init
    private init() {
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
            
            self?.children = documents.compactMap { doc -> ChildModel? in
                return try? doc.data(as: ChildModel.self)
            }
            
            // 🚀 2. Attach listeners for both History and Peak Flows for every child
            for child in self?.children ?? [] {
                self?.listenToHistory(childID: child.id.uuidString)
                self?.listenToPeakFlows(childID: child.id.uuidString)
            }
        }
    }
    
    // MARK: - Peak Flow Listener
    func listenToPeakFlows(childID: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        peakFlowListeners[childID]?.remove()
        
        peakFlowListeners[childID] = db.collection("parents").document(uid)
            .collection("children").document(childID)
            .collection("peakFlows")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("[PeakFlow] listener error: \(error.localizedDescription)")
                    return
                }
                
                guard let docs = snapshot?.documents else { return }
                
                let entries: [PeakFlowEntry] = docs.compactMap { doc in
                    try? doc.data(as: PeakFlowEntry.self)
                }
                
                DispatchQueue.main.async {
                    self?.peakFlowLogs[childID] = entries
                    
                    // Update latest vitals if entries exist
                    if let latest = entries.first, var vitals = self?.latestVitals[childID] {
                        vitals.peakFlow = latest.value
                        vitals.peakZone = latest.value >= 240 ? .green : latest.value >= 160 ? .yellow : .red
                        self?.latestVitals[childID] = vitals
                    }
                }
            }
    }
    
    // MARK: - History Listener
    func listenToHistory(childID: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        historyListeners[childID]?.remove()
     
        let dateFmt = DateFormatter()
        dateFmt.setLocalizedDateFormatFromTemplate("EEE, d MMM yyyy")
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "hh:mm a"
     
        historyListeners[childID] = db.collection("parents").document(uid)
            .collection("children").document(childID)
            .collection("history")
            .order(by: "timestamp", descending: true)
            .limit(to: 200)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("[History] listener error: \(error)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
     
                func num(_ v: Any?) -> Double? { (v as? NSNumber)?.doubleValue }
     
                let entries: [HistoryEntry] = docs.compactMap { doc -> HistoryEntry? in
                    let d = doc.data()
                    guard let ts = (d["timestamp"] as? Timestamp)?.dateValue(),
                          (d["status"] as? String) == "attack" else { return nil }

                    return HistoryEntry(
                        date: dateFmt.string(from: ts),
                        time: timeFmt.string(from: ts),
                        bp: num(d["bpm"]).map { String(Int($0)) },
                        spO2: num(d["spo2"]).map { Int($0) },
                        iaq: num(d["iaq"]).map { Int($0) },
                        peakFlow: num(d["pefr"]).map { Int($0) }
                    )
                }
                DispatchQueue.main.async { self?.historyEntries[childID] = entries }
            }
    }
    
    // MARK: - CRUD Operations
    func addChild(_ child: ChildModel) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try db.collection("parents").document(uid).collection("children").document(child.id.uuidString).setData(from: child)
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
        
        db.collection("parents").document(uid).collection("children").document(childId).delete()
        
        historyListeners[childId]?.remove()
        historyListeners.removeValue(forKey: childId)
        
        peakFlowListeners[childId]?.remove()
        peakFlowListeners.removeValue(forKey: childId)
        
        children.removeAll { $0.id.uuidString == childId }
        latestVitals.removeValue(forKey: childId)
        historyEntries.removeValue(forKey: childId)
        peakFlowLogs.removeValue(forKey: childId)
    }
    
    func addPeakFlow(childID: String, entry: PeakFlowEntry) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // 🚀 3. Use addDocument so Firestore handles the document ID automatically
        do {
            try db.collection("parents").document(uid)
                  .collection("children").document(childID)
                  .collection("peakFlows")
                  .addDocument(from: entry)
        } catch {
            print("Error saving Peak Flow to Firestore: \(error)")
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

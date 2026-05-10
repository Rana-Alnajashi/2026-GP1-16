import SwiftUI
import Combine

@MainActor
final class AddChildViewModel: ObservableObject {
    @Published var name = ""
    @Published var birthDate = Date()
    @Published var gender: ChildModel.Gender = .male
    @Published var height = ""
    @Published var weight = ""
    @Published var relationship: ChildModel.GuardianRelationship = .mother
    
    // 1. Changed from @State to @Published for the ViewModel
    @Published var emergencyContacts: [EmergencyContact] = []
    
    @Published var selectedColor = "#1F6FEB"
    @Published var selectedAvatarImage: UIImage?
    
    @Published var isSaving = false
    @Published var createdChild: ChildModel?
    
    let avatarColors = ["#1F6FEB", "#E0478A", "#34C759", "#AF52DE"]
    private let store = NafasStore.shared
    
    // 2. Updated to validate the new EmergencyContact array
    var arePhonesValid: Bool {
        if emergencyContacts.isEmpty { return true }
        return emergencyContacts.allSatisfy { $0.phoneNumber.count == 9 }
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && arePhonesValid
    }
    
    func saveChild() {
        isSaving = true
        
        // 3. Removed the old 'let phones = ...' string filtering logic
        
        let newChild = ChildModel(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            birthDate: birthDate,
            height: Int(height),
            weight: Int(weight),
            gender: gender,
            isConnected: false,
            deviceID: nil,
            condition: nil,
            avatarColor: selectedColor,
            guardianRelationship: relationship,
            avatarImageData: selectedAvatarImage?.jpegData(compressionQuality: 0.7),
            emergencyContacts: emergencyContacts // Pass the objects directly
        )
        
        store.addChild(newChild)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSaving = false
            self.createdChild = newChild
        }
    }
}

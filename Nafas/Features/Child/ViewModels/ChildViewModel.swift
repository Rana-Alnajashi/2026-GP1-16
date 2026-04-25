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
    @Published var emergencyPhoneNumbers: [String] = [""]
    @Published var selectedColor = "#1F6FEB"
    @Published var selectedAvatarImage: UIImage?
    
    @Published var isSaving = false
    @Published var createdChild: ChildModel?
    
    let avatarColors = ["#1F6FEB", "#E0478A", "#34C759", "#AF52DE"]
    private let store = NafasStore.shared
    
    var arePhonesValid: Bool {
        let activePhones = emergencyPhoneNumbers.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if activePhones.isEmpty { return true }
        return activePhones.allSatisfy { $0.count == 9 }
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && arePhonesValid
    }
    
    func saveChild() {
        isSaving = true
        let phones = emergencyPhoneNumbers.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
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
            emergencyPhoneNumbers: phones
        )
        
        store.addChild(newChild)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSaving = false
            self.createdChild = newChild
        }
    }
}

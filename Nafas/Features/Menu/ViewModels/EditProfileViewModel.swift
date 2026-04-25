import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class EditProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var phoneNumber: String = ""
    @Published var emailAddress: String = ""
    
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    
    var hasPhoneLinked: Bool { !phoneNumber.isEmpty }
    var hasEmailLinked: Bool { !emailAddress.isEmpty }
    
    private let db = Firestore.firestore(database: "nafas")
    
    init() {
        Task { await loadUserProfile() }
    }
    
    func loadUserProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        do {
            let document = try await db.collection("parents").document(uid).getDocument()
            if let data = document.data() {
                self.displayName = data["displayName"] as? String ?? ""
                self.phoneNumber = data["phone"] as? String ?? ""
                self.emailAddress = data["email"] as? String ?? ""
            }
        } catch {
            self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func saveName() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await db.collection("parents").document(uid).setData([
                "displayName": displayName.trimmingCharacters(in: .whitespaces)
            ], merge: true)
            
            await MainActor.run {
                UserProfileManager.shared.displayName = self.displayName.trimmingCharacters(in: .whitespaces)
                self.successMessage = "Profile updated successfully!"
                self.isSaving = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to save: \(error.localizedDescription)"
                self.isSaving = false
            }
        }
    }
    
    func linkGoogleAccount() async {
        do {
            let helper = SignInGoogleHelper()
            let tokens = try await helper.signIn()
            guard let currentUser = Auth.auth().currentUser else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
            
            let result = try await currentUser.link(with: credential)
            if let newEmail = result.user.email {
                try await db.collection("parents").document(currentUser.uid).setData([
                    "email": newEmail
                ], merge: true)
                self.emailAddress = newEmail
                self.successMessage = "Google Account Linked Successfully!"
            }
        } catch {
            self.errorMessage = "Could not link Google account: \(error.localizedDescription)"
        }
    }
}

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthenticationViewModel: ObservableObject {

    // MARK: - Properties
    @Published var fullName: String = ""
    @Published var countryCode: String = "+966"
    @Published var localPhoneNumber: String = ""
    @Published var verificationID: String? = nil
    @Published var otpCode: String = ""
    
    @Published var isPhoneAuthLoading: Bool = false
    @Published var phoneAuthError: String? = nil
    
    // 🚀 Tracks if the user clicked "New User" or "Existing Account"
    @Published var isRegistration: Bool = false

    var fullPhoneNumber: String { "\(countryCode)\(localPhoneNumber)" }
    var isPhoneInputValid: Bool { localPhoneNumber.count >= 9 }

    // MARK: - Google Sign-In
    func signInGoogle() async throws -> Bool {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        let result = try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
        
        return try await processDatabase(authUser: result)
    }

    // MARK: - Phone Auth
    func sendPhoneVerification() async {
        isPhoneAuthLoading = true
        phoneAuthError = nil
        do {
            verificationID = try await AuthenticationManager.shared.sendPhoneVerification(phoneNumber: fullPhoneNumber)
        } catch {
            phoneAuthError = error.localizedDescription
        }
        isPhoneAuthLoading = false
    }

    func verifyOTPAndSignIn() async throws -> Bool {
        guard let id = verificationID else { throw URLError(.badServerResponse) }
        let result = try await AuthenticationManager.shared.signInWithPhone(
            verificationID: id,
            verificationCode: otpCode
        )
        return try await processDatabase(authUser: result)
    }
    
    // MARK: - THE DATABASE GATEKEEPER
    private func processDatabase(authUser: AuthDataResultModel) async throws -> Bool {
        let db = Firestore.firestore(database: "nafas")
        let parentRef = db.collection("parents").document(authUser.uid)
        let document = try await parentRef.getDocument()
        
        if isRegistration {
            // 🟢 REGISTRATION FLOW
            if document.exists {
                phoneAuthError = "An account already exists. Please go back and Log In."
                try? Auth.auth().signOut()
                return false
            }
            
            let finalName = !fullName.trimmingCharacters(in: .whitespaces).isEmpty ? fullName : (authUser.name ?? "Parent")
            
            let newParentData: [String: Any] = [
                "uid": authUser.uid,
                "email": authUser.email ?? "",
                "phone": Auth.auth().currentUser?.phoneNumber ?? "",
                "displayName": finalName,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            try await parentRef.setData(newParentData)
            UserProfileManager.shared.displayName = finalName
            NafasStore.shared.loadDataFromFirestore()
            return true
            
        } else {
            // 🔵 LOGIN FLOW
            if document.exists {
                if let data = document.data(), let savedName = data["displayName"] as? String {
                    UserProfileManager.shared.displayName = savedName
                }
                NafasStore.shared.loadDataFromFirestore()
                return true
            } else {
                phoneAuthError = "No account found. Please go back and create a New User account."
                try? Auth.auth().signOut()
                return false
            }
        }
    }
}

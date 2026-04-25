import Foundation
import FirebaseAuth

struct AuthDataResultModel {
    let uid: String
    let email: String?
    let photoUrl: String?
    let isAnonymous: Bool
    
    // 👇 ADDED THESE TWO LINES 👇
    let name: String?
    let phoneNumber: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoUrl = user.photoURL?.absoluteString
        self.isAnonymous = user.isAnonymous
        
        // 👇 ADDED THESE TWO LINES 👇
        self.name = user.displayName
        self.phoneNumber = user.phoneNumber
    }
}

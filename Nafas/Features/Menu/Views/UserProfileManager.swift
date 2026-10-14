import Foundation
import Combine

final class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    private let nameKey   = "nafas_display_name"
    private let photoKey  = "nafas_photo_url"
    private let emailKey  = "nafas_email" // 👇 Added key for simulation
    
    @Published var displayName: String? {
        didSet {
            if let displayName = displayName {
                UserDefaults.standard.set(displayName, forKey: nameKey)
            } else {
                UserDefaults.standard.removeObject(forKey: nameKey)
            }
        }
    }
    
    @Published var photoURL: String? {
        didSet {
            if let photoURL = photoURL {
                UserDefaults.standard.set(photoURL, forKey: photoKey)
            } else {
                UserDefaults.standard.removeObject(forKey: photoKey)
            }
        }
    }

    // 👇 ADDED THIS FOR THE DEVELOPER SIMULATION
    @Published var email: String? {
        didSet {
            if let email = email {
                UserDefaults.standard.set(email, forKey: emailKey)
            } else {
                UserDefaults.standard.removeObject(forKey: emailKey)
            }
        }
    }

    private init() {
        self.displayName = UserDefaults.standard.string(forKey: nameKey)
        self.photoURL = UserDefaults.standard.string(forKey: photoKey)
        self.email = UserDefaults.standard.string(forKey: emailKey) // 👇 Load email on app start
        //self.email = "r18290230@gmail.com"
            
    }

    func clearProfile() {
        displayName = nil
        photoURL = nil
        email = nil // 👇 Cleared on logout
    }
}

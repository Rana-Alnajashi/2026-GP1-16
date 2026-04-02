//
//  UserProfileManager.swift
//  Nafas
//

import Foundation
import Combine

final class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    private let nameKey   = "nafas_display_name"
    private let photoKey  = "nafas_photo_url"

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

    private init() {
        self.displayName = UserDefaults.standard.string(forKey: nameKey)
        self.photoURL = UserDefaults.standard.string(forKey: photoKey)
    }

    func clearProfile() {
        displayName = nil
        photoURL = nil
    }
}

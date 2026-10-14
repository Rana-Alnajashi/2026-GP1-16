//
//  LocationManager.swift
//  Nafas
//
//  Created by Rana Alngashy on 05/10/2026.
//

import Foundation
import CoreLocation
import Combine


@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var permissionDenied = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        // 1. Diagnostic Check: Does the compiled app actually have the privacy key?
        if Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") == nil {
            print("🚨 FATAL ERROR: The privacy key is MISSING from the compiled app bundle. iOS is blocking the request.")
        } else {
            print("✅ Privacy key found in bundle! Triggering location request...")
            // 2. Force the request immediately when the manager is created
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func requestLocation() {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            self.permissionDenied = true
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 Auth Status Changed: \(manager.authorizationStatus.rawValue)")
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else { return }
        DispatchQueue.main.async {
            print("📍 Acquired Coordinates: \(latestLocation.coordinate.latitude), \(latestLocation.coordinate.longitude)")
            self.location = latestLocation.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 GPS Error on device: \(error.localizedDescription)")
    }
}

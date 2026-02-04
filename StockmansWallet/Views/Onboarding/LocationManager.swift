//
//  LocationManager.swift
//  StockmansWallet
//
//  Location Manager for onboarding property localization
//  Debug: Uses @Observable for modern SwiftUI state management
//

import SwiftUI
import CoreLocation
import Observation

// MARK: - Location Manager
// Debug: @Observable macro provides automatic change tracking
@Observable
class LocationManager: NSObject {
    private let manager = CLLocationManager()
    private var completion: ((CLLocation) -> Void)?
    private let delegate = LocationManagerDelegate()
    
    override init() {
        super.init()
        // Debug: Configure location manager with delegate and accuracy
        manager.delegate = delegate
        manager.desiredAccuracy = kCLLocationAccuracyBest
        delegate.completionHandler = { [weak self] location in
            DispatchQueue.main.async {
                self?.completion?(location)
                self?.completion = nil
            }
        }
    }
    
    func requestLocation(completion: @escaping (CLLocation) -> Void) {
        self.completion = completion
        
        // Debug: iOS 18+ minimum - authorizationStatus is always available
        let status = manager.authorizationStatus
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }
}

// MARK: - Location Manager Delegate
class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    var completionHandler: ((CLLocation) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            DispatchQueue.main.async { [weak self] in
                self?.completionHandler?(location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler = nil
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Debug: iOS 18+ minimum - authorizationStatus is always available
        let status = manager.authorizationStatus
        
        if status == .authorizedWhenInUse || .authorizedAlways == status {
            manager.requestLocation()
        }
    }
}


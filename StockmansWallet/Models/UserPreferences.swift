//
//  UserPreferences.swift
//  StockmansWallet
//
//  SwiftData Model for User Settings and Preferences
//

import Foundation
import SwiftData

// MARK: - User Role Enum
enum UserRole: String, Codable, CaseIterable {
    case farmerGrazier = "Farmer/Grazier"
    case agribusinessBanker = "Agribusiness Banker"
    case insurer = "Insurer"
    case livestockAgent = "Livestock Agent"
}

@Model
final class UserPreferences {
    var id: UUID
    var hasCompletedOnboarding: Bool
    
    // MARK: - Identity & Credentials
    var firstName: String?
    var lastName: String?
    var email: String?
    var profilePhotoData: Data? // Profile photo as Data
    
    // MARK: - Persona & Security
    var role: String? // UserRole as String for SwiftData compatibility
    var twoFactorEnabled: Bool
    var appsComplianceAccepted: Bool
    
    // MARK: - Property Localization
    var propertyName: String?
    var propertyPIC: String? // Property Identification Code
    var defaultState: String // "NSW", "VIC", "QLD", etc.
    var latitude: Double?
    var longitude: Double?
    
    // MARK: - Market & Logistics
    var defaultSaleyard: String?
    var region: String?
    var truckItEnabled: Bool
    
    // MARK: - Financial Ecosystem
    var xeroConnected: Bool
    var myobConnected: Bool
    
    // MARK: - Valuation Settings
    var defaultMortalityRate: Double // Annual percentage (e.g., 0.05 for 5%)
    var defaultCalvingRate: Double // Default for breeding stock (e.g., 0.85)
    
    // MARK: - Cost to Carry
    var monthlyAgistmentCost: Double
    var monthlyFeedCost: Double
    var monthlyVetCost: Double
    var freightCostPerKm: Double
    
    // MARK: - Display Preferences
    var currency: String // "AUD", "USD", etc.
    var weightUnit: String // "kg", "lbs"
    var dateFormat: String
    var backgroundImageName: String? // Name of selected background image
    
    init() {
        self.id = UUID()
        self.hasCompletedOnboarding = false
        self.firstName = nil
        self.lastName = nil
        self.email = nil
        self.profilePhotoData = nil
        self.role = nil
        self.twoFactorEnabled = false
        self.appsComplianceAccepted = false
        self.propertyName = nil
        self.propertyPIC = nil
        self.defaultState = "NSW"
        self.latitude = nil
        self.longitude = nil
        self.defaultSaleyard = nil
        self.region = nil
        self.truckItEnabled = false
        self.xeroConnected = false
        self.myobConnected = false
        self.defaultMortalityRate = 0.05 // 5% annual
        self.defaultCalvingRate = 0.85 // 85%
        self.monthlyAgistmentCost = 0.0
        self.monthlyFeedCost = 0.0
        self.monthlyVetCost = 0.0
        self.freightCostPerKm = 0.0
        self.currency = "AUD"
        self.weightUnit = "kg"
        self.dateFormat = "dd/MM/yyyy"
        self.backgroundImageName = "BackgroundDefault" // Default background image
    }
    
    // Helper to get/set role as enum
    var userRole: UserRole? {
        get {
            guard let roleString = role else { return nil }
            return UserRole(rawValue: roleString)
        }
        set {
            role = newValue?.rawValue
        }
    }
}


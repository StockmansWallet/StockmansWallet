//
//  Property.swift
//  StockmansWallet
//
//  SwiftData Model for Properties/Farms
//  Debug: Supports multiple properties with individual preferences
//

import Foundation
import SwiftData

// Debug: Property model for managing multiple farm properties
@Model
final class Property {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Property Identity
    var propertyName: String
    var propertyPIC: String? // Property Identification Code
    var isDefault: Bool // Primary/default property
    
    // MARK: - Location
    var state: String // "NSW", "VIC", "QLD", etc.
    var region: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    
    // MARK: - Property Details
    var acreage: Double? // Total property size
    var propertyType: String? // "Grazing", "Mixed", "Feedlot", etc.
    var notes: String?
    
    // MARK: - Market & Logistics Preferences
    var defaultSaleyard: String?
    var defaultSaleyardDistance: Double? // km
    
    // MARK: - Valuation Settings
    var mortalityRate: Double // Annual percentage (e.g., 0.05 for 5%)
    var calvingRate: Double // Default for breeding stock (e.g., 0.85)
    
    // MARK: - Cost to Carry (Property-specific)
    var monthlyAgistmentCost: Double
    var monthlyFeedCost: Double
    var monthlyVetCost: Double
    var freightCostPerKm: Double
    
    init(
        propertyName: String,
        propertyPIC: String? = nil,
        state: String = "QLD",
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.propertyName = propertyName
        self.propertyPIC = propertyPIC
        self.state = state
        self.isDefault = isDefault
        self.region = nil
        self.address = nil
        self.latitude = nil
        self.longitude = nil
        self.acreage = nil
        self.propertyType = nil
        self.notes = nil
        self.defaultSaleyard = nil
        self.defaultSaleyardDistance = nil
        self.mortalityRate = 0.05 // 5% default
        self.calvingRate = 0.85 // 85% default
        self.monthlyAgistmentCost = 0.0
        self.monthlyFeedCost = 0.0
        self.monthlyVetCost = 0.0
        self.freightCostPerKm = 0.0
    }
    
    // MARK: - Computed Properties
    
    /// Display name with PIC if available
    var displayName: String {
        if let pic = propertyPIC, !pic.isEmpty {
            return "\(propertyName) (PIC: \(pic))"
        }
        return propertyName
    }
    
    /// Full location string
    var locationDescription: String {
        var parts: [String] = []
        if let region = region, !region.isEmpty {
            parts.append(region)
        }
        parts.append(state)
        return parts.joined(separator: ", ")
    }
    
    /// Update timestamp
    func markUpdated() {
        self.updatedAt = Date()
    }
}


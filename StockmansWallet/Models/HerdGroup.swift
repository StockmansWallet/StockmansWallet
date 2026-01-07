//
//  HerdGroup.swift
//  StockmansWallet
//
//  SwiftData Model for Livestock Herd Groups
//  Debug: Enhanced with computed properties for better data access
//

import Foundation
import SwiftData

@Model
final class HerdGroup {
    // MARK: - Identification
    var id: UUID
    var name: String // Paddock name or herd identifier
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Biological Attributes
    var species: String // "Cattle", "Sheep", "Pig"
    var breed: String // From Appendix C breed list
    var sex: String // "Male", "Female"
    var category: String // Derived from taxonomy (e.g., "Weaner Steer", "Breeding Cow")
    var ageMonths: Int
    
    // MARK: - Physical Attributes
    var headCount: Int
    var initialWeight: Double // kg
    var currentWeight: Double // kg (calculated)
    var dailyWeightGain: Double // kg/day (DWG)
    var dwgChangeDate: Date? // Date when DWG was last changed
    var previousDWG: Double? // Previous DWG value for split calculation
    var useCreationDateForWeight: Bool // If true, calculate weight from creation date; if false, from today
    
    // MARK: - Breeding Status
    var isBreeder: Bool
    var isPregnant: Bool
    var joinedDate: Date? // Conception date
    var calvingRate: Double // Percentage (e.g., 0.85 for 85%)
    var lactationStatus: String? // "Lactating", "Dry"
    
    // MARK: - Market Mapping
    var selectedSaleyard: String? // From saleyard list
    var marketCategory: String? // Mapped market category
    
    // MARK: - Status
    var isSold: Bool
    var soldDate: Date?
    var soldPrice: Double? // Realized price per kg
    
    // MARK: - Location
    var paddockName: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    
    // MARK: - Additional Information
    var additionalInfo: String? // Notes, mortality rate, calves at foot, etc.
    var mortalityRate: Double? // Annual mortality rate as decimal (e.g., 0.05 for 5%)
    
    init(
        name: String,
        species: String,
        breed: String,
        sex: String,
        category: String,
        ageMonths: Int,
        headCount: Int,
        initialWeight: Double,
        dailyWeightGain: Double = 0.0,
        isBreeder: Bool = false,
        selectedSaleyard: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.species = species
        self.breed = breed
        self.sex = sex
        self.category = category
        self.ageMonths = ageMonths
        self.headCount = headCount
        self.initialWeight = initialWeight
        self.currentWeight = initialWeight
        self.dailyWeightGain = dailyWeightGain
        self.dwgChangeDate = nil
        self.previousDWG = nil
        self.useCreationDateForWeight = false // Default: calculate from today
        self.isBreeder = isBreeder
        self.isPregnant = false
        self.joinedDate = nil
        self.calvingRate = 0.85 // Default
        self.lactationStatus = nil
        self.selectedSaleyard = selectedSaleyard
        self.marketCategory = nil
        self.isSold = false
        self.soldDate = nil
        self.soldPrice = nil
        self.paddockName = nil
        self.locationLatitude = nil
        self.locationLongitude = nil
        self.additionalInfo = nil
        self.mortalityRate = nil
    }
    
    // MARK: - Computed Properties
    // Debug: Lightweight computed properties for common data access patterns
    
    /// Days the herd has been held (from creation to now or sold date)
    var daysHeld: Int {
        let endDate = isSold ? (soldDate ?? Date()) : Date()
        return Calendar.current.dateComponents([.day], from: createdAt, to: endDate).day ?? 0
    }
    
    /// Months the herd has been held
    var monthsHeld: Double {
        return Double(daysHeld) / 30.0
    }
    
    /// Display string for herd summary (used in lists and cards)
    var summaryDescription: String {
        return "\(headCount) head • \(breed) \(category)"
    }
    
    /// Full location description if available
    var locationDescription: String? {
        guard let lat = locationLatitude, let lon = locationLongitude else {
            return paddockName
        }
        if let paddock = paddockName, !paddock.isEmpty {
            return "\(paddock) (\(String(format: "%.4f", lat)), \(String(format: "%.4f", lon)))"
        }
        return "\(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))"
    }
    
    /// Check if breeding data is complete and valid
    var hasValidBreedingData: Bool {
        return isPregnant && joinedDate != nil && calvingRate > 0
    }
    
    /// Check if weight gain tracking is active
    var isTrackingWeightGain: Bool {
        return dailyWeightGain > 0
    }
    
    /// Simple projected weight calculation (for quick display only)
    /// Debug: For accurate valuations, use ValuationEngine.calculateProjectedWeight()
    var approximateCurrentWeight: Double {
        let days = Double(Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0)
        return initialWeight + (dailyWeightGain * days)
    }
    
    // MARK: - Utility Methods
    
    /// Update the DWG and track the change for split calculation
    func updateDailyWeightGain(newDWG: Double) {
        // Debug: Store previous DWG for split calculation in ValuationEngine
        self.previousDWG = self.dailyWeightGain
        self.dwgChangeDate = Date()
        self.dailyWeightGain = newDWG
        self.updatedAt = Date()
    }
    
    /// Mark the herd as sold with price and date
    func markAsSold(price: Double, date: Date = Date()) {
        // Debug: Record sale details and update status
        self.isSold = true
        self.soldPrice = price
        self.soldDate = date
        self.updatedAt = Date()
    }
    
    /// Update location data
    func updateLocation(paddock: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        // Debug: Update location details for market price localization
        if let paddock = paddock {
            self.paddockName = paddock
        }
        if let lat = latitude, let lon = longitude {
            self.locationLatitude = lat
            self.locationLongitude = lon
        }
        self.updatedAt = Date()
    }
}


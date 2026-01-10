//
//  SalesRecord.swift
//  StockmansWallet
//
//  SwiftData Model for Sales Transactions
//  Debug: Enhanced with pricing type, sale type, and location for better API data
//

import Foundation
import SwiftData

// Debug: Enum for pricing type - per kg or per head
enum PricingType: String, Codable {
    case perKg = "per_kg"
    case perHead = "per_head"
}

@Model
final class SalesRecord {
    var id: UUID
    var herdGroupId: UUID
    var saleDate: Date
    var headCount: Int
    var averageWeight: Double // kg
    var pricePerKg: Double // Debug: Always stored, calculated from pricePerHead if needed
    var pricePerHead: Double? // Debug: Optional - only used when pricingType is perHead
    var pricingType: String = "per_kg" // Debug: "per_kg" or "per_head" (stored as String for SwiftData, default for backward compatibility)
    var saleType: String? // Debug: "Saleyard", "Private Sale", "Other", etc.
    var saleLocation: String? // Debug: Name of saleyard or custom location
    var totalGrossValue: Double
    var freightCost: Double
    var freightDistance: Double // km
    var netValue: Double
    var notes: String?
    var pdfPath: String? // Path to generated Pro-forma PDF
    
    // Debug: Computed property to get PricingType enum from string (read-only for SwiftData compatibility)
    var pricingTypeEnum: PricingType {
        PricingType(rawValue: pricingType) ?? .perKg
    }
    
    init(
        herdGroupId: UUID,
        saleDate: Date,
        headCount: Int,
        averageWeight: Double,
        pricePerKg: Double,
        pricePerHead: Double? = nil,
        pricingType: PricingType = .perKg,
        saleType: String? = nil,
        saleLocation: String? = nil,
        totalGrossValue: Double,
        freightCost: Double = 0.0,
        freightDistance: Double = 0.0,
        netValue: Double,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.herdGroupId = herdGroupId
        self.saleDate = saleDate
        self.headCount = headCount
        self.averageWeight = averageWeight
        self.pricePerKg = pricePerKg
        self.pricePerHead = pricePerHead
        self.pricingType = pricingType.rawValue
        self.saleType = saleType
        self.saleLocation = saleLocation
        self.totalGrossValue = totalGrossValue
        self.freightCost = freightCost
        self.freightDistance = freightDistance
        self.netValue = netValue
        self.notes = notes
        self.pdfPath = nil
    }
}



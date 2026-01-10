//
//  SalesService.swift
//  StockmansWallet
//
//  Handles Sales Learning Loop and Pro-forma Sales Summary
//  Debug: Uses @Observable for modern SwiftUI state management
//

import Foundation
import SwiftData
import Observation

// Debug: @Observable provides automatic change tracking for SwiftUI
@Observable
class SalesService {
    static let shared = SalesService()
    
    // MARK: - Mark as Sold
    /// Marks a herd as sold and triggers the Sales Learning Loop
    // Debug: Enhanced with optional sale type and location parameters
    @MainActor
    func markHerdAsSold(
        herd: HerdGroup,
        saleDate: Date,
        realizedPrice: Double,
        freightDistance: Double?,
        modelContext: ModelContext,
        preferences: UserPreferences,
        pricingType: PricingType = .perKg,
        pricePerHead: Double? = nil,
        saleType: String? = nil,
        saleLocation: String? = nil
    ) async -> SalesRecord {
        HapticManager.tap()
        
        // Calculate freight cost if distance provided
        let freightCost = (freightDistance ?? 0.0) * preferences.freightCostPerKm
        
        // Debug: Calculate values based on pricing type
        let averageWeight = herd.currentWeight
        let totalGrossValue: Double
        
        if pricingType == .perKg {
            totalGrossValue = Double(herd.headCount) * averageWeight * realizedPrice
        } else {
            // Debug: Use price per head if provided, otherwise calculate from price per kg
            let perHeadPrice = pricePerHead ?? (averageWeight * realizedPrice)
            totalGrossValue = Double(herd.headCount) * perHeadPrice
        }
        
        let netValue = totalGrossValue - freightCost
        
        // Debug: Create sales record with new fields
        let salesRecord = SalesRecord(
            herdGroupId: herd.id,
            saleDate: saleDate,
            headCount: herd.headCount,
            averageWeight: averageWeight,
            pricePerKg: realizedPrice,
            pricePerHead: pricePerHead,
            pricingType: pricingType,
            saleType: saleType,
            saleLocation: saleLocation,
            totalGrossValue: totalGrossValue,
            freightCost: freightCost,
            freightDistance: freightDistance ?? 0.0,
            netValue: netValue
        )
        
        // Update herd status
        herd.isSold = true
        herd.soldDate = saleDate
        herd.soldPrice = realizedPrice
        
        // Save to context
        modelContext.insert(salesRecord)
        try? modelContext.save()
        
        HapticManager.success()
        
        return salesRecord
    }
    
    // MARK: - Generate Pro-forma Sales Summary
    /// Generates a PDF sales summary (placeholder for now)
    func generateSalesSummaryPDF(salesRecord: SalesRecord) -> URL? {
        // TODO: Implement actual PDF generation using PDFKit
        // This would create a professional pro-forma sales summary
        return nil
    }
}


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
    @MainActor
    func markHerdAsSold(
        herd: HerdGroup,
        saleDate: Date,
        realizedPrice: Double,
        freightDistance: Double?,
        modelContext: ModelContext,
        preferences: UserPreferences
    ) async -> SalesRecord {
        HapticManager.tap()
        
        // Calculate freight cost if distance provided
        let freightCost = (freightDistance ?? 0.0) * preferences.freightCostPerKm
        
        // Calculate values
        let averageWeight = herd.currentWeight
        let totalGrossValue = Double(herd.headCount) * averageWeight * realizedPrice
        let netValue = totalGrossValue - freightCost
        
        // Create sales record
        let salesRecord = SalesRecord(
            herdGroupId: herd.id,
            saleDate: saleDate,
            headCount: herd.headCount,
            averageWeight: averageWeight,
            pricePerKg: realizedPrice,
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


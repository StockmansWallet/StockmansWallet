//
//  ValuationEngine.swift
//  StockmansWallet
//
//  Core Valuation Engine implementing Appendix A formulas
//  Debug: Uses @Observable for modern SwiftUI state management
//

import Foundation
import SwiftData
import Observation

// Debug: @Observable macro provides automatic change tracking for SwiftUI
@Observable
class ValuationEngine {
    static let shared = ValuationEngine()
    
    // MARK: - Constants
    private let cattleGestationDays = 283
    private let sheepGestationDays = 150
    
    // MARK: - Weight Gain Calculation (Split Approach)
    /// Calculates projected weight using Scenario B: Split Calculation
    /// Formula: ProjectedWeight = WeightInitial + (DWG_Old × DaysPhase1) + (DWG_New × DaysPhase2)
    func calculateProjectedWeight(
        initialWeight: Double,
        dateStart: Date,
        dateChange: Date?,
        dateCurrent: Date,
        dwgOld: Double?,
        dwgNew: Double
    ) -> Double {
        let daysPhase1: Double
        let daysPhase2: Double
        
        if let dateChange = dateChange, let dwgOld = dwgOld {
            // Split calculation: DWG was changed
            daysPhase1 = max(0, dateChange.timeIntervalSince(dateStart) / 86400)
            daysPhase2 = max(0, dateCurrent.timeIntervalSince(dateChange) / 86400)
            return initialWeight + (dwgOld * daysPhase1) + (dwgNew * daysPhase2)
        } else {
            // Simple calculation: no DWG change
            daysPhase2 = max(0, dateCurrent.timeIntervalSince(dateStart) / 86400)
            return initialWeight + (dwgNew * daysPhase2)
        }
    }
    
    // MARK: - Breeding Value Accrual (Progressive Valuation)
    /// Calculates accrued value of pregnant stock
    /// Formula: TotalAccruedValue = ExpectedProgeny × (DaysElapsed / CycleLength) × ValueCalf
    func calculateBreedingAccrual(
        headCount: Int,
        calvingRate: Double,
        daysElapsed: Int,
        cycleLength: Int,
        valueCalf: Double
    ) -> Double {
        // Cap accrual percentage at 100%
        let accruedPct = min(1.0, Double(daysElapsed) / Double(cycleLength))
        
        // Calculate expected progeny
        let expectedProgeny = Double(headCount) * calvingRate
        
        // Calculate total accrued value
        let totalAccruedValue = expectedProgeny * accruedPct * valueCalf
        
        return totalAccruedValue
    }
    
    // MARK: - Mortality Risk Deduction
    /// Reduces herd value based on statistical mortality probability
    /// Formula: NetValue = GrossValue × (1 - EffectiveRate)
    /// EffectiveRate = MortalityRateAnnual × (DaysHeld / 365)
    func applyMortalityDeduction(
        grossValue: Double,
        mortalityRateAnnual: Double,
        daysHeld: Int
    ) -> Double {
        let effectiveRate = mortalityRateAnnual * (Double(daysHeld) / 365.0)
        let netValue = grossValue * (1.0 - effectiveRate)
        return netValue
    }
    
    // MARK: - Market Pricing (Fallback Hierarchy)
    /// Gets market price with fallback: Saleyard → State Indicator → National Benchmark
    /// Uses historical prices if asOfDate is provided
    func getMarketPrice(
        category: String,
        saleyard: String?,
        state: String?,
        modelContext: ModelContext,
        asOfDate: Date = Date()
    ) async -> (price: Double, source: String) {
        // Try direct saleyard quote first
        if let saleyard = saleyard {
            if let price = await fetchSaleyardPrice(category: category, saleyard: saleyard, modelContext: modelContext, asOfDate: asOfDate) {
                return (price, "Saleyard")
            }
        }
        
        // Fallback to state indicator
        if let state = state {
            if let price = await fetchStateIndicator(category: category, state: state, modelContext: modelContext, asOfDate: asOfDate) {
                return (price, "State Indicator")
            }
        }
        
        // Final fallback to national benchmark
        if let price = await fetchNationalBenchmark(category: category, modelContext: modelContext, asOfDate: asOfDate) {
            return (price, "National Benchmark")
        }
        
        // Default fallback price (should rarely happen)
        return (5.0, "Default")
    }
    
    // MARK: - Complete Valuation
    /// Calculates total portfolio value for a herd group
    /// Debug: Supports optional saleyard override for dashboard-level price filtering
    @MainActor
    func calculateHerdValue(
        herd: HerdGroup,
        preferences: UserPreferences,
        modelContext: ModelContext,
        asOfDate: Date = Date(),
        saleyardOverride: String? = nil
    ) async -> HerdValuation {
        // 1. Calculate projected weight
        let projectedWeight = calculateProjectedWeight(
            initialWeight: herd.initialWeight,
            dateStart: herd.createdAt,
            dateChange: herd.dwgChangeDate,
            dateCurrent: asOfDate,
            dwgOld: herd.previousDWG,
            dwgNew: herd.dailyWeightGain
        )
        
        // 2. Get market price (use historical price if asOfDate is provided)
        // Debug: Use saleyardOverride if provided (for dashboard comparison mode), 
        // otherwise use herd's configured saleyard (normal operation)
        let effectiveSaleyard = saleyardOverride ?? herd.selectedSaleyard
        let (pricePerKg, priceSource) = await getMarketPrice(
            category: herd.category,
            saleyard: effectiveSaleyard,
            state: preferences.defaultState,
            modelContext: modelContext,
            asOfDate: asOfDate
        )
        
        // 3. Calculate physical value (weight × price × head count)
        let physicalValue = Double(herd.headCount) * projectedWeight * pricePerKg
        
        // 4. Calculate breeding accrual if applicable
        var breedingAccrual: Double = 0.0
        if herd.isPregnant, let joinedDate = herd.joinedDate {
            let daysElapsed = Calendar.current.dateComponents([.day], from: joinedDate, to: asOfDate).day ?? 0
            let cycleLength = herd.species == "Cattle" ? cattleGestationDays : sheepGestationDays
            
            // Estimate calf value (simplified - could be enhanced)
            let calfValue = projectedWeight * 0.3 * pricePerKg // Rough estimate
            
            breedingAccrual = calculateBreedingAccrual(
                headCount: herd.headCount,
                calvingRate: herd.calvingRate,
                daysElapsed: daysElapsed,
                cycleLength: cycleLength,
                valueCalf: calfValue
            )
        }
        
        // 5. Calculate gross value
        let grossValue = physicalValue + breedingAccrual
        
        // 6. Apply mortality deduction
        let daysHeld = Calendar.current.dateComponents([.day], from: herd.createdAt, to: asOfDate).day ?? 0
        let netValue = applyMortalityDeduction(
            grossValue: grossValue,
            mortalityRateAnnual: preferences.defaultMortalityRate,
            daysHeld: daysHeld
        )
        
        // 7. Calculate cost to carry
        let monthsHeld = Double(daysHeld) / 30.0
        let costToCarry = (preferences.monthlyAgistmentCost + 
                          preferences.monthlyFeedCost + 
                          preferences.monthlyVetCost) * monthsHeld
        
        // 8. Calculate net realizable value
        let netRealizableValue = netValue - costToCarry
        
        return HerdValuation(
            herdId: herd.id,
            physicalValue: physicalValue,
            breedingAccrual: breedingAccrual,
            grossValue: grossValue,
            mortalityDeduction: grossValue - netValue,
            netValue: netValue,
            costToCarry: costToCarry,
            netRealizableValue: netRealizableValue,
            pricePerKg: pricePerKg,
            priceSource: priceSource,
            projectedWeight: projectedWeight,
            valuationDate: asOfDate
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchSaleyardPrice(category: String, saleyard: String, modelContext: ModelContext, asOfDate: Date = Date()) async -> Double? {
        // Find the most recent price on or before the asOfDate
        let descriptor = FetchDescriptor<MarketPrice>(
            predicate: #Predicate<MarketPrice> { price in
                price.category == category && 
                price.saleyard == saleyard &&
                price.priceDate <= asOfDate
            },
            sortBy: [SortDescriptor(\.priceDate, order: .reverse)]
        )
        
        if let cachedPrice = try? modelContext.fetch(descriptor).first {
            return cachedPrice.pricePerKg
        }
        
        // Fallback: use a default price based on the date (declining trend for 2023)
        let daysSince2023 = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: 1672531200), to: asOfDate).day ?? 0
        if daysSince2023 < 200 {
            // Early 2023 - higher prices
            return 7.2
        } else if daysSince2023 < 400 {
            // Mid 2023 - dip
            return 5.5
        } else {
            // Late 2023 onwards - recovery
            return 6.5
        }
    }
    
    private func fetchStateIndicator(category: String, state: String, modelContext: ModelContext, asOfDate: Date = Date()) async -> Double? {
        // Find the most recent state indicator price on or before the asOfDate
        let descriptor = FetchDescriptor<MarketPrice>(
            predicate: #Predicate<MarketPrice> { price in
                price.category == category &&
                price.state == state &&
                price.priceDate <= asOfDate
            },
            sortBy: [SortDescriptor(\.priceDate, order: .reverse)]
        )
        
        if let cachedPrice = try? modelContext.fetch(descriptor).first {
            return cachedPrice.pricePerKg
        }
        
        // Fallback price based on date
        let daysSince2023 = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: 1672531200), to: asOfDate).day ?? 0
        if daysSince2023 < 200 {
            return 7.0
        } else if daysSince2023 < 400 {
            return 5.3
        } else {
            return 6.2
        }
    }
    
    private func fetchNationalBenchmark(category: String, modelContext: ModelContext, asOfDate: Date = Date()) async -> Double? {
        // Find the most recent national benchmark price on or before the asOfDate
        let descriptor = FetchDescriptor<MarketPrice>(
            predicate: #Predicate<MarketPrice> { price in
                price.category == category &&
                price.source == "National Benchmark" &&
                price.priceDate <= asOfDate
            },
            sortBy: [SortDescriptor(\.priceDate, order: .reverse)]
        )
        
        if let cachedPrice = try? modelContext.fetch(descriptor).first {
            return cachedPrice.pricePerKg
        }
        
        // Fallback price based on date
        let daysSince2023 = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: 1672531200), to: asOfDate).day ?? 0
        if daysSince2023 < 200 {
            return 6.8
        } else if daysSince2023 < 400 {
            return 5.0
        } else {
            return 6.0
        }
    }
}

// MARK: - Valuation Result Model
struct HerdValuation {
    let herdId: UUID
    let physicalValue: Double
    let breedingAccrual: Double
    let grossValue: Double
    let mortalityDeduction: Double
    let netValue: Double
    let costToCarry: Double
    let netRealizableValue: Double
    let pricePerKg: Double
    let priceSource: String
    let projectedWeight: Double
    let valuationDate: Date
}


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
    
    // MARK: - Dependencies
    private let supabaseService = SupabaseMarketService.shared
    
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
    
    // MARK: - Category Mapping
    /// Maps app categories to MLA database categories
    /// Debug: Handles cases where app UI uses different terminology than MLA data
    private func mapCategoryToMLACategory(_ appCategory: String) -> String {
        // Map app categories to MLA categories used in database
        switch appCategory {
        case "Breeder":
            return "Breeding Cow"
        case "Weaner Heifer", "Heifer (Unjoined)", "Heifer (Joined)", "Feeder Heifer":
            return "Heifer"
        case "First Calf Heifer":
            return "Breeding Cow"
        case "Cull Cow":
            return "Dry Cow"
        case "Calves":
            return "Weaner Steer"
        case "Slaughter Cattle":
            return "Grown Steer"
        default:
            // Categories that match MLA directly (Yearling Steer, Grown Steer, etc.)
            return appCategory
        }
    }
    
    // MARK: - Market Pricing (Fallback Hierarchy)
    /// Gets market price with fallback: Saleyard → State → National
    /// Debug: Now fetches from Supabase category_prices table with real MLA data
    func getMarketPrice(
        category: String,
        breed: String,
        saleyard: String?,
        state: String?,
        modelContext: ModelContext,
        asOfDate: Date = Date()
    ) async -> (price: Double, source: String) {
        // Try direct saleyard quote first (with breed-specific pricing)
        if let saleyard = saleyard {
            if let price = await fetchSupabasePrice(category: category, breed: breed, saleyard: saleyard, state: nil) {
                return (price, "\(saleyard) - \(breed)")
            }
        }
        
        // Fallback to state-level pricing (with breed)
        if let state = state {
            if let price = await fetchSupabasePrice(category: category, breed: breed, saleyard: nil, state: state) {
                return (price, "\(state) - \(breed)")
            }
        }
        
        // Fallback to any available price for this category+breed combination
        if let price = await fetchSupabasePrice(category: category, breed: breed, saleyard: nil, state: nil) {
            return (price, "National - \(breed)")
        }
        
        // Default fallback price (should rarely happen)
        // Debug: Use category-specific default based on realistic market rates
        // Targets: Yearling Steer ~$4.10, Breeding Cow/Heifer ~$3.80
        // Comprehensive coverage for all livestock categories
        let defaultPrice: Double
        
        // Cattle categories
        if category.contains("Weaner") && (category.contains("Steer") || category.contains("Bull") || category.contains("Heifer")) {
            defaultPrice = 3.89 // ~$3.90/kg
        } else if category.contains("Yearling") && (category.contains("Steer") || category.contains("Bull")) {
            defaultPrice = 4.10 // Target price
        } else if (category.contains("Breeding") || (category.contains("Breeder") && !category.contains("Doe") && !category.contains("Buck"))) || category.contains("Heifer") || category.contains("Dry Cow") {
            defaultPrice = 3.80 // Target price for breeders
        } else if category.contains("Cull Cow") {
            defaultPrice = 3.14 // Cull animals typically lower
        } else if category.contains("Feeder") && (category.contains("Steer") || category.contains("Heifer")) {
            defaultPrice = 3.89 // ~$3.90/kg
        } else if category.contains("Grown") && (category.contains("Steer") || category.contains("Bull")) {
            defaultPrice = 3.30 // Base price
        } else if category.contains("Slaughter Cattle") {
            defaultPrice = 3.04 // Slaughter typically lower
        } else if category.contains("Calves") {
            defaultPrice = 4.13 // Calves premium
        }
        // Sheep categories (higher per kg)
        else if category.contains("Breeding Ewe") || category.contains("Maiden Ewe") || category.contains("Dry Ewe") {
            defaultPrice = 10.56
        } else if category.contains("Cull Ewe") || category.contains("Slaughter Ewe") {
            defaultPrice = 9.24
        } else if category.contains("Wether Lamb") || category.contains("Weaner Lamb") || category.contains("Feeder Lamb") {
            defaultPrice = 11.55
        } else if category.contains("Slaughter Lamb") || category.contains("Lambs") {
            defaultPrice = 10.89
        }
        // Pig categories
        else if (category.contains("Breeder") || category.contains("Dry Sow")) && category.contains("Sow") {
            defaultPrice = 2.18
        } else if category.contains("Cull Sow") {
            defaultPrice = 1.98
        } else if category.contains("Weaner Pig") || category.contains("Feeder Pig") {
            defaultPrice = 2.31
        } else if category.contains("Grower") || category.contains("Finisher") {
            defaultPrice = 2.15
        } else if category.contains("Porker") || category.contains("Baconer") {
            defaultPrice = 2.18
        }
        // Goat categories
        else if category.contains("Breeder Doe") || category.contains("Dry Doe") {
            defaultPrice = 4.29
        } else if category.contains("Cull Doe") {
            defaultPrice = 3.96
        } else if category.contains("Breeder Buck") || category.contains("Sale Buck") {
            defaultPrice = 4.46
        } else if category.contains("Mature Wether") || category.contains("Rangeland Goat") {
            defaultPrice = 4.29
        } else if category.contains("Capretto") {
            defaultPrice = 5.05 // Premium
        } else if category.contains("Chevon") {
            defaultPrice = 4.13
        }
        // Default fallback
        else {
            defaultPrice = 3.30 // Grown Steer base price
        }
        
        print("⚠️ ValuationEngine: No Supabase price found, using default fallback: $\(defaultPrice)/kg for \(category) (\(breed))")
        return (defaultPrice, "Default Fallback")
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
        // Debug: Use creation date if useCreationDateForWeight is true, otherwise use asOfDate
        let calculationDate = herd.useCreationDateForWeight ? herd.createdAt : asOfDate
        
        let projectedWeight = calculateProjectedWeight(
            initialWeight: herd.initialWeight,
            dateStart: herd.createdAt,
            dateChange: herd.dwgChangeDate,
            dateCurrent: calculationDate,
            dwgOld: herd.previousDWG,
            dwgNew: herd.dailyWeightGain
        )
        
        // 2. Get market price from Supabase (real MLA data with breed-specific pricing)
        // Debug: Use saleyardOverride if provided (for dashboard comparison mode), 
        // otherwise use herd's configured saleyard (normal operation)
        let effectiveSaleyard = saleyardOverride ?? herd.selectedSaleyard
        let (pricePerKg, priceSource) = await getMarketPrice(
            category: herd.category,
            breed: herd.breed,
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
    
    /// Fetches price from Supabase category_prices table (real MLA data)
    /// Debug: Replaces old local MarketPrice database queries
    private func fetchSupabasePrice(category: String, breed: String, saleyard: String?, state: String?) async -> Double? {
        do {
            // Debug: Map app category to MLA category for database query
            let mlaCategory = mapCategoryToMLACategory(category)
            
            // Fetch prices from Supabase with filters
            let prices = try await supabaseService.fetchCategoryPrices(
                categories: [mlaCategory],
                saleyard: saleyard,
                state: state,
                breed: breed
            )
            
            // Find exact match for this category + breed
            if let matchingPrice = prices.first(where: { $0.category == mlaCategory && $0.breed == breed }) {
                print("✅ ValuationEngine: Found Supabase price for \(category) [→\(mlaCategory)] (\(breed)): $\(matchingPrice.price)/kg from \(matchingPrice.source)")
                return matchingPrice.price
            }
            
            // If no exact match, log and return nil to try next fallback
            print("⚠️ ValuationEngine: No Supabase price found for \(category) [→\(mlaCategory)] (\(breed)) with saleyard=\(saleyard ?? "any"), state=\(state ?? "any")")
            return nil
            
        } catch {
            print("❌ ValuationEngine: Error fetching from Supabase: \(error)")
            return nil
        }
    }
    
    // DEPRECATED: Old method kept for reference, now using fetchSupabasePrice
    private func fetchSaleyardPrice_OLD(category: String, saleyard: String, modelContext: ModelContext, asOfDate: Date = Date()) async -> Double? {
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
        
        // Fallback: use category-specific default prices based on realistic market rates
        // Debug: Comprehensive coverage for all livestock categories
        // Targets: Yearling Steer ~$4.10, Breeding Cow/Heifer ~$3.80
        
        // Cattle categories
        if category.contains("Weaner") && (category.contains("Steer") || category.contains("Bull") || category.contains("Heifer")) {
            return 3.89
        } else if category.contains("Yearling") && (category.contains("Steer") || category.contains("Bull")) {
            return 4.10
        } else if (category.contains("Breeding") || (category.contains("Breeder") && !category.contains("Doe") && !category.contains("Buck"))) || category.contains("Heifer") || category.contains("Dry Cow") {
            return 3.80
        } else if category.contains("Cull Cow") {
            return 3.14
        } else if category.contains("Feeder") && (category.contains("Steer") || category.contains("Heifer")) {
            return 3.89
        } else if category.contains("Grown") && (category.contains("Steer") || category.contains("Bull")) {
            return 3.30
        } else if category.contains("Slaughter Cattle") {
            return 3.04
        } else if category.contains("Calves") {
            return 4.13
        }
        // Sheep categories
        else if category.contains("Breeding Ewe") || category.contains("Maiden Ewe") || category.contains("Dry Ewe") {
            return 10.56
        } else if category.contains("Cull Ewe") || category.contains("Slaughter Ewe") {
            return 9.24
        } else if category.contains("Wether Lamb") || category.contains("Weaner Lamb") || category.contains("Feeder Lamb") {
            return 11.55
        } else if category.contains("Slaughter Lamb") || category.contains("Lambs") {
            return 10.89
        }
        // Pig categories
        else if (category.contains("Breeder") || category.contains("Dry Sow")) && category.contains("Sow") {
            return 2.18
        } else if category.contains("Cull Sow") {
            return 1.98
        } else if category.contains("Weaner Pig") || category.contains("Feeder Pig") {
            return 2.31
        } else if category.contains("Grower") || category.contains("Finisher") {
            return 2.15
        } else if category.contains("Porker") || category.contains("Baconer") {
            return 2.18
        }
        // Goat categories
        else if category.contains("Breeder Doe") || category.contains("Dry Doe") {
            return 4.29
        } else if category.contains("Cull Doe") {
            return 3.96
        } else if category.contains("Breeder Buck") || category.contains("Sale Buck") {
            return 4.46
        } else if category.contains("Mature Wether") || category.contains("Rangeland Goat") {
            return 4.29
        } else if category.contains("Capretto") {
            return 5.05
        } else if category.contains("Chevon") {
            return 4.13
        }
        return 3.30 // Grown Steer base price (default)
    }
    
    // DEPRECATED: Old method kept for reference, now using fetchSupabasePrice
    private func fetchStateIndicator_OLD(category: String, state: String, modelContext: ModelContext, asOfDate: Date = Date()) async -> Double? {
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
        
        // Fallback: use category-specific default prices based on realistic market rates
        // Debug: Comprehensive coverage for all livestock categories
        // Targets: Yearling Steer ~$4.10, Breeding Cow/Heifer ~$3.80
        
        // Cattle categories
        if category.contains("Weaner") && (category.contains("Steer") || category.contains("Bull") || category.contains("Heifer")) {
            return 3.89
        } else if category.contains("Yearling") && (category.contains("Steer") || category.contains("Bull")) {
            return 4.10
        } else if (category.contains("Breeding") || (category.contains("Breeder") && !category.contains("Doe") && !category.contains("Buck"))) || category.contains("Heifer") || category.contains("Dry Cow") {
            return 3.80
        } else if category.contains("Cull Cow") {
            return 3.14
        } else if category.contains("Feeder") && (category.contains("Steer") || category.contains("Heifer")) {
            return 3.89
        } else if category.contains("Grown") && (category.contains("Steer") || category.contains("Bull")) {
            return 3.30
        } else if category.contains("Slaughter Cattle") {
            return 3.04
        } else if category.contains("Calves") {
            return 4.13
        }
        // Sheep categories
        else if category.contains("Breeding Ewe") || category.contains("Maiden Ewe") || category.contains("Dry Ewe") {
            return 10.56
        } else if category.contains("Cull Ewe") || category.contains("Slaughter Ewe") {
            return 9.24
        } else if category.contains("Wether Lamb") || category.contains("Weaner Lamb") || category.contains("Feeder Lamb") {
            return 11.55
        } else if category.contains("Slaughter Lamb") || category.contains("Lambs") {
            return 10.89
        }
        // Pig categories
        else if (category.contains("Breeder") || category.contains("Dry Sow")) && category.contains("Sow") {
            return 2.18
        } else if category.contains("Cull Sow") {
            return 1.98
        } else if category.contains("Weaner Pig") || category.contains("Feeder Pig") {
            return 2.31
        } else if category.contains("Grower") || category.contains("Finisher") {
            return 2.15
        } else if category.contains("Porker") || category.contains("Baconer") {
            return 2.18
        }
        // Goat categories
        else if category.contains("Breeder Doe") || category.contains("Dry Doe") {
            return 4.29
        } else if category.contains("Cull Doe") {
            return 3.96
        } else if category.contains("Breeder Buck") || category.contains("Sale Buck") {
            return 4.46
        } else if category.contains("Mature Wether") || category.contains("Rangeland Goat") {
            return 4.29
        } else if category.contains("Capretto") {
            return 5.05
        } else if category.contains("Chevon") {
            return 4.13
        }
        return 3.30 // Grown Steer base price (default)
    }
    
    // DEPRECATED: Old method kept for reference, now using fetchSupabasePrice
    private func fetchNationalBenchmark_OLD(category: String, modelContext: ModelContext, asOfDate: Date = Date()) async -> Double? {
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
        
        // Fallback: use category-specific default prices based on realistic market rates
        // Debug: Comprehensive coverage for all livestock categories
        // Targets: Yearling Steer ~$4.10, Breeding Cow/Heifer ~$3.80
        
        // Cattle categories
        if category.contains("Weaner") && (category.contains("Steer") || category.contains("Bull") || category.contains("Heifer")) {
            return 3.89
        } else if category.contains("Yearling") && (category.contains("Steer") || category.contains("Bull")) {
            return 4.10
        } else if (category.contains("Breeding") || (category.contains("Breeder") && !category.contains("Doe") && !category.contains("Buck"))) || category.contains("Heifer") || category.contains("Dry Cow") {
            return 3.80
        } else if category.contains("Cull Cow") {
            return 3.14
        } else if category.contains("Feeder") && (category.contains("Steer") || category.contains("Heifer")) {
            return 3.89
        } else if category.contains("Grown") && (category.contains("Steer") || category.contains("Bull")) {
            return 3.30
        } else if category.contains("Slaughter Cattle") {
            return 3.04
        } else if category.contains("Calves") {
            return 4.13
        }
        // Sheep categories
        else if category.contains("Breeding Ewe") || category.contains("Maiden Ewe") || category.contains("Dry Ewe") {
            return 10.56
        } else if category.contains("Cull Ewe") || category.contains("Slaughter Ewe") {
            return 9.24
        } else if category.contains("Wether Lamb") || category.contains("Weaner Lamb") || category.contains("Feeder Lamb") {
            return 11.55
        } else if category.contains("Slaughter Lamb") || category.contains("Lambs") {
            return 10.89
        }
        // Pig categories
        else if (category.contains("Breeder") || category.contains("Dry Sow")) && category.contains("Sow") {
            return 2.18
        } else if category.contains("Cull Sow") {
            return 1.98
        } else if category.contains("Weaner Pig") || category.contains("Feeder Pig") {
            return 2.31
        } else if category.contains("Grower") || category.contains("Finisher") {
            return 2.15
        } else if category.contains("Porker") || category.contains("Baconer") {
            return 2.18
        }
        // Goat categories
        else if category.contains("Breeder Doe") || category.contains("Dry Doe") {
            return 4.29
        } else if category.contains("Cull Doe") {
            return 3.96
        } else if category.contains("Breeder Buck") || category.contains("Sale Buck") {
            return 4.46
        } else if category.contains("Mature Wether") || category.contains("Rangeland Goat") {
            return 4.29
        } else if category.contains("Capretto") {
            return 5.05
        } else if category.contains("Chevon") {
            return 4.13
        }
        return 3.30 // Grown Steer base price (default)
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


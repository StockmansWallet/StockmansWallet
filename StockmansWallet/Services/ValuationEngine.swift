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
    
    // MARK: - Price Cache
    // Debug: Cache fetched prices to avoid redundant API calls
    // MLA data updates once daily at 1am, so cache for 24 hours
    private var priceCache: [String: (price: Double, source: String)] = [:]
    private var priceCacheTimestamp: Date? = nil
    private let priceCacheDuration: TimeInterval = 86400 // 24 hours (MLA updates daily)
    
    // Debug: Offline state tracking
    var isOffline: Bool = false
    
    // Debug: Session state - tracks if dashboard has loaded data this app session
    // Persists across view recreations (tab switches, navigation) to prevent unnecessary reloads
    var dashboardHasLoadedThisSession: Bool = false
    
    // Debug: Generate cache key for price lookups
    private func priceCacheKey(category: String, breed: String, saleyard: String?, state: String?) -> String {
        return "\(category)|\(breed)|\(saleyard ?? "nil")|\(state ?? "nil")"
    }
    
    // Debug: Check if cache is from before the last 1:30am MLA update
    // MLA scraper runs at 1am daily, check for 1:30am to allow 30min for server processing
    private func isCacheFromBeforeLastMLAUpdate() -> Bool {
        guard let timestamp = priceCacheTimestamp else { return true }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Get today's 1:30am (MLA scraper runs at 1am, 30min buffer for processing)
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 1
        components.minute = 30  // 30-minute buffer for server to fetch & populate data
        components.second = 0
        
        guard let todayOneThirtyAM = calendar.date(from: components) else { return false }
        
        // If it's currently before 1:30am, check against yesterday's 1:30am
        let lastMLAUpdate: Date
        if now < todayOneThirtyAM {
            // Before 1:30am today, so last update was yesterday at 1:30am
            lastMLAUpdate = calendar.date(byAdding: .day, value: -1, to: todayOneThirtyAM) ?? todayOneThirtyAM
        } else {
            // After 1:30am today, so last update was today at 1:30am
            lastMLAUpdate = todayOneThirtyAM
        }
        
        // Cache is stale if it's older than the last 1:30am update
        let isStale = timestamp < lastMLAUpdate
        
        #if DEBUG
        if isStale {
            let hoursSinceCache = Date().timeIntervalSince(timestamp) / 3600
            print("🔵 Cache is from before last 1:30am MLA update (\(String(format: "%.1f", hoursSinceCache))h ago), needs refresh")
        }
        #endif
        
        return isStale
    }
    
    // Debug: Check if price cache is still fresh
    // Fresh = within 24 hours AND not from before last 1:30am MLA update
    private func isPriceCacheFresh() -> Bool {
        guard let timestamp = priceCacheTimestamp else { return false }
        
        // Check if cache is from before last 1:30am update (primary check)
        if isCacheFromBeforeLastMLAUpdate() {
            return false
        }
        
        // Check age (24 hour fallback for safety, though 1:30am check should catch it)
        let age = Date().timeIntervalSince(timestamp)
        let isFresh = age < priceCacheDuration
        
        #if DEBUG
        if isFresh {
            let hoursOld = age / 3600
            print("✅ Price cache is fresh (\(String(format: "%.1f", hoursOld))h old, valid until next 1:30am)")
        }
        #endif
        
        return isFresh
    }
    
    // Debug: Clear price cache (forces fresh fetch)
    func clearPriceCache() {
        priceCache = [:]
        priceCacheTimestamp = nil
        print("🔵 Debug: ValuationEngine price cache cleared")
    }
    
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
    
    // MARK: - Batch Price Prefetch
    /// Pre-fetches all prices for a list of herds in ONE API call
    /// Debug: Dramatically reduces API calls from hundreds to ONE
    func prefetchPricesForHerds(_ herds: [HerdGroup]) async {
        // Debug: Skip if cache is still fresh
        if isPriceCacheFresh() && !priceCache.isEmpty {
            print("✅ Debug: Using cached prices (age: \(Int(Date().timeIntervalSince(priceCacheTimestamp!)))s)")
            return
        }
        
        // Debug: If offline and we have cached prices, keep using them
        if isOffline && !priceCache.isEmpty {
            print("⚠️ Debug: Offline - keeping cached prices")
            return
        }
        
        // Collect all unique category+breed+saleyard combinations
        var uniqueCombos: Set<String> = []
        var categories: Set<String> = []
        var breeds: Set<String> = []
        var saleyards: Set<String> = []
        
        for herd in herds where !herd.isSold {
            let mlaCategory = mapCategoryToMLACategory(herd.category)
            categories.insert(mlaCategory)
            breeds.insert(herd.breed)
            if let saleyard = herd.selectedSaleyard {
                saleyards.insert(saleyard)
            }
            uniqueCombos.insert("\(mlaCategory)|\(herd.breed)|\(herd.selectedSaleyard ?? "nil")")
        }
        
        print("🔵 Debug: Batch prefetching prices for \(uniqueCombos.count) unique combinations")
        print("   Categories: \(categories.sorted().joined(separator: ", "))")
        print("   Breeds: \(Array(breeds.prefix(10)).sorted().joined(separator: ", "))\(breeds.count > 10 ? "..." : "")")
        print("   Saleyards: \(Array(saleyards.prefix(5)).sorted().joined(separator: ", "))\(saleyards.count > 5 ? "..." : "")")
        
        do {
            // Fetch ALL prices in ONE query
            let prices = try await supabaseService.fetchCategoryPrices(
                categories: Array(categories),
                saleyard: nil, // Get all saleyards
                state: nil, // Get all states
                states: nil, // Don't filter by state - get nationwide data
                breed: nil // Get all breeds
            )
            
            print("✅ Debug: Batch fetched \(prices.count) prices from Supabase")
            
            // Clear old cache and populate with new data
            priceCache = [:]
            
            // Index prices by all possible lookup patterns
            for price in prices {
                // Cache by saleyard+breed
                if !price.source.isEmpty {
                    let key1 = priceCacheKey(category: price.category, breed: price.breed ?? "general", saleyard: price.source, state: nil)
                    priceCache[key1] = (price.price, price.source)
                }
                
                // Cache by category+breed only (national/general)
                let key2 = priceCacheKey(category: price.category, breed: price.breed ?? "general", saleyard: nil, state: nil)
                if priceCache[key2] == nil { // Only if not already set by more specific price
                    priceCache[key2] = (price.price, price.source)
                }
            }
            
            // Update cache timestamp
            priceCacheTimestamp = Date()
            
            // Debug: Reset offline status on MainActor so SwiftUI immediately reacts
            await MainActor.run {
                self.isOffline = false
            }
            
            print("✅ Debug: Price cache populated with \(priceCache.count) entries")
            
        } catch {
            // Debug: Check if error is task cancellation (Code -999) - not a real network failure
            let nsError = error as NSError
            let isCancellation = nsError.code == NSURLErrorCancelled
            
            // Debug: Check for other transient errors that aren't "offline" scenarios
            let isTransientError = [
                NSURLErrorCancelled,           // -999: Task was cancelled by app
                NSURLErrorNetworkConnectionLost, // -1005: Connection dropped mid-request (can recover)
            ].contains(nsError.code)
            
            if isCancellation {
                print("⚠️ Debug: Batch prefetch cancelled (task interrupted)")
                // Don't mark as offline - this is expected when navigating away
            } else if isTransientError {
                print("⚠️ Debug: Batch prefetch had transient error (code \(nsError.code)), will retry later")
                // Don't mark as offline - transient errors can recover
            } else {
                print("❌ Debug: Batch prefetch failed with network error: \(error.localizedDescription) (code: \(nsError.code))")
                // Debug: Only mark as offline on MainActor so SwiftUI immediately reacts
                await MainActor.run {
                    self.isOffline = true
                }
            }
            // Keep existing cache if available
        }
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
    /// Gets market price with fallback: Cache → Saleyard → State → National → Default
    /// Debug: Now checks cache first to avoid redundant API calls
    func getMarketPrice(
        category: String,
        breed: String,
        saleyard: String?,
        state: String?,
        modelContext: ModelContext,
        asOfDate: Date = Date()
    ) async -> (price: Double, source: String) {
        let mlaCategory = mapCategoryToMLACategory(category)
        
        // Debug: Check cache first (saleyard level)
        if let saleyard = saleyard {
            let key = priceCacheKey(category: mlaCategory, breed: breed, saleyard: saleyard, state: nil)
            if let cached = priceCache[key] {
                return cached
            }
        }
        
        // Debug: Check cache (state level)
        if let state = state {
            let key = priceCacheKey(category: mlaCategory, breed: breed, saleyard: nil, state: state)
            if let cached = priceCache[key] {
                return cached
            }
        }
        
        // Debug: Check cache (national level)
        let nationalKey = priceCacheKey(category: mlaCategory, breed: breed, saleyard: nil, state: nil)
        if let cached = priceCache[nationalKey] {
            return cached
        }
        
        // Debug: Cache miss - fetch from Supabase (fallback for individual lookups)
        // This should rarely happen if prefetchPricesForHerds was called first
        print("⚠️ Debug: Cache miss for \(category) (\(breed)) - fetching individually")
        
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
        // Debug: Always calculate weight dynamically from today's date for accurate projections
        let projectedWeight = calculateProjectedWeight(
            initialWeight: herd.initialWeight,
            dateStart: herd.createdAt,
            dateChange: herd.dwgChangeDate,
            dateCurrent: asOfDate,
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
            
            // Debug: Estimate newborn progeny value based on realistic birth weights
            // Cattle calves: ~7% of mother's weight (35-40kg from 500-550kg cow)
            // Sheep lambs: ~8% of mother's weight (5-6kg from 60-70kg ewe)
            let birthWeightRatio = herd.species == "Cattle" ? 0.07 : 0.08
            let calfValue = projectedWeight * birthWeightRatio * pricePerKg
            
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
            
            // Debug: Cache ALL returned prices for future use (prevents duplicate fetches)
            for price in prices {
                // Cache by saleyard+breed if saleyard exists
                if !price.source.isEmpty {
                    let key1 = priceCacheKey(category: price.category, breed: price.breed ?? "general", saleyard: price.source, state: nil)
                    if priceCache[key1] == nil { // Don't overwrite existing cache entries
                        priceCache[key1] = (price.price, price.source)
                    }
                }
                
                // Cache by category+breed only (national/general)
                let key2 = priceCacheKey(category: price.category, breed: price.breed ?? "general", saleyard: nil, state: nil)
                if priceCache[key2] == nil {
                    priceCache[key2] = (price.price, price.source)
                }
            }
            
            // Debug: Successfully fetched prices - reset offline status on MainActor
            await MainActor.run {
                self.isOffline = false
            }
            
            // Find exact match for this category + breed
            if let matchingPrice = prices.first(where: { $0.category == mlaCategory && $0.breed == breed }) {
                print("✅ ValuationEngine: Found Supabase price for \(category) [→\(mlaCategory)] (\(breed)): $\(matchingPrice.price)/kg from \(matchingPrice.source)")
                return matchingPrice.price
            }
            
            // If no exact match, log and return nil to try next fallback
            print("⚠️ ValuationEngine: No Supabase price found for \(category) [→\(mlaCategory)] (\(breed)) with saleyard=\(saleyard ?? "any"), state=\(state ?? "any")")
            return nil
            
        } catch {
            // Debug: Check if error is task cancellation or transient - not a real network failure
            let nsError = error as NSError
            let isTransientError = [
                NSURLErrorCancelled,           // -999: Task was cancelled by app
                NSURLErrorNetworkConnectionLost, // -1005: Connection dropped mid-request (can recover)
            ].contains(nsError.code)
            
            if !isTransientError {
                print("❌ ValuationEngine: Error fetching from Supabase: \(error) (code: \(nsError.code))")
                // Debug: Only mark as offline on MainActor for genuine network failures
                await MainActor.run {
                    self.isOffline = true
                }
            } else {
                print("⚠️ ValuationEngine: Individual fetch had transient error (code \(nsError.code)), will use fallback")
            }
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


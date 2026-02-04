//
//  MarketViewModel.swift
//  StockmansWallet
//
//  Market View Model - manages market data state and business logic
//  Debug: Uses @Observable for modern SwiftUI state management
//

import Foundation
import SwiftData
import Observation

// MARK: - Market View Model
// Debug: @Observable provides automatic change tracking for SwiftUI views
@Observable
class MarketViewModel {
    // MARK: - Published State
    var topInsight: TopInsight? = nil
    var nationalIndicators: [NationalIndicator] = []
    var categoryPrices: [CategoryPrice] = []
    var historicalPrices: [HistoricalPricePoint] = []
    var regionalPrices: [RegionalPrice] = []
    var saleyardReports: [SaleyardReport] = []
    var marketIntelligence: [MarketIntelligence] = []
    var physicalSalesReport: PhysicalSalesReport? = nil // Debug: Physical sales data from MLA
    
    // MARK: - UI State
    var isLoadingInsight = false
    var isLoadingIndicators = false
    var isLoadingPrices = false
    var isLoadingHistory = false
    var isLoadingRegional = false
    var isLoadingReports = false
    var isLoadingIntelligence = false
    var isLoadingPhysicalReport = false // Debug: Loading state for physical report
    var lastUpdated: Date? = nil
    var errorMessage: String? = nil
    
    // MARK: - Cache Timestamps
    // Debug: Track when each data type was last loaded for smart caching
    private var pricesLoadedAt: Date? = nil
    private var indicatorsLoadedAt: Date? = nil
    private var physicalReportLoadedAt: Date? = nil
    private var intelligenceLoadedAt: Date? = nil
    
    // Debug: Cache duration - MLA data updates once daily at 1am, so cache for 24 hours
    private let cacheDuration: TimeInterval = 86400 // 24 hours (MLA updates daily)
    
    // Debug: Offline state tracking
    var isOffline: Bool = false
    
    // MARK: - Filter State
    var selectedState: String? = nil
    // Debug: Saleyard selector for filtering market data (same as dashboard)
    var selectedSaleyard: String? = nil
    // Debug: Physical sales report filters
    var selectedPhysicalSaleyard: String = "Mount Barker" // Debug: Default saleyard
    var selectedReportDate: Date = Date() // Debug: Default to today
    var availableReportDates: [Date] = [] // Debug: Available dates for selected saleyard
    var selectedCategory: String = "All" // Debug: Category filter for physical sales
    var selectedSalePrefix: String = "All" // Debug: Sale prefix filter for physical sales
    
    // MARK: - Dependencies
    private let dataService = MarketDataService.shared
    private let supabaseService = SupabaseMarketService.shared // Debug: Supabase backend service
    
    // MARK: - Initialization
    init() {
        // Debug: Initialize with empty state
    }
    
    // MARK: - Cache Management
    // Debug: Check if cached data is still fresh (within cacheDuration)
    private func isCacheFresh(_ loadedAt: Date?) -> Bool {
        guard let loadedAt = loadedAt else { return false }
        let age = Date().timeIntervalSince(loadedAt)
        return age < cacheDuration
    }
    
    // Debug: Clear all cached timestamps (forces refresh on next load)
    func clearCache() {
        pricesLoadedAt = nil
        indicatorsLoadedAt = nil
        physicalReportLoadedAt = nil
        intelligenceLoadedAt = nil
        print("🔵 Debug: Cache cleared - next load will fetch fresh data")
    }
    
    // MARK: - Load All Data
    /// Loads all market data (insight, indicators, prices, reports, intelligence)
    /// Debug: Runs tasks in parallel for better performance
    func loadAllData() async {
        await MainActor.run {
            self.errorMessage = nil
        }
        
        // Debug: Load available report dates first
        await loadAvailableReportDates()
        
        // Run all data fetches in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTopInsight() }
            group.addTask { await self.loadNationalIndicators() }
            group.addTask { await self.loadSaleyardReports() }
            group.addTask { await self.loadMarketIntelligence() }
            group.addTask { await self.loadPhysicalSalesReport() } // Debug: Added physical sales
        }
        
        await MainActor.run {
            self.lastUpdated = Date()
        }
    }
    
    // MARK: - Load Top Insight
    /// Fetches daily market takeaway for engagement
    func loadTopInsight() async {
        await MainActor.run { self.isLoadingInsight = true }
        
        let insight = await dataService.fetchTopInsight()
        await MainActor.run {
            self.topInsight = insight
            self.isLoadingInsight = false
        }
    }
    
    // MARK: - Load National Indicators
    /// Fetches national market indicators (EYCI, WYCI, NSI, etc.)
    func loadNationalIndicators(forceRefresh: Bool = false) async {
        // Debug: Check cache first (unless force refresh requested)
        if !forceRefresh && isCacheFresh(indicatorsLoadedAt) && !nationalIndicators.isEmpty {
            print("✅ Debug: Using cached national indicators (age: \(Int(Date().timeIntervalSince(indicatorsLoadedAt!)))s)")
            return
        }
        
        // Debug: If we have cached data but no network, keep showing it
        if !nationalIndicators.isEmpty && isOffline {
            print("⚠️ Debug: Offline - keeping existing cached indicators")
            return
        }
        
        await MainActor.run { self.isLoadingIndicators = true }
        
        let indicators = await dataService.fetchNationalIndicators()
        await MainActor.run {
            self.nationalIndicators = indicators
            self.indicatorsLoadedAt = Date() // Debug: Store cache timestamp
            self.isOffline = false // Debug: Successful load means we're online
            self.isLoadingIndicators = false
        }
    }
    
    // MARK: - Load Category Prices (for My Markets tab)
    /// Fetches category-specific prices filtered by user's exact category+breed combinations
    /// Debug: Only shows prices for the exact herds the user owns, plus general prices
    // MARK: - Category Mapping Helper
    /// Maps app categories to MLA database categories
    private func mapCategoryToMLACategory(_ appCategory: String) -> String {
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
            return appCategory
        }
    }
    
    func loadCategoryPrices(forCategoryBreedPairs pairs: [(category: String, breed: String, state: String)], forceRefresh: Bool = false) async {
        // Debug: Check cache first (unless force refresh requested)
        if !forceRefresh && isCacheFresh(pricesLoadedAt) && !categoryPrices.isEmpty {
            print("✅ Debug: Using cached category prices (age: \(Int(Date().timeIntervalSince(pricesLoadedAt!)))s, fresh for \(Int(cacheDuration))s)")
            return
        }
        
        // Debug: If we have cached data but no network, keep showing it
        if !categoryPrices.isEmpty && isOffline {
            print("⚠️ Debug: Offline - keeping existing cached prices")
            return
        }
        
        await MainActor.run { self.isLoadingPrices = true }
        
        // Debug: Map app categories to MLA categories for comparison
        let mappedPairs = pairs.map { (category: mapCategoryToMLACategory($0.category), breed: $0.breed, state: $0.state, originalCategory: $0.category) }
        
        print("🔵 Debug: loadCategoryPrices called with \(pairs.count) herds:")
        for pair in mappedPairs {
            print("   - \(pair.originalCategory) → \(pair.category) (\(pair.breed)) in \(pair.state)")
        }
        
        // Debug: Fetch prices for ALL unique breeds in user's herds
        let uniqueBreeds = Set(pairs.map { $0.breed })
        print("🔵 Debug: Fetching prices for breeds: \(uniqueBreeds)")
        
        // Get unique MLA categories from user's herds
        let uniqueMLACategories = Set(mappedPairs.map { $0.category })
        print("🔵 Debug: Fetching prices for MLA categories: \(uniqueMLACategories.sorted())")
        
        // Smart state filtering - handles single state, multiple states, or manual filter
        // This dramatically reduces query size (e.g., QLD only = ~280 prices vs all states = ~1400)
        let uniqueStates = Set(mappedPairs.map { $0.state })
        print("🔵 Debug: User's herd states: \(uniqueStates.sorted())")
        
        let (singleState, multipleStates): (String?, [String]?) = {
            if let selected = selectedState {
                // User manually selected a state filter
                return (selected, nil)
            } else if uniqueStates.count == 1, let single = uniqueStates.first {
                // All herds in same state - use single state filter
                return (single, nil)
            } else if uniqueStates.count > 1 {
                // Multiple states - pass array of states (e.g., ["NSW", "VIC"])
                return (nil, Array(uniqueStates))
            } else {
                // No states (shouldn't happen) - fetch all
                return (nil, nil)
            }
        }()
        
        if let states = multipleStates {
            print("🔵 Debug: Fetching prices for MULTIPLE states: \(states.joined(separator: ", "))")
        } else {
            print("🔵 Debug: Fetching prices for state: \(singleState ?? "All states")")
        }
        
        // Fetch prices for ONLY the categories and states we need
        // Debug: Wrap in error handling to detect offline state
        let allPrices: [CategoryPrice]
        do {
            allPrices = await dataService.fetchCategoryPrices(
                categories: Array(uniqueMLACategories),
                livestockType: nil,
                saleyard: nil,
                state: singleState,
                states: multipleStates
            )
            
            // If fetch was cancelled or returned no data, keep existing prices
            // Debug: Don't clear the UI on task cancellation or network errors
            guard !allPrices.isEmpty else {
                print("⚠️ Debug: No prices returned (possibly cancelled or offline), keeping existing data")
                await MainActor.run { 
                    self.isOffline = true
                    self.isLoadingPrices = false 
                }
                return
            }
        } catch {
            // Debug: Network error - mark as offline and keep existing data
            print("❌ Debug: Error fetching prices (likely offline): \(error.localizedDescription)")
            await MainActor.run {
                self.isOffline = true
                self.errorMessage = "Unable to load latest prices. Showing cached data."
                self.isLoadingPrices = false
            }
            return
        }
        
        print("🔵 Debug: Sample price categories from database: \(allPrices.prefix(5).map { $0.category })")
        
        // Get unique categories from fetched data
        let uniqueCategories = Set(allPrices.map { $0.category }).sorted()
        print("🔵 Debug: ALL unique categories in fetched data: \(uniqueCategories)")
        
        // Debug: Check specifically for Yearling Steer
        let yearlingPrices = allPrices.filter { $0.category == "Yearling Steer" }
        print("🔵 Debug: Found \(yearlingPrices.count) Yearling Steer prices")
        if !yearlingPrices.isEmpty {
            print("🔵 Debug: Yearling Steer breeds available: \(yearlingPrices.compactMap { $0.breed })")
        }
        
        // Filter to show prices for user's categories
        // Debug: Include both breed-specific AND general prices for relevant categories
        let filteredPrices = allPrices.filter { price in
            // Check if price category matches any of user's categories (using mapped MLA categories)
            let categoryMatches = mappedPairs.contains(where: { pair in
                pair.category == price.category
            })
            
            if !categoryMatches {
                return false // Category doesn't match any user herd
            }
            
            // If price has a breed, it must match one of the user's breeds for that category
            if let priceBreed = price.breed {
                return mappedPairs.contains(where: { pair in
                    pair.category == price.category && pair.breed == priceBreed
                })
            }
            
            // If price has no breed (general price), include it for matching category
            return true
        }
        
        print("🔵 Debug: After filtering by user categories (breed-specific + general), got \(filteredPrices.count) matching prices")
        
        // De-duplicate by MLA category (so all app categories that map to same MLA category show as one card)
        // Debug: Show one card per unique MLA category (e.g., "Heifer (Unjoined)" and "Weaner Heifer" both show as one "Heifer" card)
        // Priority: breed-specific match for user's herds > general price
        var uniquePrices: [String: CategoryPrice] = [:]
        
        // First pass: Add all filtered prices
        for price in filteredPrices {
            // Use MLA category as key (so Weaner Heifer and Heifer (Unjoined) both map to single "Heifer" card)
            let key = price.category
            
            // Priority: breed-specific match > general price
            if let existingPrice = uniquePrices[key] {
                // If current price has breed that matches user's herd, prefer it over general
                if let priceBreed = price.breed,
                   mappedPairs.contains(where: { $0.category == price.category && $0.breed == priceBreed }),
                   existingPrice.breed == nil {
                    uniquePrices[key] = price
                }
                // If both have breeds or both are general, keep first one
            } else {
                // First price for this MLA category
                uniquePrices[key] = price
            }
        }
        
        // Convert back to CategoryPrice array and sort
        let deduplicatedPrices = uniquePrices.values.sorted { 
            if $0.category == $1.category {
                // Sort by breed within same category (general prices first)
                let breed0 = $0.breed ?? ""
                let breed1 = $1.breed ?? ""
                return breed0 < breed1
            }
            return $0.category < $1.category
        }
        
        print("✅ Debug: Updating UI with \(deduplicatedPrices.count) de-duplicated prices (exact user herds only)")
        
        await MainActor.run {
            self.categoryPrices = deduplicatedPrices
            self.pricesLoadedAt = Date() // Debug: Store cache timestamp
            self.isOffline = false // Debug: Successful load means we're online
            self.isLoadingPrices = false
        }
    }
    
    // MARK: - Load Saleyard Reports
    /// Fetches saleyard reports with optional state filter
    func loadSaleyardReports(state: String? = nil) async {
        await MainActor.run { self.isLoadingReports = true }
        
        let reports = await dataService.fetchSaleyardReports(state: state)
        await MainActor.run {
            self.saleyardReports = reports
            self.isLoadingReports = false
        }
    }
    
    // MARK: - Load Market Intelligence
    /// Fetches AI predictive insights
    func loadMarketIntelligence(forCategories categories: [String] = [], forceRefresh: Bool = false) async {
        // Debug: Check cache first (unless force refresh requested)
        if !forceRefresh && isCacheFresh(intelligenceLoadedAt) && !marketIntelligence.isEmpty {
            print("✅ Debug: Using cached market intelligence (age: \(Int(Date().timeIntervalSince(intelligenceLoadedAt!)))s)")
            return
        }
        
        // Debug: If we have cached data but no network, keep showing it
        if !marketIntelligence.isEmpty && isOffline {
            print("⚠️ Debug: Offline - keeping existing cached intelligence")
            return
        }
        
        await MainActor.run { self.isLoadingIntelligence = true }
        
        let intelligence = await dataService.fetchMarketIntelligence(categories: categories)
        await MainActor.run {
            self.marketIntelligence = intelligence
            self.intelligenceLoadedAt = Date() // Debug: Store cache timestamp
            self.isOffline = false // Debug: Successful load means we're online
            self.isLoadingIntelligence = false
        }
    }
    
    // MARK: - Load Historical Prices
    /// Fetches historical price data for charting
    func loadHistoricalPrices(category: String, livestockType: LivestockType, months: Int = 12) async {
        await MainActor.run { self.isLoadingHistory = true }
        
        let history = await dataService.fetchHistoricalPrices(
            category: category,
            livestockType: livestockType,
            months: months
        )
        await MainActor.run {
            self.historicalPrices = history
            self.isLoadingHistory = false
        }
    }
    
    // MARK: - Load Regional Comparison
    /// Fetches regional price comparison data
    func loadRegionalComparison(category: String, livestockType: LivestockType) async {
        await MainActor.run { self.isLoadingRegional = true }
        
        let regional = await dataService.fetchRegionalComparison(
            category: category,
            livestockType: livestockType
        )
        await MainActor.run {
            self.regionalPrices = regional
            self.isLoadingRegional = false
        }
    }
    
    // MARK: - Load Physical Sales Report
    /// Fetches MLA physical sales report
    /// Debug: First tries MLA API directly, then falls back to Supabase, then mock data
    func loadPhysicalSalesReport(saleyard: String? = nil, date: Date = Date(), forceRefresh: Bool = false) async {
        let selectedYard = saleyard ?? selectedPhysicalSaleyard
        
        // Debug: Check cache first (unless force refresh requested or different saleyard/date)
        if !forceRefresh && isCacheFresh(physicalReportLoadedAt) && physicalSalesReport != nil {
            // Check if cached report matches requested saleyard and date
            if let cached = physicalSalesReport,
               cached.saleyard == selectedYard,
               Calendar.current.isDate(cached.reportDate, inSameDayAs: date) {
                print("✅ Debug: Using cached physical sales report (age: \(Int(Date().timeIntervalSince(physicalReportLoadedAt!)))s)")
                return
            }
        }
        
        // Debug: If we have cached data but no network, keep showing it
        if physicalSalesReport != nil && isOffline {
            print("⚠️ Debug: Offline - keeping existing cached physical report")
            return
        }
        
        await MainActor.run { self.isLoadingPhysicalReport = true }
        
        print("🔵 Debug: loadPhysicalSalesReport called for \(selectedYard)")
        
        // Debug: Try MLA API first to see what data structure we get
        if !Config.useMockData {
            print("🔵 Debug: Attempting to fetch physical sales from MLA API...")
            do {
                let report = try await MLAAPIService.shared.fetchPhysicalSalesReport(
                    saleyard: selectedYard,
                    date: date
                )
                print("✅ Debug: Successfully fetched physical sales report from MLA API")
                await MainActor.run {
                    self.physicalSalesReport = report
                    self.physicalReportLoadedAt = Date() // Debug: Store cache timestamp
                    self.isOffline = false // Debug: Successful load means we're online
                    self.isLoadingPhysicalReport = false
                }
                return
            } catch {
                print("⚠️ Debug: MLA API failed for physical sales: \(error)")
                print("⚠️ Debug: Check console above for raw JSON structure")
                // Continue to fallback options
            }
        }
        
        // Fallback to mock data
        print("🔵 Debug: Using mock physical sales data")
        await MainActor.run {
            self.physicalSalesReport = createMockPhysicalReport(saleyard: selectedYard, date: date)
            self.physicalReportLoadedAt = Date() // Debug: Store cache timestamp even for mock data
            self.isLoadingPhysicalReport = false
        }
    }
    
    // MARK: - Mock Physical Report
    /// Debug: Mock physical sales report for testing UI
    private func createMockPhysicalReport(saleyard: String, date: Date) -> PhysicalSalesReport {
        // Debug: Map saleyard to state
        let saleyardState: [String: String] = [
            "Mount Barker": "WA",
            "Wagga Wagga": "NSW",
            "Roma": "QLD",
            "Ballarat": "VIC",
            "Mount Gambier": "SA"
        ]
        
        return PhysicalSalesReport(
            id: UUID().uuidString,
            saleyard: saleyard,
            reportDate: date,
            comparisonDate: Calendar.current.date(byAdding: .day, value: -1, to: date),
            totalYarding: Int.random(in: 250...500),
            categories: [
                // Bulls
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Bulls",
                    weightRange: "600+",
                    salePrefix: "Processor",
                    muscleScore: "C",
                    fatScore: 4,
                    headCount: Int.random(in: 3...8),
                    minPriceCentsPerKg: 366.0,
                    maxPriceCentsPerKg: 372.0,
                    avgPriceCentsPerKg: 369.0,
                    minPriceDollarsPerHead: 2340.0,
                    maxPriceDollarsPerHead: 2480.0,
                    avgPriceDollarsPerHead: 2410.0,
                    priceChangePerKg: 10.0,
                    priceChangePerHead: 65.0
                ),
                // Cows
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Cows",
                    weightRange: "450-550",
                    salePrefix: "Processor",
                    muscleScore: "C",
                    fatScore: 3,
                    headCount: Int.random(in: 15...25),
                    minPriceCentsPerKg: 290.0,
                    maxPriceCentsPerKg: 340.0,
                    avgPriceCentsPerKg: 315.0,
                    minPriceDollarsPerHead: 1305.0,
                    maxPriceDollarsPerHead: 1870.0,
                    avgPriceDollarsPerHead: 1587.5,
                    priceChangePerKg: 2.0,
                    priceChangePerHead: 10.0
                ),
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Cows",
                    weightRange: "450-550",
                    salePrefix: "PTIC",
                    muscleScore: nil,
                    fatScore: nil,
                    headCount: Int.random(in: 8...15),
                    minPriceCentsPerKg: 310.0,
                    maxPriceCentsPerKg: 320.0,
                    avgPriceCentsPerKg: 315.0,
                    minPriceDollarsPerHead: 1550.0,
                    maxPriceDollarsPerHead: 1760.0,
                    avgPriceDollarsPerHead: 1655.0,
                    priceChangePerKg: nil,
                    priceChangePerHead: nil
                ),
                // Grown Heifer
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Grown Heifer",
                    weightRange: "400-540",
                    salePrefix: "Feeder",
                    muscleScore: "C",
                    fatScore: 3,
                    headCount: Int.random(in: 10...18),
                    minPriceCentsPerKg: 330.0,
                    maxPriceCentsPerKg: 360.0,
                    avgPriceCentsPerKg: 345.0,
                    minPriceDollarsPerHead: 1320.0,
                    maxPriceDollarsPerHead: 1944.0,
                    avgPriceDollarsPerHead: 1632.0,
                    priceChangePerKg: -4.0,
                    priceChangePerHead: -18.0
                ),
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Grown Heifer",
                    weightRange: "400-540",
                    salePrefix: "Processor",
                    muscleScore: "B",
                    fatScore: 3,
                    headCount: Int.random(in: 5...12),
                    minPriceCentsPerKg: 325.0,
                    maxPriceCentsPerKg: 368.0,
                    avgPriceCentsPerKg: 346.5,
                    minPriceDollarsPerHead: 1300.0,
                    maxPriceDollarsPerHead: 1987.2,
                    avgPriceDollarsPerHead: 1643.6,
                    priceChangePerKg: -3.0,
                    priceChangePerHead: -16.0
                ),
                // Grown Steer
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Grown Steer",
                    weightRange: "500-600",
                    salePrefix: "Feeder",
                    muscleScore: "C",
                    fatScore: 3,
                    headCount: Int.random(in: 12...20),
                    minPriceCentsPerKg: 300.0,
                    maxPriceCentsPerKg: 370.0,
                    avgPriceCentsPerKg: 340.0,
                    minPriceDollarsPerHead: 1500.0,
                    maxPriceDollarsPerHead: 2220.0,
                    avgPriceDollarsPerHead: 1870.0,
                    priceChangePerKg: -3.0,
                    priceChangePerHead: -15.0
                ),
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Grown Steer",
                    weightRange: "600+",
                    salePrefix: "Processor",
                    muscleScore: "C",
                    fatScore: 4,
                    headCount: Int.random(in: 8...15),
                    minPriceCentsPerKg: 366.0,
                    maxPriceCentsPerKg: 372.0,
                    avgPriceCentsPerKg: 369.0,
                    minPriceDollarsPerHead: 2196.0,
                    maxPriceDollarsPerHead: 2604.0,
                    avgPriceDollarsPerHead: 2400.0,
                    priceChangePerKg: 10.0,
                    priceChangePerHead: 60.0
                ),
                // Yearling Heifer
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Yearling Heifer",
                    weightRange: "330-400",
                    salePrefix: "Feeder",
                    muscleScore: "C",
                    fatScore: 3,
                    headCount: Int.random(in: 8...14),
                    minPriceCentsPerKg: 384.0,
                    maxPriceCentsPerKg: 384.0,
                    avgPriceCentsPerKg: 384.0,
                    minPriceDollarsPerHead: 1267.2,
                    maxPriceDollarsPerHead: 1536.0,
                    avgPriceDollarsPerHead: 1401.6,
                    priceChangePerKg: nil,
                    priceChangePerHead: nil
                ),
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Yearling Heifer",
                    weightRange: "400+",
                    salePrefix: "Feeder",
                    muscleScore: "B",
                    fatScore: 3,
                    headCount: Int.random(in: 5...10),
                    minPriceCentsPerKg: 366.0,
                    maxPriceCentsPerKg: 366.0,
                    avgPriceCentsPerKg: 366.0,
                    minPriceDollarsPerHead: 1464.0,
                    maxPriceDollarsPerHead: 1683.6,
                    avgPriceDollarsPerHead: 1573.8,
                    priceChangePerKg: nil,
                    priceChangePerHead: nil
                ),
                // Yearling Steer
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Yearling Steer",
                    weightRange: "400+",
                    salePrefix: "Processor",
                    muscleScore: "C",
                    fatScore: 4,
                    headCount: Int.random(in: 5...12),
                    minPriceCentsPerKg: 340.0,
                    maxPriceCentsPerKg: 340.0,
                    avgPriceCentsPerKg: 340.0,
                    minPriceDollarsPerHead: 1360.0,
                    maxPriceDollarsPerHead: 1734.0,
                    avgPriceDollarsPerHead: 1547.0,
                    priceChangePerKg: nil,
                    priceChangePerHead: nil
                ),
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Yearling Steer",
                    weightRange: "330-400",
                    salePrefix: "Feeder",
                    muscleScore: "C",
                    fatScore: 3,
                    headCount: Int.random(in: 10...18),
                    minPriceCentsPerKg: 342.0,
                    maxPriceCentsPerKg: 366.0,
                    avgPriceCentsPerKg: 354.0,
                    minPriceDollarsPerHead: 1128.6,
                    maxPriceDollarsPerHead: 1464.0,
                    avgPriceDollarsPerHead: 1296.3,
                    priceChangePerKg: nil,
                    priceChangePerHead: nil
                ),
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Yearling Steer",
                    weightRange: "400+",
                    salePrefix: "Restocker",
                    muscleScore: "C",
                    fatScore: 3,
                    headCount: Int.random(in: 6...12),
                    minPriceCentsPerKg: 342.0,
                    maxPriceCentsPerKg: 342.0,
                    avgPriceCentsPerKg: 342.0,
                    minPriceDollarsPerHead: 1368.0,
                    maxPriceDollarsPerHead: 1625.4,
                    avgPriceDollarsPerHead: 1496.7,
                    priceChangePerKg: nil,
                    priceChangePerHead: nil
                )
            ],
            state: saleyardState[saleyard] ?? "NSW",
            summary: "Numbers were down for total small yarding of \(Int.random(in: 250...500)) head with the total fire ban yesterday disrupting transport. Trade weight cattle and cows dominated the yarding with processors keeping prices mainly firm. Heavy bullocks sold to 372c while a pen of cows reached 340c/kg. Heavy bulls gained 10c to average 310c/kg. Yearling heifers weighing over 400kg sold for 342c to 366c /kg. Bullocks weighing over 600kg sold for 366c to 372c while lighter weight steers made 300c to 370c/kg. Grown heifers weighing under 540kg sold from 330c to 360c and heavier weights returned 325c to 368c /kg. Heavy weight cows gained 2c selling at 290c to 340c, medium weights sold for 306c, and store cows made 250c to 290c /kg. Heavy bulls gained selling from 250c to 320c/kg. PTIC cows sold from 310c to 320c/kg.",
            audioURL: "https://example.com/audio/report.mp3"
        )
    }
    
    // MARK: - Load Available Report Dates
    /// Loads available report dates for physical sales
    /// Debug: Mock implementation - in production would query API
    func loadAvailableReportDates() async {
        // Debug: Generate last 7 days of dates
        let calendar = Calendar.current
        let dates = (0..<7).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: Date())
        }
        
        await MainActor.run {
            self.availableReportDates = dates
        }
    }
    
    // MARK: - Filter Actions
    
    /// Updates state filter and reloads data
    func selectState(_ state: String?) async {
        await MainActor.run {
            self.selectedState = state
        }
        HapticManager.tap()
        await loadSaleyardReports(state: state)
    }
    
    /// Updates physical sales saleyard and reloads report
    func selectPhysicalSaleyard(_ saleyard: String) async {
        await MainActor.run {
            self.selectedPhysicalSaleyard = saleyard
        }
        HapticManager.tap()
        await loadAvailableReportDates()
        await loadPhysicalSalesReport(saleyard: saleyard, date: selectedReportDate)
    }
    
    /// Updates physical sales report date and reloads report
    func selectReportDate(_ date: Date) async {
        await MainActor.run {
            self.selectedReportDate = date
        }
        HapticManager.tap()
        await loadPhysicalSalesReport(saleyard: selectedPhysicalSaleyard, date: date)
    }
}


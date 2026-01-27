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
        
        HapticManager.success()
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
    func loadNationalIndicators() async {
        await MainActor.run { self.isLoadingIndicators = true }
        
        let indicators = await dataService.fetchNationalIndicators()
        await MainActor.run {
            self.nationalIndicators = indicators
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
    
    func loadCategoryPrices(forCategoryBreedPairs pairs: [(category: String, breed: String)]) async {
        await MainActor.run { self.isLoadingPrices = true }
        
        // Debug: Map app categories to MLA categories for comparison
        let mappedPairs = pairs.map { (category: mapCategoryToMLACategory($0.category), breed: $0.breed, originalCategory: $0.category) }
        
        print("🔵 Debug: loadCategoryPrices called with \(pairs.count) herds:")
        for pair in mappedPairs {
            print("   - \(pair.originalCategory) → \(pair.category) (\(pair.breed))")
        }
        
        // Fetch all prices then filter to user's categories
        let allPrices = await dataService.fetchCategoryPrices(
            livestockType: nil,
            saleyard: nil,
            state: selectedState
        )
        
        // If fetch was cancelled or returned no data, keep existing prices
        // Debug: Don't clear the UI on task cancellation
        guard !allPrices.isEmpty else {
            print("⚠️ Debug: No prices returned (possibly cancelled), keeping existing data")
            await MainActor.run { self.isLoadingPrices = false }
            return
        }
        
        print("🔵 Debug: Sample price categories from database: \(allPrices.prefix(5).map { $0.category })")
        
        // Get unique categories from fetched data
        let uniqueCategories = Set(allPrices.map { $0.category }).sorted()
        print("🔵 Debug: ALL unique categories in fetched data: \(uniqueCategories)")
        
        // Filter to only show prices for exact category+breed combinations the user owns
        // Debug: Use mapped MLA categories for comparison
        let filteredPrices = allPrices.filter { price in
            // Must have a breed (skip general prices)
            guard let priceBreed = price.breed else { return false }
            
            // Must match one of user's exact category+breed combinations (using mapped MLA categories)
            return mappedPairs.contains(where: { pair in
                pair.category == price.category && pair.breed == priceBreed
            })
        }
        
        print("🔵 Debug: After filtering by exact category+breed pairs, got \(filteredPrices.count) matching prices")
        
        // De-duplicate by user's original herd category + breed combination
        // Debug: Show one card per unique herd type the user owns (e.g., separate cards for Breeder vs Weaner Heifer)
        var uniquePrices: [String: (price: CategoryPrice, originalCategory: String)] = [:]
        for price in filteredPrices {
            // Find which original user category this price matches
            if let matchedPair = mappedPairs.first(where: { pair in
                pair.category == price.category && pair.breed == price.breed
            }) {
                // Key based on ORIGINAL app category + breed
                let key = "\(matchedPair.originalCategory)-\(matchedPair.breed)"
                
                // Keep the first price found for each unique herd type
                if uniquePrices[key] == nil {
                    uniquePrices[key] = (price: price, originalCategory: matchedPair.originalCategory)
                }
            }
        }
        
        // Convert back to CategoryPrice array
        let deduplicatedPrices = uniquePrices.values.map { $0.price }.sorted { 
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
    func loadMarketIntelligence(forCategories categories: [String] = []) async {
        await MainActor.run { self.isLoadingIntelligence = true }
        
        let intelligence = await dataService.fetchMarketIntelligence(categories: categories)
        await MainActor.run {
            self.marketIntelligence = intelligence
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
    func loadPhysicalSalesReport(saleyard: String? = nil, date: Date = Date()) async {
        await MainActor.run { self.isLoadingPhysicalReport = true }
        
        let selectedYard = saleyard ?? selectedPhysicalSaleyard
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


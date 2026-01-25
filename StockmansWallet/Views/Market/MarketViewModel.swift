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
    /// Fetches category-specific prices filtered by user's herd categories
    /// Debug: Takes array of category strings from user's actual herds
    func loadCategoryPrices(forCategories categories: [String]) async {
        await MainActor.run { self.isLoadingPrices = true }
        
        // Fetch all prices then filter to user's categories
        let allPrices = await dataService.fetchCategoryPrices(
            livestockType: nil,
            saleyard: nil,
            state: selectedState
        )
        
        // Filter to only show categories the user actually has
        let filteredPrices = allPrices.filter { price in
            categories.contains(price.category)
        }
        
        await MainActor.run {
            self.categoryPrices = filteredPrices
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
        
        print("🔵 Debug: loadPhysicalSalesReport called")
        
        // Debug: Try MLA API first to see what data structure we get
        if !Config.useMockData {
            print("🔵 Debug: Attempting to fetch physical sales from MLA API...")
            do {
                let report = try await MLAAPIService.shared.fetchPhysicalSalesReport(
                    saleyard: saleyard,
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
            self.physicalSalesReport = createMockPhysicalReport()
            self.isLoadingPhysicalReport = false
        }
    }
    
    // MARK: - Mock Physical Report
    /// Debug: Mock physical sales report for testing UI
    private func createMockPhysicalReport() -> PhysicalSalesReport {
        return PhysicalSalesReport(
            id: UUID().uuidString,
            saleyard: "Mount Barker",
            reportDate: Date(),
            totalYarding: 336,
            categories: [
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Yearling Steer",
                    weightRange: "400-500",
                    salePrefix: "Processor",
                    muscleScore: "C",
                    fatScore: 3,
                    headCount: 4,
                    minPriceCentsPerKg: 340.0,
                    maxPriceCentsPerKg: 340.0,
                    avgPriceCentsPerKg: 340.0,
                    minPriceDollarsPerHead: 1734.0,
                    maxPriceDollarsPerHead: 1734.0,
                    avgPriceDollarsPerHead: 1734.0
                ),
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Yearling Heifer",
                    weightRange: "400-500",
                    salePrefix: "Feeder",
                    muscleScore: "C",
                    fatScore: 3,
                    headCount: 6,
                    minPriceCentsPerKg: 384.0,
                    maxPriceCentsPerKg: 384.0,
                    avgPriceCentsPerKg: 384.0,
                    minPriceDollarsPerHead: 1536.0,
                    maxPriceDollarsPerHead: 1536.0,
                    avgPriceDollarsPerHead: 1536.0
                ),
                PhysicalSalesCategory(
                    id: UUID().uuidString,
                    categoryName: "Grown Steer",
                    weightRange: "400-500",
                    salePrefix: "Feeder",
                    muscleScore: "C",
                    fatScore: 3,
                    headCount: 11,
                    minPriceCentsPerKg: 300.0,
                    maxPriceCentsPerKg: 370.0,
                    avgPriceCentsPerKg: 340.0,
                    minPriceDollarsPerHead: 1245.0,
                    maxPriceDollarsPerHead: 1586.0,
                    avgPriceDollarsPerHead: 1454.58
                )
            ]
        )
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
}


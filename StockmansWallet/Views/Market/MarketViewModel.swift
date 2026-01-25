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
    
    // MARK: - UI State
    var isLoadingInsight = false
    var isLoadingIndicators = false
    var isLoadingPrices = false
    var isLoadingHistory = false
    var isLoadingRegional = false
    var isLoadingReports = false
    var isLoadingIntelligence = false
    var lastUpdated: Date? = nil
    var errorMessage: String? = nil
    
    // MARK: - Filter State
    var selectedState: String? = nil
    // Debug: Saleyard selector for filtering market data (same as dashboard)
    var selectedSaleyard: String? = nil
    
    // MARK: - Dependencies
    private let dataService = MarketDataService.shared
    
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


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
    var nationalIndicators: [NationalIndicator] = []
    var categoryPrices: [CategoryPrice] = []
    var historicalPrices: [HistoricalPricePoint] = []
    var regionalPrices: [RegionalPrice] = []
    var marketCommentary: [MarketCommentary] = []
    
    // MARK: - Filter State
    var selectedLivestockType: LivestockType? = nil
    var selectedSaleyard: String? = nil
    var selectedState: String? = nil
    var selectedCategory: String? = nil
    
    // MARK: - UI State
    var isLoadingIndicators = false
    var isLoadingPrices = false
    var isLoadingHistory = false
    var isLoadingRegional = false
    var isLoadingCommentary = false
    var lastUpdated: Date? = nil
    var errorMessage: String? = nil
    
    // MARK: - Dependencies
    private let dataService = MarketDataService.shared
    
    // MARK: - Initialization
    init() {
        // Debug: Initialize with empty state
    }
    
    // MARK: - Load All Data
    /// Loads all market data (indicators, prices, commentary)
    /// Debug: Runs tasks in parallel for better performance
    func loadAllData() async {
        await MainActor.run {
            self.errorMessage = nil
        }
        
        // Run all data fetches in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadNationalIndicators() }
            group.addTask { await self.loadCategoryPrices() }
            group.addTask { await self.loadMarketCommentary() }
        }
        
        await MainActor.run {
            self.lastUpdated = Date()
        }
        
        HapticManager.success()
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
    
    // MARK: - Load Category Prices
    /// Fetches category-specific prices with current filters applied
    func loadCategoryPrices() async {
        await MainActor.run { self.isLoadingPrices = true }
        
        let prices = await dataService.fetchCategoryPrices(
            livestockType: selectedLivestockType,
            saleyard: selectedSaleyard,
            state: selectedState
        )
        await MainActor.run {
            self.categoryPrices = prices
            self.isLoadingPrices = false
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
            self.selectedCategory = category
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
    
    // MARK: - Load Market Commentary
    /// Fetches market insights and commentary
    func loadMarketCommentary() async {
        await MainActor.run { self.isLoadingCommentary = true }
        
        let commentary = await dataService.fetchMarketCommentary()
        await MainActor.run {
            self.marketCommentary = commentary
            self.isLoadingCommentary = false
        }
    }
    
    // MARK: - Filter Actions
    
    /// Updates livestock type filter and reloads prices
    func selectLivestockType(_ type: LivestockType?) async {
        await MainActor.run {
            self.selectedLivestockType = type
        }
        HapticManager.tap()
        await loadCategoryPrices()
    }
    
    /// Updates saleyard filter and reloads prices
    func selectSaleyard(_ saleyard: String?) async {
        await MainActor.run {
            self.selectedSaleyard = saleyard
        }
        HapticManager.tap()
        await loadCategoryPrices()
    }
    
    /// Updates state filter and reloads prices
    func selectState(_ state: String?) async {
        await MainActor.run {
            self.selectedState = state
        }
        HapticManager.tap()
        await loadCategoryPrices()
    }
    
    /// Clears all filters and reloads data
    func clearFilters() async {
        await MainActor.run {
            self.selectedLivestockType = nil
            self.selectedSaleyard = nil
            self.selectedState = nil
        }
        HapticManager.tap()
        await loadCategoryPrices()
    }
    
    // MARK: - Computed Properties
    
    /// Returns filtered prices based on selected livestock type
    var filteredPrices: [CategoryPrice] {
        if let type = selectedLivestockType {
            return categoryPrices.filter { $0.livestockType == type }
        }
        return categoryPrices
    }
    
    /// Returns true if any filters are active
    var hasActiveFilters: Bool {
        return selectedLivestockType != nil || selectedSaleyard != nil || selectedState != nil
    }
    
    /// Returns count of active filters
    var activeFilterCount: Int {
        var count = 0
        if selectedLivestockType != nil { count += 1 }
        if selectedSaleyard != nil { count += 1 }
        if selectedState != nil { count += 1 }
        return count
    }
}


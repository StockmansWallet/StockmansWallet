//
//  MarketDataService.swift
//  StockmansWallet
//
//  Mock Market Data Service - provides comprehensive market data
//  Debug: Structured for easy replacement with MLA API integration
//

import Foundation
import SwiftData

// MARK: - Market Data Service
// Debug: Singleton service that provides mock market data until MLA API is integrated
@Observable
class MarketDataService {
    static let shared = MarketDataService()
    
    private init() {}
    
    // MARK: - National Indicators
    // Debug: Major market indicators (EYCI, WYCI, NSI, etc.)
    func fetchNationalIndicators() async -> [NationalIndicator] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        return [
            NationalIndicator(
                name: "Eastern Young Cattle Indicator",
                abbreviation: "EYCI",
                value: 645.50,
                change: 8.20,
                trend: .up,
                unit: "¢/kg cwt"
            ),
            NationalIndicator(
                name: "Western Young Cattle Indicator",
                abbreviation: "WYCI",
                value: 620.30,
                change: -4.50,
                trend: .down,
                unit: "¢/kg cwt"
            ),
            NationalIndicator(
                name: "National Sheep Indicator",
                abbreviation: "NSI",
                value: 810.00,
                change: 5.20,
                trend: .up,
                unit: "¢/kg cwt"
            ),
            NationalIndicator(
                name: "National Heavy Lamb Indicator",
                abbreviation: "NHLI",
                value: 875.50,
                change: 12.30,
                trend: .up,
                unit: "¢/kg cwt"
            )
        ]
    }
    
    // MARK: - Category Prices
    // Debug: Fetch prices for specific livestock categories with filtering
    func fetchCategoryPrices(
        livestockType: LivestockType?,
        saleyard: String?,
        state: String?
    ) async -> [CategoryPrice] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        // Filter based on livestock type
        var prices: [CategoryPrice] = []
        
        if livestockType == nil || livestockType == .cattle {
            prices.append(contentsOf: cattlePrices(saleyard: saleyard, state: state))
        }
        if livestockType == nil || livestockType == .sheep {
            prices.append(contentsOf: sheepPrices(saleyard: saleyard, state: state))
        }
        if livestockType == nil || livestockType == .pigs {
            prices.append(contentsOf: pigPrices(saleyard: saleyard, state: state))
        }
        if livestockType == nil || livestockType == .goats {
            prices.append(contentsOf: goatPrices(saleyard: saleyard, state: state))
        }
        
        return prices
    }
    
    // MARK: - Historical Prices
    // Debug: Generate historical price data for charting (last 12 months)
    func fetchHistoricalPrices(
        category: String,
        livestockType: LivestockType,
        months: Int = 12
    ) async -> [HistoricalPricePoint] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        var points: [HistoricalPricePoint] = []
        let calendar = Calendar.current
        let endDate = Date()
        
        // Generate data points for each week
        for weekOffset in (0..<(months * 4)).reversed() {
            guard let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: endDate) else { continue }
            
            // Create realistic price variation based on category and time
            let basePrice = getBasePrice(category: category, livestockType: livestockType)
            let seasonalVariation = sin(Double(weekOffset) * 0.2) * 0.15 // ±15% seasonal swing
            let randomVariation = Double.random(in: -0.05...0.05) // ±5% random variation
            let trendAdjustment = Double(weekOffset) * 0.002 // Slight upward trend
            
            let price = basePrice * (1 + seasonalVariation + randomVariation + trendAdjustment)
            
            points.append(HistoricalPricePoint(date: date, price: price))
        }
        
        return points.sorted { $0.date < $1.date }
    }
    
    // MARK: - Regional Comparison
    // Debug: Compare prices across different states for a category
    func fetchRegionalComparison(
        category: String,
        livestockType: LivestockType
    ) async -> [RegionalPrice] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 350_000_000)
        
        let basePrice = getBasePrice(category: category, livestockType: livestockType)
        
        return [
            RegionalPrice(state: "NSW", price: basePrice * 1.05, change: 3.2, trend: .up),
            RegionalPrice(state: "VIC", price: basePrice * 0.98, change: -1.5, trend: .down),
            RegionalPrice(state: "QLD", price: basePrice * 1.02, change: 2.1, trend: .up),
            RegionalPrice(state: "SA", price: basePrice * 0.95, change: 0.5, trend: .up),
            RegionalPrice(state: "WA", price: basePrice * 1.08, change: 4.8, trend: .up),
            RegionalPrice(state: "TAS", price: basePrice * 0.92, change: -0.8, trend: .down)
        ]
    }
    
    // MARK: - Market Commentary
    // Debug: Fetch market insights and commentary
    func fetchMarketCommentary() async -> [MarketCommentary] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 250_000_000)
        
        return [
            MarketCommentary(
                title: "Strong Demand Lifts Cattle Prices",
                summary: "Eastern Young Cattle Indicator climbs 8.2¢ as restocking demand intensifies across NSW and QLD saleyards.",
                date: Date().addingTimeInterval(-3600 * 2), // 2 hours ago
                category: "Cattle",
                sentiment: .positive
            ),
            MarketCommentary(
                title: "Seasonal Lamb Supply Increases",
                summary: "National Heavy Lamb Indicator gains 12.3¢ amid strong processor demand and improved seasonal conditions.",
                date: Date().addingTimeInterval(-3600 * 5), // 5 hours ago
                category: "Sheep",
                sentiment: .positive
            ),
            MarketCommentary(
                title: "Western Markets See Price Correction",
                summary: "WYCI drops 4.5¢ as increased yardings ease recent supply tightness in WA markets.",
                date: Date().addingTimeInterval(-86400), // 1 day ago
                category: "Cattle",
                sentiment: .neutral
            )
        ]
    }
    
    // MARK: - Private Helper Methods
    
    private func cattlePrices(saleyard: String?, state: String?) -> [CategoryPrice] {
        return [
            CategoryPrice(
                category: "Feeder Steer",
                livestockType: .cattle,
                price: 6.45,
                change: 0.15,
                trend: .up,
                weightRange: "300-400kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Yearling Steer",
                livestockType: .cattle,
                price: 6.80,
                change: -0.10,
                trend: .down,
                weightRange: "400-500kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Grown Steer",
                livestockType: .cattle,
                price: 6.15,
                change: -0.05,
                trend: .down,
                weightRange: "500-600kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Breeding Cow",
                livestockType: .cattle,
                price: 4.20,
                change: 0.05,
                trend: .up,
                weightRange: "450-550kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Heifer",
                livestockType: .cattle,
                price: 6.30,
                change: 0.12,
                trend: .up,
                weightRange: "350-450kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Weaner Steer",
                livestockType: .cattle,
                price: 7.20,
                change: 0.25,
                trend: .up,
                weightRange: "200-300kg",
                source: saleyard ?? "National Average"
            )
        ]
    }
    
    private func sheepPrices(saleyard: String?, state: String?) -> [CategoryPrice] {
        return [
            CategoryPrice(
                category: "Heavy Lamb",
                livestockType: .sheep,
                price: 8.75,
                change: 0.32,
                trend: .up,
                weightRange: "22-26kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Trade Lamb",
                livestockType: .sheep,
                price: 8.20,
                change: 0.15,
                trend: .up,
                weightRange: "18-22kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Merino Wether",
                livestockType: .sheep,
                price: 7.50,
                change: -0.08,
                trend: .down,
                weightRange: "50-60kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Breeding Ewe",
                livestockType: .sheep,
                price: 6.80,
                change: 0.10,
                trend: .up,
                weightRange: "45-55kg",
                source: saleyard ?? "National Average"
            )
        ]
    }
    
    private func pigPrices(saleyard: String?, state: String?) -> [CategoryPrice] {
        return [
            CategoryPrice(
                category: "Baconer",
                livestockType: .pigs,
                price: 3.85,
                change: 0.05,
                trend: .up,
                weightRange: "70-85kg",
                source: "Processor Average"
            ),
            CategoryPrice(
                category: "Porker",
                livestockType: .pigs,
                price: 3.95,
                change: 0.08,
                trend: .up,
                weightRange: "60-70kg",
                source: "Processor Average"
            ),
            CategoryPrice(
                category: "Grower Pig",
                livestockType: .pigs,
                price: 4.20,
                change: -0.02,
                trend: .down,
                weightRange: "30-50kg",
                source: "Private Sale Average"
            )
        ]
    }
    
    private func goatPrices(saleyard: String?, state: String?) -> [CategoryPrice] {
        return [
            CategoryPrice(
                category: "Rangeland Goat",
                livestockType: .goats,
                price: 7.80,
                change: 0.20,
                trend: .up,
                weightRange: "20-30kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Breeding Doe",
                livestockType: .goats,
                price: 6.50,
                change: 0.15,
                trend: .up,
                weightRange: "35-45kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Capretto",
                livestockType: .goats,
                price: 9.20,
                change: -0.10,
                trend: .down,
                weightRange: "8-12kg",
                source: "Processor Average"
            )
        ]
    }
    
    private func getBasePrice(category: String, livestockType: LivestockType) -> Double {
        switch livestockType {
        case .cattle:
            if category.contains("Weaner") { return 7.20 }
            if category.contains("Feeder") { return 6.45 }
            if category.contains("Yearling") { return 6.80 }
            if category.contains("Heifer") { return 6.30 }
            return 6.15
        case .sheep:
            if category.contains("Heavy") { return 8.75 }
            if category.contains("Trade") { return 8.20 }
            return 7.50
        case .pigs:
            return 3.95
        case .goats:
            if category.contains("Capretto") { return 9.20 }
            if category.contains("Rangeland") { return 7.80 }
            return 6.50
        }
    }
}

// MARK: - Data Models

enum LivestockType: String, CaseIterable, Identifiable {
    case cattle = "Cattle"
    case sheep = "Sheep"
    case pigs = "Pigs"
    case goats = "Goats"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .cattle: return "🐄"
        case .sheep: return "🐑"
        case .pigs: return "🐷"
        case .goats: return "🐐"
        }
    }
}

struct NationalIndicator: Identifiable {
    let id = UUID()
    let name: String
    let abbreviation: String
    let value: Double
    let change: Double
    let trend: PriceTrend
    let unit: String
}

struct CategoryPrice: Identifiable {
    let id = UUID()
    let category: String
    let livestockType: LivestockType
    let price: Double
    let change: Double
    let trend: PriceTrend
    let weightRange: String
    let source: String
}

struct HistoricalPricePoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}

struct RegionalPrice: Identifiable {
    let id = UUID()
    let state: String
    let price: Double
    let change: Double
    let trend: PriceTrend
}

struct MarketCommentary: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let date: Date
    let category: String
    let sentiment: MarketSentiment
}

enum MarketSentiment {
    case positive
    case neutral
    case negative
    
    var icon: String {
        switch self {
        case .positive: return "arrow.up.circle.fill"
        case .neutral: return "minus.circle.fill"
        case .negative: return "arrow.down.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .positive: return "green"
        case .neutral: return "gray"
        case .negative: return "red"
        }
    }
}


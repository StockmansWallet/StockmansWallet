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
    
    // MARK: - Top Insight
    // Debug: Daily market takeaway sentence for engagement
    func fetchTopInsight() async -> TopInsight? {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        return TopInsight(
            text: "Market conditions for weaners in your region are improving as tightening supply supports prices",
            date: Date(),
            category: "Cattle"
        )
    }
    
    // MARK: - Saleyard Reports
    // Debug: Fetch saleyard reports with summary data
    func fetchSaleyardReports(state: String? = nil) async -> [SaleyardReport] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 350_000_000)
        
        let allReports = [
            SaleyardReport(
                saleyardName: "Roma",
                state: "QLD",
                date: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                yardings: 4250,
                summary: "Strong demand for quality weaners. Prices firm to 10¢ higher across most categories.",
                categories: ["Weaner Steer", "Feeder Steer", "Yearling Steer"]
            ),
            SaleyardReport(
                saleyardName: "Wagga Wagga",
                state: "NSW",
                date: Date().addingTimeInterval(-86400 * 1), // 1 day ago
                yardings: 3100,
                summary: "Mixed quality yarding with solid processor demand. Heavy steers particularly sought after.",
                categories: ["Grown Steer", "Breeding Cow", "Heifer"]
            ),
            SaleyardReport(
                saleyardName: "Ballarat",
                state: "VIC",
                date: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                yardings: 2800,
                summary: "Restockers active despite wet conditions. Prime lambs holding firm.",
                categories: ["Heavy Lamb", "Trade Lamb", "Merino Wether"]
            ),
            SaleyardReport(
                saleyardName: "Dubbo",
                state: "NSW",
                date: Date().addingTimeInterval(-86400 * 1), // 1 day ago
                yardings: 5200,
                summary: "Large yarding with increased supply easing recent price pressure.",
                categories: ["Weaner Steer", "Yearling Steer", "Breeding Cow"]
            )
        ]
        
        // Filter by state if provided
        if let state = state {
            return allReports.filter { $0.state == state }
        }
        return allReports
    }
    
    // MARK: - Market Intelligence
    // Debug: AI predictive insights with confidence levels
    func fetchMarketIntelligence(categories: [String] = []) async -> [MarketIntelligence] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        return [
            MarketIntelligence(
                category: "Cattle - Weaners",
                prediction: "Weaner prices expected to strengthen by 8-12% over the next 30-45 days as seasonal supply tightens.",
                confidence: .high,
                timeHorizon: "30-45 days",
                keyDrivers: ["Reduced supply from drought-affected regions", "Strong restocking demand", "Favorable seasonal outlook"],
                lastUpdated: Date()
            ),
            MarketIntelligence(
                category: "Sheep - Heavy Lambs",
                prediction: "Heavy lamb prices likely to remain stable with slight upward pressure as export demand increases.",
                confidence: .medium,
                timeHorizon: "60 days",
                keyDrivers: ["Increasing export demand", "Stable domestic supply", "Currency movements favoring exports"],
                lastUpdated: Date()
            ),
            MarketIntelligence(
                category: "Cattle - Breeding Stock",
                prediction: "Breeding cow values to hold firm with potential for 5-8% gains as herd rebuilding continues.",
                confidence: .high,
                timeHorizon: "90 days",
                keyDrivers: ["Ongoing herd rebuilding phase", "Improved seasonal conditions", "Limited quality female supply"],
                lastUpdated: Date()
            ),
            MarketIntelligence(
                category: "Sheep - Merino Wethers",
                prediction: "Merino wether prices may soften slightly as increased yardings meet steady but not exceptional demand.",
                confidence: .medium,
                timeHorizon: "45 days",
                keyDrivers: ["Increased supply from seasonal turnoff", "Moderate processor demand", "Competing with lamb market"],
                lastUpdated: Date()
            )
        ]
    }
    
    // MARK: - National Indicators
    // Debug: Major market indicators (EYCI, WYCI, NSI, etc.)
    // Debug: Now fetches REAL data from MLA API when useMockData = false
    func fetchNationalIndicators() async -> [NationalIndicator] {
        print("🟢 MarketDataService: fetchNationalIndicators called")
        print("🟢 useMockData = \(Config.useMockData)")
        
        // Check if we should use real MLA data
        if !Config.useMockData {
            print("🟢 Attempting to fetch from MLA API...")
            do {
                // Fetch real data from MLA API
                let indicators = try await MLAAPIService.shared.fetchNationalIndicators()
                print("✅ Successfully fetched \(indicators.count) indicators from MLA API")
                return indicators
            } catch {
                print("❌ Error fetching from MLA API, falling back to mock data: \(error)")
                // Fall through to mock data if API fails
            }
        } else {
            print("🟡 Using mock data (Config.useMockData = true)")
        }
        
        // Simulate network delay for mock data
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Debug: Mock data for testing (cattle only for MVP)
        print("🟡 Returning mock data")
        return [
            NationalIndicator(
                name: "Eastern Young Cattle Indicator",
                abbreviation: "EYCI",
                value: 355.03,
                change: 4.51,
                trend: .up,
                unit: "¢/kg cwt"
            ),
            NationalIndicator(
                name: "Western Young Cattle Indicator",
                abbreviation: "WYCI",
                value: 341.17,
                change: -2.48,
                trend: .down,
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
        // Debug: Cattle prices adjusted to realistic market values based on current Australian market rates
        return [
            CategoryPrice(
                category: "Feeder Steer",
                livestockType: .cattle,
                price: 3.90, // Adjusted to realistic market rate
                change: 0.08,
                trend: .up,
                weightRange: "300-400kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Yearling Steer",
                livestockType: .cattle,
                price: 4.10, // Adjusted to realistic market rate (~$4.10/kg)
                change: -0.06,
                trend: .down,
                weightRange: "400-500kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Grown Steer",
                livestockType: .cattle,
                price: 3.70, // Adjusted to realistic market rate (base price)
                change: -0.03,
                trend: .down,
                weightRange: "500-600kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Breeding Cow",
                livestockType: .cattle,
                price: 3.80, // Adjusted to realistic market rate (~$3.80/kg)
                change: 0.03,
                trend: .up,
                weightRange: "450-550kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Heifer",
                livestockType: .cattle,
                price: 3.85, // Adjusted to realistic market rate
                change: 0.07,
                trend: .up,
                weightRange: "350-450kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Weaner Steer",
                livestockType: .cattle,
                price: 4.35, // Adjusted to realistic market rate (highest per kg)
                change: 0.14,
                trend: .up,
                weightRange: "200-300kg",
                source: saleyard ?? "National Average"
            )
        ]
    }
    
    private func sheepPrices(saleyard: String?, state: String?) -> [CategoryPrice] {
        // Debug: All sheep prices reduced by 45% (×0.55) for realistic market values
        return [
            CategoryPrice(
                category: "Heavy Lamb",
                livestockType: .sheep,
                price: 4.81, // Adjusted from 8.75 (×0.55)
                change: 0.18, // Adjusted from 0.32 (×0.55)
                trend: .up,
                weightRange: "22-26kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Trade Lamb",
                livestockType: .sheep,
                price: 4.51, // Adjusted from 8.20 (×0.55)
                change: 0.08, // Adjusted from 0.15 (×0.55)
                trend: .up,
                weightRange: "18-22kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Merino Wether",
                livestockType: .sheep,
                price: 4.13, // Adjusted from 7.50 (×0.55)
                change: -0.04, // Adjusted from -0.08 (×0.55)
                trend: .down,
                weightRange: "50-60kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Breeding Ewe",
                livestockType: .sheep,
                price: 3.74, // Adjusted from 6.80 (×0.55)
                change: 0.06, // Adjusted from 0.10 (×0.55)
                trend: .up,
                weightRange: "45-55kg",
                source: saleyard ?? "National Average"
            )
        ]
    }
    
    private func pigPrices(saleyard: String?, state: String?) -> [CategoryPrice] {
        // Debug: All pig prices reduced by 45% (×0.55) for realistic market values
        return [
            CategoryPrice(
                category: "Baconer",
                livestockType: .pigs,
                price: 2.12, // Adjusted from 3.85 (×0.55)
                change: 0.03, // Adjusted from 0.05 (×0.55)
                trend: .up,
                weightRange: "70-85kg",
                source: "Processor Average"
            ),
            CategoryPrice(
                category: "Porker",
                livestockType: .pigs,
                price: 2.17, // Adjusted from 3.95 (×0.55)
                change: 0.04, // Adjusted from 0.08 (×0.55)
                trend: .up,
                weightRange: "60-70kg",
                source: "Processor Average"
            ),
            CategoryPrice(
                category: "Grower Pig",
                livestockType: .pigs,
                price: 2.31, // Adjusted from 4.20 (×0.55)
                change: -0.01, // Adjusted from -0.02 (×0.55)
                trend: .down,
                weightRange: "30-50kg",
                source: "Private Sale Average"
            )
        ]
    }
    
    private func goatPrices(saleyard: String?, state: String?) -> [CategoryPrice] {
        // Debug: All goat prices reduced by 45% (×0.55) for realistic market values
        return [
            CategoryPrice(
                category: "Rangeland Goat",
                livestockType: .goats,
                price: 4.29, // Adjusted from 7.80 (×0.55)
                change: 0.11, // Adjusted from 0.20 (×0.55)
                trend: .up,
                weightRange: "20-30kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Breeding Doe",
                livestockType: .goats,
                price: 3.58, // Adjusted from 6.50 (×0.55)
                change: 0.08, // Adjusted from 0.15 (×0.55)
                trend: .up,
                weightRange: "35-45kg",
                source: saleyard ?? "National Average"
            ),
            CategoryPrice(
                category: "Capretto",
                livestockType: .goats,
                price: 5.06, // Adjusted from 9.20 (×0.55)
                change: -0.06, // Adjusted from -0.10 (×0.55)
                trend: .down,
                weightRange: "8-12kg",
                source: "Processor Average"
            )
        ]
    }
    
    private func getBasePrice(category: String, livestockType: LivestockType) -> Double {
        // Debug: Base prices set to realistic market values based on current Australian market rates
        switch livestockType {
        case .cattle:
            if category.contains("Weaner") { return 4.35 } // Highest per kg (youngest animals)
            if category.contains("Yearling") { return 4.10 } // ~$4.10/kg target
            if category.contains("Feeder") { return 3.90 } // Mid-range price
            if category.contains("Heifer") { return 3.85 } // Similar to breeding stock
            if category.contains("Breeding") { return 3.80 } // ~$3.80/kg target
            return 3.70 // Grown Steer base price
        case .sheep:
            if category.contains("Heavy") { return 4.81 } // Adjusted from 8.75
            if category.contains("Trade") { return 4.51 } // Adjusted from 8.20
            return 4.13 // Adjusted from 7.50
        case .pigs:
            return 2.17 // Adjusted from 3.95
        case .goats:
            if category.contains("Capretto") { return 5.06 } // Adjusted from 9.20
            if category.contains("Rangeland") { return 4.29 } // Adjusted from 7.80
            return 3.58 // Adjusted from 6.50
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

// MARK: - Top Insight Model
// Debug: Daily market takeaway for top of Markets page
struct TopInsight: Identifiable {
    let id = UUID()
    let text: String
    let date: Date
    let category: String // Related livestock category
}

// MARK: - Saleyard Report Model
// Debug: Saleyard report summaries with key metrics
struct SaleyardReport: Identifiable {
    let id = UUID()
    let saleyardName: String
    let state: String
    let date: Date
    let yardings: Int // Number of head yarded
    let summary: String
    let categories: [String] // Livestock categories traded
}

// MARK: - Market Intelligence Model
// Debug: AI predictive insights with confidence indicators
struct MarketIntelligence: Identifiable {
    let id = UUID()
    let category: String // Livestock category (e.g., "Cattle - Weaners")
    let prediction: String // Forward-looking insight
    let confidence: ConfidenceLevel
    let timeHorizon: String // e.g., "30-60 days"
    let keyDrivers: [String] // Factors influencing the prediction
    let lastUpdated: Date
}

// MARK: - Confidence Level Enum
enum ConfidenceLevel: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: String {
        switch self {
        case .high: return "green"
        case .medium: return "orange"
        case .low: return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .high: return "checkmark.seal.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .low: return "questionmark.circle.fill"
        }
    }
}



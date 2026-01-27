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
    // Debug: Fetches REAL data from Supabase (cached with daily changes) or MLA API - no mock fallback
    func fetchNationalIndicators() async -> [NationalIndicator] {
        print("🟢 MarketDataService: fetchNationalIndicators called")
        print("🟢 useSupabaseBackend = \(Config.useSupabaseBackend)")
        
        // Try Supabase first (cached data with daily changes)
        if Config.useSupabaseBackend {
            print("🟢 Attempting to fetch from Supabase (cached data with changes)...")
            do {
                let indicators = try await SupabaseMarketService.shared.fetchNationalIndicators()
                if !indicators.isEmpty {
                    print("✅ Successfully fetched \(indicators.count) indicators from Supabase")
                    return indicators
                }
                print("⚠️ Supabase returned empty, trying MLA API...")
            } catch {
                print("⚠️ Supabase fetch failed: \(error), trying MLA API...")
            }
        }
        
        // Fallback to MLA API (direct, no daily changes)
        print("🟢 Attempting to fetch from MLA API...")
        do {
            let indicators = try await MLAAPIService.shared.fetchNationalIndicators()
            print("✅ Successfully fetched \(indicators.count) indicators from MLA API")
            return indicators
        } catch {
            print("❌ Error fetching from MLA API: \(error)")
            return [] // Return empty array on error
        }
    }
    
    // MARK: - Category Prices
    // Debug: Fetch REAL prices from Supabase only - no mock fallback
    func fetchCategoryPrices(
        categories: [String] = [],
        livestockType: LivestockType?,
        saleyard: String?,
        state: String? = nil,
        states: [String]? = nil
    ) async -> [CategoryPrice] {
        print("🔵 Debug: fetchCategoryPrices called")
        print("   categories: \(categories.isEmpty ? "All" : categories.joined(separator: ", "))")
        print("   livestockType: \(livestockType?.rawValue ?? "All")")
        print("   saleyard: \(saleyard ?? "Any")")
        if let states = states {
            print("   states: \(states.joined(separator: ", "))")
        } else {
            print("   state: \(state ?? "Any")")
        }
        
        // Fetch REAL data from Supabase only (no mock fallback)
        if Config.useSupabaseBackend {
            print("🔵 Debug: Fetching from Supabase category_prices...")
            do {
                let prices = try await SupabaseMarketService.shared.fetchCategoryPrices(
                    categories: categories,
                    saleyard: saleyard,
                    state: state,
                    states: states,
                    breed: nil // General prices for now
                )
                
                // Filter by livestock type if specified
                var filteredPrices = prices
                if let livestockType = livestockType {
                    filteredPrices = prices.filter { $0.livestockType == livestockType }
                }
                
                print("✅ Debug: Got \(filteredPrices.count) prices from Supabase")
                return filteredPrices
            } catch {
                print("❌ Debug: Error fetching from Supabase: \(error)")
                return [] // Return empty array on error
            }
        } else {
            print("❌ Debug: Supabase backend disabled in Config")
            return [] // Return empty array if backend disabled
        }
    }
    
    // MARK: - Historical Prices
    // Debug: Fetch REAL historical price data from MLA API (cached in Supabase)
    func fetchHistoricalPrices(
        category: String,
        livestockType: LivestockType,
        months: Int = 12
    ) async -> [HistoricalPricePoint] {
        print("🔵 Debug: fetchHistoricalPrices for \(category) (\(livestockType.rawValue))")
        
        // For cattle categories, use real MLA indicator data
        if livestockType == .cattle {
            // Map category to appropriate indicator
            let indicatorID: Int
            let indicatorCode: String
            
            // Yearling/Young cattle -> EYCI (Eastern Young Cattle Indicator)
            if category.contains("Yearling") || category.contains("Weaner") {
                indicatorID = 0
                indicatorCode = "EYCI"
            }
            // All other cattle -> WYCI (Western Young Cattle Indicator) as fallback
            else {
                indicatorID = 1
                indicatorCode = "WYCI"
            }
            
            // Fetch real historical data from Supabase (which caches MLA API)
            do {
                let days = months * 30 // Approximate days for requested months
                let historicalData = try await SupabaseMarketService.shared.fetchHistoricalIndicatorData(
                    indicatorID: indicatorID,
                    indicatorCode: indicatorCode,
                    days: days
                )
                print("✅ Debug: Got \(historicalData.count) real historical data points from MLA/Supabase")
                return historicalData
            } catch {
                print("❌ Debug: Error fetching real historical data: \(error)")
                return [] // Return empty array for cattle if real data fails
            }
        }
        
        // For non-cattle livestock (sheep, pigs, goats), return empty array
        // Debug: We don't have MLA historical data for these yet
        print("⚠️ Debug: No historical data available for \(livestockType.rawValue) yet")
        return []
    }
    
    
    // MARK: - Regional Comparison
    // Debug: Compare prices across different states for a category
    // TODO: Implement real regional comparison from Supabase category_prices grouped by state
    func fetchRegionalComparison(
        category: String,
        livestockType: LivestockType
    ) async -> [RegionalPrice] {
        print("⚠️ Debug: Regional comparison not yet implemented with real data")
        // Return empty array - no mock financial data
        return []
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
    let changeDuration: String // Debug: Duration for price change (e.g., "24h", "7d")
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
    let changeDuration: String // Debug: Duration for price change (e.g., "24h", "7d")
    let breed: String? // Debug: Breed name (e.g., "Angus", "Hereford") - nil for general prices
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
    let changeDuration: String // Debug: Duration for price change (e.g., "24h", "7d")
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



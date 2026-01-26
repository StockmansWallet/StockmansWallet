//
//  SupabaseMarketService.swift
//  StockmansWallet
//
//  Service for fetching MLA market data from Supabase backend
//  Debug: Fetches cached MLA data from Supabase database tables
//

import Foundation
import Supabase

// MARK: - Supabase Market Service
// Debug: Handles all market data fetching from Supabase backend
@Observable
class SupabaseMarketService {
    static let shared = SupabaseMarketService()
    
    private let supabase = SupabaseClientManager.shared.client
    
    private init() {}
    
    // MARK: - Physical Sales Reports
    // Debug: Fetch cached MLA physical sales report from Supabase
    func fetchPhysicalReport(saleyard: String, date: Date = Date()) async throws -> PhysicalSalesReport? {
        print("🔵 Debug: Fetching physical report for \(saleyard) on \(date)")
        
        // Format date for query
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: date)
        
        // Query Supabase for cached report
        let response: SupabasePhysicalReport = try await supabase
            .from("mla_physical_reports")
            .select()
            .eq("saleyard_name", value: saleyard)
            .eq("report_date", value: dateString)
            .gt("expires_at", value: Date().ISO8601Format()) // Only non-expired
            .single()
            .execute()
            .value
        
        // Convert from Supabase model to app model
        return response.toPhysicalSalesReport()
    }
    
    // MARK: - National Indicators
    // Debug: Fetch cached national indicators (EYCI, WYCI, NSI, NHLI) from Supabase
    func fetchNationalIndicators(date: Date = Date()) async throws -> [NationalIndicator] {
        print("🔵 Debug: Fetching national indicators from Supabase")
        
        // Query Supabase for the most recent indicators that haven't expired
        // Don't filter by exact date - just get the latest data
        let response: [SupabaseNationalIndicator] = try await supabase
            .from("mla_national_indicators")
            .select()
            .gt("expires_at", value: Date().ISO8601Format())
            .order("report_date", ascending: false)
            .limit(10) // Get up to 10 indicators (we only have 2 for MVP: EYCI, WYCI)
            .execute()
            .value
        
        print("✅ Debug: Supabase returned \(response.count) indicators")
        
        // Convert to app models
        return response.map { $0.toNationalIndicator() }
    }
    
    // MARK: - Saleyard Reports
    // Debug: Fetch cached saleyard reports from Supabase
    func fetchSaleyardReports(state: String? = nil, limit: Int = 10) async throws -> [SaleyardReport] {
        print("🔵 Debug: Fetching saleyard reports for state: \(state ?? "all")")
        
        // Build query with all filters before executing
        var queryBuilder = supabase
            .from("mla_saleyard_reports")
            .select()
            .gt("expires_at", value: Date().ISO8601Format())
        
        // Filter by state if provided (apply before order and limit)
        if let state = state {
            queryBuilder = queryBuilder.eq("state", value: state)
        }
        
        // Apply order and limit at the end
        let response: [SupabaseSaleyardReport] = try await queryBuilder
            .order("report_date", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return response.map { $0.toSaleyardReport() }
    }
    
    // MARK: - Category Prices (Smart Mapped)
    // Debug: Fetch smart-mapped category prices from Supabase
    func fetchCategoryPrices(
        categories: [String] = [],
        saleyard: String? = nil,
        state: String? = nil,
        breed: String? = nil
    ) async throws -> [CategoryPrice] {
        print("🔵 Debug: Fetching category prices from Supabase")
        print("   Categories: \(categories.isEmpty ? "All" : categories.joined(separator: ", "))")
        print("   Saleyard: \(saleyard ?? "Any")")
        print("   State: \(state ?? "Any")")
        print("   Breed: \(breed ?? "General")")
        
        // Build query
        var query = supabase
            .from("category_prices")
            .select()
            .gt("expires_at", value: Date().ISO8601Format())
        
        // Apply filters
        if !categories.isEmpty {
            query = query.in("category", values: categories)
        }
        
        if let saleyard = saleyard {
            query = query.eq("saleyard", value: saleyard)
        }
        
        if let state = state {
            query = query.eq("state", value: state)
        }
        
        // Breed filter (NULL = general prices, specific breed = breed-specific)
        if let breed = breed {
            query = query.or("breed.eq.\(breed),breed.is.null")
        }
        
        let response: [SupabaseCategoryPrice] = try await query
            .order("data_date", ascending: false)
            .limit(500) // Fetch enough to include all categories
            .execute()
            .value
        
        print("✅ Debug: Supabase returned \(response.count) category prices")
        
        // Debug: Include both general prices AND breed-specific prices
        // This allows the UI to show breed badges when available
        print("🔵 Debug: Including all prices (general + breed-specific)")
        
        // Convert to app models
        return response.map { $0.toCategoryPrice() }
    }
    
    // MARK: - Check Data Freshness
    // Debug: Check if we have fresh data for a given saleyard and date
    func hasFreshData(saleyard: String, date: Date) async -> Bool {
        do {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            let dateString = dateFormatter.string(from: date)
            
            let count: Int = try await supabase
                .from("mla_physical_reports")
                .select("id", head: false, count: .exact)
                .eq("saleyard_name", value: saleyard)
                .eq("report_date", value: dateString)
                .gt("expires_at", value: Date().ISO8601Format())
                .execute()
                .count ?? 0
            
            return count > 0
        } catch {
            print("❌ Debug: Error checking data freshness: \(error)")
            return false
        }
    }
    
    // MARK: - Historical Indicator Data
    // Debug: Fetch historical indicator data from cache (or MLA API if not cached)
    func fetchHistoricalIndicatorData(indicatorID: Int, indicatorCode: String, days: Int = 365) async throws -> [HistoricalPricePoint] {
        print("🔵 Debug: Fetching \(days) days of historical data for \(indicatorCode)")
        
        // Check if we have cached data (less than 24 hours old)
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        let response: [SupabaseHistoricalIndicator] = try await supabase
            .from("mla_historical_indicators")
            .select()
            .eq("indicator_id", value: indicatorID)
            .gte("updated_at", value: oneDayAgo.ISO8601Format())
            .order("calendar_date", ascending: false)
            .limit(days)
            .execute()
            .value
        
        // If we have enough fresh cached data, use it
        if response.count >= days - 7 { // Allow 7 days tolerance
            print("✅ Debug: Using \(response.count) cached historical data points")
            return response.map { $0.toHistoricalPricePoint() }
        }
        
        // Otherwise, fetch from MLA API and cache it
        print("🔵 Debug: Cache miss or stale, fetching from MLA API...")
        let mlaData = try await MLAAPIService.shared.fetchHistoricalIndicatorData(indicatorID: indicatorID, days: days)
        
        // Cache the data in Supabase
        print("🔵 Debug: Caching \(mlaData.count) historical data points...")
        try await cacheHistoricalIndicatorData(mlaData, indicatorCode: indicatorCode)
        
        // Convert to HistoricalPricePoint
        return mlaData.map { point in
            HistoricalPricePoint(date: point.date, price: point.value)
        }
    }
    
    // MARK: - Cache Historical Data
    // Debug: Store historical indicator data in Supabase
    private func cacheHistoricalIndicatorData(_ dataPoints: [MLAHistoricalDataPoint], indicatorCode: String) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Convert to cacheable struct
        let cacheData = dataPoints.map { point in
            SupabaseHistoricalIndicatorInsert(
                indicator_id: point.indicatorID,
                indicator_name: point.indicatorName,
                indicator_code: indicatorCode,
                calendar_date: dateFormatter.string(from: point.date),
                value: point.value,
                unit: "¢/kg cwt"
            )
        }
        
        // Upsert (insert or update if exists)
        try await supabase
            .from("mla_historical_indicators")
            .upsert(cacheData)
            .execute()
        
        print("✅ Debug: Cached \(dataPoints.count) historical data points")
    }
}

// MARK: - Supabase Models
// Debug: Models matching Supabase database schema

struct SupabasePhysicalReport: Codable {
    let id: String
    let saleyard_name: String
    let report_date: String
    let comparison_date: String? // Debug: For price comparison
    let total_yarding: Int?
    let report_summary: String?
    let state: String? // Debug: State where saleyard is located
    let audio_url: String? // Debug: Audio recording URL
    let report_data: ReportData?
    
    struct ReportData: Codable {
        let categories: [CategoryData]?
        
        struct CategoryData: Codable {
            let category_name: String
            let weight_range: String
            let sale_prefix: String
            let muscle_score: String?
            let fat_score: Int?
            let head_count: Int
            let min_price_cents_kg: Double?
            let max_price_cents_kg: Double?
            let avg_price_cents_kg: Double?
            let min_price_dollars_head: Double?
            let max_price_dollars_head: Double?
            let avg_price_dollars_head: Double?
            let price_change_per_kg: Double? // Debug: Change from comparison date
            let price_change_per_head: Double? // Debug: Change from comparison date
        }
    }
    
    func toPhysicalSalesReport() -> PhysicalSalesReport {
        let dateFormatter = ISO8601DateFormatter()
        let reportDate = dateFormatter.date(from: report_date) ?? Date()
        
        // Debug: Parse comparison date if available
        let comparisonDate: Date? = {
            guard let comparison_date = comparison_date else { return nil }
            return dateFormatter.date(from: comparison_date)
        }()
        
        let categories = report_data?.categories?.map { category in
            PhysicalSalesCategory(
                id: UUID().uuidString,
                categoryName: category.category_name,
                weightRange: category.weight_range,
                salePrefix: category.sale_prefix,
                muscleScore: category.muscle_score,
                fatScore: category.fat_score,
                headCount: category.head_count,
                minPriceCentsPerKg: category.min_price_cents_kg,
                maxPriceCentsPerKg: category.max_price_cents_kg,
                avgPriceCentsPerKg: category.avg_price_cents_kg,
                minPriceDollarsPerHead: category.min_price_dollars_head,
                maxPriceDollarsPerHead: category.max_price_dollars_head,
                avgPriceDollarsPerHead: category.avg_price_dollars_head,
                priceChangePerKg: category.price_change_per_kg,
                priceChangePerHead: category.price_change_per_head
            )
        } ?? []
        
        return PhysicalSalesReport(
            id: id,
            saleyard: saleyard_name,
            reportDate: reportDate,
            comparisonDate: comparisonDate,
            totalYarding: total_yarding ?? 0,
            categories: categories,
            state: state,
            summary: report_summary,
            audioURL: audio_url
        )
    }
}

struct SupabaseNationalIndicator: Codable {
    let id: String
    let indicator_code: String
    let indicator_name: String?
    let value: Double
    let change: Double
    let trend: String
    let report_date: String
    
    func toNationalIndicator() -> NationalIndicator {
        return NationalIndicator(
            name: indicator_name ?? indicator_code,
            abbreviation: indicator_code,
            value: value,
            change: change,
            trend: parseTrend(trend),
            unit: "¢/kg cwt",
            changeDuration: "24h" // Debug: Daily change from Supabase
        )
    }
    
    // Debug: Parse trend string to enum, use .neutral instead of .steady
    private func parseTrend(_ trendString: String) -> PriceTrend {
        switch trendString.lowercased() {
        case "up": return .up
        case "down": return .down
        default: return .neutral
        }
    }
}

struct SupabaseSaleyardReport: Codable {
    let id: String
    let saleyard_name: String
    let state: String?
    let report_date: String
    let yardings: Int?
    let summary: String?
    let categories: [String]?
    
    func toSaleyardReport() -> SaleyardReport {
        let dateFormatter = ISO8601DateFormatter()
        let reportDate = dateFormatter.date(from: report_date) ?? Date()
        
        return SaleyardReport(
            saleyardName: saleyard_name,
            state: state ?? "Unknown",
            date: reportDate,
            yardings: yardings ?? 0,
            summary: summary ?? "",
            categories: categories ?? []
        )
    }
}

struct SupabaseHistoricalIndicator: Codable {
    let id: String
    let indicator_id: Int
    let indicator_name: String
    let indicator_code: String
    let calendar_date: String
    let value: Double
    let unit: String?
    
    func toHistoricalPricePoint() -> HistoricalPricePoint {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: calendar_date) ?? Date()
        
        return HistoricalPricePoint(date: date, price: value)
    }
}

// Debug: Model for inserting historical indicator data
struct SupabaseHistoricalIndicatorInsert: Codable {
    let indicator_id: Int
    let indicator_name: String
    let indicator_code: String
    let calendar_date: String
    let value: Double
    let unit: String
}

// Debug: Smart-mapped category price from Supabase
struct SupabaseCategoryPrice: Codable {
    let id: String
    let category: String
    let species: String
    let breed: String?
    let breed_premium_pct: Double
    let base_price_per_kg: Double
    let final_price_per_kg: Double
    let weight_range: String?
    let saleyard: String
    let state: String
    let source: String
    let mla_category: String
    let data_date: String
    
    func toCategoryPrice() -> CategoryPrice {
        // Map species string to LivestockType enum
        let livestockType: LivestockType
        switch species.lowercased() {
        case "cattle":
            livestockType = .cattle
        case "sheep":
            livestockType = .sheep
        case "pigs":
            livestockType = .pigs
        case "goats":
            livestockType = .goats
        default:
            livestockType = .cattle
        }
        
        // Convert cents to dollars
        let priceInDollars = final_price_per_kg / 100.0
        
        return CategoryPrice(
            category: category,
            livestockType: livestockType,
            price: priceInDollars,
            change: 0.0, // TODO: Calculate from previous day's data
            trend: .neutral,
            weightRange: weight_range ?? "Variable",
            source: saleyard,
            changeDuration: "24h",
            breed: breed // Debug: Include breed from Supabase (nil for general prices)
        )
    }
}

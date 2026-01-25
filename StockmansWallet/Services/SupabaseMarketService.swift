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
        print("🔵 Debug: Fetching national indicators for \(date)")
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: date)
        
        // Query Supabase for all indicators for the given date
        let response: [SupabaseNationalIndicator] = try await supabase
            .from("mla_national_indicators")
            .select()
            .eq("report_date", value: dateString)
            .gt("expires_at", value: Date().ISO8601Format())
            .execute()
            .value
        
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
}

// MARK: - Supabase Models
// Debug: Models matching Supabase database schema

struct SupabasePhysicalReport: Codable {
    let id: String
    let saleyard_name: String
    let report_date: String
    let total_yarding: Int?
    let report_summary: String?
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
        }
    }
    
    func toPhysicalSalesReport() -> PhysicalSalesReport {
        let dateFormatter = ISO8601DateFormatter()
        let reportDate = dateFormatter.date(from: report_date) ?? Date()
        
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
                avgPriceDollarsPerHead: category.avg_price_dollars_head
            )
        } ?? []
        
        return PhysicalSalesReport(
            id: id,
            saleyard: saleyard_name,
            reportDate: reportDate,
            totalYarding: total_yarding ?? 0,
            categories: categories
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
            unit: "¢/kg cwt"
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

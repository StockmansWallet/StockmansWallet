//
//  ReportData.swift
//  StockmansWallet
//
//  Data models for report generation
//  Debug: Structured data for different report types
//

import Foundation

// MARK: - Main Report Data
// Debug: Container for all report data
struct ReportData {
    var farmName: String?
    var totalValue: Double
    var totalSales: Double
    var herdData: [HerdReportData]
    var salesData: [SaleReportData]
    var saleyardComparison: [SaleyardComparisonData]
    var landValueAnalysis: [LandValueAnalysisData]
    var farmComparison: [FarmComparisonData]
}

// MARK: - Herd Report Data
struct HerdReportData: Identifiable {
    let id: UUID
    let name: String
    let category: String
    let headCount: Int
    let ageMonths: Int
    let weight: Double
    let pricePerKg: Double
    let minPrice: Double
    let maxPrice: Double
    let avgPrice: Double
    let netValue: Double
}

// MARK: - Sale Report Data
struct SaleReportData: Identifiable {
    let id: UUID
    let date: Date
    let headCount: Int
    let avgWeight: Double
    let pricePerKg: Double
    let netValue: Double
}

// MARK: - Saleyard Comparison Data
struct SaleyardComparisonData: Identifiable {
    let id = UUID()
    let saleyardName: String
    let avgPrice: Double
    let minPrice: Double
    let maxPrice: Double
    let totalHeadCount: Int
}

// MARK: - Land Value Analysis Data
struct LandValueAnalysisData: Identifiable {
    let id = UUID()
    let propertyName: String
    let acreage: Double
    let livestockValue: Double
    let valuePerAcre: Double
    let totalHeadCount: Int
}

// MARK: - Farm Comparison Data
struct FarmComparisonData: Identifiable {
    let id = UUID()
    let propertyName: String
    let totalValue: Double
    let totalHeadCount: Int
    let avgPricePerKg: Double
    let valuePerHead: Double
}





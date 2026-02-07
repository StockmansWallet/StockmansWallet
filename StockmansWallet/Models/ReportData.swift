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
    // Debug: User and property details for PDF headers
    var userDetails: UserDetails?
    var propertyDetails: PropertyDetails?
}

// MARK: - User Details
// Debug: User information for PDF headers from UserPreferences
struct UserDetails {
    let fullName: String?
    let email: String?
    let propertyName: String?
    let propertyPIC: String?
    let propertyRole: String?
    let propertyAddress: String?
    let state: String?
    // For advisory users
    let companyName: String?
    let companyType: String?
    let roleInCompany: String?
}

// MARK: - Property Details
// Debug: Additional property information for reports
struct PropertyDetails {
    let acreage: Double?
    let propertyType: String?
    let defaultSaleyard: String?
    let region: String?
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
    // Debug: Additional fields for Asset Register (bank review)
    let breedingAccrual: Double? // Calf accrual value for breeding stock
    let dailyWeightGain: Double // DWG allocation in kg/day
    let mortalityRate: Double // Mortality rate as decimal (e.g., 0.05 for 5%)
    let isBreeder: Bool // Flag to identify breeding stock
}

// MARK: - Sale Report Data
// Debug: Enhanced with pricing type, sale type, and location
struct SaleReportData: Identifiable {
    let id: UUID
    let date: Date
    let headCount: Int
    let avgWeight: Double
    let pricePerKg: Double
    let pricePerHead: Double? // Debug: Optional price per head
    let pricingType: PricingType // Debug: Pricing type enum
    let saleType: String? // Debug: Sale type (Saleyard, Private Sale, Other)
    let saleLocation: String? // Debug: Location name
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





//
//  PhysicalSalesModels.swift
//  StockmansWallet
//
//  Models for Physical Sales Reports
//  Debug: Separated from Supabase service so they can be used independently
//

import Foundation

// MARK: - App Models for Physical Sales
// Debug: Models used in the iOS app UI

struct PhysicalSalesReport: Identifiable, Codable {
    let id: String
    let saleyard: String
    let reportDate: Date
    let comparisonDate: Date? // Debug: For showing comparison data (e.g., previous day)
    let totalYarding: Int
    let categories: [PhysicalSalesCategory]
    let state: String? // Debug: State where saleyard is located
    let summary: String? // Debug: Text summary of the market report
    let audioURL: String? // Debug: URL to audio recording of report
}

struct PhysicalSalesCategory: Identifiable, Codable {
    let id: String
    let categoryName: String
    let weightRange: String
    let salePrefix: String
    let muscleScore: String?
    let fatScore: Int?
    let headCount: Int
    let minPriceCentsPerKg: Double?
    let maxPriceCentsPerKg: Double?
    let avgPriceCentsPerKg: Double?
    let minPriceDollarsPerHead: Double?
    let maxPriceDollarsPerHead: Double?
    let avgPriceDollarsPerHead: Double?
    
    // Debug: Additional fields for change tracking
    let priceChangePerKg: Double? // Debug: Change from comparison date
    let priceChangePerHead: Double? // Debug: Change from comparison date
}

// MARK: - Filter Options
// Debug: Enums for filtering physical sales data

enum PhysicalSalesFilter {
    case all
    case category(String)
    case salePrefix(String)
    case state(String)
}

// MARK: - Available Categories
// Debug: Categories that can appear in physical sales reports
struct PhysicalSalesCategories {
    static let cattle = [
        "Bulls",
        "Cows",
        "Grown Heifer",
        "Grown Steer",
        "Yearling Heifer",
        "Yearling Steer"
    ]
    
    static let salePrefixes = [
        "Feeder",
        "Processor",
        "PTIC",
        "Restocker"
    ]
}

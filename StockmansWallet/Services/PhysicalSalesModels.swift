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
    let totalYarding: Int
    let categories: [PhysicalSalesCategory]
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
}

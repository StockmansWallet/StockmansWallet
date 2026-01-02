//
//  Models+DerivedTypes.swift
//  StockmansWallet
//
//  Lightweight data models used by views (charts and market).
//

import Foundation

// MARK: - Valuation Data Point (for charts like DashboardView)
struct ValuationDataPoint: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let value: Double
    let physicalValue: Double
    let breedingAccrual: Double
    
    init(
        id: UUID = UUID(),
        date: Date,
        value: Double,
        physicalValue: Double,
        breedingAccrual: Double
    ) {
        self.id = id
        self.date = date
        self.value = value
        self.physicalValue = physicalValue
        self.breedingAccrual = breedingAccrual
    }
}

// MARK: - Market Price Data (for MarketView and portfolio market components)
enum PriceTrend: String, Codable {
    case up
    case down
    case neutral
}

struct MarketPriceData: Identifiable, Hashable, Codable {
    let id: UUID
    let category: String
    let price: Double
    let change: Double
    let trend: PriceTrend
    
    init(
        id: UUID = UUID(),
        category: String,
        price: Double,
        change: Double,
        trend: PriceTrend
    ) {
        self.id = id
        self.category = category
        self.price = price
        self.change = change
        self.trend = trend
    }
}

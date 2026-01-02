//
//  MarketPrice.swift
//  StockmansWallet
//
//  SwiftData Model for Cached Market Pricing Data
//

import Foundation
import SwiftData

@Model
final class MarketPrice {
    var id: UUID
    var category: String // Market category (e.g., "Feeder Steer", "Breeding Cow")
    var saleyard: String?
    var state: String?
    var pricePerKg: Double
    var priceDate: Date
    var source: String // "Saleyard", "State Indicator", "National Benchmark"
    var isHistorical: Bool
    
    init(
        category: String,
        saleyard: String? = nil,
        state: String? = nil,
        pricePerKg: Double,
        priceDate: Date = Date(),
        source: String,
        isHistorical: Bool = false
    ) {
        self.id = UUID()
        self.category = category
        self.saleyard = saleyard
        self.state = state
        self.pricePerKg = pricePerKg
        self.priceDate = priceDate
        self.source = source
        self.isHistorical = isHistorical
    }
}



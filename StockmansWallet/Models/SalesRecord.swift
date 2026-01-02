//
//  SalesRecord.swift
//  StockmansWallet
//
//  SwiftData Model for Sales Transactions
//

import Foundation
import SwiftData

@Model
final class SalesRecord {
    var id: UUID
    var herdGroupId: UUID
    var saleDate: Date
    var headCount: Int
    var averageWeight: Double // kg
    var pricePerKg: Double
    var totalGrossValue: Double
    var freightCost: Double
    var freightDistance: Double // km
    var netValue: Double
    var notes: String?
    var pdfPath: String? // Path to generated Pro-forma PDF
    
    init(
        herdGroupId: UUID,
        saleDate: Date,
        headCount: Int,
        averageWeight: Double,
        pricePerKg: Double,
        totalGrossValue: Double,
        freightCost: Double = 0.0,
        freightDistance: Double = 0.0,
        netValue: Double,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.herdGroupId = herdGroupId
        self.saleDate = saleDate
        self.headCount = headCount
        self.averageWeight = averageWeight
        self.pricePerKg = pricePerKg
        self.totalGrossValue = totalGrossValue
        self.freightCost = freightCost
        self.freightDistance = freightDistance
        self.netValue = netValue
        self.notes = notes
        self.pdfPath = nil
    }
}



//
//  MockDataService.swift
//  StockmansWallet
//
//  Generates realistic mock data for testing
//

import Foundation
import SwiftData

@MainActor
class MockDataService {
    static let shared = MockDataService()
    
    // MARK: - Generate Mock Herd Data
    func generateMockHerds(modelContext: ModelContext, preferences: UserPreferences) async {
        let calendar = Calendar.current
        
        // Generate herds with different start dates over the past year
        let herdConfigs: [(name: String, breed: String, category: String, headCount: Int, initialWeight: Double, dwg: Double, startDateOffset: Int)] = [
            ("North Paddock - Breeding Cows", "Angus", "Breeding Cow", 120, 550.0, 0.3, -365),
            ("South Paddock - Yearling Steers", "Hereford", "Yearling Steer", 85, 380.0, 0.9, -300),
            ("East Paddock - Weaners", "Angus X Friesian", "Weaner Steer", 150, 250.0, 1.1, -180),
            ("West Paddock - Feeder Steers", "Charolais", "Grown Steer", 65, 450.0, 0.7, -120),
            ("Central Paddock - Heifers", "Murray Grey", "Heifer", 95, 320.0, 0.8, -90),
        ]
        
        for config in herdConfigs {
            let startDate = calendar.date(byAdding: .day, value: config.startDateOffset, to: Date()) ?? Date()
            
            let herd = HerdGroup(
                name: config.name,
                species: "Cattle",
                breed: config.breed,
                sex: config.category.contains("Cow") || config.category.contains("Heifer") ? "Female" : "Male",
                category: config.category,
                ageMonths: config.category.contains("Weaner") ? 8 : config.category.contains("Yearling") ? 18 : 36,
                headCount: config.headCount,
                initialWeight: config.initialWeight,
                dailyWeightGain: config.dwg,
                isBreeder: config.category.contains("Breeding") || config.category.contains("Heifer"),
                selectedSaleyard: preferences.defaultSaleyard
            )
            
            herd.createdAt = startDate
            herd.updatedAt = startDate
            herd.isPregnant = herd.isBreeder && Bool.random()
            
            if herd.isPregnant {
                let joinedDate = calendar.date(byAdding: .day, value: -150, to: startDate) ?? startDate
                herd.joinedDate = joinedDate
            }
            
            modelContext.insert(herd)
        }
        
        // Debug: Generate individual tagged animals for testing searchable list
        let individualAnimals: [(name: String, breed: String, category: String, weight: Double, dwg: Double, paddock: String, tagInfo: String)] = [
            ("Bessie #A123", "Angus", "Breeding Cow", 580.0, 0.2, "North Paddock", "NLIS: 982000123456789"),
            ("Bull #B456", "Angus", "Breeding Cow", 920.0, 0.3, "North Paddock", "NLIS: 982000234567890"),
            ("Daisy #C789", "Angus", "Breeding Cow", 550.0, 0.2, "North Paddock", "NLIS: 982000345678901"),
            ("Rex #D012", "Hereford", "Yearling Steer", 420.0, 0.9, "South Paddock", "NLIS: 982000456789012"),
            ("Max #E345", "Hereford", "Yearling Steer", 395.0, 0.8, "South Paddock", "NLIS: 982000567890123"),
            ("Duke #F678", "Angus X Friesian", "Weaner Steer", 265.0, 1.1, "East Paddock", "NLIS: 982000678901234"),
            ("Rusty #G901", "Angus X Friesian", "Weaner Steer", 248.0, 1.0, "East Paddock", "NLIS: 982000789012345"),
            ("Blaze #H234", "Charolais", "Grown Steer", 485.0, 0.7, "West Paddock", "NLIS: 982000890123456"),
            ("Thunder #I567", "Charolais", "Grown Steer", 470.0, 0.6, "West Paddock", "NLIS: 982000901234567"),
            ("Rosie #J890", "Murray Grey", "Heifer", 340.0, 0.8, "Central Paddock", "NLIS: 982001012345678"),
        ]
        
        for animal in individualAnimals {
            let startDate = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            
            let individual = HerdGroup(
                name: animal.name,
                species: "Cattle",
                breed: animal.breed,
                sex: animal.category.contains("Cow") || animal.category.contains("Heifer") ? "Female" : "Male",
                category: animal.category,
                ageMonths: animal.category.contains("Weaner") ? 8 : animal.category.contains("Yearling") ? 18 : 36,
                headCount: 1, // Debug: Individual animal
                initialWeight: animal.weight,
                dailyWeightGain: animal.dwg,
                isBreeder: animal.category.contains("Breeding") || animal.category.contains("Heifer"),
                selectedSaleyard: preferences.defaultSaleyard
            )
            
            individual.createdAt = startDate
            individual.updatedAt = startDate
            individual.paddockName = animal.paddock
            individual.additionalInfo = animal.tagInfo
            
            modelContext.insert(individual)
        }
        
        // Note: Sales records would need to be linked to actual herd IDs
        // This is a simplified version - sales records generation can be added later
        
        try? modelContext.save()
    }
    
    // MARK: - Generate Historical Market Prices
    func generateHistoricalMarketPrices(modelContext: ModelContext, preferences: UserPreferences) async {
        let calendar = Calendar.current
        let categories = ["Feeder Steer", "Yearling Steer", "Breeding Cow", "Weaner Steer"]
        
        // Generate prices for the past year (daily)
        // Debug: Base price adjusted by 45% reduction (×0.55) for realistic market values
        var basePrice = 3.58 // Adjusted from 6.50 (×0.55)
        let volatility = 0.15 // 15% volatility
        
        for dayOffset in (0..<365).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            // Simulate price movement with some trend
            let trend = sin(Double(dayOffset) / 365.0 * 2 * .pi) * 0.3 // Seasonal trend
            let random = (Double.random(in: -1...1) * volatility)
            // Debug: Price clamps adjusted by 45% reduction (×0.55) for realistic ranges
            basePrice = max(2.20, min(4.95, basePrice + trend + random)) // Adjusted from 4.0-9.0 (×0.55)
            
            for category in categories {
                // Category-specific price adjustments
                var categoryPrice = basePrice
                switch category {
                case "Weaner Steer":
                    categoryPrice = basePrice * 1.15
                case "Yearling Steer":
                    categoryPrice = basePrice * 1.05
                case "Breeding Cow":
                    categoryPrice = basePrice * 0.65
                default:
                    categoryPrice = basePrice
                }
                
                let marketPrice = MarketPrice(
                    category: category,
                    saleyard: preferences.defaultSaleyard,
                    state: preferences.defaultState,
                    pricePerKg: categoryPrice,
                    priceDate: date,
                    source: dayOffset < 7 ? "Saleyard" : "State Indicator",
                    isHistorical: dayOffset > 0
                )
                
                modelContext.insert(marketPrice)
            }
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Generate Complete Mock Dataset
    func generateCompleteMockData(modelContext: ModelContext, preferences: UserPreferences) async {
        await generateMockHerds(modelContext: modelContext, preferences: preferences)
        await generateHistoricalMarketPrices(modelContext: modelContext, preferences: preferences)
    }
    
    // MARK: - Clear Mock Data
    func clearMockData(modelContext: ModelContext) async {
        // Delete all herds
        let herdDescriptor = FetchDescriptor<HerdGroup>()
        if let herds = try? modelContext.fetch(herdDescriptor) {
            for herd in herds {
                modelContext.delete(herd)
            }
        }
        
        // Delete all market prices
        let priceDescriptor = FetchDescriptor<MarketPrice>()
        if let prices = try? modelContext.fetch(priceDescriptor) {
            for price in prices {
                modelContext.delete(price)
            }
        }
        
        // Delete all sales records
        let salesDescriptor = FetchDescriptor<SalesRecord>()
        if let sales = try? modelContext.fetch(salesDescriptor) {
            for sale in sales {
                modelContext.delete(sale)
            }
        }
        
        try? modelContext.save()
    }
}


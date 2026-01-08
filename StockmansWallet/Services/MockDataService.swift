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
        // Debug: Expanded collection with varied breeds, categories, weights, and realistic NLIS tags
        let individualAnimals: [(name: String, breed: String, category: String, weight: Double, dwg: Double, paddock: String, tagInfo: String, daysAgo: Int, ageMonths: Int)] = [
            // North Paddock - Breeding Cows (Angus) - Mix of nicknamed and ID-only
            ("Bessie #A001", "Angus", "Breeding Cow", 580.0, 0.2, "North Paddock", "NLIS: 982000123456789", -365, 48),
            ("Matilda #A002", "Angus", "Breeding Cow", 565.0, 0.25, "North Paddock", "NLIS: 982000123456790", -365, 52),
            ("#A003", "Angus", "Breeding Cow", 590.0, 0.18, "North Paddock", "NLIS: 982000123456791", -340, 45), // No nickname
            ("Pearl #A004", "Angus", "Breeding Cow", 572.0, 0.22, "North Paddock", "NLIS: 982000123456792", -365, 54),
            ("#A005", "Angus", "Breeding Cow", 555.0, 0.21, "North Paddock", "NLIS: 982000123456793", -320, 46), // No nickname
            ("Luna #A006", "Angus", "Breeding Cow", 568.0, 0.19, "North Paddock", "NLIS: 982000123456794", -365, 50),
            ("#A007", "Angus", "Breeding Cow", 550.0, 0.2, "North Paddock", "NLIS: 982000345678901", -300, 49), // No nickname
            ("Rosie #A008", "Angus", "Breeding Cow", 585.0, 0.23, "North Paddock", "NLIS: 982000123456795", -310, 47),
            
            // North Paddock - Bulls
            ("#B001", "Angus", "Bull", 920.0, 0.3, "North Paddock", "NLIS: 982000234567890", -400, 60), // No nickname
            ("Caesar #B002", "Angus", "Bull", 950.0, 0.28, "North Paddock", "NLIS: 982000234567891", -420, 72),
            
            // South Paddock - Yearling Steers (Hereford) - Mostly ID-only
            ("#S001", "Hereford", "Yearling Steer", 420.0, 0.9, "South Paddock", "NLIS: 982000456789012", -300, 16), // No nickname
            ("#S002", "Hereford", "Yearling Steer", 395.0, 0.8, "South Paddock", "NLIS: 982000567890123", -290, 15), // No nickname
            ("#S003", "Hereford", "Yearling Steer", 410.0, 0.85, "South Paddock", "NLIS: 982000456789013", -300, 17), // No nickname
            ("Rocky #S004", "Hereford", "Yearling Steer", 405.0, 0.92, "South Paddock", "NLIS: 982000456789014", -280, 16),
            ("#S005", "Hereford", "Yearling Steer", 390.0, 0.88, "South Paddock", "NLIS: 982000456789015", -295, 15), // No nickname
            ("#S006", "Hereford", "Yearling Steer", 425.0, 0.91, "South Paddock", "NLIS: 982000456789016", -310, 18), // No nickname
            ("#S007", "Hereford", "Yearling Steer", 415.0, 0.87, "South Paddock", "NLIS: 982000456789017", -285, 16), // No nickname
            
            // East Paddock - Weaners (Angus X Friesian) - All ID-only
            ("#W001", "Angus X Friesian", "Weaner Steer", 265.0, 1.1, "East Paddock", "NLIS: 982000678901234", -180, 8),
            ("#W002", "Angus X Friesian", "Weaner Steer", 248.0, 1.0, "East Paddock", "NLIS: 982000789012345", -175, 7),
            ("#W003", "Angus X Friesian", "Weaner Steer", 255.0, 1.15, "East Paddock", "NLIS: 982000678901235", -180, 8),
            ("#W004", "Angus X Friesian", "Weaner Steer", 270.0, 1.08, "East Paddock", "NLIS: 982000678901236", -170, 9),
            ("#W005", "Angus X Friesian", "Weaner Steer", 260.0, 1.12, "East Paddock", "NLIS: 982000678901237", -180, 8),
            ("#W006", "Angus X Friesian", "Weaner Steer", 252.0, 1.05, "East Paddock", "NLIS: 982000678901238", -185, 7),
            ("#W007", "Angus X Friesian", "Weaner Steer", 268.0, 1.18, "East Paddock", "NLIS: 982000678901239", -175, 8),
            ("#W008", "Angus X Friesian", "Weaner Steer", 245.0, 1.02, "East Paddock", "NLIS: 982000678901240", -190, 7),
            ("#W009", "Angus X Friesian", "Weaner Steer", 258.0, 1.09, "East Paddock", "NLIS: 982000678901241", -180, 8),
            
            // West Paddock - Grown Steers (Charolais) - Mix
            ("Blaze #G001", "Charolais", "Grown Steer", 485.0, 0.7, "West Paddock", "NLIS: 982000890123456", -120, 26),
            ("#G002", "Charolais", "Grown Steer", 470.0, 0.6, "West Paddock", "NLIS: 982000901234567", -115, 24), // No nickname
            ("Titan #G003", "Charolais", "Grown Steer", 495.0, 0.72, "West Paddock", "NLIS: 982000890123457", -120, 28),
            ("#G004", "Charolais", "Grown Steer", 478.0, 0.68, "West Paddock", "NLIS: 982000890123458", -125, 25), // No nickname
            ("Zeus #G005", "Charolais", "Grown Steer", 490.0, 0.71, "West Paddock", "NLIS: 982000890123459", -118, 27),
            ("#G006", "Charolais", "Grown Steer", 482.0, 0.65, "West Paddock", "NLIS: 982000890123460", -122, 26), // No nickname
            
            // Central Paddock - Heifers (Murray Grey) - All have nicknames
            ("Rosie #H001", "Murray Grey", "Heifer", 340.0, 0.8, "Central Paddock", "NLIS: 982001012345678", -90, 14),
            ("Lily #H002", "Murray Grey", "Heifer", 335.0, 0.82, "Central Paddock", "NLIS: 982001012345679", -92, 13),
            ("Willow #H003", "Murray Grey", "Heifer", 345.0, 0.78, "Central Paddock", "NLIS: 982001012345680", -88, 15),
            ("Poppy #H004", "Murray Grey", "Heifer", 338.0, 0.81, "Central Paddock", "NLIS: 982001012345681", -90, 14),
            ("Ivy #H005", "Murray Grey", "Heifer", 342.0, 0.79, "Central Paddock", "NLIS: 982001012345682", -95, 14),
            ("Hazel #H006", "Murray Grey", "Heifer", 330.0, 0.83, "Central Paddock", "NLIS: 982001012345683", -85, 13),
            
            // River Paddock - Feeder Steers (Brahman) - ID-only
            ("#F001", "Brahman", "Feeder Steer", 365.0, 0.95, "River Paddock", "NLIS: 982001112345600", -150, 12),
            ("#F002", "Brahman", "Feeder Steer", 358.0, 0.92, "River Paddock", "NLIS: 982001112345601", -155, 11),
            ("#F003", "Brahman", "Feeder Steer", 370.0, 0.98, "River Paddock", "NLIS: 982001112345602", -148, 13),
            ("#F004", "Brahman", "Feeder Steer", 362.0, 0.94, "River Paddock", "NLIS: 982001112345603", -152, 12),
            ("#F005", "Brahman", "Feeder Steer", 368.0, 0.96, "River Paddock", "NLIS: 982001112345604", -150, 12),
            
            // Hill Paddock - Mixed Breeds (Speckle Park & Limousin)
            ("Freckle #S03", "Speckle Park", "Heifer", 335.0, 0.89, "Hill Top", "NLISL 982501100001103", -270, 16),
            ("#L001", "Speckle Park", "Yearling Steer", 405.0, 0.91, "Hill Paddock", "NLIS: 982001212345701", -275, 17), // No nickname
            ("Storm #L002", "Limousin", "Grown Steer", 488.0, 0.73, "Hill Paddock", "NLIS: 982001312345800", -130, 27),
            ("#L003", "Limousin", "Grown Steer", 492.0, 0.69, "Hill Paddock", "NLIS: 982001312345801", -135, 28), // No nickname
            
            // Valley Paddock - Santa Gertrudis
            ("Jasper #V001", "Santa Gertrudis", "Feeder Steer", 372.0, 0.97, "Valley Paddock", "NLIS: 982001412345900", -145, 13),
            ("#V002", "Santa Gertrudis", "Feeder Steer", 366.0, 0.93, "Valley Paddock", "NLIS: 982001412345901", -150, 12), // No nickname
            ("Russet #V003", "Santa Gertrudis", "Breeding Cow", 575.0, 0.24, "Valley Paddock", "NLIS: 982001412345902", -330, 51),
            
            // Home Paddock - Premium Wagyu - All have nicknames (premium stock)
            ("Kobe #P001", "Wagyu", "Grown Steer", 465.0, 0.62, "Home Paddock", "NLIS: 982001612346100", -200, 30),
            ("Miyazaki #P002", "Wagyu", "Grown Steer", 472.0, 0.64, "Home Paddock", "NLIS: 982001612346101", -205, 31),
            ("Hokkaido #P003", "Wagyu", "Heifer", 348.0, 0.76, "Home Paddock", "NLIS: 982001612346102", -100, 15),
        ]
        
        // Debug: Iterate through individual animals with varied start dates for realistic data spread
        for animal in individualAnimals {
            let startDate = calendar.date(byAdding: .day, value: animal.daysAgo, to: Date()) ?? Date()
            
            // Debug: Parse name to extract ID number and nickname
            // Format: "Nickname #ID" or just "#ID" or just "Nickname"
            var idNumber: String? = nil
            var nickname: String = animal.name
            
            if let hashIndex = animal.name.firstIndex(of: "#") {
                // Has an ID number
                let beforeHash = animal.name[..<hashIndex].trimmingCharacters(in: .whitespaces)
                let afterHash = animal.name[animal.name.index(after: hashIndex)...].trimmingCharacters(in: .whitespaces)
                
                if !afterHash.isEmpty {
                    idNumber = String(afterHash)
                    nickname = beforeHash.isEmpty ? "" : beforeHash
                }
            }
            
            print("🐄 MockData: Parsing '\(animal.name)' -> ID: '\(idNumber ?? "nil")', Nickname: '\(nickname)'")
            
            let individual = HerdGroup(
                name: nickname,
                species: "Cattle",
                breed: animal.breed,
                sex: animal.category.contains("Cow") || animal.category.contains("Heifer") ? "Female" : "Male",
                category: animal.category,
                ageMonths: animal.ageMonths,
                headCount: 1, // Debug: Individual animal (headCount: 1)
                initialWeight: animal.weight,
                dailyWeightGain: animal.dwg,
                isBreeder: animal.category.contains("Breeding") || animal.category.contains("Heifer"),
                selectedSaleyard: preferences.defaultSaleyard,
                animalIdNumber: idNumber
            )
            
            individual.createdAt = startDate
            individual.updatedAt = startDate
            individual.paddockName = animal.paddock
            individual.additionalInfo = animal.tagInfo
            
            // Debug: Set breeding status for breeding cows with realistic pregnancy distribution
            if animal.category == "Breeding Cow" {
                individual.isPregnant = Bool.random() // ~50% pregnancy rate
                if individual.isPregnant {
                    // Debug: Set joined date 3-6 months before creation date (realistic gestation period)
                    let daysPregnant = Int.random(in: 90...180)
                    individual.joinedDate = calendar.date(byAdding: .day, value: -daysPregnant, to: startDate)
                }
                individual.calvingRate = Double.random(in: 0.75...0.95) // 75-95% calving rate
            }
            
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
        // Debug: Base price set to realistic market values (Grown Steer base)
        var basePrice = 3.70 // Base price for Grown Steer at realistic market rate
        let volatility = 0.15 // 15% volatility
        
        for dayOffset in (0..<365).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            // Simulate price movement with some trend
            let trend = sin(Double(dayOffset) / 365.0 * 2 * .pi) * 0.3 // Seasonal trend
            let random = (Double.random(in: -1...1) * volatility)
            // Debug: Price clamps set to realistic market ranges
            basePrice = max(2.80, min(5.20, basePrice + trend + random)) // Realistic range for cattle prices
            
            for category in categories {
                // Category-specific price adjustments - aligned with realistic market rates
                var categoryPrice = basePrice
                switch category {
                case "Weaner Steer":
                    categoryPrice = basePrice * 1.18 // ~$4.35/kg
                case "Yearling Steer":
                    categoryPrice = basePrice * 1.11 // ~$4.10/kg target
                case "Breeding Cow":
                    categoryPrice = basePrice * 1.03 // ~$3.80/kg target
                case "Feeder Steer":
                    categoryPrice = basePrice * 1.05 // ~$3.90/kg
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


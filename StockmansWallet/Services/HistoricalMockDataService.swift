//
//  HistoricalMockDataService.swift
//  StockmansWallet
//
//  Generates 3 years of comprehensive historical mock data
//  From January 1, 2023 to current date (2025)
//

import Foundation
import SwiftData

@MainActor
class HistoricalMockDataService {
    static let shared = HistoricalMockDataService()
    
    private let calendar = Calendar.current
    private let startDate = Date(timeIntervalSince1970: 1672531200) // Jan 1, 2023
    private let endDate = Date() // Current date
    
    // MARK: - Generate Complete 3-Year Dataset
    
    func generate3YearHistoricalData(modelContext: ModelContext, preferences: UserPreferences) async {
        // Clear existing data first
        await clearAllData(modelContext: modelContext)
        
        // Generate herds
        await generateHistoricalHerds(modelContext: modelContext, preferences: preferences)
        
        // Generate 3 years of market prices
        await generate3YearMarketPrices(modelContext: modelContext, preferences: preferences)
        
        try? modelContext.save()
        print("✅ Generated 3 years of historical mock data")
    }
    
    // MARK: - Generate Historical Herds
    
    private func generateHistoricalHerds(modelContext: ModelContext, preferences: UserPreferences) async {
        let paddocks = [
            "River Paddock", "Back Hill", "The Flats", "North Ridge",
            "South Pasture", "East Valley", "West Slope", "Central Plains",
            "Upper Meadow", "Lower Field", "Hill Top", "Bottom Paddock",
            "Green Valley", "Dry Creek", "Sunset Ridge"
        ]
        
        let saleyards = [
            "Wagga Wagga Livestock Marketing Centre",
            "Dubbo Regional Livestock Market",
            "Roma Saleyards",
            "Tamworth Regional Livestock Exchange",
            "Forbes Central West Livestock Exchange"
        ]
        
        // Define 15 diverse herd configurations
        let herdConfigs: [(name: String, species: String, breed: String, category: String, 
                          sex: String, headCount: Int, initialWeight: Double, dwg: Double,
                          dwgChange: Double?, dwgChangeDays: Int?, startDateOffset: Int,
                          isBreeder: Bool, calvingRate: Double, saleyard: String)] = [
            // Cattle - Breeding herds (3)
            ("River Paddock - Angus Breeding Cows", "Cattle", "Angus", "Breeding Cow", "Female",
             120, 550.0, 0.3, nil, nil, -730, true, 0.88, saleyards[0]),
            
            ("Back Hill - Wagyu Breeding Cows", "Cattle", "Wagyu", "Breeding Cow", "Female",
             85, 580.0, 0.25, nil, nil, -650, true, 0.82, saleyards[1]),
            
            ("The Flats - Brahman Breeding Cows", "Cattle", "Brahman", "Breeding Cow", "Female",
             150, 520.0, 0.35, nil, nil, -600, true, 0.85, saleyards[2]),
            
            // Cattle - Growing herds with DWG changes (5)
            ("North Ridge - Yearling Steers", "Cattle", "Angus", "Yearling Steer", "Male",
             95, 380.0, 0.6, 1.1, 120, -500, false, 0.0, saleyards[0]),
            
            ("South Pasture - Feeder Steers", "Cattle", "Hereford", "Grown Steer", "Male",
             75, 450.0, 0.5, 0.9, 90, -450, false, 0.0, saleyards[1]),
            
            ("East Valley - Weaner Steers", "Cattle", "Angus X Friesian", "Weaner Steer", "Male",
             140, 250.0, 0.8, 1.2, 100, -400, false, 0.0, saleyards[0]),
            
            ("West Slope - Yearling Heifers", "Cattle", "Charolais", "Heifer", "Female",
             110, 320.0, 0.7, 1.0, 110, -350, false, 0.0, saleyards[3]),
            
            ("Central Plains - Weaner Bulls", "Cattle", "Murray Grey", "Weaner Bull", "Male",
             60, 280.0, 0.9, 1.3, 95, -300, false, 0.0, saleyards[4]),
            
            // Cattle - Standard growing herds (4)
            ("Upper Meadow - Grown Steers", "Cattle", "Droughtmaster", "Grown Steer", "Male",
             80, 480.0, 0.65, nil, nil, -250, false, 0.0, saleyards[2]),
            
            ("Lower Field - Yearling Steers", "Cattle", "Limousin", "Yearling Steer", "Male",
             100, 360.0, 0.85, nil, nil, -200, false, 0.0, saleyards[1]),
            
            ("Hill Top - Weaner Steers", "Cattle", "Santa Gertrudis", "Weaner Steer", "Male",
             130, 240.0, 1.0, nil, nil, -150, false, 0.0, saleyards[0]),
            
            ("Bottom Paddock - Heifers", "Cattle", "Red Angus", "Heifer", "Female",
             90, 310.0, 0.75, nil, nil, -100, false, 0.0, saleyards[3]),
            
            // Sheep herds (3)
            ("Green Valley - Merino Breeding Ewes", "Sheep", "Merino", "Breeding Ewe", "Female",
             500, 65.0, 0.05, nil, nil, -500, true, 0.92, saleyards[0]),
            
            ("Dry Creek - Poll Dorset Breeding Ewes", "Sheep", "Poll Dorset", "Breeding Ewe", "Female",
             400, 70.0, 0.06, nil, nil, -400, true, 0.90, saleyards[1]),
            
            ("Sunset Ridge - Merino Wethers", "Sheep", "Merino", "Wether Lamb", "Male",
             600, 45.0, 0.08, nil, nil, -180, false, 0.0, saleyards[0])
        ]
        
        for (index, config) in herdConfigs.enumerated() {
            let paddock = paddocks[index % paddocks.count]
            let herdStartDate = calendar.date(byAdding: .day, value: config.startDateOffset, to: endDate) ?? startDate
            
            let herd = HerdGroup(
                name: config.name,
                species: config.species,
                breed: config.breed,
                sex: config.sex,
                category: config.category,
                ageMonths: calculateAgeMonths(category: config.category),
                headCount: config.headCount,
                initialWeight: config.initialWeight,
                dailyWeightGain: config.dwg,
                isBreeder: config.isBreeder,
                selectedSaleyard: config.saleyard
            )
            
            herd.createdAt = herdStartDate
            herd.updatedAt = herdStartDate
            herd.paddockName = paddock
            herd.calvingRate = config.calvingRate
            herd.currentWeight = config.initialWeight
            
            // Set breeding status for breeding herds
            if config.isBreeder {
                // Randomly assign pregnancy status (70% chance)
                herd.isPregnant = Double.random(in: 0...1) < 0.7
                
                if herd.isPregnant {
                    // Set joined date (conception) - between 50-250 days ago
                    let daysSinceConception = Int.random(in: 50...250)
                    let joinedDate = calendar.date(byAdding: .day, value: -daysSinceConception, to: herdStartDate) ?? herdStartDate
                    herd.joinedDate = joinedDate
                }
            }
            
            // Set DWG change for herds that have it
            if let newDWG = config.dwgChange, let changeDays = config.dwgChangeDays {
                let dwgChangeDate = calendar.date(byAdding: .day, value: changeDays, to: herdStartDate) ?? herdStartDate
                herd.dwgChangeDate = dwgChangeDate
                herd.previousDWG = config.dwg
                herd.dailyWeightGain = newDWG
            }
            
            modelContext.insert(herd)
        }
    }
    
    // MARK: - Generate 3 Years of Market Prices
    
    private func generate3YearMarketPrices(modelContext: ModelContext, preferences: UserPreferences) async {
        let categories = [
            "Feeder Steer", "Yearling Steer", "Grown Steer", "Weaner Steer",
            "Breeding Cow", "Heifer", "Breeding Ewe", "Wether Lamb"
        ]
        
        // Calculate days from start to end
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1095
        let totalDays = min(days, 1095) // Max 3 years
        
        // Base price trend: Peak in late 2022/early 2023, significant dip in 2023, then recovery
        let basePrice = 7.50 // Peak price in early 2023 (EYCI was around $7.50/kg)
        
        for dayOffset in (0..<totalDays).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { continue }
            
            // Calculate days since start (Jan 1, 2023)
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
            let progress = Double(daysSinceStart) / 1095.0 // 0 to 1 over 3 years
            
            // Realistic market trend based on actual EYCI patterns:
            // - Peak early 2023 (~$7.50/kg)
            // - Sharp decline through mid-2023 (bottom ~$5.20/kg in Aug 2023, ~30% drop)
            // - Gradual recovery late 2023 through 2024
            // - Continued strength into 2025
            let trend: Double
            if progress < 0.2 {
                // Jan-Mar 2023: Peak period, slight decline starting
                trend = -0.05 * (progress / 0.2) // Gradual 5% decline
            } else if progress < 0.4 {
                // Apr-Aug 2023: Sharp decline to bottom (~30% total from peak)
                let declineProgress = (progress - 0.2) / 0.2 // 0 to 1 through decline period
                trend = -0.05 - (0.25 * declineProgress) // Total 30% down from peak
            } else if progress < 0.6 {
                // Sep 2023 - Mar 2024: Recovery phase
                let recoveryProgress = (progress - 0.4) / 0.2 // 0 to 1 through recovery
                trend = -0.30 + (0.20 * recoveryProgress) // Recover 20% of the drop
            } else if progress < 0.8 {
                // Apr-Sep 2024: Continued recovery
                let recoveryProgress = (progress - 0.6) / 0.2
                trend = -0.10 + (0.15 * recoveryProgress) // Further recovery
            } else {
                // Oct 2024 - Dec 2025: Strong period, approaching new highs
                let growthProgress = (progress - 0.8) / 0.2
                trend = 0.05 + (0.10 * growthProgress) // 5-15% above original peak
            }
            
            // Seasonal variation (higher in autumn/winter, lower in spring)
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 180
            // Peak in May-June (autumn), low in Oct-Nov (spring)
            let seasonal = sin((Double(dayOfYear) / 365.0 * 2 * .pi) - (.pi / 2)) * 0.10 // ±10% seasonal
            
            // Weekly volatility (more realistic than daily random)
            let weekNumber = daysSinceStart / 7
            let weeklySeed = Double(weekNumber % 13) // Cycle through 13 weeks
            let weeklyVolatility = sin(weeklySeed / 13.0 * 2 * .pi) * 0.08 // ±8% weekly pattern
            
            // Small random daily variation
            let dailyVolatility = (Double.random(in: -1...1) * 0.03) // ±3% daily noise
            
            // Calculate final price
            let adjustedPrice = basePrice * (1.0 + trend + seasonal + weeklyVolatility + dailyVolatility)
            let finalPrice = max(4.5, min(9.5, adjustedPrice)) // Clamp between $4.50-$9.50/kg
            
            // Generate prices for each category
            for category in categories {
                var categoryPrice = finalPrice
                
                // Category-specific multipliers
                switch category {
                case "Weaner Steer":
                    categoryPrice = finalPrice * 1.18
                case "Yearling Steer":
                    categoryPrice = finalPrice * 1.08
                case "Grown Steer":
                    categoryPrice = finalPrice * 1.0
                case "Feeder Steer":
                    categoryPrice = finalPrice * 0.95
                case "Breeding Cow":
                    categoryPrice = finalPrice * 0.68
                case "Heifer":
                    categoryPrice = finalPrice * 0.92
                case "Breeding Ewe":
                    categoryPrice = finalPrice * 3.2 // Sheep prices per kg are higher
                case "Wether Lamb":
                    categoryPrice = finalPrice * 3.5
                default:
                    categoryPrice = finalPrice
                }
                
                // Assign to random saleyard for variety
                let saleyards = ReferenceData.saleyards
                let saleyard = saleyards.randomElement() ?? preferences.defaultSaleyard
                
                let marketPrice = MarketPrice(
                    category: category,
                    saleyard: saleyard,
                    state: preferences.defaultState,
                    pricePerKg: categoryPrice,
                    priceDate: date,
                    source: dayOffset < 7 ? "Saleyard" : (dayOffset < 30 ? "State Indicator" : "National Benchmark"),
                    isHistorical: dayOffset > 0
                )
                
                modelContext.insert(marketPrice)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateAgeMonths(category: String) -> Int {
        switch category {
        case "Weaner Steer", "Weaner Bull", "Weaner Barrow":
            return Int.random(in: 6...10)
        case "Yearling Steer", "Yearling Bull", "Ewe Lamb":
            return Int.random(in: 12...18)
        case "Grown Steer", "Grown Bull", "Hogget Wether":
            return Int.random(in: 24...36)
        case "Breeding Cow", "Breeding Ewe", "Breeding Ram":
            return Int.random(in: 36...84)
        case "Heifer", "Maiden Ewe":
            return Int.random(in: 18...30)
        default:
            return 24
        }
    }
    
    // MARK: - Clear All Data
    
    func clearAllData(modelContext: ModelContext) async {
        do {
            try modelContext.delete(model: HerdGroup.self)
            try modelContext.delete(model: MarketPrice.self)
            try modelContext.delete(model: SalesRecord.self)
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}

// MARK: - Preview Container

@MainActor
struct PreviewContainer {
    static func create() -> ModelContainer {
        let schema = Schema([
            HerdGroup.self,
            UserPreferences.self,
            MarketPrice.self,
            SalesRecord.self
        ])
        
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            
            // Create default preferences
            let preferences = UserPreferences()
            preferences.defaultState = "NSW"
            preferences.defaultSaleyard = "Wagga Wagga Livestock Marketing Centre"
            container.mainContext.insert(preferences)
            
            // Generate 3 years of data synchronously for preview
            Task { @MainActor in
                await HistoricalMockDataService.shared.generate3YearHistoricalData(
                    modelContext: container.mainContext,
                    preferences: preferences
                )
            }
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}


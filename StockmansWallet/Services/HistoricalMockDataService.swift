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
        
        // Generate individual animals
        await generateIndividualAnimals(modelContext: modelContext, preferences: preferences)
        
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
        // Debug: Extended startDateOffset values to go back to Jan 10, 2023 (~1090 days from Jan 6, 2026)
        let herdConfigs: [(name: String, species: String, breed: String, category: String, 
                          sex: String, headCount: Int, initialWeight: Double, dwg: Double,
                          dwgChange: Double?, dwgChangeDays: Int?, startDateOffset: Int,
                          isBreeder: Bool, calvingRate: Double, saleyard: String)] = [
            // Cattle - Breeding herds (3) - Starting from early 2023
            ("River Paddock - Angus Breeding Cows", "Cattle", "Angus", "Breeding Cow", "Female",
             120, 550.0, 0.3, nil, nil, -1090, true, 0.88, saleyards[0]),
            
            ("Back Hill - Wagyu Breeding Cows", "Cattle", "Wagyu", "Breeding Cow", "Female",
             85, 580.0, 0.25, nil, nil, -1070, true, 0.82, saleyards[1]),
            
            ("The Flats - Brahman Breeding Cows", "Cattle", "Brahman", "Breeding Cow", "Female",
             150, 520.0, 0.35, nil, nil, -1050, true, 0.85, saleyards[2]),
            
            // Cattle - Growing herds with DWG changes (5) - Staggered through 2023-2024
            ("North Ridge - Yearling Steers", "Cattle", "Angus", "Yearling Steer", "Male",
             95, 380.0, 0.6, 1.1, 120, -1000, false, 0.0, saleyards[0]),
            
            ("South Pasture - Feeder Steers", "Cattle", "Hereford", "Grown Steer", "Male",
             75, 450.0, 0.5, 0.9, 90, -950, false, 0.0, saleyards[1]),
            
            ("East Valley - Weaner Steers", "Cattle", "Angus X", "Weaner Steer", "Male",
             140, 250.0, 0.8, 1.2, 100, -900, false, 0.0, saleyards[0]),
            
            ("West Slope - Yearling Heifers", "Cattle", "Charolais", "Heifer", "Female",
             110, 320.0, 0.7, 1.0, 110, -850, false, 0.0, saleyards[3]),
            
            ("Central Plains - Weaner Bulls", "Cattle", "Murray Grey", "Weaner Bull", "Male",
             60, 280.0, 0.9, 1.3, 95, -800, false, 0.0, saleyards[4]),
            
            // Cattle - Standard growing herds (4) - More recent additions through 2024-2025
            ("Upper Meadow - Grown Steers", "Cattle", "Droughtmaster", "Grown Steer", "Male",
             80, 480.0, 0.65, nil, nil, -700, false, 0.0, saleyards[2]),
            
            ("Lower Field - Yearling Steers", "Cattle", "Limousin", "Yearling Steer", "Male",
             100, 360.0, 0.85, nil, nil, -550, false, 0.0, saleyards[1]),
            
            ("Hill Top - Weaner Steers", "Cattle", "Santa Gertrudis", "Weaner Steer", "Male",
             130, 240.0, 1.0, nil, nil, -400, false, 0.0, saleyards[0]),
            
            ("Bottom Paddock - Heifers", "Cattle", "Red Angus", "Heifer", "Female",
             90, 310.0, 0.75, nil, nil, -250, false, 0.0, saleyards[3])
            
            // Debug: CATTLE ONLY for Beta - Sheep, pigs, goats coming in future versions
        ]
        
        for (index, config) in herdConfigs.enumerated() {
            let paddock = paddocks[index % paddocks.count]
            let herdStartDate = calendar.date(byAdding: .day, value: config.startDateOffset, to: endDate) ?? startDate
            
            // Parse name to extract ID number and nickname (e.g., "North Paddock #NP01")
            var idNumber: String? = nil
            var nickname: String = config.name
            
            if let dashIndex = config.name.firstIndex(of: "-") {
                // Format: "Paddock Name - Description"
                // Convert to ID/Nickname format
                let beforeDash = config.name[..<dashIndex].trimmingCharacters(in: .whitespaces)
                let afterDash = config.name[config.name.index(after: dashIndex)...].trimmingCharacters(in: .whitespaces)
                
                // Create a simple ID from the first letters
                let words = beforeDash.split(separator: " ")
                if words.count >= 2 {
                    let id = String(words[0].prefix(1)) + String(words[1].prefix(1)) + "01"
                    idNumber = id.uppercased()
                    nickname = afterDash
                }
            }
            
            let herd = HerdGroup(
                name: nickname,
                species: config.species,
                breed: config.breed,
                sex: config.sex,
                category: config.category,
                ageMonths: calculateAgeMonths(category: config.category),
                headCount: config.headCount,
                initialWeight: config.initialWeight,
                dailyWeightGain: config.dwg,
                isBreeder: config.isBreeder,
                selectedSaleyard: config.saleyard,
                animalIdNumber: idNumber
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
    
    // MARK: - Generate Individual Animals
    
    private func generateIndividualAnimals(modelContext: ModelContext, preferences: UserPreferences) async {
        // Debug: Generate individual tagged animals for 3-year historical dataset
        // Debug: Individual animals with varied breeds, ages, and realistic NLIS tags
        let individualAnimals: [(name: String, breed: String, category: String, weight: Double, dwg: Double, paddock: String, tagInfo: String, daysAgo: Int, ageMonths: Int)] = [
            // River Paddock - Premium Angus Breeding Cows
            ("Bella #001", "Angus", "Breeding Cow", 585.0, 0.22, "River Paddock", "NLIS: 982500100000001", -1000, 54),
            ("Charlotte #002", "Angus", "Breeding Cow", 575.0, 0.21, "River Paddock", "NLIS: 982500100000002", -1010, 52),
            ("Diana #003", "Angus", "Breeding Cow", 592.0, 0.19, "River Paddock", "NLIS: 982500100000003", -980, 56),
            ("Emma #004", "Angus", "Breeding Cow", 568.0, 0.23, "River Paddock", "NLIS: 982500100000004", -1020, 51),
            ("Fiona #005", "Angus", "Breeding Cow", 580.0, 0.20, "River Paddock", "NLIS: 982500100000005", -990, 53),
            
            // Back Hill - Wagyu Premium Stock
            ("Sakura #W01", "Wagyu", "Breeding Cow", 595.0, 0.18, "Back Hill", "NLIS: 982500200000101", -950, 58),
            ("Yuki #W02", "Wagyu", "Breeding Cow", 588.0, 0.17, "Back Hill", "NLIS: 982500200000102", -970, 60),
            ("Kiku #W03", "Wagyu", "Grown Steer", 478.0, 0.65, "Back Hill", "NLIS: 982500200000103", -600, 32),
            ("Hiro #W04", "Wagyu", "Grown Steer", 485.0, 0.63, "Back Hill", "NLIS: 982500200000104", -610, 33),
            
            // The Flats - Brahman Tropical Breed
            ("Tropico #B01", "Brahman", "Breeding Cow", 545.0, 0.28, "The Flats", "NLIS: 982500300000201", -930, 48),
            ("Savanna #B02", "Brahman", "Breeding Cow", 538.0, 0.26, "The Flats", "NLIS: 982500300000202", -940, 47),
            ("Rio #B03", "Brahman", "Feeder Steer", 375.0, 0.96, "The Flats", "NLIS: 982500300000203", -400, 14),
            ("Cruz #B04", "Brahman", "Feeder Steer", 368.0, 0.94, "The Flats", "NLIS: 982500300000204", -410, 13),
            ("Mesa #B05", "Brahman", "Feeder Steer", 372.0, 0.98, "The Flats", "NLIS: 982500300000205", -395, 14),
            
            // North Ridge - Yearling Angus Steers
            ("Ridge #Y01", "Angus", "Yearling Steer", 425.0, 0.93, "North Ridge", "NLIS: 982500400000301", -500, 18),
            ("Summit #Y02", "Angus", "Yearling Steer", 415.0, 0.89, "North Ridge", "NLIS: 982500400000302", -510, 17),
            ("Peak #Y03", "Angus", "Yearling Steer", 430.0, 0.95, "North Ridge", "NLIS: 982500400000303", -495, 18),
            ("Cliff #Y04", "Angus", "Yearling Steer", 408.0, 0.87, "North Ridge", "NLIS: 982500400000304", -520, 16),
            ("Boulder #Y05", "Angus", "Yearling Steer", 418.0, 0.91, "North Ridge", "NLIS: 982500400000305", -505, 17),
            
            // South Pasture - Hereford Feeders
            ("Rusty #H01", "Hereford", "Grown Steer", 492.0, 0.71, "South Pasture", "NLIS: 982500500000401", -450, 28),
            ("Buck #H02", "Hereford", "Grown Steer", 485.0, 0.69, "South Pasture", "NLIS: 982500500000402", -460, 27),
            ("Champ #H03", "Hereford", "Grown Steer", 498.0, 0.73, "South Pasture", "NLIS: 982500500000403", -445, 29),
            ("Duke #H04", "Hereford", "Grown Steer", 488.0, 0.70, "South Pasture", "NLIS: 982500500000404", -455, 28),
            
            // East Valley - Weaner Crossbreeds
            ("Jet #X01", "Angus X", "Weaner Steer", 272.0, 1.14, "East Valley", "NLIS: 982500600000501", -300, 9),
            ("Rocket #X02", "Angus X", "Weaner Steer", 265.0, 1.10, "East Valley", "NLIS: 982500600000502", -310, 8),
            ("Zoom #X03", "Angus X", "Weaner Steer", 278.0, 1.18, "East Valley", "NLIS: 982500600000503", -295, 9),
            ("Flash #X04", "Angus X", "Weaner Steer", 260.0, 1.08, "East Valley", "NLIS: 982500600000504", -315, 8),
            ("Sprint #X05", "Angus X", "Weaner Steer", 268.0, 1.12, "East Valley", "NLIS: 982500600000505", -305, 9),
            ("Dash #X06", "Angus X", "Weaner Steer", 275.0, 1.16, "East Valley", "NLIS: 982500600000506", -300, 9),
            
            // West Slope - Charolais Heifers
            ("Ivory #C01", "Charolais", "Heifer", 348.0, 0.82, "West Slope", "NLIS: 982500700000601", -350, 15),
            ("Pearl #C02", "Charolais", "Heifer", 342.0, 0.79, "West Slope", "NLIS: 982500700000602", -360, 14),
            ("Snow #C03", "Charolais", "Heifer", 352.0, 0.84, "West Slope", "NLIS: 982500700000603", -345, 16),
            ("Crystal #C04", "Charolais", "Heifer", 338.0, 0.77, "West Slope", "NLIS: 982500700000604", -365, 14),
            ("Cloud #C05", "Charolais", "Heifer", 345.0, 0.81, "West Slope", "NLIS: 982500700000605", -355, 15),
            
            // Central Plains - Murray Grey Bulls
            ("Titan #M01", "Murray Grey", "Weaner Bull", 305.0, 1.25, "Central Plains", "NLIS: 982500800000701", -280, 10),
            ("Magnus #M02", "Murray Grey", "Weaner Bull", 298.0, 1.20, "Central Plains", "NLIS: 982500800000702", -290, 9),
            ("Brutus #M03", "Murray Grey", "Weaner Bull", 312.0, 1.30, "Central Plains", "NLIS: 982500800000703", -275, 10),
            
            // Upper Meadow - Droughtmaster
            ("Outback #D01", "Droughtmaster", "Grown Steer", 495.0, 0.68, "Upper Meadow", "NLIS: 982500900000801", -380, 29),
            ("Desert #D02", "Droughtmaster", "Grown Steer", 488.0, 0.66, "Upper Meadow", "NLIS: 982500900000802", -390, 28),
            ("Sahara #D03", "Droughtmaster", "Grown Steer", 502.0, 0.70, "Upper Meadow", "NLIS: 982500900000803", -375, 30),
            
            // Lower Field - Limousin Yearlings
            ("Russet #L01", "Limousin", "Yearling Steer", 412.0, 0.90, "Lower Field", "NLIS: 982501000000901", -250, 17),
            ("Copper #L02", "Limousin", "Yearling Steer", 405.0, 0.88, "Lower Field", "NLIS: 982501000001002", -260, 16),
            ("Bronze #L03", "Limousin", "Yearling Steer", 418.0, 0.92, "Lower Field", "NLIS: 982501000001003", -245, 18),
            ("Amber #L04", "Limousin", "Yearling Steer", 410.0, 0.89, "Lower Field", "NLIS: 982501000001004", -255, 17),
            
            // Hill Top - Speckle Park
            ("Patch #S01", "Speckle Park", "Yearling Steer", 402.0, 0.86, "Hill Top", "NLIS: 982501100001101", -240, 16),
            ("Spot #S02", "Speckle Park", "Yearling Steer", 408.0, 0.88, "Hill Top", "NLIS: 982501100001102", -235, 17),
            ("Freckle #S03", "Speckle Park", "Heifer", 335.0, 0.78, "Hill Top", "NLIS: 982501100001103", -220, 14),
            
            // Bottom Paddock - Santa Gertrudis
            ("Sunset #SG01", "Santa Gertrudis", "Breeding Cow", 572.0, 0.24, "Bottom Paddock", "NLIS: 982501200001201", -850, 50),
            ("Sunrise #SG02", "Santa Gertrudis", "Breeding Cow", 565.0, 0.22, "Bottom Paddock", "NLIS: 982501200001202", -860, 49),
            ("Dawn #SG03", "Santa Gertrudis", "Feeder Steer", 370.0, 0.95, "Bottom Paddock", "NLIS: 982501200001203", -320, 13),
            ("Dusk #SG04", "Santa Gertrudis", "Feeder Steer", 365.0, 0.93, "Bottom Paddock", "NLIS: 982501200001204", -325, 12),
        ]
        
        // Debug: Create individual animals with historical dates
        for animal in individualAnimals {
            let startDate = calendar.date(byAdding: .day, value: animal.daysAgo, to: endDate) ?? endDate
            
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
                individual.isPregnant = Double.random(in: 0...1) < 0.65 // 65% pregnancy rate
                if individual.isPregnant {
                    // Debug: Set joined date 3-6 months before creation date (realistic gestation period)
                    let daysPregnant = Int.random(in: 90...180)
                    individual.joinedDate = calendar.date(byAdding: .day, value: -daysPregnant, to: startDate)
                }
                individual.calvingRate = Double.random(in: 0.75...0.92) // 75-92% calving rate
            }
            
            modelContext.insert(individual)
        }
    }
    
    // MARK: - Generate 3 Years of Market Prices
    
    private func generate3YearMarketPrices(modelContext: ModelContext, preferences: UserPreferences) async {
        // Debug: Comprehensive list of all market categories to ensure complete price coverage
        // These categories will match user-entered categories via pattern matching (contains)
        let categories = [
            // Cattle categories
            "Feeder Steer", "Feeder Heifer", 
            "Yearling Steer", "Yearling Bull",
            "Grown Steer", "Grown Bull",
            "Weaner Steer", "Weaner Bull", "Weaner Heifer",
            "Breeding Cow", "Breeder", "Dry Cow", "Cull Cow",
            "Heifer", "First Calf Heifer",
            "Slaughter Cattle", "Calves"
            
            // Debug: CATTLE ONLY for Beta - Sheep, pigs, goats coming in future versions
            // Sheep categories  
            // "Breeding Ewe", "Maiden Ewe", "Dry Ewe", "Cull Ewe",
            // "Weaner Ewe", "Feeder Ewe", "Slaughter Ewe",
            // "Wether Lamb", "Weaner Lamb", "Feeder Lamb", "Slaughter Lamb", "Lambs",
            // Pig categories
            // "Breeder", "Dry Sow", "Cull Sow",
            // "Weaner Pig", "Feeder Pig", "Grower Pig", "Finisher Pig",
            // "Porker", "Baconer", "Grower Barrow", "Finisher Barrow",
            // Goat categories
            // "Breeder Doe", "Dry Doe", "Cull Doe", "Breeder Buck", "Sale Buck",
            // "Mature Wether", "Rangeland Goat", "Capretto", "Chevon"
        ]
        
        // Calculate days from start to end
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1095
        let totalDays = min(days, 1095) // Max 3 years
        
        // Base price trend: Peak in late 2022/early 2023, significant dip in 2023, then recovery
        // Debug: Base price set to realistic market values - represents Grown Steer base price
        // Adjusted to target Yearling Steer ~$4.10 and Breeding Cow/Heifer ~$3.80
        let basePrice = 3.30 // Base price for Grown Steer - reduced to meet targets
        
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
            // Debug: Price clamps set to realistic market ranges - tighter range to keep prices lower
            // Max 3.50 ensures Yearling (1.22x) stays around $4.27 max, average ~$4.10
            let finalPrice = max(3.10, min(3.50, adjustedPrice)) // Clamp between $3.10-$3.50/kg for realistic market ranges
            
            // Generate prices for each category
            for category in categories {
                var categoryPrice = finalPrice
                
                // Category-specific multipliers - adjusted to realistic market rates
                // Base (finalPrice) represents Grown Steer at ~$3.30/kg
                // Targets: Yearling Steer ~$4.10, Breeding Cow/Heifer ~$3.80
                // Debug: Prices set to match targets for all categories
                
                // Cattle categories
                if category.contains("Weaner") && (category.contains("Steer") || category.contains("Bull") || category.contains("Heifer")) {
                    categoryPrice = finalPrice * 1.18 // ~$3.66-4.25/kg range
                } else if category.contains("Yearling") && (category.contains("Steer") || category.contains("Bull")) {
                    categoryPrice = finalPrice * 1.22 // ~$4.10/kg target
                } else if category.contains("Breeding") || (category.contains("Breeder") && !category.contains("Doe") && !category.contains("Buck")) || category.contains("Heifer") || category.contains("Dry Cow") {
                    categoryPrice = finalPrice * 1.15 // ~$3.80/kg target for breeders
                } else if category.contains("Cull Cow") {
                    categoryPrice = finalPrice * 0.95 // ~$3.14/kg (cull animals typically lower)
                } else if category.contains("Feeder") && (category.contains("Steer") || category.contains("Heifer")) {
                    categoryPrice = finalPrice * 1.18 // ~$3.89/kg
                } else if category.contains("Grown") && (category.contains("Steer") || category.contains("Bull")) {
                    categoryPrice = finalPrice * 1.0 // Base price ~$3.30/kg
                } else if category.contains("Slaughter Cattle") {
                    categoryPrice = finalPrice * 0.92 // ~$3.04/kg (slaughter typically lower)
                } else if category.contains("Calves") {
                    categoryPrice = finalPrice * 1.25 // ~$4.13/kg (calves premium)
                }
                
                // Debug: CATTLE ONLY for Beta - Non-cattle pricing commented out
                /*
                // Sheep categories (higher per kg than cattle)
                else if category.contains("Breeding Ewe") || category.contains("Maiden Ewe") || category.contains("Dry Ewe") {
                    categoryPrice = finalPrice * 3.2 // ~$10.56/kg
                } else if category.contains("Cull Ewe") || category.contains("Slaughter Ewe") {
                    categoryPrice = finalPrice * 2.8 // ~$9.24/kg
                } else if category.contains("Wether Lamb") || category.contains("Weaner Lamb") || category.contains("Feeder Lamb") {
                    categoryPrice = finalPrice * 3.5 // ~$11.55/kg
                } else if category.contains("Slaughter Lamb") || category.contains("Lambs") {
                    categoryPrice = finalPrice * 3.3 // ~$10.89/kg
                }
                // Pig categories
                else if (category.contains("Breeder") || category.contains("Dry Sow")) && category.contains("Sow") {
                    categoryPrice = finalPrice * 0.66 // ~$2.18/kg
                } else if category.contains("Cull Sow") {
                    categoryPrice = finalPrice * 0.60 // ~$1.98/kg
                } else if category.contains("Weaner Pig") || category.contains("Feeder Pig") {
                    categoryPrice = finalPrice * 0.70 // ~$2.31/kg
                } else if category.contains("Grower") || category.contains("Finisher") {
                    categoryPrice = finalPrice * 0.65 // ~$2.15/kg
                } else if category.contains("Porker") || category.contains("Baconer") {
                    categoryPrice = finalPrice * 0.66 // ~$2.18/kg
                }
                // Goat categories
                else if category.contains("Breeder Doe") || category.contains("Dry Doe") {
                    categoryPrice = finalPrice * 1.30 // ~$4.29/kg
                } else if category.contains("Cull Doe") {
                    categoryPrice = finalPrice * 1.20 // ~$3.96/kg
                } else if category.contains("Breeder Buck") || category.contains("Sale Buck") {
                    categoryPrice = finalPrice * 1.35 // ~$4.46/kg
                } else if category.contains("Mature Wether") || category.contains("Rangeland Goat") {
                    categoryPrice = finalPrice * 1.30 // ~$4.29/kg
                } else if category.contains("Capretto") {
                    categoryPrice = finalPrice * 1.53 // ~$5.05/kg (premium)
                } else if category.contains("Chevon") {
                    categoryPrice = finalPrice * 1.25 // ~$4.13/kg
                }
                */
                // Default fallback
                else {
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


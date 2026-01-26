//
//  SupabaseSampleDataGenerator.swift
//  StockmansWallet
//
//  Generates and uploads sample data to Supabase
//  Debug: Run this ONCE to populate sample_herds and historical_market_prices tables
//

import Foundation
import Supabase

// MARK: - Supabase Sample Data Generator
// Debug: Generates sample data on server instead of client device
@MainActor
class SupabaseSampleDataGenerator {
    static let shared = SupabaseSampleDataGenerator()
    
    private let supabase = SupabaseClientManager.shared.client
    private let calendar = Calendar.current
    private let startDate = Date(timeIntervalSince1970: 1672531200) // Jan 1, 2023
    private let endDate = Date() // Current date
    
    private init() {}
    
    // MARK: - Main Generation Method
    // Debug: Call this once to populate Supabase with 3 years of sample data
    func generateAndUploadSampleData() async throws {
        print("🚀 Starting sample data generation and upload to Supabase...")
        
        // Step 1: Generate and upload sample herds
        print("📊 Generating sample herds...")
        let herds = generateSampleHerds()
        try await uploadSampleHerds(herds)
        print("✅ Uploaded \(herds.count) sample herds")
        
        // Step 2: Generate and upload historical market prices (3 years)
        print("📈 Generating 3 years of historical market prices...")
        let prices = generateHistoricalPrices()
        print("📦 Generated \(prices.count) price records")
        
        // Upload in batches (Supabase has limits)
        print("⬆️ Uploading prices in batches...")
        try await uploadHistoricalPricesInBatches(prices, batchSize: 1000)
        print("✅ Successfully uploaded all historical prices")
        
        print("🎉 Sample data generation complete!")
    }
    
    // MARK: - Generate Sample Herds
    // Debug: Create diverse herd configurations for demo purposes
    private func generateSampleHerds() -> [SupabaseSampleHerd] {
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
        
        // Debug: Diverse herd configurations matching HistoricalMockDataService
        let herdConfigs: [(name: String, species: String, breed: String, category: String,
                          sex: String, headCount: Int, initialWeight: Double, dwg: Double,
                          dwgChange: Double?, dwgChangeDays: Int?, startDateOffset: Int,
                          isBreeder: Bool, calvingRate: Double, saleyard: String)] = [
            // Cattle - Breeding herds (3)
            ("Angus Breeding Cows", "Cattle", "Angus", "Breeding Cow", "Female",
             120, 550.0, 0.3, nil, nil, -1090, true, 0.88, saleyards[0]),
            
            ("Wagyu Breeding Cows", "Cattle", "Wagyu", "Breeding Cow", "Female",
             85, 580.0, 0.25, nil, nil, -1070, true, 0.82, saleyards[1]),
            
            ("Brahman Breeding Cows", "Cattle", "Brahman", "Breeding Cow", "Female",
             150, 520.0, 0.35, nil, nil, -1050, true, 0.85, saleyards[2]),
            
            // Cattle - Growing herds with DWG changes (5)
            ("Yearling Steers", "Cattle", "Angus", "Yearling Steer", "Male",
             95, 380.0, 0.6, 1.1, 120, -1000, false, 0.0, saleyards[0]),
            
            ("Feeder Steers", "Cattle", "Hereford", "Grown Steer", "Male",
             75, 450.0, 0.5, 0.9, 90, -950, false, 0.0, saleyards[1]),
            
            ("Weaner Steers", "Cattle", "Angus X Friesian", "Weaner Steer", "Male",
             140, 250.0, 0.8, 1.2, 100, -900, false, 0.0, saleyards[0]),
            
            ("Yearling Heifers", "Cattle", "Charolais", "Heifer", "Female",
             110, 320.0, 0.7, 1.0, 110, -850, false, 0.0, saleyards[3]),
            
            ("Weaner Bulls", "Cattle", "Murray Grey", "Weaner Bull", "Male",
             60, 280.0, 0.9, 1.3, 95, -800, false, 0.0, saleyards[4]),
            
            // Cattle - Standard growing herds (4)
            ("Grown Steers", "Cattle", "Droughtmaster", "Grown Steer", "Male",
             80, 480.0, 0.65, nil, nil, -700, false, 0.0, saleyards[2]),
            
            ("Limousin Yearlings", "Cattle", "Limousin", "Yearling Steer", "Male",
             100, 360.0, 0.85, nil, nil, -550, false, 0.0, saleyards[1]),
            
            ("Santa Gertrudis Weaners", "Cattle", "Santa Gertrudis", "Weaner Steer", "Male",
             130, 240.0, 1.0, nil, nil, -400, false, 0.0, saleyards[0]),
            
            ("Red Angus Heifers", "Cattle", "Red Angus", "Heifer", "Female",
             90, 310.0, 0.75, nil, nil, -250, false, 0.0, saleyards[3]),
            
            // Sheep herds (3)
            ("Merino Breeding Ewes", "Sheep", "Merino", "Breeding Ewe", "Female",
             500, 65.0, 0.05, nil, nil, -1020, true, 0.92, saleyards[0]),
            
            ("Poll Dorset Breeding Ewes", "Sheep", "Poll Dorset", "Breeding Ewe", "Female",
             400, 70.0, 0.06, nil, nil, -980, true, 0.90, saleyards[1]),
            
            ("Merino Wethers", "Sheep", "Merino", "Wether Lamb", "Male",
             600, 45.0, 0.08, nil, nil, -600, false, 0.0, saleyards[0])
        ]
        
        var herds: [SupabaseSampleHerd] = []
        
        for (index, config) in herdConfigs.enumerated() {
            let paddock = paddocks[index % paddocks.count]
            let herdStartDate = calendar.date(byAdding: .day, value: config.startDateOffset, to: endDate) ?? startDate
            
            let ageMonths = calculateAgeMonths(category: config.category)
            
            let herd = SupabaseSampleHerd(
                name: config.name,
                species: config.species,
                breed: config.breed,
                sex: config.sex,
                category: config.category,
                age_months: ageMonths,
                head_count: config.headCount,
                initial_weight: config.initialWeight,
                current_weight: config.initialWeight,
                daily_weight_gain: config.dwg,
                is_breeder: config.isBreeder,
                calving_rate: config.calvingRate,
                paddock_name: paddock,
                selected_saleyard: config.saleyard,
                animal_id_number: nil,
                additional_info: nil,
                is_pregnant: config.isBreeder ? (Double.random(in: 0...1) < 0.7) : false,
                joined_date: config.isBreeder ? calendar.date(byAdding: .day, value: -Int.random(in: 50...250), to: herdStartDate) : nil,
                dwg_change_date: config.dwgChangeDays != nil ? calendar.date(byAdding: .day, value: config.dwgChangeDays!, to: herdStartDate) : nil,
                previous_dwg: config.dwgChange != nil ? config.dwg : nil,
                days_offset: config.startDateOffset
            )
            
            herds.append(herd)
        }
        
        return herds
    }
    
    // MARK: - Generate Historical Prices
    // Debug: Generate 3 years of realistic market price data
    private func generateHistoricalPrices() -> [SupabaseHistoricalPrice] {
        let categories = [
            // Cattle categories
            "Feeder Steer", "Feeder Heifer",
            "Yearling Steer", "Yearling Bull",
            "Grown Steer", "Grown Bull",
            "Weaner Steer", "Weaner Bull", "Weaner Heifer",
            "Breeding Cow", "Breeder", "Dry Cow", "Cull Cow",
            "Heifer", "First Calf Heifer",
            "Slaughter Cattle", "Calves",
            // Sheep categories
            "Breeding Ewe", "Maiden Ewe", "Dry Ewe", "Cull Ewe",
            "Weaner Ewe", "Feeder Ewe", "Slaughter Ewe",
            "Wether Lamb", "Weaner Lamb", "Feeder Lamb", "Slaughter Lamb", "Lambs",
            // Pig categories
            "Breeder", "Dry Sow", "Cull Sow",
            "Weaner Pig", "Feeder Pig", "Grower Pig", "Finisher Pig",
            "Porker", "Baconer", "Grower Barrow", "Finisher Barrow",
            // Goat categories
            "Breeder Doe", "Dry Doe", "Cull Doe", "Breeder Buck", "Sale Buck",
            "Mature Wether", "Rangeland Goat", "Capretto", "Chevon"
        ]
        
        let saleyards = [
            "Wagga Wagga Livestock Marketing Centre",
            "Dubbo Regional Livestock Market",
            "Roma Saleyards",
            "Ballarat Regional Livestock Exchange",
            "Mount Gambier Livestock Exchange"
        ]
        
        let states = ["NSW", "VIC", "QLD", "SA", "WA"]
        
        // Calculate days from start to end
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1095
        let totalDays = min(days, 1095) // Max 3 years
        
        let basePrice = 3.30 // Base price for Grown Steer
        
        var prices: [SupabaseHistoricalPrice] = []
        
        for dayOffset in (0..<totalDays).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { continue }
            
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
            let progress = Double(daysSinceStart) / 1095.0
            
            // Realistic market trend (matching HistoricalMockDataService)
            let trend: Double
            if progress < 0.2 {
                trend = -0.05 * (progress / 0.2)
            } else if progress < 0.4 {
                let declineProgress = (progress - 0.2) / 0.2
                trend = -0.05 - (0.25 * declineProgress)
            } else if progress < 0.6 {
                let recoveryProgress = (progress - 0.4) / 0.2
                trend = -0.30 + (0.20 * recoveryProgress)
            } else if progress < 0.8 {
                let recoveryProgress = (progress - 0.6) / 0.2
                trend = -0.10 + (0.15 * recoveryProgress)
            } else {
                let growthProgress = (progress - 0.8) / 0.2
                trend = 0.05 + (0.10 * growthProgress)
            }
            
            // Seasonal variation
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 180
            let seasonal = sin((Double(dayOfYear) / 365.0 * 2 * .pi) - (.pi / 2)) * 0.10
            
            // Weekly volatility
            let weekNumber = daysSinceStart / 7
            let weeklySeed = Double(weekNumber % 13)
            let weeklyVolatility = sin(weeklySeed / 13.0 * 2 * .pi) * 0.08
            
            // Daily variation
            let dailyVolatility = (Double.random(in: -1...1) * 0.03)
            
            let adjustedPrice = basePrice * (1.0 + trend + seasonal + weeklyVolatility + dailyVolatility)
            let finalPrice = max(3.10, min(3.50, adjustedPrice))
            
            // Generate prices for each category
            for category in categories {
                var categoryPrice = finalPrice
                
                // Apply category multipliers (same logic as HistoricalMockDataService)
                if category.contains("Weaner") && (category.contains("Steer") || category.contains("Bull") || category.contains("Heifer")) {
                    categoryPrice = finalPrice * 1.18
                } else if category.contains("Yearling") && (category.contains("Steer") || category.contains("Bull")) {
                    categoryPrice = finalPrice * 1.22
                } else if category.contains("Breeding") || (category.contains("Breeder") && !category.contains("Doe") && !category.contains("Buck")) || category.contains("Heifer") || category.contains("Dry Cow") {
                    categoryPrice = finalPrice * 1.15
                } else if category.contains("Cull Cow") {
                    categoryPrice = finalPrice * 0.95
                } else if category.contains("Feeder") && (category.contains("Steer") || category.contains("Heifer")) {
                    categoryPrice = finalPrice * 1.18
                } else if category.contains("Grown") && (category.contains("Steer") || category.contains("Bull")) {
                    categoryPrice = finalPrice * 1.0
                } else if category.contains("Slaughter Cattle") {
                    categoryPrice = finalPrice * 0.92
                } else if category.contains("Calves") {
                    categoryPrice = finalPrice * 1.25
                }
                // Sheep categories
                else if category.contains("Breeding Ewe") || category.contains("Maiden Ewe") || category.contains("Dry Ewe") {
                    categoryPrice = finalPrice * 3.2
                } else if category.contains("Cull Ewe") || category.contains("Slaughter Ewe") {
                    categoryPrice = finalPrice * 2.8
                } else if category.contains("Wether Lamb") || category.contains("Weaner Lamb") || category.contains("Feeder Lamb") {
                    categoryPrice = finalPrice * 3.5
                } else if category.contains("Slaughter Lamb") || category.contains("Lambs") {
                    categoryPrice = finalPrice * 3.3
                }
                // Pig categories
                else if (category.contains("Breeder") || category.contains("Dry Sow")) && category.contains("Sow") {
                    categoryPrice = finalPrice * 0.66
                } else if category.contains("Cull Sow") {
                    categoryPrice = finalPrice * 0.60
                } else if category.contains("Weaner Pig") || category.contains("Feeder Pig") {
                    categoryPrice = finalPrice * 0.70
                } else if category.contains("Grower") || category.contains("Finisher") {
                    categoryPrice = finalPrice * 0.65
                } else if category.contains("Porker") || category.contains("Baconer") {
                    categoryPrice = finalPrice * 0.66
                }
                // Goat categories
                else if category.contains("Breeder Doe") || category.contains("Dry Doe") {
                    categoryPrice = finalPrice * 1.30
                } else if category.contains("Cull Doe") {
                    categoryPrice = finalPrice * 1.20
                } else if category.contains("Breeder Buck") || category.contains("Sale Buck") {
                    categoryPrice = finalPrice * 1.35
                } else if category.contains("Mature Wether") || category.contains("Rangeland Goat") {
                    categoryPrice = finalPrice * 1.30
                } else if category.contains("Capretto") {
                    categoryPrice = finalPrice * 1.53
                } else if category.contains("Chevon") {
                    categoryPrice = finalPrice * 1.25
                }
                
                // Random saleyard and state
                let saleyard = saleyards.randomElement() ?? saleyards[0]
                let state = states.randomElement() ?? "NSW"
                
                let price = SupabaseHistoricalPrice(
                    category: category,
                    saleyard: saleyard,
                    state: state,
                    price_per_kg: categoryPrice,
                    price_date: date,
                    source: dayOffset < 7 ? "Saleyard" : (dayOffset < 30 ? "State Indicator" : "National Benchmark"),
                    is_historical: true
                )
                
                prices.append(price)
            }
        }
        
        return prices
    }
    
    // MARK: - Upload Methods
    
    private func uploadSampleHerds(_ herds: [SupabaseSampleHerd]) async throws {
        try await supabase
            .from("sample_herds")
            .insert(herds)
            .execute()
    }
    
    private func uploadHistoricalPricesInBatches(_ prices: [SupabaseHistoricalPrice], batchSize: Int) async throws {
        let totalBatches = (prices.count + batchSize - 1) / batchSize
        
        for batchIndex in 0..<totalBatches {
            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, prices.count)
            let batch = Array(prices[startIndex..<endIndex])
            
            print("⬆️ Uploading batch \(batchIndex + 1)/\(totalBatches) (\(batch.count) records)...")
            
            try await supabase
                .from("historical_market_prices")
                .insert(batch)
                .execute()
            
            // Small delay to avoid rate limiting
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateAgeMonths(category: String) -> Int {
        switch category {
        case let cat where cat.contains("Weaner"):
            return Int.random(in: 6...10)
        case let cat where cat.contains("Yearling"):
            return Int.random(in: 12...18)
        case let cat where cat.contains("Grown"):
            return Int.random(in: 24...36)
        case let cat where cat.contains("Breeding"):
            return Int.random(in: 36...84)
        case let cat where cat.contains("Heifer"):
            return Int.random(in: 18...30)
        default:
            return 24
        }
    }
}

// MARK: - Supabase Data Models

struct SupabaseSampleHerd: Codable {
    let name: String
    let species: String
    let breed: String
    let sex: String
    let category: String
    let age_months: Int
    let head_count: Int
    let initial_weight: Double
    let current_weight: Double
    let daily_weight_gain: Double
    let is_breeder: Bool
    let calving_rate: Double
    let paddock_name: String?
    let selected_saleyard: String?
    let animal_id_number: String?
    let additional_info: String?
    let is_pregnant: Bool
    let joined_date: Date?
    let dwg_change_date: Date?
    let previous_dwg: Double?
    let days_offset: Int
}

struct SupabaseHistoricalPrice: Codable {
    let category: String
    let saleyard: String
    let state: String
    let price_per_kg: Double
    let price_date: Date
    let source: String
    let is_historical: Bool
}

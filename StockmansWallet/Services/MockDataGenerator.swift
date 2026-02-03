//
//  MockDataGenerator.swift
//  StockmansWallet
//
//  Generates realistic demo data for testing and visualization
//  Debug: Creates herds spread over time with realistic farming patterns
//

import Foundation
import SwiftData

// Debug: Service to generate and manage mock/demo livestock data
@MainActor
class MockDataGenerator {
    
    // Debug: Singleton instance for consistent mock data generation
    static let shared = MockDataGenerator()
    
    private init() {}
    
    // MARK: - Mock Data Generation
    
    /// Generate realistic mock herds spread over a specified time period
    /// Debug: Creates varied herds with different species, breeds, ages, and realistic farming activity patterns
    func generateMockData(
        for duration: MockDataDuration,
        in modelContext: ModelContext
    ) async throws {
        let endDate = Date()
        let startDate = duration.startDate(from: endDate)
        let calendar = Calendar.current
        
        // Debug: Calculate how many herds to generate based on duration
        let numberOfHerds = duration.herdCount
        
        #if DEBUG
        print("📊 Generating \(numberOfHerds) mock herds from \(startDate.formatted()) to \(endDate.formatted())")
        #endif
        
        // Debug: Create realistic farming activity patterns with clustering and variation
        var activityDates: [Date] = []
        let timeInterval = endDate.timeIntervalSince(startDate)
        let totalDays = Int(timeInterval / 86400) // Convert to days
        
        // Debug: Generate activity dates with realistic clustering (farmers buy herds in batches)
        var remainingHerds = numberOfHerds
        var currentDay = 0
        
        while remainingHerds > 0 && currentDay < totalDays {
            // Debug: Random gap between activity (1-7 days for short durations, up to 14 for longer)
            let maxGap = duration == .oneMonth ? 5 : (duration == .threeMonths ? 7 : 14)
            let gap = Int.random(in: 1...maxGap)
            currentDay += gap
            
            if currentDay >= totalDays {
                currentDay = totalDays - 1
            }
            
            // Debug: Random number of herds purchased on this day (1-3 for variety)
            let herdsOnThisDay = min(remainingHerds, Int.random(in: 1...3))
            
            // Debug: Create dates for this activity day with slight time variation
            for _ in 0..<herdsOnThisDay {
                if let activityDate = calendar.date(byAdding: .day, value: currentDay, to: startDate) {
                    // Debug: Add random hour within the day (8am to 5pm farming hours)
                    let randomHour = Int.random(in: 8...17)
                    let randomMinute = Int.random(in: 0...59)
                    if let finalDate = calendar.date(bySettingHour: randomHour, minute: randomMinute, second: 0, of: activityDate) {
                        activityDates.append(finalDate)
                    }
                }
            }
            
            remainingHerds -= herdsOnThisDay
        }
        
        // Debug: Sort dates chronologically
        activityDates.sort()
        
        // Debug: Generate herds for each activity date
        var generatedHerds: [HerdGroup] = []
        for (index, createdAt) in activityDates.enumerated() {
            // Debug: Generate a random herd with realistic properties
            let herd = generateRandomHerd(createdAt: createdAt)
            
            // Debug: Add realistic edit history (60% chance of being edited)
            if Bool.random(probability: 0.6) {
                // Debug: Edit happened between creation and now
                let daysAfterCreation = Int.random(in: 1...max(1, calendar.dateComponents([.day], from: createdAt, to: endDate).day ?? 1))
                if let editDate = calendar.date(byAdding: .day, value: daysAfterCreation, to: createdAt) {
                    herd.updatedAt = editDate
                    
                    // Debug: Sometimes weight is updated (DWG change simulating re-weighing)
                    if Bool.random(probability: 0.4) {
                        let dwgVariation = Double.random(in: -0.15...0.15)
                        herd.updateDailyWeightGain(newDWG: max(0, herd.dailyWeightGain + dwgVariation))
                    }
                }
            }
            
            generatedHerds.append(herd)
            modelContext.insert(herd)
        }
        
        // Debug: Simulate sales to create realistic portfolio value dips (35-45% of herds)
        let salePercentage = Double.random(in: 0.35...0.45)
        let numberOfSales = max(2, Int(Double(numberOfHerds) * salePercentage))
        let herdsToSell = generatedHerds.shuffled().prefix(numberOfSales)
        
        var salesDates: [Date] = []
        
        for herd in herdsToSell {
            // Debug: Sell date is between creation and now (minimum 3 days for short-term trading)
            let daysHeld = max(3, calendar.dateComponents([.day], from: herd.createdAt, to: endDate).day ?? 7)
            let randomDaysHeld = Int.random(in: 3...daysHeld)
            
            if let soldDate = calendar.date(byAdding: .day, value: randomDaysHeld, to: herd.createdAt) {
                // Debug: Realistic sale price variation (±15% from market average ~$4.50/kg)
                let basePrice = 4.50
                let priceVariation = Double.random(in: -0.70...0.70)
                let salePrice = max(3.50, basePrice + priceVariation)
                
                herd.markAsSold(price: salePrice, date: soldDate)
                salesDates.append(soldDate)
                
                #if DEBUG
                print("💰 Sold: \(herd.displayName) (\(herd.headCount) head) after \(randomDaysHeld) days at $\(String(format: "%.2f", salePrice))/kg")
                #endif
            }
        }
        
        // Debug: Simulate realistic weight changes and adjustments over time (creates value fluctuations)
        let herdsToAdjust = generatedHerds.filter { !$0.isSold }.shuffled().prefix(max(3, numberOfHerds / 3))
        
        for herd in herdsToAdjust {
            let daysActive = calendar.dateComponents([.day], from: herd.createdAt, to: endDate).day ?? 0
            
            guard daysActive > 3 else { continue }
            
            // Debug: Random adjustment event (weight change, head count reduction, etc.)
            let adjustmentDay = Int.random(in: 3...daysActive)
            if let adjustmentDate = calendar.date(byAdding: .day, value: adjustmentDay, to: herd.createdAt) {
                
                // Debug: 60% chance of DWG adjustment (weight gain slowdown or improvement)
                if Bool.random(probability: 0.6) && herd.dailyWeightGain > 0 {
                    // Debug: DWG can increase or decrease (reflecting seasonal changes, feed quality)
                    let dwgChange = Double.random(in: -0.25...0.20)
                    let newDWG = max(0.1, herd.dailyWeightGain + dwgChange)
                    herd.updateDailyWeightGain(newDWG: newDWG)
                    herd.updatedAt = adjustmentDate
                    
                    #if DEBUG
                    print("⚖️  Adjusted DWG: \(herd.displayName) from \(String(format: "%.2f", herd.dailyWeightGain))kg to \(String(format: "%.2f", newDWG))kg/day")
                    #endif
                }
                
                // Debug: 25% chance of head count reduction (mortality, culling, selling some animals)
                if Bool.random(probability: 0.25) && herd.headCount > 3 {
                    let reduction = Int.random(in: 1...min(5, herd.headCount / 4))
                    let oldCount = herd.headCount
                    herd.headCount = max(1, herd.headCount - reduction)
                    herd.updatedAt = adjustmentDate
                    
                    #if DEBUG
                    print("📉 Head count reduced: \(herd.displayName) from \(oldCount) to \(herd.headCount) head")
                    #endif
                }
                
                // Debug: 15% chance of weight loss period (illness, poor feed, drought)
                if Bool.random(probability: 0.15) && herd.dailyWeightGain > 0 {
                    // Debug: Temporary weight loss period
                    herd.updateDailyWeightGain(newDWG: -Double.random(in: 0.05...0.15))
                    herd.updatedAt = adjustmentDate
                    
                    #if DEBUG
                    print("📉 Weight loss period: \(herd.displayName) now losing \(String(format: "%.2f", abs(herd.dailyWeightGain)))kg/day")
                    #endif
                }
            }
        }
        
        // Debug: Save all mock data to database
        try modelContext.save()
        
        #if DEBUG
        print("✅ Successfully generated \(numberOfHerds) mock herds:")
        print("   📅 Purchase events: \(activityDates.count) over \(totalDays) days")
        print("   💰 Sales: \(numberOfSales) herds sold (\(Int(salePercentage * 100))%)")
        print("   ⚖️  Weight adjustments: \(herdsToAdjust.count) herds")
        print("   📊 Chart will show realistic ups and downs from sales, weight changes, and head count reductions")
        #endif
    }
    
    /// Remove all mock data from the database
    /// Debug: Safely removes only herds marked as mock data
    func removeMockData(from modelContext: ModelContext) throws {
        // Debug: Fetch all herds marked as mock data
        let descriptor = FetchDescriptor<HerdGroup>(
            predicate: #Predicate<HerdGroup> { herd in
                herd.isMockData == true
            }
        )
        
        let mockHerds = try modelContext.fetch(descriptor)
        
        #if DEBUG
        print("🗑️ Removing \(mockHerds.count) mock herds")
        #endif
        
        // Debug: Delete each mock herd (related records cascade automatically)
        for herd in mockHerds {
            modelContext.delete(herd)
        }
        
        try modelContext.save()
        
        #if DEBUG
        print("✅ Successfully removed all mock data")
        #endif
    }
    
    /// Check if any mock data exists
    /// Debug: Used to show/hide the remove button
    func hasMockData(in modelContext: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<HerdGroup>(
            predicate: #Predicate<HerdGroup> { herd in
                herd.isMockData == true
            }
        )
        
        do {
            let count = try modelContext.fetchCount(descriptor)
            return count > 0
        } catch {
            #if DEBUG
            print("⚠️ Error checking for mock data: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Generate a single random herd with realistic properties
    /// Debug: Creates varied herds with appropriate attributes for Australian farming
    private func generateRandomHerd(createdAt: Date) -> HerdGroup {
        // Debug: Randomly select species (70% cattle, 25% sheep, 5% pigs)
        let random = Double.random(in: 0...1)
        let species: String
        let breed: String
        let category: String
        let headCount: Int
        let weight: Double
        let dwg: Double
        let isBreeder: Bool
        
        if random < 0.70 {
            // Debug: Cattle - most common in Australian grazing
            species = "Cattle"
            breed = ReferenceData.cattleBreeds.randomElement() ?? "Angus"
            
            // Debug: Select realistic cattle category
            let categoryOptions = ReferenceData.cattleCategories
            category = categoryOptions.randomElement() ?? "Weaner Steer"
            
            // Debug: Determine if this is a breeding herd
            isBreeder = category.contains("Breeder") || category.contains("Cow")
            
            // Debug: Realistic head count for cattle with wider variation for more fluctuation
            headCount = isBreeder ? Int.random(in: 3...35) : Int.random(in: 5...60)
            
            // Debug: Realistic cattle weights (kg) based on category with wider variation
            if category.contains("Weaner") {
                weight = Double.random(in: 180...300)
                dwg = Double.random(in: 0.5...1.1)
            } else if category.contains("Yearling") {
                weight = Double.random(in: 260...400)
                dwg = Double.random(in: 0.7...1.3)
            } else if category.contains("Breeder") || category.contains("Cow") {
                weight = Double.random(in: 420...620)
                dwg = 0.0 // Breeders typically don't have weight gain tracking
            } else if category.contains("Calves") {
                weight = Double.random(in: 140...230)
                dwg = Double.random(in: 0.6...1.2)
            } else {
                // Debug: Grown/Feeder cattle
                weight = Double.random(in: 330...520)
                dwg = Double.random(in: 0.6...1.4)
            }
            
        } else if random < 0.95 {
            // Debug: Sheep - common in Australian agriculture
            species = "Sheep"
            breed = ReferenceData.sheepBreeds.randomElement() ?? "Merino"
            
            let categoryOptions = ReferenceData.sheepCategories
            category = categoryOptions.randomElement() ?? "Weaner Lamb"
            
            isBreeder = category.contains("Breeder") || category.contains("Ewe")
            
            // Debug: Realistic head count for sheep with wider variation (larger flocks)
            headCount = isBreeder ? Int.random(in: 15...120) : Int.random(in: 25...180)
            
            // Debug: Realistic sheep weights (kg) based on category with wider variation
            if category.contains("Lamb") || category.contains("Weaner") {
                weight = Double.random(in: 22...48)
                dwg = Double.random(in: 0.12...0.35)
            } else if category.contains("Breeder") || category.contains("Ewe") {
                weight = Double.random(in: 50...80)
                dwg = 0.0 // Breeders typically don't have weight gain tracking
            } else {
                // Debug: Feeder/Slaughter sheep
                weight = Double.random(in: 38...68)
                dwg = Double.random(in: 0.18...0.38)
            }
            
        } else {
            // Debug: Pigs - less common but included for variety
            species = "Pig"
            breed = ReferenceData.pigBreeds.randomElement() ?? "Large White"
            
            let categoryOptions = ReferenceData.pigCategories
            category = categoryOptions.randomElement() ?? "Grower Pig"
            
            isBreeder = category.contains("Breeder") || category.contains("Sow")
            
            // Debug: Realistic head count for pigs with variation
            headCount = isBreeder ? Int.random(in: 3...18) : Int.random(in: 8...45)
            
            // Debug: Realistic pig weights (kg) based on category with wider variation
            if category.contains("Weaner") {
                weight = Double.random(in: 12...28)
                dwg = Double.random(in: 0.35...0.65)
            } else if category.contains("Grower") {
                weight = Double.random(in: 28...65)
                dwg = Double.random(in: 0.55...0.95)
            } else if category.contains("Finisher") || category.contains("Baconer") {
                weight = Double.random(in: 55...105)
                dwg = Double.random(in: 0.65...1.05)
            } else if category.contains("Breeder") || category.contains("Sow") {
                weight = Double.random(in: 140...260)
                dwg = 0.0
            } else {
                weight = Double.random(in: 45...95)
                dwg = Double.random(in: 0.45...0.85)
            }
        }
        
        // Debug: Generate realistic paddock names
        let paddockNames = [
            "Home Paddock", "North Field", "South Block", "River Flat",
            "Hill Paddock", "Back 40", "Creek Paddock", "Top Field",
            "Lower Pasture", "Main Run", "East Block", "West Paddock"
        ]
        let paddockName = paddockNames.randomElement()
        
        // Debug: Select a random saleyard (60% chance)
        let saleyard = Bool.random(probability: 0.6) ? ReferenceData.saleyards.randomElement() : nil
        
        // Debug: Determine sex based on category
        let sex: String
        if category.contains("Steer") || category.contains("Bull") || category.contains("Barrow") || category.contains("Wether") || category.contains("Buck") {
            sex = "Male"
        } else if category.contains("Heifer") || category.contains("Cow") || category.contains("Ewe") || category.contains("Sow") || category.contains("Doe") {
            sex = "Female"
        } else {
            // Debug: Mixed or unspecified
            sex = Bool.random() ? "Male" : "Female"
        }
        
        // Debug: Calculate age based on category
        let ageMonths: Int
        if category.contains("Weaner") || category.contains("Calves") || category.contains("Lamb") {
            ageMonths = Int.random(in: 4...8)
        } else if category.contains("Yearling") {
            ageMonths = Int.random(in: 12...18)
        } else if category.contains("Breeder") || category.contains("Grown") || category.contains("Mature") {
            ageMonths = Int.random(in: 24...60)
        } else {
            ageMonths = Int.random(in: 10...20)
        }
        
        // Debug: Create the herd with all realistic properties
        let herd = HerdGroup(
            name: paddockName ?? "Paddock \(Int.random(in: 1...20))",
            species: species,
            breed: breed,
            sex: sex,
            category: category,
            ageMonths: ageMonths,
            headCount: headCount,
            initialWeight: weight,
            dailyWeightGain: dwg,
            isBreeder: isBreeder,
            selectedSaleyard: saleyard
        )
        
        // Debug: Set creation and update dates
        herd.createdAt = createdAt
        herd.updatedAt = createdAt
        
        // Debug: Mark as mock data for easy removal
        herd.isMockData = true
        
        // Debug: Set paddock name if not already set
        if let paddock = paddockName {
            herd.paddockName = paddock
        }
        
        // Debug: Add some breeding-specific info for breeders (40% chance)
        if isBreeder && Bool.random(probability: 0.4) {
            let programs = ["Natural joining", "AI program", "ET program", "Performance recording"]
            herd.additionalInfo = programs.randomElement()
            
            // Debug: 70% chance pregnant if breeder and female
            if sex == "Female" && Bool.random(probability: 0.7) {
                herd.isPregnant = true
                // Debug: Random joining date in the last 3-9 months
                let daysAgo = Int.random(in: 90...270)
                herd.joinedDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: createdAt)
                herd.calvingRate = Double.random(in: 0.80...0.95)
            }
        }
        
        // Debug: Add notes for some herds (30% chance)
        if Bool.random(probability: 0.3) {
            let noteOptions = [
                "Good condition", "Ready for sale", "Monitor closely",
                "Strong performers", "Need supplementary feed", "Top quality"
            ]
            herd.notes = noteOptions.randomElement()
        }
        
        return herd
    }
}

// MARK: - Mock Data Duration Options

/// Debug: Duration options for mock data generation
enum MockDataDuration: String, CaseIterable {
    case oneMonth = "1 Month"
    case threeMonths = "3 Months"
    case oneYear = "1 Year"
    
    /// Calculate the start date for this duration
    /// Debug: Returns the date to start generating mock data from
    func startDate(from endDate: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        }
    }
    
    /// Number of herds to generate for this duration
    /// Debug: Increased for better chart visualization and day-to-day fluctuation
    var herdCount: Int {
        switch self {
        case .oneMonth:
            return 12 // ~3 per week for good day/week view fluctuation
        case .threeMonths:
            return 25 // ~2 per week for visible weekly patterns
        case .oneYear:
            return 50 // ~4 per month for varied monthly activity
        }
    }
}

// MARK: - Helper Extensions

extension Bool {
    /// Debug: Helper to generate random bools with custom probability
    static func random(probability: Double) -> Bool {
        return Double.random(in: 0...1) < probability
    }
}

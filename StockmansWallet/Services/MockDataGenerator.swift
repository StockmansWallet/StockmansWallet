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
    /// Debug: Creates varied herds with different species, breeds, and ages
    func generateMockData(
        for duration: MockDataDuration,
        in modelContext: ModelContext
    ) async throws {
        let endDate = Date()
        let startDate = duration.startDate(from: endDate)
        
        // Debug: Calculate how many herds to generate based on duration
        let numberOfHerds = duration.herdCount
        
        #if DEBUG
        print("📊 Generating \(numberOfHerds) mock herds from \(startDate.formatted()) to \(endDate.formatted())")
        #endif
        
        // Debug: Generate herds spread evenly over the time period
        let timeInterval = endDate.timeIntervalSince(startDate)
        let intervalPerHerd = timeInterval / Double(numberOfHerds)
        
        for i in 0..<numberOfHerds {
            // Debug: Calculate creation date for this herd (spread evenly over time)
            let offset = Double(i) * intervalPerHerd
            let createdAt = startDate.addingTimeInterval(offset)
            
            // Debug: Generate a random herd with realistic properties
            let herd = generateRandomHerd(createdAt: createdAt)
            
            // Debug: Randomly add some edits to simulate real farming activity
            if Bool.random() {
                // Debug: 50% chance the herd was edited at some point
                let editOffset = Double.random(in: 0.1...0.9) * timeInterval
                herd.updatedAt = startDate.addingTimeInterval(offset + editOffset)
            }
            
            modelContext.insert(herd)
        }
        
        // Debug: Save all mock data to database
        try modelContext.save()
        
        #if DEBUG
        print("✅ Successfully generated \(numberOfHerds) mock herds")
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
            
            // Debug: Realistic head count for cattle (smaller for individuals, larger for herds)
            headCount = isBreeder ? Int.random(in: 5...30) : Int.random(in: 10...50)
            
            // Debug: Realistic cattle weights (kg) based on category
            if category.contains("Weaner") {
                weight = Double.random(in: 200...280)
                dwg = Double.random(in: 0.6...1.0)
            } else if category.contains("Yearling") {
                weight = Double.random(in: 280...380)
                dwg = Double.random(in: 0.8...1.2)
            } else if category.contains("Breeder") || category.contains("Cow") {
                weight = Double.random(in: 450...600)
                dwg = 0.0 // Breeders typically don't have weight gain tracking
            } else if category.contains("Calves") {
                weight = Double.random(in: 150...220)
                dwg = Double.random(in: 0.7...1.1)
            } else {
                // Debug: Grown/Feeder cattle
                weight = Double.random(in: 350...500)
                dwg = Double.random(in: 0.7...1.3)
            }
            
        } else if random < 0.95 {
            // Debug: Sheep - common in Australian agriculture
            species = "Sheep"
            breed = ReferenceData.sheepBreeds.randomElement() ?? "Merino"
            
            let categoryOptions = ReferenceData.sheepCategories
            category = categoryOptions.randomElement() ?? "Weaner Lamb"
            
            isBreeder = category.contains("Breeder") || category.contains("Ewe")
            
            // Debug: Realistic head count for sheep (larger flocks)
            headCount = isBreeder ? Int.random(in: 20...100) : Int.random(in: 30...150)
            
            // Debug: Realistic sheep weights (kg) based on category
            if category.contains("Lamb") || category.contains("Weaner") {
                weight = Double.random(in: 25...45)
                dwg = Double.random(in: 0.15...0.30)
            } else if category.contains("Breeder") || category.contains("Ewe") {
                weight = Double.random(in: 55...75)
                dwg = 0.0 // Breeders typically don't have weight gain tracking
            } else {
                // Debug: Feeder/Slaughter sheep
                weight = Double.random(in: 40...65)
                dwg = Double.random(in: 0.20...0.35)
            }
            
        } else {
            // Debug: Pigs - less common but included for variety
            species = "Pig"
            breed = ReferenceData.pigBreeds.randomElement() ?? "Large White"
            
            let categoryOptions = ReferenceData.pigCategories
            category = categoryOptions.randomElement() ?? "Grower Pig"
            
            isBreeder = category.contains("Breeder") || category.contains("Sow")
            
            // Debug: Realistic head count for pigs
            headCount = isBreeder ? Int.random(in: 5...15) : Int.random(in: 10...40)
            
            // Debug: Realistic pig weights (kg) based on category
            if category.contains("Weaner") {
                weight = Double.random(in: 15...25)
                dwg = Double.random(in: 0.4...0.6)
            } else if category.contains("Grower") {
                weight = Double.random(in: 30...60)
                dwg = Double.random(in: 0.6...0.9)
            } else if category.contains("Finisher") || category.contains("Baconer") {
                weight = Double.random(in: 60...100)
                dwg = Double.random(in: 0.7...1.0)
            } else if category.contains("Breeder") || category.contains("Sow") {
                weight = Double.random(in: 150...250)
                dwg = 0.0
            } else {
                weight = Double.random(in: 50...90)
                dwg = Double.random(in: 0.5...0.8)
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
    /// Debug: Realistic number of herd additions over time
    var herdCount: Int {
        switch self {
        case .oneMonth:
            return 5 // ~1 per week
        case .threeMonths:
            return 12 // ~1 per week
        case .oneYear:
            return 24 // ~2 per month
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

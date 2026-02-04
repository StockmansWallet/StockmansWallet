//
//  CalvingManager.swift
//  StockmansWallet
//
//  Automatic calf generation service for breeding herds
//  Debug: Monitors pregnant herds and auto-creates calf records after gestation completes
//

import Foundation
import SwiftData

@Observable
class CalvingManager {
    static let shared = CalvingManager()
    
    // MARK: - Constants
    // Debug: Gestation periods in days
    private let cattleGestationDays = 283
    private let sheepGestationDays = 150
    private let goatGestationDays = 150
    private let pigGestationDays = 114
    
    // Debug: Default daily weight gain for newborn progeny (kg/day)
    // Based on Australian industry standards
    private let defaultDailyWeightGain: [String: Double] = [
        "Cattle": 0.9,  // Beef calves: 0.8-1.2 kg/day, 0.9 is solid middle ground
        "Sheep": 0.25,  // Lambs: 0.2-0.3 kg/day
        "Goats": 0.15,  // Kids: 0.1-0.2 kg/day
        "Pigs": 0.5     // Piglets: 0.4-0.6 kg/day
    ]
    
    // Debug: Birth weight as percentage of mother's weight
    private let birthWeightRatio: [String: Double] = [
        "Cattle": 0.07,  // 7% (35-40kg from 500-550kg cow)
        "Sheep": 0.08,   // 8% (5-6kg from 60-70kg ewe)
        "Goats": 0.08,   // 8% (4-5kg from 50-60kg doe)
        "Pigs": 0.02     // 2% (2-3kg from 150kg sow)
    ]
    
    private init() {}
    
    // MARK: - Main Processing Function
    /// Checks all breeding herds and auto-generates calves for those past gestation
    /// Debug: Should be called when portfolio loads or when viewing breeding herds
    @MainActor
    func processCalvingEvents(herds: [HerdGroup], modelContext: ModelContext) async {
        var calvesGenerated = 0
        
        for herd in herds {
            // Debug: Only process pregnant breeding herds that haven't been processed yet
            guard herd.isPregnant,
                  herd.isBreeder,
                  let joinedDate = herd.joinedDate,
                  herd.calvingProcessedDate == nil else {
                continue
            }
            
            // Debug: Check if gestation period is complete
            let daysElapsed = Calendar.current.dateComponents([.day], from: joinedDate, to: Date()).day ?? 0
            let gestationDays = getGestationDays(for: herd.species)
            
            guard daysElapsed >= gestationDays else {
                continue // Still pregnant
            }
            
            // Debug: Calculate calving date (gestation days after joining)
            guard let calvingDate = Calendar.current.date(byAdding: .day, value: gestationDays, to: joinedDate) else {
                continue
            }
            
            #if DEBUG
            print("🐄 CalvingManager: Processing calving for \(herd.name)")
            print("   Joined: \(joinedDate.formatted(date: .abbreviated, time: .omitted))")
            print("   Calving: \(calvingDate.formatted(date: .abbreviated, time: .omitted))")
            print("   Days elapsed: \(daysElapsed)")
            #endif
            
            // Debug: Generate calves
            let generatedCount = await generateCalves(
                from: herd,
                calvingDate: calvingDate,
                modelContext: modelContext
            )
            
            calvesGenerated += generatedCount
            
            // Debug: Mark this herd as processed
            herd.calvingProcessedDate = Date()
            herd.isPregnant = false // No longer pregnant after calving
            herd.updatedAt = Date()
        }
        
        if calvesGenerated > 0 {
            do {
                try modelContext.save()
                #if DEBUG
                print("✅ CalvingManager: Generated \(calvesGenerated) calves")
                #endif
            } catch {
                print("❌ CalvingManager: Error saving calves: \(error)")
            }
        }
    }
    
    // MARK: - Calf Generation
    /// Generates individual calf records for a breeding herd
    private func generateCalves(
        from motherHerd: HerdGroup,
        calvingDate: Date,
        modelContext: ModelContext
    ) async -> Int {
        // Debug: Calculate expected number of progeny based on calving rate
        let expectedProgeny = Int(Double(motherHerd.headCount) * motherHerd.calvingRate)
        
        guard expectedProgeny > 0 else {
            #if DEBUG
            print("⚠️ CalvingManager: No calves expected (calving rate too low)")
            #endif
            return 0
        }
        
        // Debug: Calculate birth weight based on mother's current weight
        let motherWeight = motherHerd.approximateCurrentWeight
        let birthWeight = motherWeight * (birthWeightRatio[motherHerd.species] ?? 0.07)
        
        // Debug: Get appropriate daily weight gain for species
        let dwg = defaultDailyWeightGain[motherHerd.species] ?? 0.9
        
        // Debug: Determine calf category based on species
        let calfCategory = getCalfCategory(for: motherHerd.species)
        
        #if DEBUG
        print("   Expected progeny: \(expectedProgeny)")
        print("   Birth weight: \(String(format: "%.1f", birthWeight)) kg")
        print("   Daily weight gain: \(dwg) kg/day")
        #endif
        
        // Debug: Generate individual calf records
        for i in 1...expectedProgeny {
            let calf = HerdGroup(
                name: "Calf \(i) from \(motherHerd.name)",
                species: motherHerd.species,
                breed: motherHerd.breed,
                sex: "Mixed", // Could randomize M/F if needed
                category: calfCategory,
                ageMonths: 0, // Newborn
                headCount: 1,
                initialWeight: birthWeight,
                dailyWeightGain: dwg,
                isBreeder: false,
                selectedSaleyard: motherHerd.selectedSaleyard
            )
            
            // Debug: Set creation date to calving date (not today)
            calf.createdAt = calvingDate
            calf.updatedAt = Date()
            
            // Debug: Copy location from mother
            calf.paddockName = motherHerd.paddockName
            calf.locationLatitude = motherHerd.locationLatitude
            calf.locationLongitude = motherHerd.locationLongitude
            
            // Debug: Add note about origin
            calf.notes = "Auto-generated from \(motherHerd.displayName) on \(calvingDate.formatted(date: .abbreviated, time: .omitted))"
            
            modelContext.insert(calf)
        }
        
        return expectedProgeny
    }
    
    // MARK: - Helper Functions
    
    /// Returns gestation period in days for a species
    private func getGestationDays(for species: String) -> Int {
        switch species {
        case "Cattle":
            return cattleGestationDays
        case "Sheep":
            return sheepGestationDays
        case "Goats":
            return goatGestationDays
        case "Pigs":
            return pigGestationDays
        default:
            return cattleGestationDays // Default to cattle
        }
    }
    
    /// Returns appropriate category name for newborn progeny
    private func getCalfCategory(for species: String) -> String {
        switch species {
        case "Cattle":
            return "Calves"
        case "Sheep":
            return "Lambs"
        case "Goats":
            return "Kids"
        case "Pigs":
            return "Piglets"
        default:
            return "Calves"
        }
    }
}

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
    
    // MARK: - Manual Calves at Foot Conversion
    /// Converts manual "calves at foot" text entries into real HerdGroup entities
    /// Debug: Processes all herds with "Calves at Foot" in additionalInfo and creates actual calf records
    @MainActor
    func processManualCalvesAtFoot(herds: [HerdGroup], modelContext: ModelContext) async {
        var calvesGenerated = 0
        
        for herd in herds {
            // Debug: Only process breeding herds with calves at foot info
            guard herd.isBreeder,
                  let additionalInfo = herd.additionalInfo,
                  additionalInfo.contains("Calves at Foot:") else {
                continue
            }
            
            // Debug: Parse calves at foot data
            guard let calvesData = parseCalvesAtFootData(from: additionalInfo) else {
                continue
            }
            
            #if DEBUG
            print("🍼 CalvingManager: Converting manual calves at foot for \(herd.name)")
            print("   Head count: \(calvesData.headCount)")
            print("   Age: \(calvesData.ageMonths) months")
            print("   Weight: \(calvesData.averageWeight ?? 0) kg")
            #endif
            
            // Debug: Generate individual calf records
            let generatedCount = await generateManualCalves(
                from: herd,
                calvesData: calvesData,
                modelContext: modelContext
            )
            
            calvesGenerated += generatedCount
            
            // Debug: Remove "Calves at Foot" from additionalInfo after conversion
            herd.additionalInfo = removeCalvesAtFootFromInfo(additionalInfo)
            herd.updatedAt = Date()
        }
        
        if calvesGenerated > 0 {
            do {
                try modelContext.save()
                #if DEBUG
                print("✅ CalvingManager: Converted \(calvesGenerated) manual calves to real entities")
                #endif
            } catch {
                print("❌ CalvingManager: Error saving manual calves: \(error)")
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
    
    // MARK: - Manual Calves Helpers
    
    /// Parses calves at foot data from additionalInfo string
    /// Debug: Extracts head count, age in months, and optional average weight
    private func parseCalvesAtFootData(from additionalInfo: String) -> (headCount: Int, ageMonths: Int, averageWeight: Double?)? {
        // Look for pattern: "Calves at Foot: X head, Y months" or "Calves at Foot: X head, Y months, Z kg"
        guard let range = additionalInfo.range(of: "Calves at Foot: ([^|\\n]+)", options: .regularExpression) else {
            return nil
        }
        
        let calvesInfo = String(additionalInfo[range])
        let parts = calvesInfo.replacingOccurrences(of: "Calves at Foot: ", with: "").components(separatedBy: ", ")
        
        var headCount: Int? = nil
        var ageMonths: Int? = nil
        var averageWeight: Double? = nil
        
        for part in parts {
            if part.contains("head") {
                headCount = Int(part.replacingOccurrences(of: " head", with: "").trimmingCharacters(in: .whitespaces))
            } else if part.contains("months") {
                ageMonths = Int(part.replacingOccurrences(of: " months", with: "").trimmingCharacters(in: .whitespaces))
            } else if part.contains("kg") {
                averageWeight = Double(part.replacingOccurrences(of: " kg", with: "").trimmingCharacters(in: .whitespaces))
            }
        }
        
        guard let count = headCount, count > 0, let age = ageMonths else {
            return nil
        }
        
        return (count, age, averageWeight)
    }
    
    /// Generates individual calf records from manual "calves at foot" data
    /// Debug: Creates real HerdGroup entities with proper DWG and backdated creation dates
    private func generateManualCalves(
        from motherHerd: HerdGroup,
        calvesData: (headCount: Int, ageMonths: Int, averageWeight: Double?),
        modelContext: ModelContext
    ) async -> Int {
        let headCount = calvesData.headCount
        let ageMonths = calvesData.ageMonths
        let averageWeight = calvesData.averageWeight
        
        // Debug: Get appropriate daily weight gain for species
        let dwg = defaultDailyWeightGain[motherHerd.species] ?? 0.9
        
        // Debug: Determine calf category based on species
        let calfCategory = getCalfCategory(for: motherHerd.species)
        
        // Debug: Calculate birth date based on age (backdate creation)
        let birthDate = Calendar.current.date(byAdding: .month, value: -ageMonths, to: Date()) ?? Date()
        
        // Debug: Calculate initial weight at birth
        let birthWeightRatio = birthWeightRatio[motherHerd.species] ?? 0.07
        let calculatedBirthWeight: Double
        
        if let userWeight = averageWeight {
            // Debug: User provided average weight - work backward to calculate birth weight
            // Formula: userWeight = birthWeight + (dwg × days)
            let daysOld = Double(ageMonths) * 30.0 // Approximate days in a month
            calculatedBirthWeight = max(userWeight - (dwg * daysOld), userWeight * 0.3) // Ensure birth weight is at least 30% of current
        } else {
            // Debug: No weight provided - use mother's weight to estimate
            calculatedBirthWeight = motherHerd.approximateCurrentWeight * birthWeightRatio
        }
        
        #if DEBUG
        print("   Birth weight: \(String(format: "%.1f", calculatedBirthWeight)) kg")
        print("   Daily weight gain: \(dwg) kg/day")
        print("   Birth date (backdated): \(birthDate.formatted(date: .abbreviated, time: .omitted))")
        #endif
        
        // Debug: Generate individual calf records
        for i in 1...headCount {
            let calf = HerdGroup(
                name: "Calf \(i) from \(motherHerd.name)",
                species: motherHerd.species,
                breed: motherHerd.breed,
                sex: "Mixed",
                category: calfCategory,
                ageMonths: ageMonths,
                headCount: 1,
                initialWeight: calculatedBirthWeight,
                dailyWeightGain: dwg,
                isBreeder: false,
                selectedSaleyard: motherHerd.selectedSaleyard
            )
            
            // Debug: Set creation date to birth date (backdate for accurate weight tracking)
            calf.createdAt = birthDate
            calf.updatedAt = Date()
            
            // Debug: Copy location from mother
            calf.paddockName = motherHerd.paddockName
            calf.locationLatitude = motherHerd.locationLatitude
            calf.locationLongitude = motherHerd.locationLongitude
            
            // Debug: Add note about origin
            calf.notes = "Converted from manual 'calves at foot' entry on \(motherHerd.displayName)"
            
            modelContext.insert(calf)
        }
        
        return headCount
    }
    
    /// Removes "Calves at Foot" entry from additionalInfo while preserving other data
    /// Debug: Returns cleaned additionalInfo or nil if empty after removal
    private func removeCalvesAtFootFromInfo(_ additionalInfo: String) -> String? {
        // Split by pipe and filter out calves at foot entries
        let parts = additionalInfo.components(separatedBy: " | ")
        let filtered = parts.filter { !$0.contains("Calves at Foot:") }
        
        let result = filtered.joined(separator: " | ").trimmingCharacters(in: .whitespaces)
        return result.isEmpty ? nil : result
    }
}

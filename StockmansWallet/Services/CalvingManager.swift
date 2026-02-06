//
//  CalvingManager.swift
//  StockmansWallet
//
//  DEPRECATED: Automatic calf generation service (no longer creates separate HerdGroups)
//  Debug: Calf value is now calculated within breeding herd valuation (see ValuationEngine.calculateHerdValue)
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
    /// DEPRECATED: No longer creates separate calf HerdGroups
    /// Debug: Calf value is now calculated within breeding herd's breedingAccrual (see ValuationEngine)
    @MainActor
    func processCalvingEvents(herds: [HerdGroup], modelContext: ModelContext) async {
        // Debug: Disabled - calves are now included in parent herd valuation
        return
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
    /// DEPRECATED: No longer creates separate calf HerdGroups
    /// Debug: Calves at foot are now displayed in BreedingDetailsCard and included in parent herd valuation
    @MainActor
    func processManualCalvesAtFoot(herds: [HerdGroup], modelContext: ModelContext) async {
        // Debug: Disabled - calves at foot are now part of parent herd valuation
        return
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
    /// Generates a grouped calf herd for a breeding herd
    /// Debug: Creates one HerdGroup entity with headCount = total progeny (efficient for portfolio management)
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
        
        // Debug: Format year for calf group name
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        let calvingYear = yearFormatter.string(from: calvingDate)
        
        #if DEBUG
        print("   Expected progeny: \(expectedProgeny)")
        print("   Birth weight: \(String(format: "%.1f", birthWeight)) kg")
        print("   Daily weight gain: \(dwg) kg/day")
        print("   Creating grouped calf herd with \(expectedProgeny) head")
        #endif
        
        // Debug: Generate one grouped calf herd (efficient for commercial operations)
        let calfHerd = HerdGroup(
            name: "\(calvingYear) \(calfCategory) from \(motherHerd.name)",
            species: motherHerd.species,
            breed: motherHerd.breed,
            sex: "Mixed", // Mixed sex for commercial calves
            category: calfCategory,
            ageMonths: 0, // Newborn
            headCount: expectedProgeny, // Group all calves together
            initialWeight: birthWeight,
            dailyWeightGain: dwg,
            isBreeder: false,
            selectedSaleyard: motherHerd.selectedSaleyard
        )
        
        // Debug: Set creation date to calving date (not today)
        calfHerd.createdAt = calvingDate
        calfHerd.updatedAt = Date()
        
        // Debug: DEPRECATED - parentHerdId no longer used (calves not created as separate HerdGroups)
        // calfHerd.parentHerdId = motherHerd.id
        
        // Debug: Copy location from mother
        calfHerd.paddockName = motherHerd.paddockName
        calfHerd.locationLatitude = motherHerd.locationLatitude
        calfHerd.locationLongitude = motherHerd.locationLongitude
        
        // Debug: Add note about origin
        calfHerd.notes = "Auto-generated from \(motherHerd.displayName) on \(calvingDate.formatted(date: .abbreviated, time: .omitted))"
        
        modelContext.insert(calfHerd)
        
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
    
    /// Generates a grouped calf herd from manual "calves at foot" data
    /// Debug: Creates one HerdGroup entity with proper DWG and backdated creation date
    private func generateManualCalves(
        from motherHerd: HerdGroup,
        calvesData: (headCount: Int, ageMonths: Int, averageWeight: Double?),
        modelContext: ModelContext
    ) async -> Int {
        let headCount = calvesData.headCount
        let ageMonths = calvesData.ageMonths
        let averageWeight = calvesData.averageWeight
        
        guard headCount > 0 else {
            return 0
        }
        
        // Debug: Get appropriate daily weight gain for species
        let dwg = defaultDailyWeightGain[motherHerd.species] ?? 0.9
        
        // Debug: Determine calf category based on species
        let calfCategory = getCalfCategory(for: motherHerd.species)
        
        // Debug: Calculate birth date based on age (backdate creation)
        let birthDate = Calendar.current.date(byAdding: .month, value: -ageMonths, to: Date()) ?? Date()
        
        // Debug: Format year for calf group name
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        let birthYear = yearFormatter.string(from: birthDate)
        
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
        print("   Creating grouped calf herd with \(headCount) head")
        #endif
        
        // Debug: Generate one grouped calf herd (efficient for commercial operations)
        let calfHerd = HerdGroup(
            name: "\(birthYear) \(calfCategory) from \(motherHerd.name)",
            species: motherHerd.species,
            breed: motherHerd.breed,
            sex: "Mixed",
            category: calfCategory,
            ageMonths: ageMonths,
            headCount: headCount, // Group all calves together
            initialWeight: calculatedBirthWeight,
            dailyWeightGain: dwg,
            isBreeder: false,
            selectedSaleyard: motherHerd.selectedSaleyard
        )
        
        // Debug: Set creation date to birth date (backdate for accurate weight tracking)
        calfHerd.createdAt = birthDate
        calfHerd.updatedAt = Date()
        
        // Debug: DEPRECATED - parentHerdId no longer used (calves not created as separate HerdGroups)
        // calfHerd.parentHerdId = motherHerd.id
        
        // Debug: Copy location from mother
        calfHerd.paddockName = motherHerd.paddockName
        calfHerd.locationLatitude = motherHerd.locationLatitude
        calfHerd.locationLongitude = motherHerd.locationLongitude
        
        // Debug: Add note about origin
        calfHerd.notes = "Converted from manual 'calves at foot' entry on \(motherHerd.displayName)"
        
        modelContext.insert(calfHerd)
        
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

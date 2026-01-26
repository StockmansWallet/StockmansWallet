//
//  HealthRecord.swift
//  StockmansWallet
//
//  SwiftData Model for Health Treatment Records
//  Debug: Tracks vaccinations, drenching, parasite treatments, and other health events
//

import Foundation
import SwiftData

// MARK: - Health Treatment Types
enum HealthTreatmentType: String, Codable, CaseIterable {
    case vaccination = "Vaccination"
    case drenching = "Drenching"
    case parasiteTreatment = "Parasite Treatment"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .vaccination:
            return "syringe"
        case .drenching:
            return "drop.fill"
        case .parasiteTreatment:
            return "ant.fill"
        case .other:
            return "cross.case.fill"
        }
    }
}

@Model
final class HealthRecord {
    // MARK: - Properties
    var id: UUID
    var date: Date
    var treatmentTypeRaw: String // Store enum as string for SwiftData compatibility
    var notes: String? // Optional notes about this treatment (e.g., "5-in-1 vaccine", "Ivomec drench", etc.)
    var createdAt: Date
    
    // MARK: - Relationships
    // Debug: Relationship back to the herd/animal this health record belongs to
    var herd: HerdGroup?
    
    init(
        date: Date,
        treatmentType: HealthTreatmentType,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.treatmentTypeRaw = treatmentType.rawValue
        self.notes = notes
        self.createdAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Get the treatment type as enum
    var treatmentType: HealthTreatmentType {
        get {
            return HealthTreatmentType(rawValue: treatmentTypeRaw) ?? .other
        }
        set {
            treatmentTypeRaw = newValue.rawValue
        }
    }
    
    /// Format the health record date for display
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    /// Display string for treatment type
    var treatmentDescription: String {
        treatmentType.rawValue
    }
    
    /// Icon for the treatment type
    var treatmentIcon: String {
        treatmentType.icon
    }
}

//
//  MusterRecord.swift
//  StockmansWallet
//
//  SwiftData Model for Mustering History Records
//  Debug: Tracks individual muster events with date and optional notes
//

import Foundation
import SwiftData

@Model
final class MusterRecord {
    // MARK: - Properties
    var id: UUID
    var date: Date
    var notes: String? // Optional notes about this muster (e.g., "Drenched", "Tagged 5 new calves", etc.)
    var createdAt: Date
    
    // MARK: - Relationships
    // Debug: Relationship back to the herd/animal this muster record belongs to
    var herd: HerdGroup?
    
    init(
        date: Date,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.notes = notes
        self.createdAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Format the muster date for display
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    /// Display string combining date and notes
    var displayDescription: String {
        if let notes = notes, !notes.isEmpty {
            return "\(formattedDate) - \(notes)"
        } else {
            return formattedDate
        }
    }
}

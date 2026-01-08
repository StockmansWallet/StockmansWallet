//
//  CustomSaleLocation.swift
//  StockmansWallet
//
//  Model for user-defined private sale locations and other sale venues
//  Debug: Stores custom sale locations with contact details
//

import Foundation
import SwiftData

@Model
final class CustomSaleLocation {
    var id: UUID
    var name: String
    var category: String // "Private" or "Other"
    var address: String?
    var contactName: String?
    var contactPhone: String?
    var contactEmail: String?
    var notes: String?
    var isEnabled: Bool // Debug: Toggle on/off like saleyards
    var createdDate: Date
    
    init(
        name: String,
        category: String,
        address: String? = nil,
        contactName: String? = nil,
        contactPhone: String? = nil,
        contactEmail: String? = nil,
        notes: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.address = address
        self.contactName = contactName
        self.contactPhone = contactPhone
        self.contactEmail = contactEmail
        self.notes = notes
        self.isEnabled = isEnabled
        self.createdDate = Date()
    }
    
    // Debug: Helper to check if location is private category
    var isPrivate: Bool {
        category == "Private"
    }
    
    // Debug: Helper to check if location is other category
    var isOther: Bool {
        category == "Other"
    }
}

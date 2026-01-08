//
//  UserPreferences.swift
//  StockmansWallet
//
//  SwiftData Model for User Settings and Preferences
//

import Foundation
import SwiftData

// MARK: - User Role Enum
// Debug: All user types from workflow diagram
enum UserRole: String, Codable, CaseIterable {
    case farmerGrazier = "Farmer/Grazier"
    case agribusinessBanker = "Agribusiness Banker"
    case insurer = "Insurer"
    case livestockAgent = "Livestock Agent"
    case accountant = "Accountant"
    case successionPlanner = "Succession Planner"
}

// MARK: - User Type Enum
// Debug: Top-level classification - determines onboarding flow path
enum UserType: String, Codable {
    case farmer = "Farmer/Grazier"
    case advisory = "Advisory User"
    
    // Helper to determine if a role is advisory
    static func isAdvisoryRole(_ role: UserRole) -> Bool {
        switch role {
        case .farmerGrazier:
            return false
        case .agribusinessBanker, .insurer, .livestockAgent, .accountant, .successionPlanner:
            return true
        }
    }
}

@Model
final class UserPreferences {
    var id: UUID
    var hasCompletedOnboarding: Bool
    
    // MARK: - Identity & Credentials
    var firstName: String?
    var lastName: String?
    var email: String?
    var profilePhotoData: Data? // Profile photo as Data
    
    // MARK: - Persona & Security
    var role: String? // UserRole as String for SwiftData compatibility
    var twoFactorEnabled: Bool
    var appsComplianceAccepted: Bool
    
    // MARK: - Property Localization (Farmer/Grazier)
    var propertyName: String?
    var propertyPIC: String? // Property Identification Code
    var propertyRole: String? // User's role on the property (Owner, Manager, etc.)
    var propertyAddress: String? // Full property address
    var defaultState: String // "NSW", "VIC", "QLD", etc.
    var latitude: Double?
    var longitude: Double?
    var farmSize: String? // Debug: Farm size for subscription tier determination ("under100" or "over100")
    
    // MARK: - Company Information (Advisory Users)
    // Debug: Fields for advisory user onboarding flow
    var companyName: String?
    var companyType: String? // e.g., "Bank", "Insurance Company", "Livestock Agency"
    var companyAddress: String?
    var roleInCompany: String? // User's specific role within the company
    
    // MARK: - Subscription Information
    // Debug: User's selected subscription tier
    var subscriptionTier: String? // SubscriptionTier as String for SwiftData compatibility
    
    // MARK: - Market & Logistics
    var defaultSaleyard: String?
    var region: String?
    var truckItEnabled: Bool
    var enabledSaleyards: [String] // Debug: Array of saleyard names that user has enabled (empty = all enabled)
    
    // MARK: - Financial Ecosystem
    var xeroConnected: Bool
    var myobConnected: Bool
    
    // MARK: - Valuation Settings
    var defaultMortalityRate: Double // Annual percentage (e.g., 0.05 for 5%)
    var defaultCalvingRate: Double // Default for breeding stock (e.g., 0.85)
    
    // MARK: - Cost to Carry
    var monthlyAgistmentCost: Double
    var monthlyFeedCost: Double
    var monthlyVetCost: Double
    var freightCostPerKm: Double
    
    // MARK: - Display Preferences
    var currency: String // "AUD", "USD", etc.
    var weightUnit: String // "kg", "lbs"
    var dateFormat: String
    var backgroundImageName: String? // Name of selected background image (asset name or custom filename)
    var isCustomBackground: Bool // Debug: True if background is a custom uploaded image
    var customBackgroundImages: [String] // Debug: Array of custom uploaded image filenames
    
    // MARK: - Dashboard Card Visibility
    // Debug: User preferences for which dashboard cards to show/hide
    var showPerformanceChart: Bool // Show/hide performance chart card
    var showQuickActions: Bool // Show/hide quick actions card
    var showMarketSummary: Bool // Show/hide market summary card
    var showRecentActivity: Bool // Show/hide recent activity card
    var showHerdComposition: Bool // Show/hide herd composition card
    var dashboardCardOrder: [String] // Debug: Custom order of dashboard cards (drag to rearrange)
    
    // MARK: - Dashboard State
    // Debug: Store last known portfolio value for "crypto-style" value reveal on dashboard load
    var lastPortfolioValue: Double // Last calculated portfolio value
    var lastPortfolioUpdateDate: Date? // When the value was last updated
    var lastChartData: Data? // Debug: Cached chart history as JSON for instant display
    
    init() {
        self.id = UUID()
        self.hasCompletedOnboarding = false
        self.firstName = nil
        self.lastName = nil
        self.email = nil
        self.profilePhotoData = nil
        self.role = nil
        self.twoFactorEnabled = false
        self.appsComplianceAccepted = false
        self.propertyName = nil
        self.propertyPIC = nil
        self.propertyRole = nil
        self.propertyAddress = nil
        self.defaultState = "QLD" // Debug: Default to QLD as per user request
        self.latitude = nil
        self.longitude = nil
        self.farmSize = nil // Debug: Set during onboarding to determine subscription tier
        self.companyName = nil
        self.companyType = nil
        self.companyAddress = nil
        self.roleInCompany = nil
        self.subscriptionTier = nil
        self.defaultSaleyard = nil
        self.region = nil
        self.truckItEnabled = false
        self.enabledSaleyards = [] // Debug: Empty array means all saleyards enabled by default
        self.xeroConnected = false
        self.myobConnected = false
        self.defaultMortalityRate = 0.05 // 5% annual
        self.defaultCalvingRate = 0.85 // 85%
        self.monthlyAgistmentCost = 0.0
        self.monthlyFeedCost = 0.0
        self.monthlyVetCost = 0.0
        self.freightCostPerKm = 0.0
        self.currency = "AUD"
        self.weightUnit = "kg"
        self.dateFormat = "dd/MM/yyyy"
        self.backgroundImageName = "BackgroundDefault" // Default background image
        self.isCustomBackground = false // Debug: Default to built-in asset
        self.customBackgroundImages = [] // Debug: Start with empty array of custom images
        self.showPerformanceChart = true // Debug: Show by default
        self.showQuickActions = true // Debug: Show by default
        self.showMarketSummary = true // Debug: Show by default
        self.showRecentActivity = true // Debug: Show by default
        self.showHerdComposition = true // Debug: Show by default
        self.dashboardCardOrder = ["performanceChart", "quickActions", "marketSummary", "recentActivity", "herdComposition"] // Debug: Default order
        self.lastPortfolioValue = 0.0 // Debug: Start at 0, will be updated after first calculation
        self.lastPortfolioUpdateDate = nil // Debug: No previous update
        self.lastChartData = nil // Debug: No cached chart data initially
    }
    
    // Helper to get/set role as enum
    var userRole: UserRole? {
        get {
            guard let roleString = role else { return nil }
            return UserRole(rawValue: roleString)
        }
        set {
            role = newValue?.rawValue
        }
    }
    
    // Debug: Get filtered list of enabled saleyards
    // Returns all saleyards if enabledSaleyards is empty (default behavior)
    var filteredSaleyards: [String] {
        if enabledSaleyards.isEmpty {
            return ReferenceData.saleyards // All saleyards enabled by default
        }
        return enabledSaleyards
    }
    
    // MARK: - Dashboard Card Helpers
    // Debug: Helper functions to check and set card visibility by ID
    func isCardVisible(_ cardId: String) -> Bool {
        switch cardId {
        case "performanceChart": return showPerformanceChart
        case "quickActions": return showQuickActions
        case "marketSummary": return showMarketSummary
        case "recentActivity": return showRecentActivity
        case "herdComposition": return showHerdComposition
        default: return false
        }
    }
    
    func setCardVisibility(_ cardId: String, isVisible: Bool) {
        switch cardId {
        case "performanceChart": showPerformanceChart = isVisible
        case "quickActions": showQuickActions = isVisible
        case "marketSummary": showMarketSummary = isVisible
        case "recentActivity": showRecentActivity = isVisible
        case "herdComposition": showHerdComposition = isVisible
        default: break
        }
    }
}


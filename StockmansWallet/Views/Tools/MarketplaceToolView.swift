//
//  MarketplaceToolView.swift
//  StockmansWallet
//
//  Marketplace - Buy and sell livestock with other farmers
//  Debug: Mockup UI showing marketplace listings (non-functional)
//

import SwiftUI

// Debug: Marketplace tool - full screen view accessible from Tools menu
struct MarketplaceToolView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFilter: MarketplaceFilter = .all
    
    // Debug: Mock listing data for UI demonstration
    private let mockListings: [MarketplaceListing] = [
        MarketplaceListing(
            id: UUID(),
            title: "Angus Weaner Steers",
            species: "Cattle",
            breed: "Angus",
            category: "Weaner Steer",
            headCount: 45,
            ageMonths: 8,
            avgWeight: 280,
            pricePerHead: 1200,
            location: "Central Queensland",
            sellerName: "Thompson Station",
            listedDate: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            description: "Quality Angus weaners, well-handled, vaccinated. Ready for backgrounding or feedlot entry."
        ),
        MarketplaceListing(
            id: UUID(),
            title: "Merino Ewes - Breeding Stock",
            species: "Sheep",
            breed: "Merino",
            category: "Breeding Ewe",
            headCount: 120,
            ageMonths: 24,
            avgWeight: 65,
            pricePerHead: 180,
            location: "New South Wales",
            sellerName: "Highland Grazing Co",
            listedDate: Date().addingTimeInterval(-86400 * 5), // 5 days ago
            description: "Mature Merino ewes, excellent wool quality. Proven breeders with good lambing history."
        ),
        MarketplaceListing(
            id: UUID(),
            title: "Hereford Yearling Heifers",
            species: "Cattle",
            breed: "Hereford",
            category: "Yearling Heifer",
            headCount: 30,
            ageMonths: 14,
            avgWeight: 320,
            pricePerHead: 1100,
            location: "Victoria",
            sellerName: "Riverbend Farm",
            listedDate: Date().addingTimeInterval(-86400), // 1 day ago
            description: "Hereford yearling heifers, suitable for breeding or finishing. Good frame and condition."
        ),
        MarketplaceListing(
            id: UUID(),
            title: "Dorper Rams",
            species: "Sheep",
            breed: "Dorper",
            category: "Ram",
            headCount: 8,
            ageMonths: 18,
            avgWeight: 85,
            pricePerHead: 450,
            location: "Western Australia",
            sellerName: "Desert Plains",
            listedDate: Date().addingTimeInterval(-86400 * 3), // 3 days ago
            description: "Registered Dorper rams, excellent genetics. Ready for breeding season."
        ),
        MarketplaceListing(
            id: UUID(),
            title: "Charolais Feeder Steers",
            species: "Cattle",
            breed: "Charolais",
            category: "Feeder Steer",
            headCount: 60,
            ageMonths: 12,
            avgWeight: 380,
            pricePerHead: 1350,
            location: "Queensland",
            sellerName: "Sunset Cattle Co",
            listedDate: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            description: "Charolais feeder steers, excellent growth rates. Ideal for feedlot or grass finishing."
        ),
        MarketplaceListing(
            id: UUID(),
            title: "Border Leicester Ewes",
            species: "Sheep",
            breed: "Border Leicester",
            category: "Breeding Ewe",
            headCount: 85,
            ageMonths: 30,
            avgWeight: 75,
            pricePerHead: 165,
            location: "Tasmania",
            sellerName: "Green Valley Farm",
            listedDate: Date().addingTimeInterval(-86400 * 4), // 4 days ago
            description: "Mature Border Leicester ewes, excellent mothers. Good wool and meat production."
        )
    ]
    
    // Debug: Filter listings based on selected filter
    private var filteredListings: [MarketplaceListing] {
        let filtered: [MarketplaceListing]
        switch selectedFilter {
        case .all:
            filtered = mockListings
        case .cattle:
            filtered = mockListings.filter { $0.species == "Cattle" }
        case .sheep:
            filtered = mockListings.filter { $0.species == "Sheep" }
        case .pigs:
            filtered = mockListings.filter { $0.species == "Pigs" }
        }
        
        // Debug: Apply search filter if text is entered
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { listing in
                listing.title.localizedCaseInsensitiveContains(searchText) ||
                listing.breed.localizedCaseInsensitiveContains(searchText) ||
                listing.location.localizedCaseInsensitiveContains(searchText) ||
                listing.sellerName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Debug: Search bar and filters
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Theme.secondaryText)
                        TextField("Search listings...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(Theme.primaryText)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                    }
                    .padding(12)
                    .background(Theme.inputFieldBackground)
                    // Debug: iOS 26 HIG - continuous curve for input field shape.
                    .clipShape(Theme.continuousRoundedRect(12))
                    
                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MarketplaceFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter
                                ) {
                                    HapticManager.tap()
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Theme.background.opacity(0.5))
                
                // Debug: Listings grid
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredListings) { listing in
                            MarketplaceListingCard(listing: listing)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                // Debug: Back button to dismiss
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.tap()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Tools")
                                .font(Theme.body)
                        }
                        .foregroundStyle(Theme.accentColor)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Marketplace")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
                
                // Debug: Add listing button (mockup - non-functional)
                // iOS 26 HIG: Text button in navigation bar trailing position (matches PortfolioView pattern)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("List") {
                        HapticManager.tap()
                        // Debug: Placeholder for future "Create Listing" functionality
                    }
                    .foregroundStyle(Theme.accentColor)
                    .accessibilityLabel("Create listing")
                }
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
        }
    }
}

// MARK: - Marketplace Listing Model
// Debug: Mock data model for marketplace listings
struct MarketplaceListing: Identifiable {
    let id: UUID
    let title: String
    let species: String
    let breed: String
    let category: String
    let headCount: Int
    let ageMonths: Int
    let avgWeight: Double // kg
    let pricePerHead: Double
    let location: String
    let sellerName: String
    let listedDate: Date
    let description: String
}

// MARK: - Marketplace Filter
// Debug: Filter options for marketplace listings
enum MarketplaceFilter: String, CaseIterable {
    case all = "All"
    case cattle = "Cattle"
    case sheep = "Sheep"
    case pigs = "Pigs"
}

// MARK: - Filter Chip Component
// Debug: Reusable filter chip button
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.caption)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? .white : Theme.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.accentColor : Theme.inputFieldBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Marketplace Listing Card
// Debug: Card component for displaying individual listings
struct MarketplaceListingCard: View {
    let listing: MarketplaceListing
    
    // Debug: Format price for display
    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "AUD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: listing.pricePerHead)) ?? "$\(Int(listing.pricePerHead))"
    }
    
    // Debug: Format date for display
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: listing.listedDate, relativeTo: Date())
    }
    
    // Debug: Get species icon
    private var speciesIcon: String {
        switch listing.species {
        case "Cattle": return "🐄"
        case "Sheep": return "🐑"
        case "Pigs": return "🐷"
        default: return "🐄"
        }
    }
    
    var body: some View {
        Button {
            HapticManager.tap()
            // Debug: Placeholder for future listing detail view
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Debug: Header with species icon and title
                HStack(alignment: .top, spacing: 12) {
                    // Species icon
                    Text(speciesIcon)
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(listing.title)
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                            .multilineTextAlignment(.leading)
                        
                        Text("\(listing.breed) • \(listing.category)")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Price badge
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedPrice)
                            .font(Theme.headline)
                            .foregroundStyle(Theme.accentColor)
                        Text("per head")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                
                Divider()
                    .background(Theme.separator)
                
                // Debug: Listing details
                VStack(alignment: .leading, spacing: 8) {
                    // Stats row
                    HStack(spacing: 16) {
                        ListingDetailItem(
                            icon: "number.circle.fill",
                            label: "\(listing.headCount) head"
                        )
                        ListingDetailItem(
                            icon: "calendar",
                            label: "\(listing.ageMonths) months"
                        )
                        ListingDetailItem(
                            icon: "scalemass",
                            label: "\(Int(listing.avgWeight))kg avg"
                        )
                    }
                    
                    // Location and seller
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.secondaryText)
                            Text(listing.location)
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.secondaryText)
                            Text(listing.sellerName)
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    
                    // Description preview
                    Text(listing.description)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Listed date
                    HStack {
                        Spacer()
                        Text("Listed \(formattedDate)")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Listing Detail Item Component
// Debug: Small detail item for listing cards
struct ListingDetailItem: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Theme.secondaryText)
            Text(label)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

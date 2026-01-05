//
//  SubscriptionView.swift
//  StockmansWallet
//
//  Subscription and Pricing Screen
//  Debug: Shows after onboarding summary, smart tier assignment based on role
//

import SwiftUI

// MARK: - Subscription Tier Enum
enum SubscriptionTier: String, Codable, CaseIterable {
    case smallFarmerFree = "Starter"
    case professionalFarmer = "Pro"
    case advisoryFree = "Advisory User"
    
    var price: String {
        switch self {
        case .smallFarmerFree, .advisoryFree:
            return "Free"
        case .professionalFarmer:
            return "$29.99"
        }
    }
    
    var priceDetail: String {
        switch self {
        case .smallFarmerFree, .advisoryFree:
            return "Up to 100 head of livestock."
        case .professionalFarmer:
            return "Billed monthly or $299/year (save 17%)"
        }
    }
    
    var description: String {
        switch self {
        case .smallFarmerFree:
            return "Designed to help you get set up and see value quickly."
        case .professionalFarmer:
            return "Built for producers managing larger or more complex operations."
        case .advisoryFree:
            return "Full access to client management and valuation tools."
        }
    }
    
    var featuresHeader: String {
        switch self {
        case .smallFarmerFree, .advisoryFree:
            return "Includes"
        case .professionalFarmer:
            return "Includes everything in Starter, plus"
        }
    }
    
    var features: [String] {
        switch self {
        case .smallFarmerFree:
            return [
                "Track up to 100 head of livestock",
                "Live herd value and basic performance view",
                "Market price alerts",
                "Manage one property",
                "Standard reports",
                "Community support"
            ]
        case .professionalFarmer:
            return [
                "Unlimited livestock tracking",
                "Advanced portfolio insights and trends",
                "Multiple properties and herds",
                "Real-time market intelligence",
                "Premium reports and exports",
                "Freight calculator",
                "Full valuation engine",
                "Priority support",
                "API access"
            ]
        case .advisoryFree:
            return [
                "Unlimited client management",
                "Client portfolio tracking",
                "Secure client messaging",
                "Property oversight",
                "Valuation reports",
                "Client collaboration tools",
                "Priority support"
            ]
        }
    }
    
    var isRecommended: Bool {
        false // Debug: Removed recommended badge
    }
    
    var isFree: Bool {
        self == .smallFarmerFree || self == .advisoryFree
    }
}

// MARK: - Subscription View
struct SubscriptionView: View {
    @Binding var userPrefs: UserPreferences
    var onComplete: () -> Void
    
    @State private var selectedTier: SubscriptionTier
    
    // Debug: Determine which tiers to show based on user role
    private var availableTiers: [SubscriptionTier] {
        if userPrefs.userRole == .farmerGrazier {
            return [.smallFarmerFree, .professionalFarmer]
        } else {
            // Advisory users only see their free tier
            return [.advisoryFree]
        }
    }
    
    // Debug: Auto-select appropriate tier based on role
    init(userPrefs: Binding<UserPreferences>, onComplete: @escaping () -> Void) {
        self._userPrefs = userPrefs
        self.onComplete = onComplete
        
        // Auto-select tier based on role
        if userPrefs.wrappedValue.userRole == .farmerGrazier {
            self._selectedTier = State(initialValue: .smallFarmerFree)
        } else {
            self._selectedTier = State(initialValue: .advisoryFree)
        }
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                // Debug: Increased spacing below header for better card positioning
                headerView
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                
                // Debug: Use horizontal paging for multiple tiers (iOS HIG pattern), simple card for single tier
                if availableTiers.count > 1 {
                    // Multiple tiers - horizontal paging (like App Store, iCloud+)
                    // Debug: Responsive height that fills available space
                    TabView(selection: $selectedTier) {
                        ForEach(availableTiers, id: \.self) { tier in
                            SubscriptionTierCard(
                                tier: tier,
                                isSelected: selectedTier == tier,
                                onSelect: {
                                    HapticManager.tap()
                                    selectedTier = tier
                                },
                                isPaginated: true
                            )
                            .padding(.horizontal, 20)
                            .tag(tier)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxHeight: .infinity) // Debug: Responsive height
                    .onChange(of: selectedTier) { _, newValue in
                        HapticManager.tap()
                    }
                    
                    // Debug: Page indicator dots below cards
                    HStack(spacing: 8) {
                        ForEach(availableTiers, id: \.self) { tier in
                            Circle()
                                .fill(selectedTier == tier ? Theme.accent : Theme.secondaryText.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Debug: Spacer to push footer down to match other onboarding pages
                    Spacer()
                } else {
                    // Single tier - simple scrollable card with responsive height
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(availableTiers, id: \.self) { tier in
                                SubscriptionTierCard(
                                    tier: tier,
                                    isSelected: true,
                                    onSelect: {},
                                    isPaginated: false
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .frame(maxHeight: .infinity) // Debug: Responsive height
                }
                
                // Footer with action button
                footerView
            }
        }
    }
    
    // MARK: - Header View
    // Debug: Simplified header with title only for more card space
    private var headerView: some View {
        VStack(spacing: 12) {
            Text(userPrefs.userRole == .farmerGrazier ? "Choose Your Plan" : "You're All Set!")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Footer View
    // Debug: Footer with consistent spacing to match other onboarding pages
    private var footerView: some View {
        VStack(spacing: 8) {
            // Primary action button
            Button(action: {
                HapticManager.success()
                // Save selected tier
                userPrefs.subscriptionTier = selectedTier.rawValue
                onComplete()
            }) {
                Text(selectedTier.isFree ? "Continue with Starter" : "Start Free Trial")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(Theme.PrimaryButtonStyle())
            .padding(.horizontal, 20)
            
            // Debug: Reserve space for trial info to prevent layout jump
            Group {
                if !selectedTier.isFree {
                    Text("7-day free trial • Cancel anytime")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    // Reserve same space with invisible text
                    Text(" ")
                        .font(Theme.caption)
                }
            }
            .frame(height: 16)
            
            // Reassurance line
            Text("No lock-in. Change or cancel anytime.")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText.opacity(0.8))
                .padding(.top, 4)
            
            // "I'll decide later" option for farmers
            if userPrefs.userRole == .farmerGrazier && availableTiers.count > 1 {
                Button(action: {
                    HapticManager.tap()
                    // Default to free tier
                    userPrefs.subscriptionTier = SubscriptionTier.smallFarmerFree.rawValue
                    onComplete()
                }) {
                    Text("I'll Decide Later")
                        .font(Theme.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .underline()
                }
                .padding(.top, 4)
            }
        }
        // Debug: Bottom padding to match other onboarding pages
        .padding(.bottom, 20)
    }
}

// MARK: - Subscription Tier Card
struct SubscriptionTierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let onSelect: () -> Void
    var isPaginated: Bool = false // Debug: Different layout for paginated vs single view
    
    var body: some View {
        Button(action: onSelect) {
            // Debug: ZStack for badge overlay to prevent layout shifts
            ZStack(alignment: .top) {
                // Main card content with consistent spacing
                VStack(alignment: .leading, spacing: 12) {
                    // Tier name - centered for paginated
                    Text(tier.rawValue)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: isPaginated ? .center : .leading)
                    
                    // Price - centered for paginated
                    VStack(spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(tier.price)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(tier.isFree ? Theme.positiveChange : Theme.accent)
                            
                            if !tier.isFree {
                                Text("/ month")
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                        
                        // Price detail
                        Text(tier.priceDetail)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: isPaginated ? .center : .leading)
                    .padding(.bottom, 8)
                    
                    // Description
                    Text(tier.description)
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                        .multilineTextAlignment(isPaginated ? .center : .leading)
                        .frame(maxWidth: .infinity, alignment: isPaginated ? .center : .leading)
                        .padding(.bottom, 8)
                    
                    // Divider
                    Rectangle()
                        .fill(Theme.separator.opacity(0.3))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                    
                    // Features header
                    Text(tier.featuresHeader)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.bottom, 4)
                    
                    // Features list - scrollable for long lists
                    // Debug: Responsive height that fills remaining card space
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(tier.features, id: \.self) { feature in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.body)
                                        .foregroundStyle(tier.isFree ? Theme.positiveChange : Theme.accent)
                                        .frame(width: 18)
                                    
                                    Text(feature)
                                        .font(Theme.subheadline)
                                        .foregroundStyle(Theme.primaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .padding(.bottom, 8) // Debug: Compact bottom padding
                    }
                    .frame(maxHeight: .infinity) // Debug: Responsive height fills available space
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16) // Debug: Balanced bottom padding
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius * 1.5, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius * 1.5, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(0.05),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isPaginated ? Theme.accent.opacity(0.15) : (isSelected ? Theme.accent.opacity(0.2) : .clear),
                radius: isPaginated ? 20 : (isSelected ? 12 : 0),
                x: 0,
                y: isPaginated ? 8 : (isSelected ? 4 : 0)
            )
        }
        .buttonStyle(.plain)
    }
}


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
    case smallFarmerFree = "Small Farmer"
    case professionalFarmer = "Professional Farmer"
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
            return "Forever"
        case .professionalFarmer:
            return "Billed monthly or $299/year (save 17%)"
        }
    }
    
    var features: [String] {
        switch self {
        case .smallFarmerFree:
            return [
                "Up to 100 head of livestock",
                "Basic portfolio tracking",
                "Market price alerts",
                "Property management (1 property)",
                "Standard reports",
                "Community support"
            ]
        case .professionalFarmer:
            return [
                "Unlimited livestock tracking",
                "Advanced portfolio analytics",
                "Real-time market insights",
                "Multiple property management",
                "Premium reports & exports",
                "Freight calculator",
                "Valuation engine",
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
        self == .professionalFarmer
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
                // Debug: Reduced top/bottom padding for more compact layout
                headerView
                    .padding(.top, 32)
                    .padding(.bottom, 20)
                
                // Debug: Use horizontal paging for multiple tiers (iOS HIG pattern), simple card for single tier
                if availableTiers.count > 1 {
                    // Multiple tiers - horizontal paging (like App Store, iCloud+)
                    // Debug: Fixed height container for consistent card alignment
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
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .frame(height: 580) // Debug: Fixed height prevents card misalignment
                    .onChange(of: selectedTier) { _, newValue in
                        HapticManager.tap()
                    }
                } else {
                    // Single tier - simple scrollable card
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
                }
                
                // Footer with action button
                footerView
            }
        }
    }
    
    // MARK: - Header View
    // Debug: Consistent styling with other onboarding pages (28pt bold title, Theme.body subtitle)
    private var headerView: some View {
        VStack(spacing: 12) {
            Text(userPrefs.userRole == .farmerGrazier ? "Choose Your Plan" : "You're All Set!")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.center)
            
            Text(userPrefs.userRole == .farmerGrazier ? 
                 "Select the plan that fits your operation" : 
                 "Your advisory account includes full access")
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Footer View
    // Debug: Compact footer with minimal spacing for better vertical balance
    private var footerView: some View {
        VStack(spacing: 8) {
            // Primary action button
            Button(action: {
                HapticManager.success()
                // Save selected tier
                userPrefs.subscriptionTier = selectedTier.rawValue
                onComplete()
            }) {
                Text(selectedTier.isFree ? "Continue with Free" : "Start Free Trial")
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
            .frame(height: 16) // Debug: Reduced fixed height
            
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
        // Debug: Minimal bottom padding to reduce empty space
        .padding(.bottom, 12)
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
                    // Debug: Fixed height spacer for badge area to ensure alignment
                    Spacer()
                        .frame(height: tier.isRecommended ? 34 : 0)
                    
                    // Tier name - centered for paginated
                    Text(tier.rawValue)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: isPaginated ? .center : .leading)
                        .padding(.top, tier.isRecommended ? 0 : 34) // Debug: Balance spacing when no badge
                    
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
                    
                    // Divider
                    Rectangle()
                        .fill(Theme.separator.opacity(0.3))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                    
                    // Features list - scrollable for long lists
                    // Debug: Optimized height for better space usage
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
                    .frame(maxHeight: isPaginated ? 320 : .infinity) // Debug: Reduced height for better fit
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16) // Debug: Balanced bottom padding
                
                // Debug: Overlay badge on top - doesn't affect layout
                if tier.isRecommended {
                    HStack {
                        Spacer()
                        Text("RECOMMENDED FOR YOU")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Theme.accent)
                            )
                        Spacer()
                    }
                    .padding(.top, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius * 1.5, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius * 1.5, style: .continuous)
                    .strokeBorder(
                        isPaginated ? Theme.accent.opacity(0.5) : (isSelected ? Theme.accent : Theme.separator.opacity(0.3)),
                        lineWidth: isPaginated ? 2 : (isSelected ? 2 : 1)
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


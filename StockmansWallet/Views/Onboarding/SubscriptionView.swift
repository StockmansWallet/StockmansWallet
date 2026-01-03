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
            return "$29.99/month"
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
                headerView
                    .padding(.top, 40)
                    .padding(.bottom, 24)
                
                // Tiers
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(availableTiers, id: \.self) { tier in
                            SubscriptionTierCard(
                                tier: tier,
                                isSelected: selectedTier == tier,
                                onSelect: {
                                    HapticManager.tap()
                                    selectedTier = tier
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                // Footer with action button
                footerView
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: userPrefs.userRole == .farmerGrazier ? "star.circle.fill" : "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)
            
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
    private var footerView: some View {
        VStack(spacing: 12) {
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
            
            // Free trial info for paid tier
            if !selectedTier.isFree {
                Text("7-day free trial • Cancel anytime")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.bottom, 8)
            }
            
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
                .padding(.bottom, 16)
            }
        }
        .background(Theme.backgroundGradient)
        .padding(.bottom, 20)
    }
}

// MARK: - Subscription Tier Card
struct SubscriptionTierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with price
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Tier name
                        HStack(spacing: 8) {
                            Text(tier.rawValue)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Theme.primaryText)
                            
                            // Recommended badge
                            if tier.isRecommended {
                                Text("RECOMMENDED")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Theme.accent)
                                    )
                            }
                        }
                        
                        // Price
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(tier.price)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(tier.isFree ? .green : Theme.accent)
                            
                            if !tier.isFree {
                                Text("/ month")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                        
                        // Price detail
                        Text(tier.priceDetail)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? Theme.accent : Theme.separator, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                
                // Divider
                Rectangle()
                    .fill(Theme.separator.opacity(0.3))
                    .frame(height: 1)
                
                // Features list
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(tier.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body)
                                .foregroundStyle(tier.isFree ? .green : Theme.accent)
                                .frame(width: 20)
                            
                            Text(feature)
                                .font(Theme.subheadline)
                                .foregroundStyle(Theme.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius * 1.5, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius * 1.5, style: .continuous)
                    .strokeBorder(
                        isSelected ? Theme.accent : Theme.separator.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? Theme.accent.opacity(0.2) : .clear,
                radius: isSelected ? 12 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .buttonStyle(.plain)
    }
}


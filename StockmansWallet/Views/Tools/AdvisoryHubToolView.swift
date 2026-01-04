//
//  AdvisoryHubToolView.swift
//  StockmansWallet
//
//  Advisory Hub - Connect with trusted rural professionals
//  Debug: Full featured information view explaining the Advisory Hub concept
//

import SwiftUI

// Debug: Advisory Hub tool - full screen view accessible from Tools menu
struct AdvisoryHubToolView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    // Debug: Header section with icon and intro
                    VStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.2.badge.gearshape.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.purple)
                        }
                        .padding(.top, 20)
                        
                        // Title and tagline
                        VStack(spacing: 8) {
                            Text("Advisory Hub")
                                .font(Theme.title)
                                .foregroundStyle(Theme.primaryText)
                            
                            Text("A central place for your farm to connect with trusted professionals.")
                                .font(Theme.body)
                                .foregroundStyle(Theme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Main description
                        Text("This section lets you find, compare, and contact rural advisors who support key business decisions.\n\nUse it when you need advice on finance, livestock sales, tax, succession, or long-term planning.")
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                            .multilineTextAlignment(.leading)
                            .padding(Theme.cardPadding)
                            .stitchedCard()
                    }
                    .padding(.horizontal)
                    
                    // Debug: What you can do section
                    AdvisorySection(
                        title: "What you can do here",
                        icon: "hand.tap.fill",
                        iconColor: .blue,
                        items: [
                            "Browse verified advisors by category",
                            "View advisor profiles with experience, regions, and services",
                            "See which advisors understand livestock and rural businesses",
                            "Contact advisors directly through in-app chat",
                            "Keep all advisory conversations linked to your farm",
                            "Return to chats anytime for follow-ups or planning reviews"
                        ]
                    )
                    .padding(.horizontal)
                    
                    // Debug: Advisor categories section
                    AdvisorySection(
                        title: "Advisor categories",
                        icon: "list.bullet.rectangle.fill",
                        iconColor: .orange,
                        items: [
                            "Bankers and agribusiness lenders",
                            "Livestock and stock agents",
                            "Accountants and tax specialists",
                            "Succession and estate planners",
                            "Business and strategy advisors"
                        ]
                    )
                    .padding(.horizontal)
                    
                    // Debug: How it works section
                    AdvisorySection(
                        title: "How it works",
                        icon: "gear.badge.checkmark",
                        iconColor: .green,
                        items: [
                            "Advisors appear in a searchable list",
                            "Filters help you narrow by role, region, and expertise",
                            "Each advisor has a profile page",
                            "Tap to start a private chat",
                            "Conversations stay inside the app"
                        ]
                    )
                    .padding(.horizontal)
                    
                    // Debug: Why it matters section
                    AdvisorySection(
                        title: "Why it matters",
                        icon: "star.fill",
                        iconColor: Theme.accent,
                        items: [
                            "Faster access to the right advice",
                            "Fewer phone calls and emails",
                            "Better decisions backed by live herd data",
                            "One place for all professional relationships"
                        ]
                    )
                    .padding(.horizontal)
                    
                    // Debug: Future upgrades section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.purple)
                            Text("Optional future upgrades")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                        }
                        
                        Divider()
                            .background(Theme.separator)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FutureFeatureRow(text: "Advisor recommendations based on your herd and activity")
                            FutureFeatureRow(text: "Shared access to reports and valuations")
                            FutureFeatureRow(text: "Paid featured listings for advisors")
                            FutureFeatureRow(text: "Meeting notes and document sharing")
                        }
                    }
                    .padding(Theme.cardPadding)
                    .stitchedCard()
                    .padding(.horizontal)
                    
                    // Debug: Coming soon badge
                    Text("Coming Soon")
                        .font(Theme.headline)
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 100)
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
                        .foregroundStyle(Theme.accent)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Advisory Hub")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
        }
    }
}

// MARK: - Advisory Section Component
// Debug: Reusable section component for displaying advisor hub information
struct AdvisorySection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
            }
            
            Divider()
                .background(Theme.separator)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(Theme.body)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 12, alignment: .leading)
                        Text(item)
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

// MARK: - Future Feature Row Component
// Debug: Component for displaying future features with different styling
struct FutureFeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "arrow.right.circle")
                .font(.system(size: 12))
                .foregroundStyle(.purple.opacity(0.6))
                .frame(width: 12, alignment: .leading)
                .padding(.top, 4)
            Text(text)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}



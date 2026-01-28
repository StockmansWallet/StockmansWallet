//
//  ToolsView.swift
//  StockmansWallet
//
//  Tools Menu - Access to Reports, Simulator, Freight Calculator, and Chat
//  Debug: Uses @Observable pattern and navigation stack for tool selection
//

import SwiftUI

// Debug: Main tools menu view with card-based navigation
struct ToolsView: View {
    @State private var showingReports = false
    @State private var showingSimulator = false
    @State private var showingFreightCalculator = false
    @State private var showingChat = false
    @State private var showingAdvisoryHub = false
    @State private var showingMarketplace = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    // Debug: Tools menu cards
                    VStack(spacing: 16) {
                        // Debug: Placeholder notice for users
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.accent)
                            Text("These features are placeholders only and not fully functional")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        
                        // Reports Tool
                        ToolMenuButton(
                            title: "Reports",
                            description: "Generate asset registers and sales summaries",
                            icon: "doc.text.fill",
                            iconColor: Theme.accent
                        ) {
                            HapticManager.tap()
                            showingReports = true
                        }
                        
                        // Simulator Tool
                        ToolMenuButton(
                            title: "Simulator",
                            description: "Run market scenarios and projections",
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: .blue
                        ) {
                            HapticManager.tap()
                            showingSimulator = true
                        }
                        
                        // Freight Calculator Tool
                        ToolMenuButton(
                            title: "Freight Calculator",
                            description: "Calculate transport costs and logistics",
                            icon: "truck.box.fill",
                            iconColor: .orange
                        ) {
                            HapticManager.tap()
                            showingFreightCalculator = true
                        }
                        
                        // Chat Tool
                        ToolMenuButton(
                            title: "Chat",
                            description: "Get help and support",
                            icon: "bubble.left.and.bubble.right.fill",
                            iconColor: Theme.positiveChange
                        ) {
                            HapticManager.tap()
                            showingChat = true
                        }
                        
                        // Advisory Hub Tool
                        ToolMenuButton(
                            title: "Advisory Hub",
                            description: "Connect with trusted rural professionals",
                            icon: "person.2.badge.gearshape.fill",
                            iconColor: .purple
                        ) {
                            HapticManager.tap()
                            showingAdvisoryHub = true
                        }
                        
                        // Marketplace Tool
                        ToolMenuButton(
                            title: "Marketplace",
                            description: "Buy and sell livestock with other farmers",
                            icon: "cart.fill",
                            iconColor: .green
                        ) {
                            HapticManager.tap()
                            showingMarketplace = true
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 100)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Tools")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            // Debug: Full screen sheets for each tool
            .fullScreenCover(isPresented: $showingReports) {
                ReportsToolView()
            }
            .fullScreenCover(isPresented: $showingSimulator) {
                SimulatorToolView()
            }
            .fullScreenCover(isPresented: $showingFreightCalculator) {
                FreightCalculatorToolView()
            }
            .fullScreenCover(isPresented: $showingChat) {
                ChatToolView()
            }
            .fullScreenCover(isPresented: $showingAdvisoryHub) {
                AdvisoryHubToolView()
            }
            .fullScreenCover(isPresented: $showingMarketplace) {
                MarketplaceToolView()
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
        }
    }
}

// MARK: - Tool Menu Button Component
// Debug: Reusable button component for tool menu items
struct ToolMenuButton: View {
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Debug: Icon container with background
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                .accessibilityHidden(true)
                
                // Debug: Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text(description)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Debug: Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(Theme.cardPadding)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(description)")
        .accessibilityHint("Double tap to open")
    }
}


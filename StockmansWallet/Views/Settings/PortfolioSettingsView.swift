//
//  PortfolioSettingsView.swift
//  StockmansWallet
//
//  Portfolio Overview Customization Settings
//  Debug: Includes portfolio card visibility and ordering options
//

import SwiftUI
import SwiftData

// Debug: Portfolio card info for rearrangeable list
struct PortfolioCard: Identifiable {
    let id: String
    let name: String
    let icon: String
    let accessibilityLabel: String
}

struct PortfolioSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: Get user preferences with fallback
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    // Debug: All available portfolio cards with metadata
    private let allCards = [
        PortfolioCard(id: "marketSummary", name: "Herd Performance", icon: "chart.bar.fill", accessibilityLabel: "Show herd performance on portfolio overview"),
        PortfolioCard(id: "recentActivity", name: "Growth & Mortality", icon: "chart.line.uptrend.xyaxis", accessibilityLabel: "Show growth and mortality on portfolio overview"),
        PortfolioCard(id: "herdComposition", name: "Herd Composition", icon: "chart.pie.fill", accessibilityLabel: "Show herd composition on portfolio overview")
    ]
    
    // Debug: Get cards in user's custom order
    private var orderedCards: [PortfolioCard] {
        let order = userPrefs.portfolioCardOrder
        return order.compactMap { cardId in
            allCards.first { $0.id == cardId }
        }
    }
    
    var body: some View {
        List {
            // Debug: Portfolio Card Visibility Section with rearrangeable list
            // Allows users to show/hide and reorder portfolio cards
            Section {
                ForEach(orderedCards) { card in
                    cardToggleRow(for: card)
                }
                .onMove { from, to in
                    moveCard(from: from, to: to)
                }
                
                // Debug: Reset to default order button
                Button(action: resetToDefaultOrder) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(Theme.accentColor)
                            .frame(width: 24)
                        Text("Reset to Default Order")
                            .font(Theme.body)
                            .foregroundStyle(Theme.accentColor)
                    }
                }
                .accessibilityLabel("Reset card order to default")
            } header: {
                Text("Portfolio Cards")
            } footer: {
                Text("Choose which cards to display on your portfolio overview and arrange them by long-pressing and dragging. Changes take effect immediately.")
                    .font(Theme.caption)
            }
            .listRowBackground(Theme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Portfolio Overview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    // MARK: - Helper Views
    
    /// Debug: Create a toggle row for a portfolio card
    @ViewBuilder
    private func cardToggleRow(for card: PortfolioCard) -> some View {
        Toggle(isOn: Binding(
            get: { getCardVisibility(for: card.id) },
            set: { newValue in setCardVisibility(for: card.id, to: newValue) }
        )) {
            HStack(spacing: 12) {
                Image(systemName: card.icon)
                    .foregroundStyle(Theme.accentColor)
                    .frame(width: 24)
                Text(card.name)
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
            }
        }
        .tint(Theme.accentColor)
        .accessibilityLabel(card.accessibilityLabel)
    }
    
    // MARK: - Helper Functions
    
    /// Debug: Get visibility state for a specific card
    private func getCardVisibility(for cardId: String) -> Bool {
        userPrefs.isPortfolioCardVisible(cardId)
    }
    
    /// Debug: Set visibility state for a specific card
    private func setCardVisibility(for cardId: String, to value: Bool) {
        guard let prefs = preferences.first else { return }
        
        prefs.setPortfolioCardVisibility(cardId, isVisible: value)
        try? modelContext.save()
    }
    
    /// Debug: Move card in the custom order
    private func moveCard(from source: IndexSet, to destination: Int) {
        guard let prefs = preferences.first else { return }
        
        var newOrder = prefs.portfolioCardOrder
        newOrder.move(fromOffsets: source, toOffset: destination)
        prefs.portfolioCardOrder = newOrder
        try? modelContext.save()
        
        HapticManager.selectionChanged()
    }
    
    /// Debug: Reset card order to default
    private func resetToDefaultOrder() {
        guard let prefs = preferences.first else { return }
        
        prefs.portfolioCardOrder = ["marketSummary", "recentActivity", "herdComposition"]
        try? modelContext.save()
        
        HapticManager.success()
    }
}

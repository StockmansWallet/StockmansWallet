//
//  AppearanceSettingsView.swift
//  StockmansWallet
//
//  Dashboard Customization Settings
//  Debug: Includes background image selection and dashboard card visibility options
//

import SwiftUI
import SwiftData

// Debug: Dashboard card info for rearrangeable list
struct DashboardCard: Identifiable {
    let id: String
    let name: String
    let icon: String
    let accessibilityLabel: String
}

struct AppearanceSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: Get user preferences with fallback
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    // Debug: All available dashboard cards with metadata
    private let allCards = [
        DashboardCard(id: "performanceChart", name: "Performance Chart", icon: "chart.line.uptrend.xyaxis", accessibilityLabel: "Show performance chart on dashboard"),
        DashboardCard(id: "quickActions", name: "Saleyards List", icon: "list.bullet", accessibilityLabel: "Show saleyards list on dashboard"),
        DashboardCard(id: "marketSummary", name: "Herd Performance", icon: "chart.bar.fill", accessibilityLabel: "Show herd performance on dashboard"),
        DashboardCard(id: "recentActivity", name: "Growth & Mortality", icon: "chart.line.uptrend.xyaxis", accessibilityLabel: "Show growth and mortality on dashboard"),
        DashboardCard(id: "herdComposition", name: "Herd Composition", icon: "chart.pie.fill", accessibilityLabel: "Show herd composition on dashboard")
    ]
    
    // Debug: Get cards in user's custom order
    private var orderedCards: [DashboardCard] {
        let order = userPrefs.dashboardCardOrder
        return order.compactMap { cardId in
            allCards.first { $0.id == cardId }
        }
    }
    
    var body: some View {
        List {
            // Debug: Background image selection section
            Section {
                NavigationLink(destination: BackgroundImageSelectorView()) {
                    SettingsListRow(
                        icon: "photo.fill",
                        title: "Background Image",
                        subtitle: nil
                    )
                }
            }
            .listRowBackground(Theme.cardBackground)
            
            // Debug: Dashboard Card Visibility Section with rearrangeable list
            // Allows users to show/hide and reorder dashboard cards
            Section {
                ForEach(orderedCards) { card in
                    cardToggleRow(for: card)
                }
                .onMove { from, to in
                    moveCard(from: from, to: to)
                }
                
                // Debug: Reset to default order button (keep accent color for action)
                Button(action: resetToDefaultOrder) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)
                        Text("Reset to Default Order")
                            .font(Theme.body)
                            .foregroundStyle(Theme.accent)
                    }
                }
                .accessibilityLabel("Reset card order to default")
            } header: {
                Text("Dashboard Cards")
            } footer: {
                Text("Choose which cards to display on your dashboard and arrange them by long-pressing and dragging. Changes take effect immediately.")
                    .font(Theme.caption)
            }
            .listRowBackground(Theme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    // MARK: - Helper Views
    
    /// Debug: Create a toggle row for a dashboard card
    @ViewBuilder
    private func cardToggleRow(for card: DashboardCard) -> some View {
        Toggle(isOn: Binding(
            get: { getCardVisibility(for: card.id) },
            set: { newValue in setCardVisibility(for: card.id, to: newValue) }
        )) {
            HStack(spacing: 12) {
                Image(systemName: card.icon)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 24)
                Text(card.name)
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText) // Debug: Use PrimaryText instead of white
            }
        }
        .tint(Theme.accent)
        .accessibilityLabel(card.accessibilityLabel)
    }
    
    // MARK: - Helper Functions
    
    /// Debug: Get visibility state for a specific card
    private func getCardVisibility(for cardId: String) -> Bool {
        switch cardId {
        case "performanceChart": return userPrefs.showPerformanceChart
        case "quickActions": return userPrefs.showQuickActions
        case "marketSummary": return userPrefs.showMarketSummary
        case "recentActivity": return userPrefs.showRecentActivity
        case "herdComposition": return userPrefs.showHerdComposition
        default: return true
        }
    }
    
    /// Debug: Set visibility state for a specific card
    private func setCardVisibility(for cardId: String, to value: Bool) {
        guard let prefs = preferences.first else { return }
        
        switch cardId {
        case "performanceChart": prefs.showPerformanceChart = value
        case "quickActions": prefs.showQuickActions = value
        case "marketSummary": prefs.showMarketSummary = value
        case "recentActivity": prefs.showRecentActivity = value
        case "herdComposition": prefs.showHerdComposition = value
        default: break
        }
        
        try? modelContext.save()
    }
    
    /// Debug: Move card in the custom order
    private func moveCard(from source: IndexSet, to destination: Int) {
        guard let prefs = preferences.first else { return }
        
        var newOrder = prefs.dashboardCardOrder
        newOrder.move(fromOffsets: source, toOffset: destination)
        prefs.dashboardCardOrder = newOrder
        try? modelContext.save()
        
        HapticManager.selectionChanged()
    }
    
    /// Debug: Reset card order to default
    private func resetToDefaultOrder() {
        guard let prefs = preferences.first else { return }
        
        prefs.dashboardCardOrder = ["performanceChart", "quickActions", "marketSummary", "recentActivity", "herdComposition"]
        try? modelContext.save()
        
        HapticManager.success()
    }
}

// ContentSizeCategory already conforms to CaseIterable in SwiftUI, no extension needed







//
//  AppearanceSettingsView.swift
//  StockmansWallet
//
//  Dashboard Customization Settings
//  Debug: Includes background image selection and dashboard card visibility options
//

import SwiftUI

struct AppearanceSettingsView: View {
    // Debug: State for dashboard card visibility toggles
    // TODO: Store these in UserPreferences and actually hide/show cards on dashboard
    @State private var showPerformanceChart = true
    @State private var showQuickActions = true
    @State private var showMarketSummary = true
    @State private var showRecentActivity = true
    
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
            
            // Debug: Dashboard Card Visibility Section
            // Allows users to show/hide specific dashboard cards
            Section {
                Toggle(isOn: $showPerformanceChart) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)
                        Text("Performance Chart")
                            .font(Theme.body)
                    }
                }
                .tint(Theme.accent)
                .accessibilityLabel("Show performance chart on dashboard")
                
                Toggle(isOn: $showQuickActions) {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)
                        Text("Quick Actions")
                            .font(Theme.body)
                    }
                }
                .tint(Theme.accent)
                .accessibilityLabel("Show quick actions on dashboard")
                
                Toggle(isOn: $showMarketSummary) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)
                        Text("Market Summary")
                            .font(Theme.body)
                    }
                }
                .tint(Theme.accent)
                .accessibilityLabel("Show market summary on dashboard")
                
                Toggle(isOn: $showRecentActivity) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)
                        Text("Recent Activity")
                            .font(Theme.body)
                    }
                }
                .tint(Theme.accent)
                .accessibilityLabel("Show recent activity on dashboard")
            } header: {
                Text("Dashboard Cards")
            } footer: {
                Text("Choose which cards to display on your dashboard. Changes take effect immediately.")
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
}

// ContentSizeCategory already conforms to CaseIterable in SwiftUI, no extension needed







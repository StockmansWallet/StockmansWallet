//
//  AppearanceSettingsView.swift
//  StockmansWallet
//
//  Dashboard Customization Settings
//  Debug: Includes background image selection and dashboard card visibility options
//

import SwiftUI

struct AppearanceSettingsView: View {
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
            
            // TODO: Dashboard Card Visibility Section
            // Debug: Future feature - allow users to show/hide specific dashboard cards
            // Section("Dashboard Cards") {
            //     Toggle("Portfolio Value", isOn: $showPortfolioCard)
            //     Toggle("Performance Chart", isOn: $showChartCard)
            //     Toggle("Quick Actions", isOn: $showQuickActionsCard)
            //     Toggle("Recent Activity", isOn: $showRecentActivityCard)
            // }
            // .listRowBackground(Theme.cardBackground)
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







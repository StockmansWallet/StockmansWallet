//
//  SettingsView.swift
//  StockmansWallet
//
//  User Profile and Settings
//

import SwiftUI
import SwiftData

extension Notification.Name {
    static let dataCleared = Notification.Name("DataCleared")
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    // Debug: Determine if user is a farmer (has properties)
    private var isFarmer: Bool {
        userPrefs.userRole == .farmerGrazier
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Section 1: User
                Section {
                    NavigationLink(destination: ProfileView()) {
                        SettingsListRow(
                            icon: "person.circle.fill",
                            title: "Your Profile",
                            subtitle: nil
                        )
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    // Debug: Only show Properties for farmers (not advisory users)
                    if isFarmer {
                        NavigationLink(destination: PropertiesView()) {
                            SettingsListRow(
                                icon: "property_icon",
                                title: "Your Properties",
                                subtitle: nil,
                                isCustomIcon: true
                            )
                        }
                        .listRowBackground(Theme.cardBackground)
                    }
                    
                    // Debug: Sale locations settings (saleyards, private, other)
                    NavigationLink(destination: SaleLocationsSettingsView()) {
                        SettingsListRow(icon: "dollarsign.bank.building", title: "Sale Locations", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listSectionSeparator(.hidden)
                
                // MARK: - Section 2: Dashboard, Portfolio & Notifications
                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsListRow(icon: "square.grid.2x2.fill", title: "Dashboard", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    NavigationLink(destination: PortfolioSettingsView()) {
                        SettingsListRow(icon: "chart.pie.fill", title: "Portfolio Overview", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    NavigationLink(destination: NotificationsSettingsView()) {
                        SettingsListRow(icon: "bell.fill", title: "Notifications", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listSectionSeparator(.hidden)
                
                // MARK: - Section 3: Security & Data
                Section {
                    NavigationLink(destination: SecuritySettingsView()) {
                        SettingsListRow(icon: "lock.shield.fill", title: "Security", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    NavigationLink(destination: DataSyncSettingsView()) {
                        SettingsListRow(icon: "arrow.clockwise", title: "Data & Sync", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listSectionSeparator(.hidden)
                
                // MARK: - Section 4: Connected Apps
                Section {
                    NavigationLink(destination: ConnectedAppsView()) {
                        SettingsListRow(icon: "link.circle.fill", title: "Connected Apps", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listSectionSeparator(.hidden)
                
                // MARK: - Section 5: Information & Support
                Section {
                    NavigationLink(destination: SupportView()) {
                        SettingsListRow(icon: "questionmark.circle.fill", title: "Help & Support", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    NavigationLink(destination: AboutView()) {
                        SettingsListRow(icon: "info.circle.fill", title: "About Stockman's Wallet", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listSectionSeparator(.hidden)
                
                // MARK: - Section 6: Dev Tools
                // Debug: Temporary section for development/testing
                // TODO: Remove this section before production release
                Section {
                    Button(action: {
                        HapticManager.tap()
                        goToLandingPage()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .foregroundStyle(Theme.accent)
                                .frame(width: 24)
                            
                            Text("Go to Landing Page")
                                .font(Theme.body)
                                .foregroundStyle(Theme.accent)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listSectionSeparator(.hidden)
                
                Section {
                    AppVersionFooter()
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient)
            .listSectionSeparator(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .task {
                ensurePreferencesExist()
            }
        }
    }
    
    @MainActor
    private func ensurePreferencesExist() {
        if preferences.first == nil {
            let prefs = UserPreferences()
            modelContext.insert(prefs)
            try? modelContext.save()
        }
    }
    
    // Debug: Reset to landing page for testing during development
    // TODO: Remove this function before production release
    @MainActor
    private func goToLandingPage() {
        if let prefs = preferences.first {
            prefs.hasCompletedOnboarding = false
            try? modelContext.save()
        }
    }
    
}

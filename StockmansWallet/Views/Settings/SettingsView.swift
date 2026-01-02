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
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: DevelopmentSettingsView()) {
                        SettingsListRow(icon: "wrench.and.screwdriver.fill", title: "Development", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listSectionSeparator(.hidden)
                
                Section {
                    NavigationLink(destination: LivestockPreferencesDetailView(prefs: userPrefs)) {
                        SettingsListRow(
                            icon: "pawprint.fill",
                            title: "Livestock Preferences",
                            subtitle: "\(userPrefs.defaultState) • \(Int(userPrefs.defaultMortalityRate * 100))% mortality"
                        )
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listSectionSeparator(.hidden)
                
                Section {
                    NavigationLink(destination: NotificationsSettingsView()) {
                        SettingsListRow(icon: "bell.fill", title: "Notifications", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    NavigationLink(destination: DataSyncSettingsView()) {
                        SettingsListRow(icon: "arrow.clockwise", title: "Data & Sync", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    NavigationLink(destination: DisplaySettingsView()) {
                        SettingsListRow(icon: "textformat", title: "Display", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listSectionSeparator(.hidden)
                
                Section {
                    NavigationLink(destination: AboutView()) {
                        SettingsListRow(icon: "info.circle.fill", title: "About Stockman's Wallet", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    NavigationLink(destination: SupportView()) {
                        SettingsListRow(icon: "questionmark.circle.fill", title: "Help & Support", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listSectionSeparator(.hidden)
                
                Section {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingsListRow(icon: "hand.raised.fill", title: "Privacy Policy", subtitle: nil)
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        SettingsListRow(icon: "doc.text.fill", title: "Terms of Service", subtitle: nil)
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
    
}

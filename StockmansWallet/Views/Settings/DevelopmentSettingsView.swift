//
//  DevelopmentSettingsView.swift
//  StockmansWallet
//
//  Development and Testing Options
//

import SwiftUI
import SwiftData

struct DevelopmentSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var body: some View {
        List {
            Section {
                // Debug: Keep reset onboarding for testing purposes
                Button(action: {
                    HapticManager.tap()
                    resetOnboarding()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(.red)
                            .frame(width: 24)
                        
                        Text("Reset Onboarding (Testing)")
                            .font(Theme.body)
                            .foregroundStyle(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.cardBackground)
                
                // Debug: Mock data generation moved to empty dashboard page for easier access
                // See EmptyDashboardView for Add/Remove mock data buttons
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Development")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    // Debug: Reset onboarding for testing purposes
    @MainActor
    private func resetOnboarding() {
        if let prefs = preferences.first {
            prefs.hasCompletedOnboarding = false
            try? modelContext.save()
        }
    }
}


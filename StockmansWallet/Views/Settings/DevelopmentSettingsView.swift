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
                
                Button(action: {
                    HapticManager.tap()
                    generateMockData()
                }) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)
                        
                        Text("Generate Mock Data (1 Year)")
                            .font(Theme.body)
                            .foregroundStyle(Theme.accent)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.cardBackground)
                
                Button(action: {
                    HapticManager.tap()
                    generate3YearHistoricalData()
                }) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)
                        
                        Text("Generate 3-Year Historical Data")
                            .font(Theme.body)
                            .foregroundStyle(Theme.accent)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.cardBackground)
                
                Button(action: {
                    HapticManager.tap()
                    clearMockData()
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                            .frame(width: 24)
                        
                        Text("Clear Mock Data")
                            .font(Theme.body)
                            .foregroundStyle(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.cardBackground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Development")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    @MainActor
    private func resetOnboarding() {
        if let prefs = preferences.first {
            prefs.hasCompletedOnboarding = false
            try? modelContext.save()
        }
    }
    
    @MainActor
    private func generateMockData() {
        Task { @MainActor in
            await MockDataService.shared.generateCompleteMockData(
                modelContext: modelContext,
                preferences: userPrefs
            )
            HapticManager.success()
        }
    }
    
    @MainActor
    private func generate3YearHistoricalData() {
        Task { @MainActor in
            await HistoricalMockDataService.shared.generate3YearHistoricalData(
                modelContext: modelContext,
                preferences: userPrefs
            )
            NotificationCenter.default.post(name: .dataCleared, object: nil)
            HapticManager.success()
        }
    }
    
    @MainActor
    private func clearMockData() {
        Task { @MainActor in
            await MockDataService.shared.clearMockData(modelContext: modelContext)
            NotificationCenter.default.post(name: .dataCleared, object: nil)
            HapticManager.success()
        }
    }
}


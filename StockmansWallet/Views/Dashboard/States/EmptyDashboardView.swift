//
//  EmptyDashboardView.swift
//  StockmansWallet
//
//  Empty state view when user has no herds or animals
//

import SwiftUI
import SwiftData

struct EmptyDashboardView: View {
    @Binding var showingAddAssetMenu: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: State for loading indicator during mock data generation
    @State private var isGeneratingData = false
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 80))
                    .foregroundStyle(Theme.accentColor.opacity(0.5))
                    .accessibilityHidden(true)
                
                Text("Add your first herd or individual animals to start tracking your livestock portfolio value in real-time")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                HapticManager.tap()
                showingAddAssetMenu = true
            }) {
                Text("Add Your First Herd")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(Theme.PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .accessibilityLabel("Add your first herd")
            .accessibilityHint("Opens the asset menu to add a herd.")
            
            // Debug: Temporary Add Mock Data button for easier development
            // TODO: Remove this button before production release
            Button(action: {
                HapticManager.tap()
                addMockData()
            }) {
                HStack(spacing: 8) {
                    if isGeneratingData {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chart.bar.fill")
                    }
                    Text(isGeneratingData ? "Generating..." : "Add Mock Data")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(Theme.SecondaryButtonStyle())
            .disabled(isGeneratingData)
            .padding(.horizontal, 40)
            .accessibilityLabel("Add mock demo data")
            .accessibilityHint("Generates 3 years of historical mock data for testing")
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
    
    // Debug: Add 3-year historical mock data
    @MainActor
    private func addMockData() {
        isGeneratingData = true
        Task { @MainActor in
            await HistoricalMockDataService.shared.generate3YearHistoricalData(
                modelContext: modelContext,
                preferences: userPrefs
            )
            // Debug: Notify dashboard to refresh after data is added
            NotificationCenter.default.post(name: NSNotification.Name("DataCleared"), object: nil)
            isGeneratingData = false
            HapticManager.success()
        }
    }
}

#Preview {
    EmptyDashboardView(showingAddAssetMenu: .constant(false))
}


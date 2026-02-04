//
//  EmptyDashboardView.swift
//  StockmansWallet
//
//  Empty state view when user has no herds or animals
//

import SwiftUI
import SwiftData

struct EmptyDashboardView: View {
    @Binding var showingAddHerd: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
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
                showingAddHerd = true
            }) {
                Text("Add Your First Herd")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(Theme.PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .accessibilityLabel("Add your first herd")
            .accessibilityHint("Opens the asset menu to add a herd.")
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
}

#Preview {
    EmptyDashboardView(showingAddHerd: .constant(false))
}


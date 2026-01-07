//
//  PortfolioValueCard.swift
//  StockmansWallet
//
//  Main portfolio value display card with animated currency and change indicator
//

import SwiftUI

struct PortfolioValueCard: View {
    let value: Double
    let change: Double
    let baseValue: Double // Debug: Base value for calculating percentage change
    let isLoading: Bool
    let isScrubbing: Bool
    let isUpdating: Bool // Debug: Pulse/glow state during value transition
    
    // Debug: Calculate percentage change from base value
    private var percentageChange: Double {
        guard baseValue > 0 else { return 0 }
        return (change / baseValue) * 100
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Total Portfolio Value")
                .font(Theme.caption)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
            
            // Debug: Always show the number - never hide it with ProgressView
            // Use pulsing effect (isUpdating) to indicate loading instead
            AnimatedCurrencyValue(
                value: value,
                isScrubbing: isScrubbing
            )
                .padding(.bottom, 8)
                // Debug: Pulse/glow effect during value update (crypto-style)
                .shadow(
                    color: isUpdating ? Theme.accent.opacity(0.6) : .clear,
                    radius: isUpdating ? 20 : 0
                )
                .shadow(
                    color: isUpdating ? Theme.accent.opacity(0.4) : .clear,
                    radius: isUpdating ? 40 : 0
                )
                .animation(.easeInOut(duration: 0.8).repeatCount(3, autoreverses: true), value: isUpdating)
            
            // Debug: Change pill with both dollar amount and percentage
            HStack(spacing: 6) {
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(change >= 0 ? Theme.positiveChange : Theme.negativeChange)
                    .accessibilityHidden(true)
                
                // Dollar change
                Text(change, format: .currency(code: "AUD"))
                    .font(.system(size: 11, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(change >= 0 ? Theme.positiveChange : Theme.negativeChange)
                
                // Debug: Separator dot between dollar and percentage
                Text("•")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle((change >= 0 ? Theme.positiveChange : Theme.negativeChange).opacity(0.5))
                    .accessibilityHidden(true)
                
                // Percentage change
                Text("\(percentageChange >= 0 ? "+" : "")\(percentageChange, specifier: "%.2f")%")
                    .font(.system(size: 11, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(change >= 0 ? Theme.positiveChange : Theme.negativeChange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            // Debug: Solid dark background matching ticker color (no glass effect)
            .background(
                Capsule()
                    .fill(change >= 0 ? Color(hex: "1E2E0E") : Color(hex: "2E0E0E"))
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            .animation(UIAccessibility.isReduceMotionEnabled ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: change)
            .accessibilityLabel("Change for selected time range")
            .accessibilityValue("\(change.formatted(.currency(code: "AUD"))), \(percentageChange, specifier: "%.2f") percent")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.cardPadding)
    }
}

#Preview {
    ZStack {
        Color.black
        PortfolioValueCard(
            value: 125750.45,
            change: 5240.20,
            baseValue: 120510.25,
            isLoading: false,
            isScrubbing: false,
            isUpdating: false
        )
    }
}


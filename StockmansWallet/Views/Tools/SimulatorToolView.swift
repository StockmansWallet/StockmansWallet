//
//  SimulatorToolView.swift
//  StockmansWallet
//
//  Market Simulator - Run scenarios and projections
//  Debug: Placeholder view for future implementation
//

import SwiftUI

// Debug: Simulator tool - full screen view accessible from Tools menu
struct SimulatorToolView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    // Debug: Coming soon card
                    VStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 40)
                        
                        // Title and description
                        VStack(spacing: 8) {
                            Text("Simulator")
                                .font(Theme.title)
                                .foregroundStyle(Theme.primaryText)
                            
                            Text("Coming Soon")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.accent)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Theme.accent.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        
                        // Feature description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Planned Features:")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            FeatureRow(icon: "chart.bar.fill", text: "Market scenario modeling")
                            FeatureRow(icon: "arrow.up.arrow.down", text: "Price fluctuation projections")
                            FeatureRow(icon: "calendar", text: "Long-term planning tools")
                            FeatureRow(icon: "dollarsign.circle", text: "ROI calculations")
                        }
                        .padding(Theme.cardPadding)
                        .stitchedCard()
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 100)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                // Debug: Back button to dismiss
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.tap()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Tools")
                                .font(Theme.body)
                        }
                        .foregroundStyle(Theme.accent)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Simulator")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
        }
    }
}

// MARK: - Feature Row Component
// Debug: Reusable row for displaying planned features
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            Text(text)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText)
            Spacer()
        }
    }
}




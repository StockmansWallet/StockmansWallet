//
//  FreightCalculatorToolView.swift
//  StockmansWallet
//
//  Freight Calculator - Calculate transport costs
//  Debug: Placeholder view for future implementation
//

import SwiftUI

// Debug: Freight Calculator tool - full screen view accessible from Tools menu
struct FreightCalculatorToolView: View {
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
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.orange)
                        }
                        .padding(.top, 40)
                        
                        // Title and description
                        VStack(spacing: 8) {
                            Text("Freight Calculator")
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
                            
                            FeatureRow(icon: "map", text: "Distance-based cost calculation")
                            FeatureRow(icon: "scalemass", text: "Weight and head count pricing")
                            FeatureRow(icon: "building.2", text: "Multiple depot comparisons")
                            FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Return trip optimization")
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
                    Text("Freight Calculator")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
        }
    }
}






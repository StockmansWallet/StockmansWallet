//
//  ReportsToolView.swift
//  StockmansWallet
//
//  Bank-Ready Asset Registers and Sales Summaries
//  Debug: Uses @Observable pattern for ValuationEngine
//

import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers
import UIKit

// Debug: Reports tool - full screen view accessible from Tools menu
struct ReportsToolView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var herds: [HerdGroup]
    @Query private var sales: [SalesRecord]
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject
    let valuationEngine = ValuationEngine.shared
    
    @State private var showingAssetRegister = false
    @State private var showingSalesSummary = false
    @State private var portfolioValue: Double = 0.0
    @State private var isLoadingValuations = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    ReportsOptionsCard(
                        showingAssetRegister: $showingAssetRegister,
                        showingSalesSummary: $showingSalesSummary
                    )
                    .padding(.horizontal)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Report options")
                    
                    if !sales.isEmpty {
                        RecentSalesCard(sales: sales)
                            .padding(.horizontal)
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Recent sales")
                    }
                    
                    AssetSummaryCard(
                        herds: herds,
                        portfolioValue: portfolioValue,
                        isLoading: isLoadingValuations,
                        modelContext: modelContext,
                        preferences: preferences.first ?? UserPreferences(),
                        valuationEngine: valuationEngine
                    )
                    .padding(.horizontal)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Asset summary")
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
                    Text("Reports")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .sheet(isPresented: $showingAssetRegister) {
                AssetRegisterPDFView(
                    herds: herds,
                    preferences: preferences.first ?? UserPreferences(),
                    modelContext: modelContext,
                    valuationEngine: valuationEngine
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.sheetBackground)
            }
            .sheet(isPresented: $showingSalesSummary) {
                SalesSummaryPDFView(sales: sales)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Theme.sheetBackground)
            }
            .task {
                await loadPortfolioValue()
            }
            .onChange(of: herds.count) { _, _ in
                Task {
                    await loadPortfolioValue()
                }
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
        }
    }
    
    // Debug: Load portfolio value from all active herds
    private func loadPortfolioValue() async {
        await MainActor.run {
            isLoadingValuations = true
        }
        
        let prefs = preferences.first ?? UserPreferences()
        let activeHerds = herds.filter { !$0.isSold }
        
        guard !activeHerds.isEmpty else {
            await MainActor.run {
                portfolioValue = 0.0
                isLoadingValuations = false
            }
            return
        }
        
        var totalValue: Double = 0.0
        
        for herd in activeHerds {
            let valuation = await valuationEngine.calculateHerdValue(
                herd: herd,
                preferences: prefs,
                modelContext: modelContext
            )
            totalValue += valuation.netRealizableValue
        }
        
        await MainActor.run {
            portfolioValue = totalValue
            isLoadingValuations = false
        }
    }
}



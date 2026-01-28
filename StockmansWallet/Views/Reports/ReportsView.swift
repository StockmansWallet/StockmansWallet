//
//  ReportsView.swift
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

struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    // Performance: Only query herds (headCount > 1), not individual animals
    @Query(filter: #Predicate<HerdGroup> { $0.headCount > 1 }) private var herds: [HerdGroup]
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

// MARK: - Report Options
struct ReportsOptionsCard: View {
    @Binding var showingAssetRegister: Bool
    @Binding var showingSalesSummary: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Generate Reports")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            VStack(spacing: 12) {
                Button {
                    HapticManager.tap()
                    showingAssetRegister = true
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)
                        Text("Asset Register (PDF)")
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Theme.secondaryText)
                            .accessibilityHidden(true)
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                Button {
                    HapticManager.tap()
                    showingSalesSummary = true
                } label: {
                    HStack {
                        Image(systemName: "doc.richtext.fill")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)
                        Text("Sales Summary (PDF)")
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Theme.secondaryText)
                            .accessibilityHidden(true)
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(Theme.cardPadding)
        .cardStyle()
    }
}

// MARK: - Recent Sales
struct RecentSalesCard: View {
    let sales: [SalesRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Sales")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            if sales.isEmpty {
                Text("No recent sales")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(sales.prefix(5)) { sale in
                        RecentSaleRow(sale: sale)
                        if sale.id != sales.prefix(5).last?.id {
                            Divider().background(Theme.separator)
                        }
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .cardStyle()
    }
}

struct RecentSaleRow: View {
    let sale: SalesRecord
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sale")
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
                
                Text("\(sale.headCount) head • avg weight \(sale.averageWeight, format: .number.precision(.fractionLength(0))) kg")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                
                Text(sale.saleDate, format: .dateTime.day().month(.abbreviated).year())
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(sale.netValue, format: .currency(code: "AUD"))
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Text("\(sale.pricePerKg, format: .number.precision(.fractionLength(2))) $/kg")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Asset Summary
struct AssetSummaryCard: View {
    let herds: [HerdGroup]
    let portfolioValue: Double
    let isLoading: Bool
    let modelContext: ModelContext
    let preferences: UserPreferences
    let valuationEngine: ValuationEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Asset Summary")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            if isLoading {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if herds.isEmpty {
                Text("No herds available")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text("Portfolio Value")
                            .font(Theme.body)
                            .foregroundStyle(Theme.secondaryText)
                        Spacer()
                        Text(portfolioValue, format: .currency(code: "AUD"))
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    Divider().background(Theme.separator)
                    
                    ForEach(herds.prefix(5)) { herd in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(herd.name)
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                Text("\(herd.headCount) head • \(herd.breed) \(herd.category)")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            Spacer()
                            Text("View")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.accent)
                        }
                        if herd.id != herds.prefix(5).last?.id {
                            Divider().background(Theme.separator)
                        }
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .cardStyle()
    }
}

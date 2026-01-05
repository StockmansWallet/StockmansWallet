//
//  ReportsToolView.swift
//  StockmansWallet
//
//  Enhanced Reports with multiple report types, preview, and print
//  Debug: Uses new EnhancedReportsView with all features
//

import SwiftUI
import SwiftData

// Debug: Reports tool - full screen view accessible from Tools menu
// Now uses the enhanced reports system
struct ReportsToolView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            // Debug: Use the new enhanced reports view
            EnhancedReportsContentView()
                .navigationBarTitleDisplayMode(.inline)
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
        }
    }
}

// Debug: Content wrapper to avoid nested NavigationStacks
struct EnhancedReportsContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var herds: [HerdGroup]
    @Query private var sales: [SalesRecord]
    @Query private var preferences: [UserPreferences]
    @Query private var properties: [Property]
    
    let valuationEngine = ValuationEngine.shared
    
    @State private var selectedReportType: ReportType?
    @State private var showingConfiguration = false
    @State private var reportConfiguration: ReportConfiguration?
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                // Debug: Header card with description
                headerCard
                
                // Debug: Report type selection cards
                VStack(spacing: 12) {
                    ForEach(ReportType.allCases) { reportType in
                        ReportTypeCard(
                            reportType: reportType,
                            onTap: {
                                HapticManager.tap()
                                selectedReportType = reportType
                                reportConfiguration = ReportConfiguration(reportType: reportType)
                                showingConfiguration = true
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 100)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .sheet(isPresented: $showingConfiguration) {
            if let config = reportConfiguration {
                ReportConfigurationView(
                    configuration: config,
                    herds: herds,
                    sales: sales,
                    preferences: userPrefs,
                    properties: properties,
                    modelContext: modelContext,
                    valuationEngine: valuationEngine
                )
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text("Generate Reports")
                    .font(Theme.title)
                    .foregroundStyle(Theme.primaryText)
            }
            
            Text("Create detailed reports with custom date ranges, comparisons, and analytics. Preview before generating or print directly.")
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .stitchedCard()
        .padding(.horizontal)
        .padding(.top)
    }
}




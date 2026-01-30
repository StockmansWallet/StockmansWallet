//
//  EnhancedReportsView.swift
//  StockmansWallet
//
//  Enhanced Reports View with multiple report types, preview, and print
//  Debug: Comprehensive reporting system with configuration options
//

import SwiftUI
import SwiftData

// Debug: Main enhanced reports view with all new features
struct EnhancedReportsView: View {
    @Environment(\.modelContext) private var modelContext
    // Performance: Only query herds (headCount > 1), not individual animals
    @Query(filter: #Predicate<HerdGroup> { $0.headCount > 1 }) private var herds: [HerdGroup]
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
        NavigationStack {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Reports")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
            }
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
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.accentColor)
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
        .cardStyle()
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Report Type Card
// Debug: Individual card for each report type
struct ReportTypeCard: View {
    let reportType: ReportType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Debug: Icon
                ZStack {
                    Circle()
                        .fill(Theme.accentColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: reportType.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.accentColor)
                }
                
                // Debug: Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(reportType.rawValue)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Text(reportType.description)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(Theme.cardPadding)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}





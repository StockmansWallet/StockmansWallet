//
//  MarketView.swift
//  StockmansWallet
//
//  Market View - Tabbed Navigation Design
//  Debug: Clean, modern layout with Overview, My Markets, Market Pulse, and Intelligence tabs
//

import SwiftUI
import SwiftData

struct MarketView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @Query(sort: \HerdGroup.updatedAt, order: .reverse) private var allHerds: [HerdGroup]
    
    // Debug: Use 'let' with @Observable instead of @StateObject (modern pattern)
    @State private var viewModel = MarketViewModel()
    
    // Debug: Tab selection state
    @State private var selectedTab: MarketTab = .overview
    
    // Debug: Price detail sheet state
    @State private var selectedPriceForDetail: CategoryPrice? = nil
    @State private var showingPriceDetail = false
    
    // Debug: Get user preferences
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    // Debug: Get unique categories from user's actual herds
    private var userHerdCategories: [String] {
        let activeHerds = allHerds.filter { !$0.isSold }
        return Array(Set(activeHerds.map { $0.category })).sorted()
    }
    
    // MARK: - Market Tab Enum
    // Debug: Four-section market view - Overview, My Markets, Market Pulse, Intelligence
    enum MarketTab: String, CaseIterable {
        case overview = "Overview"
        case myMarkets = "My Markets"
        case pulse = "Market Pulse"
        case intelligence = "Intelligence"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Debug: Tab selector (segmented control)
                MarketTabSelector(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Debug: Tab content
                ScrollView {
                    VStack(spacing: Theme.sectionSpacing) {
                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .myMarkets:
                            myMarketsContent
                        case .pulse:
                            marketPulseContent
                        case .intelligence:
                            intelligenceContent
                        }
                    }
                    .padding(.bottom, 100)
                }
                .scrollContentBackground(.hidden)
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Markets")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.tap()
                        Task { await viewModel.loadAllData() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Refresh market data")
                }
            }
            .task {
                // Debug: Load initial data on appear
                await viewModel.loadAllData()
                // Load prices specific to user's herd categories
                if !userHerdCategories.isEmpty {
                    await viewModel.loadCategoryPrices(forCategories: userHerdCategories)
                }
            }
            .refreshable {
                await viewModel.loadAllData()
                if !userHerdCategories.isEmpty {
                    await viewModel.loadCategoryPrices(forCategories: userHerdCategories)
                }
            }
            .sheet(isPresented: $showingPriceDetail) {
                if let price = selectedPriceForDetail {
                    PriceDetailSheet(
                        categoryPrice: price,
                        historicalPrices: viewModel.historicalPrices,
                        regionalPrices: viewModel.regionalPrices,
                        isLoadingHistory: viewModel.isLoadingHistory,
                        isLoadingRegional: viewModel.isLoadingRegional
                    )
                }
            }
        }
    }
    
    // MARK: - Overview Content
    // Debug: Landing page with TOP INSIGHT + summary cards
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // TOP INSIGHT Banner
            if let insight = viewModel.topInsight {
                TopInsightBanner(insight: insight)
                    .padding(.horizontal)
            } else if viewModel.isLoadingInsight {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(height: 80)
            }
            
            // Debug: Last updated timestamp
            if let lastUpdated = viewModel.lastUpdated {
                HStack {
                    Text("Last updated")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                    Text(lastUpdated, style: .relative)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.accent)
                    Text("ago")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.horizontal)
            }
            
            // Quick access cards to other tabs
            VStack(spacing: 12) {
                QuickAccessCard(
                    title: "My Markets",
                    subtitle: "Prices for your livestock",
                    icon: "chart.bar.xaxis",
                    count: userHerdCategories.isEmpty ? nil : viewModel.categoryPrices.count
                ) {
                    selectedTab = .myMarkets
                }
                
                QuickAccessCard(
                    title: "Market Pulse",
                    subtitle: "National indicators & reports",
                    icon: "waveform.path.ecg",
                    count: viewModel.nationalIndicators.count + viewModel.saleyardReports.count
                ) {
                    selectedTab = .pulse
                }
                
                QuickAccessCard(
                    title: "Intelligence",
                    subtitle: "AI predictive insights",
                    icon: "brain.head.profile",
                    count: viewModel.marketIntelligence.count
                ) {
                    selectedTab = .intelligence
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - My Markets Content
    // Debug: Prices relevant to user's actual herd categories
    private var myMarketsContent: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Market Prices")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                Text("Prices for livestock categories in your portfolio")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            if userHerdCategories.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.secondaryText.opacity(0.5))
                    Text("No Livestock Yet")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text("Add livestock to see relevant market prices here")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else if viewModel.isLoadingPrices {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(height: 200)
            } else if viewModel.categoryPrices.isEmpty {
                // No prices available
                emptyStateView(message: "No price data available for your livestock")
            } else {
                // Price cards grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(viewModel.categoryPrices) { price in
                        PriceCard(price: price) {
                            selectedPriceForDetail = price
                            Task {
                                await viewModel.loadHistoricalPrices(
                                    category: price.category,
                                    livestockType: price.livestockType,
                                    months: 12
                                )
                                await viewModel.loadRegionalComparison(
                                    category: price.category,
                                    livestockType: price.livestockType
                                )
                                showingPriceDetail = true
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Market Pulse Content
    // Debug: National indicators + saleyard reports
    private var marketPulseContent: some View {
        VStack(spacing: 24) {
            // National Indicators Section
            VStack(alignment: .leading, spacing: 12) {
                Text("National Indicators")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                    .padding(.horizontal)
                
                if viewModel.isLoadingIndicators {
                    ProgressView()
                        .tint(Theme.accent)
                        .frame(height: 150)
                } else if viewModel.nationalIndicators.isEmpty {
                    emptyStateView(message: "No indicator data available")
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(viewModel.nationalIndicators) { indicator in
                            NationalIndicatorCard(indicator: indicator)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Physical Sales Report Section
            // Debug: Detailed cattle pricing table by category
            if let physicalReport = viewModel.physicalSalesReport {
                PhysicalSalesTableView(report: physicalReport)
                    .padding(.top, 8)
            } else if viewModel.isLoadingPhysicalReport {
                VStack(spacing: 12) {
                    Text("Physical Sales Report")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    ProgressView()
                        .tint(Theme.accent)
                        .frame(height: 100)
                }
            }
            
            // Saleyard Selector Section
            // Debug: Same saleyard selector used on dashboard for filtering market data
            VStack(spacing: 12) {
                SaleyardSelector(selectedSaleyard: $viewModel.selectedSaleyard)
                
                // Debug: Info note about saleyard selection
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                        .opacity(0.5)
                    Text("Select a specific saleyard to view market data from that location, or use your default saleyards.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .opacity(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            
            // Saleyard Reports Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Saleyard Reports")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                    
                    Spacer()
                    
                    // State filter
                    Menu {
                        Button("All States") {
                            Task { await viewModel.selectState(nil) }
                        }
                        Divider()
                        ForEach(ReferenceData.states, id: \.self) { state in
                            Button(state) {
                                Task { await viewModel.selectState(state) }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedState ?? "All")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.accent)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.accent)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.accent.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                
                if viewModel.isLoadingReports {
                    ProgressView()
                        .tint(Theme.accent)
                        .frame(height: 150)
                } else if viewModel.saleyardReports.isEmpty {
                    emptyStateView(message: "No saleyard reports available")
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.saleyardReports) { report in
                            SaleyardReportCard(report: report)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Intelligence Content
    // Debug: AI predictive insights with confidence levels
    private var intelligenceContent: some View {
        VStack(spacing: 16) {
            // Header with description
            VStack(alignment: .leading, spacing: 8) {
                Text("Market Intelligence")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                Text("Forward-looking insights powered by live market, weather, supply and demand data")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.secondaryText)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            if viewModel.isLoadingIntelligence {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(height: 200)
            } else if viewModel.marketIntelligence.isEmpty {
                emptyStateView(message: "No intelligence data available")
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.marketIntelligence) { intelligence in
                        IntelligenceCard(intelligence: intelligence)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Empty State View
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40))
                .foregroundStyle(Theme.secondaryText.opacity(0.5))
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .padding(.horizontal)
    }
}

// MARK: - Market Tab Selector
// Debug: Using native segmented control for iOS HIG compliance
struct MarketTabSelector: View {
    @Binding var selectedTab: MarketView.MarketTab
    
    var body: some View {
        Picker("Market Tab", selection: $selectedTab) {
            ForEach(MarketView.MarketTab.allCases, id: \.self) { tab in
                Text(tab.rawValue)
                    .font(Theme.caption)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .frame(height: 44)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.tap()
        }
    }
}

// MARK: - Top Insight Banner
// Debug: Slim banner with daily market takeaway
struct TopInsightBanner: View {
    let insight: TopInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accent)
                Text("Today's Insight")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                Text(insight.date, style: .time)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondaryText)
            }
            
            Text(insight.text)
                .font(.system(size: 15))
                .foregroundStyle(Theme.primaryText)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Quick Access Card
// Debug: Navigate to specific tabs from Overview
struct QuickAccessCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let count: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.tap()
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Spacer()
                
                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.accent.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText.opacity(0.5))
            }
            .padding(16)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Price Card
// Debug: Market price display for user's livestock
struct PriceCard: View {
    let price: CategoryPrice
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.tap()
            action()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(price.category)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(price.weightRange)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Spacer()
                
                // Price
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$\(price.price, format: .number.precision(.fractionLength(2)))")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                    Text("/kg")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondaryText)
                }
                
                // Change indicator
                HStack(spacing: 4) {
                    Image(systemName: price.trend == .up ? "arrow.up" : price.trend == .down ? "arrow.down" : "minus")
                        .font(.system(size: 10, weight: .semibold))
                    Text("\(price.change >= 0 ? "+" : "")\(price.change, format: .number.precision(.fractionLength(2)))")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(price.trend == .up ? Theme.positiveChange : price.trend == .down ? Theme.negativeChange : Theme.secondaryText)
            }
            .padding(16)
            .frame(height: 160)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - National Indicator Card
// Debug: Display EYCI, WYCI, NSI, etc.
struct NationalIndicatorCard: View {
    let indicator: NationalIndicator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(indicator.abbreviation)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(indicator.value, format: .number.precision(.fractionLength(2)))
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.primaryText)
                .minimumScaleFactor(0.8)
            
            HStack(spacing: 4) {
                Image(systemName: indicator.trend == .up ? "arrow.up" : indicator.trend == .down ? "arrow.down" : "minus")
                    .font(.system(size: 11, weight: .semibold))
                Text("\(indicator.change >= 0 ? "+" : "")\(indicator.change, format: .number.precision(.fractionLength(2)))")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(indicator.trend == .up ? Theme.positiveChange : indicator.trend == .down ? Theme.negativeChange : Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Saleyard Report Card
// Debug: Display saleyard report summary
struct SaleyardReportCard: View {
    let report: SaleyardReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.saleyardName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                    Text(report.state)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.accent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(report.yardings)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    Text("head yarded")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            
            Text(report.summary)
                .font(.system(size: 14))
                .foregroundStyle(Theme.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text(report.date, format: .dateTime.month().day())
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondaryText)
                
                Spacer()
                
                // Show categories traded
                if !report.categories.isEmpty {
                    Text("\(report.categories.count) categories")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Intelligence Card
// Debug: AI prediction card with confidence indicator
struct IntelligenceCard: View {
    let intelligence: MarketIntelligence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with confidence
            HStack {
                Text(intelligence.category)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                
                Spacer()
                
                // Confidence badge
                HStack(spacing: 4) {
                    Image(systemName: intelligence.confidence.icon)
                        .font(.system(size: 11))
                    Text(intelligence.confidence.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(confidenceColor(intelligence.confidence))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(confidenceColor(intelligence.confidence).opacity(0.15))
                .clipShape(Capsule())
            }
            
            // Prediction text
            Text(intelligence.prediction)
                .font(.system(size: 14))
                .foregroundStyle(Theme.primaryText)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
            // Time horizon
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text(intelligence.timeHorizon)
                    .font(.system(size: 12))
            }
            .foregroundStyle(Theme.accent)
            
            // Key drivers
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Drivers:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(intelligence.keyDrivers, id: \.self) { driver in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundStyle(Theme.accent)
                                .padding(.top, 5)
                            Text(driver)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            
            // Footer with update time
            Text("Updated \(intelligence.lastUpdated, style: .relative) ago")
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondaryText.opacity(0.7))
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func confidenceColor(_ confidence: ConfidenceLevel) -> Color {
        switch confidence {
        case .high: return Theme.positiveChange
        case .medium: return .orange
        case .low: return .gray
        }
    }
}

// MARK: - Preview
#Preview {
    MarketView()
        .modelContainer(for: [HerdGroup.self, UserPreferences.self, MarketPrice.self], inMemory: true)
}

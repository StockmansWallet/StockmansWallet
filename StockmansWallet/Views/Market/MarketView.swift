//
//  MarketView.swift
//  StockmansWallet
//
//  Market View - Apple HIG Compliant Design
//  Debug: Clean, spacious layout with clear visual hierarchy
//

import SwiftUI
import SwiftData

struct MarketView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject (modern pattern)
    @State private var viewModel = MarketViewModel()
    
    // Debug: UI state
    @State private var showingHistoricalChart = false
    @State private var showingMarketInsights = false
    @State private var selectedPriceForDetail: CategoryPrice?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section - National Indicators (Priority #1)
                    // Debug: Large, prominent display at the top
                    heroIndicatorsSection
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    
                    // Compact Filter Bar
                    // Debug: Clean, horizontal layout - no card wrapper
                    compactFilterBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // Live Prices Section
                    // Debug: Main content with generous spacing
                    livePricesSection
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 100)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Market")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Market Insights button
                        Button {
                            HapticManager.tap()
                            showingMarketInsights = true
                        } label: {
                            Image(systemName: "newspaper")
                                .foregroundStyle(Theme.accent)
                        }
                        .accessibilityLabel("Market insights")
                        
                        // Refresh button
                        Button {
                            Task { await viewModel.loadAllData() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(Theme.accent)
                        }
                        .accessibilityLabel("Refresh market data")
                    }
                }
            }
            .task {
                await viewModel.loadAllData()
            }
            .refreshable {
                await viewModel.loadAllData()
            }
            .sheet(isPresented: $showingHistoricalChart) {
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
            .sheet(isPresented: $showingMarketInsights) {
                MarketInsightsSheet(
                    commentary: viewModel.marketCommentary,
                    isLoading: viewModel.isLoadingCommentary
                )
            }
        }
    }
    
    // MARK: - Hero Indicators Section
    // Debug: Large, prominent national indicators - Apple Stocks style
    private var heroIndicatorsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("National Indicators")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                if let lastUpdated = viewModel.lastUpdated {
                    Text(lastUpdated, style: .relative)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            
            if viewModel.isLoadingIndicators {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(height: 200)
            } else if viewModel.nationalIndicators.isEmpty {
                emptyStateView(message: "No indicator data available")
            } else {
                // Two-column grid for hero indicators
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(viewModel.nationalIndicators) { indicator in
                        HeroIndicatorCard(indicator: indicator)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Compact Filter Bar
    // Debug: Streamlined filters without heavy card styling
    private var compactFilterBar: some View {
        VStack(spacing: 12) {
            // Livestock type pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPill(
                        title: "All",
                        isSelected: viewModel.selectedLivestockType == nil
                    ) {
                        Task { await viewModel.selectLivestockType(nil) }
                    }
                    
                    ForEach(LivestockType.allCases) { type in
                        FilterPill(
                            title: type.rawValue,
                            icon: type.icon,
                            isSelected: viewModel.selectedLivestockType == type
                        ) {
                            Task { await viewModel.selectLivestockType(type) }
                        }
                    }
                }
            }
            
            // Secondary filters (saleyard & state) - only show if needed
            if viewModel.hasActiveFilters || viewModel.selectedLivestockType != nil {
                HStack(spacing: 8) {
                    // Saleyard filter
                    Menu {
                        Button("All Saleyards") {
                            Task { await viewModel.selectSaleyard(nil) }
                        }
                        
                        Divider()
                        
                        ForEach(ReferenceData.saleyards.prefix(10), id: \.self) { yard in
                            Button(yard) {
                                Task { await viewModel.selectSaleyard(yard) }
                            }
                        }
                    } label: {
                        SecondaryFilterButton(
                            icon: "mappin.circle",
                            title: viewModel.selectedSaleyard ?? "Saleyard",
                            isActive: viewModel.selectedSaleyard != nil
                        )
                    }
                    
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
                        SecondaryFilterButton(
                            icon: "map",
                            title: viewModel.selectedState ?? "State",
                            isActive: viewModel.selectedState != nil
                        )
                    }
                    
                    Spacer()
                    
                    // Clear filters
                    if viewModel.hasActiveFilters {
                        Button {
                            Task { await viewModel.clearFilters() }
                        } label: {
                            Text("Clear")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Live Prices Section
    // Debug: Clean grid with generous spacing
    private var livePricesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Live Prices")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                Text("\(viewModel.filteredPrices.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
            }
            
            if viewModel.isLoadingPrices {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(height: 200)
            } else if viewModel.filteredPrices.isEmpty {
                emptyStateView(message: "No prices for selected filters")
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(viewModel.filteredPrices) { price in
                        CleanPriceCard(price: price) {
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
                                showingHistoricalChart = true
                            }
                        }
                    }
                }
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
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - Hero Indicator Card
// Debug: Large, prominent cards for national indicators
struct HeroIndicatorCard: View {
    let indicator: NationalIndicator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Abbreviation
            Text(indicator.abbreviation)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .textCase(.uppercase)
                .tracking(0.5)
            
            // Value
            Text(indicator.value, format: .number.precision(.fractionLength(2)))
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
                .minimumScaleFactor(0.8)
            
            // Change
            HStack(spacing: 4) {
                Image(systemName: indicator.trend == .up ? "arrow.up" : indicator.trend == .down ? "arrow.down" : "minus")
                    .font(.system(size: 12, weight: .semibold))
                Text("\(indicator.change >= 0 ? "+" : "")\(indicator.change, format: .number.precision(.fractionLength(2)))")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(indicator.trend == .up ? Theme.positiveChange : indicator.trend == .down ? Theme.negativeChange : Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Filter Pill
// Debug: Clean pill-style filter buttons
struct FilterPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.tap()
            action()
        }) {
            HStack(spacing: 6) {
                if let icon {
                    Text(icon)
                        .font(.system(size: 16))
                }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : Theme.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Theme.accent : Theme.cardBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Secondary Filter Button
struct SecondaryFilterButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(isActive ? Theme.accent : Theme.secondaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? Theme.accent.opacity(0.12) : Theme.cardBackground)
        .clipShape(Capsule())
    }
}

// MARK: - Clean Price Card
// Debug: Refined price cards with better spacing and hierarchy
struct CleanPriceCard: View {
    let price: CategoryPrice
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.tap()
            action()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    // Category
                    Text(price.category)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Weight range
                    Text(price.weightRange)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Spacer()
                
                // Price
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$\(price.price, format: .number.precision(.fractionLength(2)))")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                    Text("/kg")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText)
                }
                
                // Change indicator
                HStack(spacing: 4) {
                    Image(systemName: price.trend == .up ? "arrow.up" : price.trend == .down ? "arrow.down" : "minus")
                        .font(.system(size: 11, weight: .semibold))
                    Text("\(price.change >= 0 ? "+" : "")\(price.change, format: .number.precision(.fractionLength(2)))")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(price.trend == .up ? Theme.positiveChange : price.trend == .down ? Theme.negativeChange : Theme.secondaryText)
            }
            .padding(20)
            .frame(height: 180)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Market Insights Sheet
struct MarketInsightsSheet: View {
    let commentary: [MarketCommentary]
    let isLoading: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .tint(Theme.accent)
                            .frame(height: 200)
                    } else if commentary.isEmpty {
                        emptyInsightsView
                    } else {
                        ForEach(commentary) { item in
                            InsightCard(commentary: item)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }
            .background(Theme.sheetBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Market Insights")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var emptyInsightsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "newspaper")
                .font(.system(size: 40))
                .foregroundStyle(Theme.secondaryText.opacity(0.5))
            Text("No insights available")
                .font(.system(size: 15))
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let commentary: MarketCommentary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(commentary.category)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
                
                Image(systemName: commentary.sentiment.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(sentimentColor)
            }
            
            // Title
            Text(commentary.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
            
            // Summary
            Text(commentary.summary)
                .font(.system(size: 15))
                .foregroundStyle(Theme.secondaryText)
                .lineSpacing(4)
            
            // Time
            Text(commentary.date, style: .relative)
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondaryText.opacity(0.7))
        }
        .padding(20)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var sentimentColor: Color {
        switch commentary.sentiment {
        case .positive: return Theme.positiveChange
        case .neutral: return .gray
        case .negative: return Theme.negativeChange
        }
    }
}

// MARK: - Preview
#Preview {
    MarketView()
        .modelContainer(for: [HerdGroup.self, UserPreferences.self, MarketPrice.self], inMemory: true)
}

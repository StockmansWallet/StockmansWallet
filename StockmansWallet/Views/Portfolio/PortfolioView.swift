//
//  PortfolioView.swift
//  StockmansWallet
//
//  Comprehensive Portfolio View: Capital Insight, Asset Breakdown, and Performance Tracking
//  Debug: Uses @Observable pattern for state management, proper accessibility labels
//

import SwiftUI
import SwiftData
import Charts

struct PortfolioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use @Query with stable sort to get automatic SwiftData updates without manual fetching
    // This prevents navigation toolbar blur by removing async fetching during transitions
    @Query(sort: \HerdGroup.updatedAt, order: .reverse) private var allHerds: [HerdGroup]
    
    // Debug: Use 'let' with @Observable instead of @StateObject
    let valuationEngine = ValuationEngine.shared
    
    @State private var showingAddAssetMenu = false
    @State private var showingSearchPanel = false
    @State private var portfolioSummary: PortfolioSummary?
    @State private var isLoading = true
    @State private var selectedView: PortfolioViewMode = .overview
    
    // Performance: Track if we've loaded summary to prevent recalculation on every navigation
    @State private var hasInitiallyLoaded = false
    
    // Debug: Search functionality for Herds and Individual sections
    @State private var herdsSearchText = ""
    @State private var individualSearchText = ""
    
    // Performance: Cache filtered results to avoid recalculating on every render
    @State private var cachedFilteredHerds: [HerdGroup] = []
    // Performance: Store individuals as plain structs to break SwiftData observation
    @State private var cachedFilteredIndividuals: [AnimalDisplayData] = []
    
    // Debug: Sell functionality - track selected herd ID (nil means sheet is dismissed)
    // Wrapper to make UUID Identifiable for fullScreenCover(item:)
    @State private var herdIdToSell: IdentifiableUUID? = nil
    
    // Debug: Wrapper struct to make UUID Identifiable
    struct IdentifiableUUID: Identifiable {
        let id: UUID
    }
    
    // Performance: Task cancellation - prevent wasted CPU when user navigates away
    @State private var loadingTask: Task<Void, Never>? = nil
    
    // Debug: Three-section portfolio view - Overview for summary stats, Herds for groups, Individual for single animals
    enum PortfolioViewMode: String, CaseIterable {
        case overview = "Overview"
        case herds = "Herds"
        case individual = "Individual"
    }
    
    var body: some View {
        ZStack {
            portfolioContent
        }
        .fullScreenCover(item: $herdIdToSell) { identifiableId in
            SellStockView(preselectedHerdId: identifiableId.id)
                .transition(.move(edge: .trailing))
                .presentationBackground(Theme.sheetBackground)
        }
    }
    
    // Debug: Break up body into smaller computed properties to help compiler
    private var portfolioContent: some View {
        NavigationStack {
            mainContent
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .toolbarBackground(.clear, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .fullScreenCover(isPresented: $showingAddAssetMenu) {
                    AddAssetMenuView(isPresented: $showingAddAssetMenu)
                        .transition(.move(edge: .trailing))
                        .presentationBackground(Theme.sheetBackground)
                }
                .sheet(isPresented: $showingSearchPanel) {
                    // Performance: Pass herds as binding to avoid capturing live query
                    PortfolioSearchPanel(herds: allHerds)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(Theme.sheetBackground)
                }
                .task(id: hasInitiallyLoaded) {
                    // Debug: @Query automatically fetches and updates herds, no manual fetch needed
                    // This prevents async operations during navigation that blur toolbar buttons
                    guard !hasInitiallyLoaded else { return }
                    
                    // Performance: Update filtered caches
                    updateFilteredCaches()
                    
                    await MainActor.run {
                        self.hasInitiallyLoaded = true
                    }
                    
                    // Calculate valuations (now uses ValuationEngine like Dashboard for consistency)
                    loadingTask = Task(priority: .userInitiated) {
                        await loadPortfolioSummary()
                    }
                }
                .onDisappear {
                    loadingTask?.cancel()
                    loadingTask = nil
                    #if DEBUG
                    print("📊 PortfolioView disappeared - cancelled loading task")
                    #endif
                }
                .onChange(of: herdsSearchText) { _, _ in
                    // Performance: Update cache when search changes
                    updateFilteredCaches()
                }
                .onChange(of: individualSearchText) { _, _ in
                    // Performance: Update cache when search changes
                    updateFilteredCaches()
                }
                .onChange(of: allHerds.count) { _, _ in
                    // Performance: Update cache when herds change
                    updateFilteredCaches()
                }
                .background(Theme.backgroundGradient.ignoresSafeArea(edges: [.horizontal, .bottom]))
        }
    }
    
    private var mainContent: some View {
        Group {
            if allHerds.isEmpty {
                EmptyPortfolioView(showingAddAssetMenu: $showingAddAssetMenu)
            } else {
                ScrollView {
                    VStack(spacing: Theme.sectionSpacing) {
                        // Always render stats card to prevent layout shift during loading
                        PortfolioStatsCards(summary: portfolioSummary, isLoading: isLoading)
                            .padding(.horizontal, Theme.cardPadding)
                           
                        
                        PortfolioViewModeSelector(selectedView: $selectedView)
                            .padding(.horizontal)
                           
                        
                        if selectedView == .overview {
                            overviewContent
                        } else if selectedView == .herds {
                            herdsContent
                        } else {
                            individualContent
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 100)
                }
                .scrollContentBackground(.hidden)
                .background(Theme.backgroundGradient)
                .refreshable {
                    // Performance: Refresh summary (herds auto-update via @Query)
                    await loadPortfolioSummary()
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Portfolio")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
                .accessibilityAddTraits(.isHeader)
        }
        
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                HapticManager.tap()
                showingSearchPanel = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.primaryText)
            }
            .accessibilityLabel("Search assets")
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Add") {
                HapticManager.tap()
                showingAddAssetMenu = true
            }
            .foregroundStyle(Theme.accent)
            .accessibilityLabel("Add Stock")
        }
    }
    
    // MARK: - Overview Content
    private var overviewContent: some View {
        let userPrefs = preferences.first ?? UserPreferences()
        
        return Group {
            if let summary = portfolioSummary {
                // Debug: Display dashboard cards in user's custom order from preferences
                ForEach(userPrefs.portfolioCardOrder, id: \.self) { cardId in
                    if userPrefs.isPortfolioCardVisible(cardId) {
                        switch cardId {
                        case "marketSummary":
                            MarketPulseView()
                                .padding(.horizontal, Theme.cardPadding)
                                .accessibilityElement(children: .contain)
                                .accessibilityLabel("Herd performance")
                            
                        case "recentActivity":
                            HerdDynamicsView(herds: allHerds.filter { !$0.isSold })
                                .padding(.horizontal, Theme.cardPadding)
                                .accessibilityElement(children: .contain)
                                .accessibilityLabel("Growth and mortality")
                            
                        case "herdComposition":
                            // Debug: Build capital concentration breakdown from portfolio summary
                            let breakdown = summary.categoryBreakdown.map {
                                CapitalConcentrationBreakdown(
                                    category: $0.category,
                                    value: $0.totalValue,
                                    percentage: summary.totalNetWorth > 0 ? ($0.totalValue / summary.totalNetWorth) * 100 : 0
                                )
                            }
                            if !breakdown.isEmpty {
                                CapitalConcentrationView(breakdown: breakdown, totalValue: summary.totalNetWorth)
                                    .padding(.horizontal, Theme.cardPadding)
                                    .accessibilityElement(children: .contain)
                                    .accessibilityLabel("Herd composition")
                            }
                            
                        default:
                            EmptyView()
                        }
                    }
                }
            } else if isLoading {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
    
    // MARK: - Herds Content
    // Debug: Display only herds (headCount > 1) with search functionality
    private var herdsContent: some View {
        Group {
            if let summary = portfolioSummary {
                VStack(spacing: 16) {
                    // Debug: Search field at top of herds section (below segmented control)
                    SearchField(text: $herdsSearchText, placeholder: "Search for a herd")
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 16) {
                        ForEach(cachedFilteredHerds, id: \.id) { herd in
                            let herdIdForSale = herd.id
                            EnhancedHerdCard(
                                herd: herd,
                                summary: summary,
                                onSellTapped: {
                                    herdIdToSell = IdentifiableUUID(id: herdIdForSale)
                                }
                            )
                            .id(herd.id) // Performance: Explicit ID for stable identity
                        }
                    }
                    .padding(.horizontal)
                    
                    // Debug: Show message if no herds found
                    if cachedFilteredHerds.isEmpty {
                        EmptySearchResultView(
                            searchText: herdsSearchText,
                            type: "herds"
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Individual Content
    // Debug: Display only individual animals (headCount == 1) with search functionality
    // Performance: Uses lightweight card for better scroll performance with many items
    private var individualContent: some View {
        Group {
            if portfolioSummary != nil {
                VStack(spacing: 16) {
                    // Debug: Search field at top of individual section (below segmented control)
                    SearchField(text: $individualSearchText, placeholder: "Search for an individual animal")
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(cachedFilteredIndividuals) { data in
                            LightweightAnimalCard(data: data)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Debug: Show message if no individuals found
                    if cachedFilteredIndividuals.isEmpty {
                        EmptySearchResultView(
                            searchText: individualSearchText,
                            type: "individual animals"
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Update Filtered Caches
    // Performance: Update cached filtered results only when search text or herds change
    private func updateFilteredCaches() {
        // Filter herds
        let herdsOnly = allHerds.filter { !$0.isSold && $0.headCount > 1 }
        if herdsSearchText.isEmpty {
            cachedFilteredHerds = herdsOnly
        } else {
            let searchLower = herdsSearchText.lowercased()
            cachedFilteredHerds = herdsOnly.filter { herd in
                herd.name.lowercased().contains(searchLower) ||
                herd.breed.lowercased().contains(searchLower) ||
                herd.category.lowercased().contains(searchLower) ||
                herd.species.lowercased().contains(searchLower) ||
                (herd.paddockName?.lowercased().contains(searchLower) ?? false) ||
                (herd.additionalInfo?.lowercased().contains(searchLower) ?? false)
            }
        }
        
        // Filter individuals and convert to plain structs with valuations
        let individualsOnly = allHerds.filter { !$0.isSold && $0.headCount == 1 }
        let filteredIndividuals: [HerdGroup]
        if individualSearchText.isEmpty {
            filteredIndividuals = individualsOnly
        } else {
            let searchLower = individualSearchText.lowercased()
            filteredIndividuals = individualsOnly.filter { herd in
                herd.name.lowercased().contains(searchLower) ||
                herd.breed.lowercased().contains(searchLower) ||
                herd.category.lowercased().contains(searchLower) ||
                herd.species.lowercased().contains(searchLower) ||
                (herd.paddockName?.lowercased().contains(searchLower) ?? false) ||
                (herd.additionalInfo?.lowercased().contains(searchLower) ?? false)
            }
        }
        
        // Performance: Calculate valuations in background and update cache
        Task {
            await updateIndividualValuations(filteredIndividuals)
        }
    }
    
    // Performance: Calculate valuations for individual animals in batch
    private func updateIndividualValuations(_ individuals: [HerdGroup]) async {
        let prefs = preferences.first ?? UserPreferences()
        
        // Debug: Calculate valuations for each individual animal
        var displayData: [AnimalDisplayData] = []
        
        for individual in individuals {
            let valuation = await valuationEngine.calculateHerdValue(
                herd: individual,
                preferences: prefs,
                modelContext: modelContext
            )
            displayData.append(AnimalDisplayData(from: individual, valuation: valuation))
        }
        
        // Update cache on main thread
        await MainActor.run {
            cachedFilteredIndividuals = displayData
        }
    }
    
    // MARK: - Load Portfolio Summary (Parallelized)
    private func loadPortfolioSummary() async {
        // Debug: Only show loading indicator if we don't have a summary yet
        // This prevents flashing spinner when updating existing data
        let shouldShowLoader = portfolioSummary == nil
        
        if shouldShowLoader {
            await MainActor.run {
                self.isLoading = true
            }
        }
        
        // Performance: Only calculate valuations for herds (headCount > 1) in summary
        // Individual animals (headCount == 1) load their valuations on-demand when viewed
        let activeHerds = allHerds.filter { !$0.isSold && $0.headCount > 1 }
        let activeIndividuals = allHerds.filter { !$0.isSold && $0.headCount == 1 }
        let allActiveAssets = allHerds.filter { !$0.isSold } // For head count totals
        
        guard !allActiveAssets.isEmpty else {
            await MainActor.run {
                self.portfolioSummary = nil
                self.isLoading = false
            }
            return
        }
        
        // Debug: Get user preferences for ValuationEngine
        let prefs = preferences.first ?? UserPreferences()
        
        // Create a mapping of herd IDs to herds for later lookup
        let herdMap = Dictionary(uniqueKeysWithValues: activeHerds.map { ($0.id, $0) })
        
        // Calculate valuations using ValuationEngine (same as Dashboard for consistency)
        var results: [(herdId: UUID, valuation: HerdValuation)] = []
        
        for herd in activeHerds {
            // Performance: Check if task was cancelled
            if Task.isCancelled {
                #if DEBUG
                print("📊 Portfolio valuation cancelled - skipping remaining herds")
                #endif
                break
            }
            
            // Use ValuationEngine to ensure Portfolio and Dashboard match exactly
            let valuation = await valuationEngine.calculateHerdValue(
                herd: herd,
                preferences: prefs,
                modelContext: modelContext
            )
            
            results.append((herdId: herd.id, valuation: valuation))
        }
        
        // Aggregate results
        var valuations: [UUID: HerdValuation] = [:]
        var categoryBreakdown: [String: CategoryBreakdown] = [:]
        var speciesBreakdown: [String: SpeciesBreakdown] = [:]
        
        for entry in results {
            guard let herd = herdMap[entry.herdId] else { continue }
            let valuation = entry.valuation
            valuations[entry.herdId] = valuation
            
            if categoryBreakdown[herd.category] == nil {
                categoryBreakdown[herd.category] = CategoryBreakdown(
                    category: herd.category,
                    totalValue: 0,
                    headCount: 0,
                    physicalValue: 0,
                    breedingAccrual: 0
                )
            }
            categoryBreakdown[herd.category]!.totalValue += valuation.netRealizableValue
            categoryBreakdown[herd.category]!.headCount += herd.headCount
            categoryBreakdown[herd.category]!.physicalValue += valuation.physicalValue
            categoryBreakdown[herd.category]!.breedingAccrual += valuation.breedingAccrual
            
            if speciesBreakdown[herd.species] == nil {
                speciesBreakdown[herd.species] = SpeciesBreakdown(
                    species: herd.species,
                    totalValue: 0,
                    headCount: 0,
                    herdCount: 0
                )
            }
            speciesBreakdown[herd.species]!.totalValue += valuation.netRealizableValue
            speciesBreakdown[herd.species]!.headCount += herd.headCount
            speciesBreakdown[herd.species]!.herdCount += 1
        }
        
        // Totals
        let totalNetWorth = valuations.values.reduce(0) { $0 + $1.netRealizableValue }
        let totalPhysicalValue = valuations.values.reduce(0) { $0 + $1.physicalValue }
        let totalBreedingAccrual = valuations.values.reduce(0) { $0 + $1.breedingAccrual }
        let totalCostToCarry = valuations.values.reduce(0) { $0 + $1.costToCarry }
        let totalGrossValue = valuations.values.reduce(0) { $0 + $1.grossValue }
        let totalMortalityDeduction = valuations.values.reduce(0) { $0 + $1.mortalityDeduction }
        
        // Unrealized gains
        var totalInitialValue: Double = 0
        for entry in results {
            guard let herd = herdMap[entry.herdId] else { continue }
            let valuation = entry.valuation
            totalInitialValue += Double(herd.headCount) * herd.initialWeight * valuation.pricePerKg
        }
        let unrealizedGains = totalNetWorth - totalInitialValue
        let unrealizedGainsPercent = totalInitialValue > 0 ? (unrealizedGains / totalInitialValue) * 100 : 0
        
        // Largest category
        let largestCategory = categoryBreakdown.values.max(by: { $0.totalValue < $1.totalValue })
        let largestCategoryPercent = totalNetWorth > 0 ? ((largestCategory?.totalValue ?? 0) / totalNetWorth) * 100 : 0
        
        // Debug: Calculate separate head counts for herds and individuals
        let headInHerds = activeHerds.reduce(0) { $0 + $1.headCount }
        let headInIndividuals = activeIndividuals.reduce(0) { $0 + $1.headCount }
        let totalHeadCount = headInHerds + headInIndividuals
        
        await MainActor.run {
            self.portfolioSummary = PortfolioSummary(
                totalNetWorth: totalNetWorth,
                totalPhysicalValue: totalPhysicalValue,
                totalBreedingAccrual: totalBreedingAccrual,
                totalGrossValue: totalGrossValue,
                totalMortalityDeduction: totalMortalityDeduction,
                totalCostToCarry: totalCostToCarry,
                totalInitialValue: totalInitialValue,
                unrealizedGains: unrealizedGains,
                unrealizedGainsPercent: unrealizedGainsPercent,
                // Performance: Total head count includes all animals (herds + individuals)
                totalHeadCount: totalHeadCount,
                // Performance: Active herd count only includes actual herds (headCount > 1)
                activeHerdCount: activeHerds.count,
                headInHerds: headInHerds,
                headInIndividuals: headInIndividuals,
                categoryBreakdown: Array(categoryBreakdown.values),
                speciesBreakdown: Array(speciesBreakdown.values),
                largestCategory: largestCategory?.category ?? "",
                largestCategoryPercent: largestCategoryPercent,
                valuations: valuations
            )
            self.isLoading = false
        }
    }
}

// MARK: - Portfolio Summary Model
struct PortfolioSummary {
    let totalNetWorth: Double
    let totalPhysicalValue: Double
    let totalBreedingAccrual: Double
    let totalGrossValue: Double
    let totalMortalityDeduction: Double
    let totalCostToCarry: Double
    let totalInitialValue: Double
    let unrealizedGains: Double
    let unrealizedGainsPercent: Double
    let totalHeadCount: Int
    let activeHerdCount: Int
    let headInHerds: Int // Debug: Total head count in herds (headCount > 1)
    let headInIndividuals: Int // Debug: Total head count in individual animals (headCount == 1)
    let categoryBreakdown: [CategoryBreakdown]
    let speciesBreakdown: [SpeciesBreakdown]
    let largestCategory: String
    let largestCategoryPercent: Double
    let valuations: [UUID: HerdValuation]
}

struct CategoryBreakdown {
    var category: String
    var totalValue: Double
    var headCount: Int
    var physicalValue: Double
    var breedingAccrual: Double
}

struct SpeciesBreakdown {
    var species: String
    var totalValue: Double
    var headCount: Int
    var herdCount: Int
}

// MARK: - Portfolio Stats Cards
// Debug: Stacked cards showing total portfolio value, total head, and active herds
struct PortfolioStatsCards: View {
    let summary: PortfolioSummary?
    let isLoading: Bool
    
    // Calculate change from initial purchase cost
    private var totalChange: Double {
        (summary?.totalNetWorth ?? 0) - (summary?.totalInitialValue ?? 0)
    }
    
    private var percentageChange: Double {
        guard let summary = summary, summary.totalInitialValue > 0 else { return 0 }
        return (totalChange / summary.totalInitialValue) * 100
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Debug: Match Dashboard's PortfolioValueCard exactly for consistent positioning
            VStack(spacing: 0) {
                // Always show value (no loader overlay)
                AnimatedCurrencyValue(
                    value: summary?.totalNetWorth ?? 0,
                    isScrubbing: false
                )
                .frame(height: 58)
                .opacity(isLoading ? 0.5 : 1.0) // Subtle fade during loading
                .animation(.easeInOut(duration: 0.3), value: isLoading)
                .padding(.bottom, 8)
                .accessibilityLabel("Total portfolio value")
                
                // Change pill (matches Dashboard)
                HStack(spacing: 6) {
                    Image(systemName: totalChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(totalChange >= 0 ? Theme.positiveChange : Theme.negativeChange)
                        .accessibilityHidden(true)
                    
                    Text(totalChange, format: .currency(code: "AUD"))
                        .font(.system(size: 11, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(totalChange >= 0 ? Theme.positiveChange : Theme.negativeChange)
                    
                    Text("|")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle((totalChange >= 0 ? Theme.positiveChange : Theme.negativeChange).opacity(0.5))
                        .accessibilityHidden(true)
                    
                    Text("\(percentageChange >= 0 ? "+" : "")\(percentageChange, specifier: "%.2f")%")
                        .font(.system(size: 11, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(totalChange >= 0 ? Theme.positiveChange : Theme.negativeChange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(totalChange >= 0 ? Theme.positiveChangeBg : Theme.negativeChangeBg)
                )
                .fixedSize()
                .opacity(isLoading ? 0.3 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isLoading)
                .accessibilityLabel("Change since purchase")
                .accessibilityValue("\(totalChange.formatted(.currency(code: "AUD"))), \(percentageChange, specifier: "%.2f") percent")
            }
            .padding(.vertical, Theme.cardPadding)
            .frame(maxWidth: .infinity)
            
            // Debug: Combined stats card with 3-section horizontal layout - shows Herds, Head in Herds, and Head in Individuals
            HStack(spacing: 16) {
                // Section 1: Herds
                VStack(spacing: 4) {
                    Text("\(summary?.activeHerdCount ?? 0)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("Herds")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Divider 1
                Rectangle()
                    .fill(Theme.separator.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                // Section 2: Head in Herds
                VStack(spacing: 4) {
                    Text("\(summary?.headInHerds ?? 0)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("Head in Herds")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Divider 2
                Rectangle()
                    .fill(Theme.separator.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                // Section 3: Head in Individuals
                VStack(spacing: 4) {
                    Text("\(summary?.headInIndividuals ?? 0)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("Head in Individuals")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isLoading ? 0.3 : 1.0) // Fade during loading
        }
    }
}

// MARK: - View Mode Selector
// Debug: Using native segmented control for iOS HIG compliance with smooth sliding animation
struct PortfolioViewModeSelector: View {
    @Binding var selectedView: PortfolioView.PortfolioViewMode
    
    var body: some View {
        Picker("View Mode", selection: $selectedView) {
            ForEach(PortfolioView.PortfolioViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue)
                    .font(Theme.headline) // Debug: Larger font for better readability
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(height: 50) // Debug: Increased height for better tap target (taller than standard 44pt)
        .onChange(of: selectedView) { _, _ in
            HapticManager.tap()
        }
    }
}

// MARK: - Net Worth Card
struct NetWorthCard: View {
    let summary: PortfolioSummary
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Total Portfolio Value")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
            
            if isLoading {
                ProgressView()
                    .tint(Theme.accent)
            } else {
                Text(summary.totalNetWorth, format: .currency(code: "AUD"))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Divider()
                .background(Theme.separator)
            
            VStack(spacing: 12) {
                ValueBreakdownRow(
                    label: "Physical Value",
                    value: summary.totalPhysicalValue,
                    color: Theme.accent
                )
                
                if summary.totalBreedingAccrual > 0 {
                    ValueBreakdownRow(
                        label: "Breeding Accrual",
                        value: summary.totalBreedingAccrual,
                        color: Theme.positiveChange
                    )
                }
                
          
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

struct ValueBreakdownRow: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(value, format: .currency(code: "AUD"))
                .font(Theme.headline)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .layoutPriority(1)
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - Capital Concentration Card
// Debug: Removed largest category section per user request
struct CapitalConcentrationCard: View {
    let summary: PortfolioSummary
    @State private var categoryTimeRange: CategoryTimeRange = .current
    @State private var showingCustomDatePicker = false
    @State private var customStartDate: Date?
    @State private var customEndDate: Date?
    
    // Debug: Time range options for category breakdown
    // Note: Currently all options display the same current data; historical comparison planned
    enum CategoryTimeRange: String, CaseIterable {
        case current = "Current"
        case week = "Week Ago"
        case month = "Month Ago"
        case year = "Year Ago"
        case custom = "Custom"
        
        var displayLabel: String {
            switch self {
            case .current: return "Now"
            case .week: return "7d ago"
            case .month: return "1m ago"
            case .year: return "1y ago"
            case .custom: return "Custom"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Category Breakdown")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                
                // Debug: Time range selector menu
                Menu {
                    ForEach(CategoryTimeRange.allCases, id: \.self) { range in
                        Button {
                            HapticManager.tap()
                            if range == .custom {
                                showingCustomDatePicker = true
                            } else {
                                categoryTimeRange = range
                            }
                        } label: {
                            HStack {
                                Text(range.rawValue)
                                if categoryTimeRange == range {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(customDateRangeLabel)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Select category view time range")
                .accessibilityValue(categoryTimeRange.rawValue)
            }
            
            if !summary.categoryBreakdown.isEmpty {
                VStack(spacing: 12) {
                    ForEach(summary.categoryBreakdown.sorted(by: { $0.totalValue > $1.totalValue }).prefix(5), id: \.category) { category in
                        CategoryRow(
                            category: category.category,
                            value: category.totalValue,
                            headCount: category.headCount,
                            totalPortfolio: summary.totalNetWorth
                        )
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
        .sheet(isPresented: $showingCustomDatePicker) {
            CustomDateRangeSheet(
                startDate: $customStartDate,
                endDate: $customEndDate,
                timeRange: Binding(
                    get: { 
                        categoryTimeRange == .custom ? .custom : .week 
                    },
                    set: { _ in 
                        categoryTimeRange = .custom 
                    }
                )
            )
        }
    }
    
    // Debug: Format custom date range label
    private var customDateRangeLabel: String {
        if categoryTimeRange == .custom,
           let start = customStartDate,
           let end = customEndDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
        return categoryTimeRange.displayLabel
    }
}

struct CategoryRow: View {
    let category: String
    let value: Double
    let headCount: Int
    let totalPortfolio: Double
    
    var percentage: Double {
        guard totalPortfolio > 0 else { return 0 }
        return (value / totalPortfolio) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category)
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                Spacer()
                Text(value, format: .currency(code: "AUD"))
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .layoutPriority(1)
            }
            .padding(.horizontal, 6)

            HStack {
                Text("\(headCount) head")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Text("\(percentage, format: .number.precision(.fractionLength(1)))%")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.accent)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.primaryText.opacity(0.1))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.accent.opacity(0.6))
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Performance Metrics Card
// Debug: Removed Head and Active Herds metrics - now shown at top
struct PerformanceMetricsCard: View {
    let summary: PortfolioSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance Tracking")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            HStack {
                Text("Unrealized Gains")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(summary.unrealizedGains, format: .currency(code: "AUD"))
                        .font(Theme.headline)
                        .foregroundStyle(summary.unrealizedGains >= 0 ? Theme.positiveChange : Theme.negativeChange)
                    Text("\(summary.unrealizedGainsPercent >= 0 ? "+" : "")\(summary.unrealizedGainsPercent, format: .number.precision(.fractionLength(1)))%")
                        .font(Theme.caption)
                        .foregroundStyle(summary.unrealizedGainsPercent >= 0 ? Theme.positiveChange : Theme.negativeChange)
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Theme.accent)
            Text(value)
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
            Text(title)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Asset Breakdown Card
struct AssetBreakdownCard: View {
    let summary: PortfolioSummary
    @State private var assetTimeRange: AssetTimeRange = .current
    @State private var showingCustomDatePicker = false
    @State private var customStartDate: Date?
    @State private var customEndDate: Date?
    
    // Debug: Time range options for asset breakdown
    // Note: Currently all options display the same current data; historical comparison planned
    enum AssetTimeRange: String, CaseIterable {
        case current = "Current"
        case week = "Week Ago"
        case month = "Month Ago"
        case year = "Year Ago"
        case custom = "Custom"
        
        var displayLabel: String {
            switch self {
            case .current: return "Now"
            case .week: return "7d ago"
            case .month: return "1m ago"
            case .year: return "1y ago"
            case .custom: return "Custom"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Asset Breakdown")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                
                // Debug: Time range selector menu
                Menu {
                    ForEach(AssetTimeRange.allCases, id: \.self) { range in
                        Button {
                            HapticManager.tap()
                            if range == .custom {
                                showingCustomDatePicker = true
                            } else {
                                assetTimeRange = range
                            }
                        } label: {
                            HStack {
                                Text(range.rawValue)
                                if assetTimeRange == range {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(customDateRangeLabel)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Select asset view time range")
                .accessibilityValue(assetTimeRange.rawValue)
            }
            
            if !summary.speciesBreakdown.isEmpty {
                VStack(spacing: 12) {
                    ForEach(summary.speciesBreakdown.sorted(by: { $0.totalValue > $1.totalValue }), id: \.species) { species in
                        SpeciesRow(
                            species: species.species,
                            value: species.totalValue,
                            headCount: species.headCount,
                            herdCount: species.herdCount,
                            totalPortfolio: summary.totalNetWorth
                        )
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
        .sheet(isPresented: $showingCustomDatePicker) {
            CustomDateRangeSheet(
                startDate: $customStartDate,
                endDate: $customEndDate,
                timeRange: Binding(
                    get: { 
                        assetTimeRange == .custom ? .custom : .week 
                    },
                    set: { _ in 
                        assetTimeRange = .custom 
                    }
                )
            )
        }
    }
    
    // Debug: Format custom date range label
    private var customDateRangeLabel: String {
        if assetTimeRange == .custom,
           let start = customStartDate,
           let end = customEndDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
        return assetTimeRange.displayLabel
    }
}

struct SpeciesRow: View {
    let species: String
    let value: Double
    let headCount: Int
    let herdCount: Int
    let totalPortfolio: Double
    
    var percentage: Double {
        guard totalPortfolio > 0 else { return 0 }
        return (value / totalPortfolio) * 100
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(species)
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
                Text("\(herdCount) herd\(herdCount == 1 ? "" : "s") • \(headCount) head")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(value, format: .currency(code: "AUD"))
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .layoutPriority(1)
                Text("\(percentage, format: .number.precision(.fractionLength(1)))%")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.vertical, 8)
    }
}



// MARK: - Asset Register Header
struct AssetRegisterHeader: View {
    let summary: PortfolioSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Asset Register")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            Text("\(summary.activeHerdCount) active herd\(summary.activeHerdCount == 1 ? "" : "s") • \(summary.totalHeadCount) total head")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

    // MARK: - Animal Display Data
// Performance: Simple struct to hold display data, breaking SwiftData observation
struct AnimalDisplayData: Identifiable, Equatable {
    let id: UUID
    let displayName: String // Formatted name with ID number for individuals
    let species: String
    let breed: String
    let category: String
    let paddockName: String?
    let selectedSaleyard: String?
    let currentWeight: Double
    let additionalInfo: String?
    let totalValue: Double // Pre-calculated valuation
    let pricePerKg: Double // Market price
    let isBreeder: Bool
    
    init(from herd: HerdGroup, valuation: HerdValuation?) {
        self.id = herd.id
        self.displayName = herd.displayName // Uses computed property for formatting
        self.species = herd.species
        self.breed = herd.breed
        self.category = herd.category
        self.selectedSaleyard = herd.selectedSaleyard
        self.isBreeder = herd.isBreeder
        self.paddockName = herd.paddockName
        self.currentWeight = herd.currentWeight
        self.additionalInfo = herd.additionalInfo
        self.totalValue = valuation?.netRealizableValue ?? 0
        self.pricePerKg = valuation?.pricePerKg ?? 0
    }
}

// MARK: - Lightweight Animal Card
// Performance: Uses plain struct instead of SwiftData model to avoid observation overhead
struct LightweightAnimalCard: View {
    let data: AnimalDisplayData
    @State private var showingSellSheet = false
    
    var body: some View {
        NavigationLink(destination: HerdDetailView(herdId: data.id)) {
            VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Text(data.displayName)
                            .font(Theme.headline)
                            .foregroundStyle(Theme.accent)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText.opacity(0.6))
                    }
                    
                    // Row 2: Species/Breed/Category
                    Text("\(data.species) | \(data.breed) | \(data.category)")
                        .font(Theme.subheadline) // Debug: Bigger font for better readability
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                    
                    // Divider
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Theme.separator.opacity(0.15))
                
                    // Row 3: Location and Value
                    HStack {
                        if let paddock = data.paddockName, !paddock.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 12)) // Debug: Slightly bigger icon
                                Text(paddock)
                            }
                            .font(Theme.subheadline) // Debug: Bigger font for better readability
                            .foregroundStyle(Theme.secondaryText.opacity(0.8))
                        }
                        Spacer()
                        if data.totalValue > 0 {
                            Text(data.totalValue, format: .currency(code: "AUD"))
                                .font(Theme.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    
                    // Row 4: Breeder info and Weight/Price
                    HStack {
                        if data.isBreeder {
                            HStack(spacing: 4) {
                                Image("chick")
                                    .resizable()
                                    .renderingMode(.template)
                                    .frame(width: 12, height: 12) // Debug: Slightly bigger icon
                                Text("Breeder")
                            }
                            .font(Theme.subheadline) // Debug: Bigger font for better readability
                            .foregroundStyle(Theme.secondaryText.opacity(0.8))
                        }
                        Spacer()
                        Text("\(Int(data.currentWeight)) kg @ \(data.pricePerKg, format: .currency(code: "AUD"))")
                            .font(Theme.subheadline) // Debug: Bigger font for better readability
                            .foregroundStyle(Theme.secondaryText)
                    }
                    
                    // Row 5: Saleyard and Sell Button
                    HStack(alignment: .center) {
                        if let saleyard = data.selectedSaleyard, !saleyard.isEmpty {
                            HStack(spacing: 4) {
                                Image("property_icon")
                                    .resizable()
                                    .renderingMode(.template)
                                    .frame(width: 10, height: 10)
                                Text(saleyard)
                            }
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText.opacity(0.8))
                            .lineLimit(1)
                        }
                        Spacer()
                        // Sell button - matching herd card style
                        Button {
                            HapticManager.tap()
                            showingSellSheet = true
                        } label: {
                            Text("Sell")
                                .font(.system(size: 12))
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Theme.accent.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Theme.accent, lineWidth: 0.8)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(Theme.cardPadding)
        .stitchedCard()
        .sheet(isPresented: $showingSellSheet) {
            SellStockView(preselectedHerdId: data.id)
        }
    }
}

// MARK: - Enhanced Herd Card
// Debug: Clear layout showing all essential herd information with optional sell button
// Layout: name, headcount, saleyard, weights, prices in logical hierarchy
// Performance: Uses cached valuations from summary to avoid expensive calculations on scroll
struct EnhancedHerdCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject
    let valuationEngine = ValuationEngine.shared
    let herd: HerdGroup
    let summary: PortfolioSummary
    var onSellTapped: (() -> Void)? = nil // Debug: Optional callback for sell action
    
    @State private var valuation: HerdValuation?
    @State private var isLoading = true
    
    // Performance: Track if we've started loading to prevent duplicate tasks
    @State private var hasStartedLoading = false
    
    var body: some View {
        // Debug: Capture herd properties early to avoid potential SwiftData access issues
        let herdId = herd.id
        let herdDisplayName = herd.displayName
        let herdHeadCount = herd.headCount
        let herdSpecies = herd.species
        let herdBreed = herd.breed
        let herdCategory = herd.category
        let herdLocation = herd.paddockName
        let herdSaleyard = herd.selectedSaleyard
        let isBreeder = herd.isBreeder
        
        NavigationLink(destination: HerdDetailView(herdId: herdId)) {
            VStack(alignment: .leading, spacing: 12) {
                // Top Row: Herd Name (left, orange) and Chevron (right)
                HStack(alignment: .top) {
                    Text(herdDisplayName)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.accent)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText.opacity(0.6))
                }
                
                // Row 2: Species/Breed/Category
                Text("\(herdSpecies) | \(herdBreed) | \(herdCategory)")
                    .font(Theme.subheadline) // Debug: Bigger font for better readability
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
                
                // Divider
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Theme.separator.opacity(0.15))
                
                // Row 3: Location and Value
                HStack {
                    if let location = herdLocation, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 12)) // Debug: Slightly bigger icon
                            Text(location)
                        }
                        .font(Theme.subheadline) // Debug: Bigger font for better readability
                        .foregroundStyle(Theme.secondaryText.opacity(0.8))
                    }
                    Spacer()
                    if let valuation = valuation {
                        Text(valuation.netRealizableValue, format: .currency(code: "AUD"))
                            .font(Theme.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.accent)
                    } else if isLoading {
                        ProgressView()
                            .tint(Theme.accent)
                            .scaleEffect(0.8)
                    }
                }
                
                // Head Count, Breeder info, and Weight/Price Row
                if let valuation = valuation {
                    HStack(alignment: .center) {
                        HStack(spacing: 4) {
                            Image("cowhead")
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: 12, height: 12) // Debug: Slightly bigger icon
                            Text("\(herdHeadCount) head")
                        }
                        .font(Theme.subheadline) // Debug: Bigger font for better readability
                        .foregroundStyle(Theme.secondaryText.opacity(0.8))
                        
                        if isBreeder {
                            HStack(spacing: 4) {
                                Image("chick")
                                    .resizable()
                                    .renderingMode(.template)
                                    .frame(width: 12, height: 12) // Debug: Slightly bigger icon
                                Text("Breeder")
                            }
                            .font(Theme.subheadline) // Debug: Bigger font for better readability
                            .foregroundStyle(Theme.secondaryText.opacity(0.8))
                            .padding(.leading, 8)
                        }
                        
                        Spacer()
                        Text("\(Int(valuation.projectedWeight)) kg @ \(valuation.pricePerKg, format: .currency(code: "AUD"))")
                            .font(Theme.subheadline) // Debug: Bigger font for better readability
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                
                // Saleyard and Sell Button Row
                HStack(alignment: .center) {
                    if let saleyard = herdSaleyard, !saleyard.isEmpty {
                        HStack(spacing: 4) {
                            Image("property_icon")
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: 10, height: 10)
                            Text(saleyard)
                        }
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText.opacity(0.8))
                        .lineLimit(1)
                    }
                    Spacer()
                    if onSellTapped != nil {
                        Button {
                            HapticManager.tap()
                            if let callback = onSellTapped {
                                callback()
                            }
                        } label: {
                            Text("Sell")
                                .font(.system(size: 12))
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Theme.accent.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Theme.accent, lineWidth: 0.8)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
        .onAppear {
            // Performance: Load valuation only when card appears, and only once
            if !hasStartedLoading {
                hasStartedLoading = true
                Task {
                    await loadValuation()
                }
            }
        }
    }
    
    private func loadValuation() async {
        // Performance: Check cache first (instant if available)
        if let cachedValuation = summary.valuations[herd.id] {
            await MainActor.run {
                self.valuation = cachedValuation
                self.isLoading = false
            }
        } else {
            // Performance: Calculate on-demand only if not cached (rare for filtered lists)
            let prefs = preferences.first ?? UserPreferences()
            let calculatedValuation = await valuationEngine.calculateHerdValue(
                herd: herd,
                preferences: prefs,
                modelContext: modelContext
            )
            await MainActor.run {
                self.valuation = calculatedValuation
                self.isLoading = false
            }
        }
    }
}

struct ValuationDetailRow: View {
    let label: String
    let value: Any
    var color: Color = Theme.primaryText
    var isText: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(1)

            Spacer(minLength: 8)

            if isText {
                Text(value as? String ?? "")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .layoutPriority(1)
            } else if let doubleValue = value as? Double {
                Text(doubleValue, format: .currency(code: "AUD"))
                    .font(Theme.caption)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - Empty Portfolio View
struct EmptyPortfolioView: View {
    @Binding var showingAddAssetMenu: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.primaryText.opacity(0.3))
            
            Text("No Assets Yet")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
            
            Text("Add your first herd, animal, or import from CSV to start tracking portfolio value")
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Debug: Per iOS HIG - Use .borderedProminent for primary CTA in empty states
            Button("Add Asset") {
                HapticManager.tap()
                showingAddAssetMenu = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .controlSize(.large)
            .accessibilityLabel("Add asset")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Portfolio Search Panel
// Debug: Search form for finding animals by NLIS/tag numbers or herd details
struct PortfolioSearchPanel: View {
    @Environment(\.dismiss) private var dismiss
    let herds: [HerdGroup]
    
    @State private var nlisTagNumber = ""
    @State private var selectedSpecies: String? = nil
    @State private var selectedPaddock: String? = nil
    @State private var searchResults: [HerdGroup] = []
    @State private var hasSearched = false
    
    // Debug: Get unique species and paddocks from herds for filter options
    var availableSpecies: [String] {
        Array(Set(herds.filter { !$0.isSold }.map { $0.species })).sorted()
    }
    
    var availablePaddocks: [String] {
        Array(Set(herds.filter { !$0.isSold }.compactMap { $0.paddockName }.filter { !$0.isEmpty })).sorted()
    }
    
    // Debug: Perform search based on NLIS tag, species, and paddock filters
    func performSearch() {
        hasSearched = true
        let activeHerds = herds.filter { !$0.isSold }
        
        // If no search criteria, show nothing
        guard !nlisTagNumber.isEmpty || selectedSpecies != nil || selectedPaddock != nil else {
            searchResults = []
            return
        }
        
        searchResults = activeHerds.filter { herd in
            var matches = true
            
            // Filter by NLIS/tag number in name or additional info
            if !nlisTagNumber.isEmpty {
                let lowercasedTag = nlisTagNumber.lowercased()
                let nameMatch = herd.name.lowercased().contains(lowercasedTag)
                let infoMatch = herd.additionalInfo?.lowercased().contains(lowercasedTag) ?? false
                matches = matches && (nameMatch || infoMatch)
            }
            
            // Filter by species
            if let species = selectedSpecies {
                matches = matches && (herd.species == species)
            }
            
            // Filter by paddock
            if let paddock = selectedPaddock {
                matches = matches && (herd.paddockName == paddock)
            }
            
            return matches
        }
    }
    
    func clearSearch() {
        nlisTagNumber = ""
        selectedSpecies = nil
        selectedPaddock = nil
        searchResults = []
        hasSearched = false
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    // Search Form Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Find Animals")
                            .font(Theme.title)
                            .foregroundStyle(Theme.primaryText)
                        Text("Search by NLIS tag, animal ID, or use filters below")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Search Form Card
                    VStack(alignment: .leading, spacing: 20) {
                        // NLIS/Tag Number Input
                        // Debug: Consistent text field styling with rest of app
                        VStack(alignment: .leading, spacing: 12) {
                            Text("NLIS Tag / Animal ID")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            TextField("Enter tag number or ID", text: $nlisTagNumber)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.characters)
                                .keyboardType(.default)
                                .submitLabel(.search)
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .onSubmit {
                                    performSearch()
                                }
                        }
                        
                        Divider()
                            .background(Theme.separator)
                        
                        // Optional Filters
                        Text("Optional Filters")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        
                        // Species Filter
                        if !availableSpecies.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Species")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                
                                Picker("Species", selection: $selectedSpecies) {
                                    Text("All Species").tag(nil as String?)
                                    ForEach(availableSpecies, id: \.self) { species in
                                        Text(species).tag(species as String?)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        // Paddock Filter
                        if !availablePaddocks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Paddock")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                
                                Picker("Paddock", selection: $selectedPaddock) {
                                    Text("All Paddocks").tag(nil as String?)
                                    ForEach(availablePaddocks, id: \.self) { paddock in
                                        Text(paddock).tag(paddock as String?)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        
                        // Debug: Per iOS HIG - Use bordered button styles for actions within content
                        HStack(spacing: 12) {
                            Button {
                                HapticManager.tap()
                                performSearch()
                            } label: {
                                Label("Search", systemImage: "magnifyingglass")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                            .frame(maxWidth: .infinity)
                            
                            if hasSearched {
                                Button {
                                    HapticManager.tap()
                                    clearSearch()
                                } label: {
                                    Label("Clear", systemImage: "xmark")
                                }
                                .buttonStyle(.bordered)
                                .tint(Theme.accent)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(Theme.cardPadding)
                    .stitchedCard()
                    .padding(.horizontal)
                    
                    // Search Results
                    if hasSearched {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(searchResults.count) Result\(searchResults.count == 1 ? "" : "s")")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                                .padding(.horizontal)
                            
                            if searchResults.isEmpty {
                                // No results
                                VStack(spacing: 16) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.5))
                                    
                                    Text("No animals found")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                    
                                    Text("Try adjusting your search criteria")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                // Results list
                                LazyVStack(spacing: 12) {
                                    ForEach(searchResults, id: \.id) { herd in
                                        SearchResultCard(herd: herd)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Search Animals")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Search Result Card
// Debug: Display search result with herd/animal details
struct SearchResultCard: View {
    let herd: HerdGroup
    
    var isIndividualAnimal: Bool {
        herd.headCount == 1
    }
    
    var body: some View {
        // Debug: Capture herd properties early to avoid SwiftData access issues
        let herdId = herd.id
        let herdName = herd.name
        let herdHeadCount = herd.headCount
        let herdBreed = herd.breed
        let herdCategory = herd.category
        let herdPaddock = herd.paddockName
        let herdInfo = herd.additionalInfo
        
        NavigationLink(destination: HerdDetailView(herdId: herdId)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        // Name with tag indicator
                        HStack(spacing: 8) {
                            Text(herdName)
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            if isIndividualAnimal {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        
                        // Details
                        Text("\(herdHeadCount) head • \(herdBreed) \(herdCategory)")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        
                        // Paddock location
                        if let paddock = herdPaddock, !paddock.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.secondaryText)
                                Text(paddock)
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                        
                        // Additional info (may contain NLIS/tag details)
                        if let info = herdInfo, !info.isEmpty {
                            Text(info)
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText.opacity(0.5))
                }
            }
            .padding(Theme.cardPadding)
        }
        .buttonStyle(PlainButtonStyle())
        .stitchedCard()
    }
}

// MARK: - Search Field
// Debug: Reusable search text field for Herds and Individual sections
struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.secondaryText)
                .font(.system(size: 16))
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            // Debug: Show clear button when text is not empty
            if !text.isEmpty {
                Button {
                    HapticManager.tap()
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.secondaryText)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.inputFieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Empty Search Result View
// Debug: Display when no search results are found
struct EmptySearchResultView: View {
    let searchText: String
    let type: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "tray.fill" : "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Theme.secondaryText.opacity(0.5))
            
            Text(searchText.isEmpty ? "No \(type) found" : "No results for \"\(searchText)\"")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            Text(searchText.isEmpty ? "Add \(type) to see them here" : "Try a different search term")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Floating Sell Button
// Debug: Prominent floating action button for selling stock at bottom of Herds/Individual pages
struct FloatingSellButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.tap()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Sell Stock")
                    .font(Theme.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Theme.accent)
                    .shadow(color: Theme.accent.opacity(0.4), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sell stock")
    }
}


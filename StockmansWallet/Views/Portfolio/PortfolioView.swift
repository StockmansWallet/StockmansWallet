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
    @Query(sort: \HerdGroup.updatedAt, order: .reverse) private var herds: [HerdGroup]
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject
    let valuationEngine = ValuationEngine.shared
    
    @State private var showingAddAssetMenu = false
    @State private var showingSearchPanel = false
    @State private var portfolioSummary: PortfolioSummary?
    @State private var isLoading = true
    @State private var selectedView: PortfolioViewMode = .overview
    
    enum PortfolioViewMode: String, CaseIterable {
        case overview = "Overview"
        case assets = "Assets"
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if herds.isEmpty {
                    EmptyPortfolioView(showingAddAssetMenu: $showingAddAssetMenu)
                } else {
                    ScrollView {
                        VStack(spacing: Theme.sectionSpacing) {
                            // Debug: Portfolio stats cards stacked at the top
                            if let summary = portfolioSummary {
                                PortfolioStatsCards(summary: summary, isLoading: isLoading)
                                    .padding(.horizontal)
                            }
                            
                            // View Mode Selector
                            PortfolioViewModeSelector(selectedView: $selectedView)
                                .padding(.horizontal)
                            
                            if selectedView == .overview {
                                overviewContent
                            } else {
                                assetsContent
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 100)
                    }
                    .scrollContentBackground(.hidden) // iOS 26: keep bar transparent, content draws behind
                    .background(Theme.backgroundGradient) // content background
                    .refreshable {
                        await loadPortfolioSummary()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Portfolio")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
                
                // Debug: Per Apple HIG - Search (secondary action) on left, Add (primary action) on right
                // This creates clear visual hierarchy and follows iOS conventions
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
                    // Debug: Per iOS HIG - Use .borderedProminent for primary toolbar action
                    // Creates a filled, tinted button that stands out as the main CTA
                    Button("Manage") {
                        HapticManager.tap()
                        showingAddAssetMenu = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .accessibilityLabel("Manage Stock")
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .fullScreenCover(isPresented: $showingAddAssetMenu) {
                AddAssetMenuView(isPresented: $showingAddAssetMenu)
                    .transition(.move(edge: .trailing))
                    .presentationBackground(Theme.sheetBackground)
            }
            .sheet(isPresented: $showingSearchPanel) {
                PortfolioSearchPanel(herds: herds)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Theme.sheetBackground)
            }
            .task {
                await loadPortfolioSummary()
            }
            .onChange(of: herds.count) { _, _ in
                Task {
                    await loadPortfolioSummary()
                }
            }
            // Keep gradient off the nav bar edges to preserve the iOS 26 transparent bar visuals
            .background(Theme.backgroundGradient.ignoresSafeArea(edges: [.horizontal, .bottom]))
        }
    }
    
    // MARK: - Overview Content
    private var overviewContent: some View {
        Group {
            if let summary = portfolioSummary {
                // Debug: Asset Breakdown moved above Capital Concentration per user request
                AssetBreakdownCard(summary: summary)
                    .padding(.horizontal)
                
                CapitalConcentrationCard(summary: summary)
                    .padding(.horizontal)
                
             
            } else if isLoading {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
    
    // MARK: - Assets Content
    // Debug: Removed AssetRegisterHeader as stats now shown above view selector
    private var assetsContent: some View {
        Group {
            if let summary = portfolioSummary {
                LazyVStack(spacing: 16) {
                    ForEach(herds.filter { !$0.isSold }) { herd in
                        EnhancedHerdCard(herd: herd, summary: summary)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Load Portfolio Summary (Parallelized)
    private func loadPortfolioSummary() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        let prefs = preferences.first ?? UserPreferences()
        let activeHerds = herds.filter { !$0.isSold }
        
        guard !activeHerds.isEmpty else {
            await MainActor.run {
                self.portfolioSummary = nil
                self.isLoading = false
            }
            return
        }
        
        // Create a mapping of herd IDs to herds for later lookup
        let herdMap = Dictionary(uniqueKeysWithValues: activeHerds.map { ($0.id, $0) })
        
        let results = await withTaskGroup(of: (herdId: UUID, valuation: HerdValuation).self) { group in
            var out: [(herdId: UUID, valuation: HerdValuation)] = []
            for herd in activeHerds {
                let herdId = herd.id
                let persistentId = herd.persistentModelID
                group.addTask { @MainActor [modelContext] in
                    // Fetch herd using persistentModelID to avoid Sendable issues
                    guard let fetchedHerd = modelContext.model(for: persistentId) as? HerdGroup else {
                        return (herdId: herdId, valuation: HerdValuation(
                            herdId: herdId,
                            physicalValue: 0,
                            breedingAccrual: 0,
                            grossValue: 0,
                            mortalityDeduction: 0,
                            netValue: 0,
                            costToCarry: 0,
                            netRealizableValue: 0,
                            pricePerKg: 0,
                            priceSource: "Unknown",
                            projectedWeight: 0,
                            valuationDate: Date()
                        ))
                    }
                    let valuation = await self.valuationEngine.calculateHerdValue(
                        herd: fetchedHerd,
                        preferences: prefs,
                        modelContext: modelContext
                    )
                    return (herdId: herdId, valuation: valuation)
                }
            }
            for await item in group {
                out.append(item)
            }
            return out
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
                totalHeadCount: activeHerds.reduce(0) { $0 + $1.headCount },
                activeHerdCount: activeHerds.count,
                categoryBreakdown: Array(categoryBreakdown.values),
                speciesBreakdown: Array(speciesBreakdown.values),
                largestCategory: largestCategory?.category ?? "",
                largestCategoryPercent: largestCategoryPercent,
                valuations: valuations
            )
            self.isLoading = false
            HapticManager.success()
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
    let summary: PortfolioSummary
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Total Portfolio Value Card (full width, prominent)
            VStack(spacing: 8) {
                Text("Total Portfolio Value")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                
                if isLoading {
                    ProgressView()
                        .tint(Theme.accent)
                } else {
                    Text(summary.totalNetWorth, format: .currency(code: "AUD"))
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // Total Head and Active Herds Cards (side by side)
            HStack(spacing: 16) {
                // Total Head
                VStack(spacing: 8) {
                    Text("Total Head")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Text("\(summary.totalHeadCount)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // Active Herds
                VStack(spacing: 8) {
                    Text("Active Herds")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Text("\(summary.activeHerdCount)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
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
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Category Breakdown")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
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
// Debug: Removed Total Head and Active Herds metrics - now shown at top
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Asset Breakdown")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
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
                Text("\(herdCount) mob\(herdCount == 1 ? "" : "s") • \(headCount) head")
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
            
            Text("\(summary.activeHerdCount) active mob\(summary.activeHerdCount == 1 ? "" : "s") • \(summary.totalHeadCount) total head")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

// MARK: - Enhanced Herd Card
// Debug: Clear layout showing all essential herd information
// Layout: name, headcount, saleyard, weights, prices in logical hierarchy
struct EnhancedHerdCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject
    let valuationEngine = ValuationEngine.shared
    let herd: HerdGroup
    let summary: PortfolioSummary
    
    @State private var valuation: HerdValuation?
    @State private var isLoading = true
    
    var body: some View {
        // Debug: Capture herd ID early to avoid potential SwiftData access issues in NavigationLink
        let herdId = herd.id
        let herdName = herd.name
        
        NavigationLink(destination: HerdDetailView(herdId: herdId)) {
            VStack(alignment: .leading, spacing: 12) {
                // Top Row: Herd Name (left, orange) and Chevron (right)
                HStack {
                    Text(herdName)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.accent)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText.opacity(0.6))
                }
                
                // Divider
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Theme.separator.opacity(0.15))
                
                // Headcount and Total Price Row
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Headcount")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text("\(herd.headCount) head")
                            .font(Theme.subheadline)
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total Value")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        
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
                }
                
                // Saleyard Row
                if let saleyard = herd.selectedSaleyard, !saleyard.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.secondaryText)
                        Text(saleyard)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                
                // Average Weight and Average Price Row
                if let valuation = valuation {
                    HStack(spacing: 20) {
                        // Average Weight
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Avg Weight")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            Text("\(Int(valuation.projectedWeight)) kg")
                                .font(Theme.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        
                        // Average Price
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Avg Price")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            Text(valuation.pricePerKg, format: .currency(code: "AUD"))
                                .font(Theme.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                            + Text("/kg")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
            }
            .padding(Theme.cardPadding)
        }
        .buttonStyle(PlainButtonStyle())
        .stitchedCard()
        .task {
            await loadValuation()
        }
    }
    
    private func loadValuation() async {
        if let cachedValuation = summary.valuations[herd.id] {
            await MainActor.run {
                self.valuation = cachedValuation
                self.isLoading = false
            }
        } else {
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


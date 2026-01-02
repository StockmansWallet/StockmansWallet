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
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
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
                // Use a standard bar button style and symbol per Apple HIG.
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        HapticManager.tap()
                        showingAddAssetMenu = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .accessibilityLabel("Add asset")
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .fullScreenCover(isPresented: $showingAddAssetMenu) {
                AddAssetMenuView(isPresented: $showingAddAssetMenu)
                    .transition(.move(edge: .trailing))
            }
            .task {
                await loadPortfolioSummary()
            }
            .onChange(of: herds.count) { _, _ in
                Task {
                    await loadPortfolioSummary()
                }
            }
            .background(Theme.background.ignoresSafeArea())
        }
    }
    
    // MARK: - Overview Content
    private var overviewContent: some View {
        Group {
            if let summary = portfolioSummary {
                NetWorthCard(summary: summary, isLoading: isLoading)
                    .padding(.horizontal)
                
                CapitalConcentrationCard(summary: summary)
                    .padding(.horizontal)
                
                PerformanceMetricsCard(summary: summary)
                    .padding(.horizontal)
                
                AssetBreakdownCard(summary: summary)
                    .padding(.horizontal)
                
                CostToCarryCard(summary: summary)
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
    private var assetsContent: some View {
        Group {
            if let summary = portfolioSummary {
                AssetRegisterHeader(summary: summary)
                    .padding(.horizontal)
                
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

// MARK: - View Mode Selector
struct PortfolioViewModeSelector: View {
    @Binding var selectedView: PortfolioView.PortfolioViewMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(PortfolioView.PortfolioViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    HapticManager.tap()
                    selectedView = mode
                }) {
                    Text(mode.rawValue)
                        .font(Theme.headline)
                        .foregroundStyle(selectedView == mode ? Theme.accent : Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedView == mode ? Theme.accent.opacity(0.15) : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonBorderShape(.roundedRectangle)
            }
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                        color: .green
                    )
                }
                
                ValueBreakdownRow(
                    label: "Cost to Carry",
                    value: -summary.totalCostToCarry,
                    color: .red
                )
                
                ValueBreakdownRow(
                    label: "Mortality Deduction",
                    value: -summary.totalMortalityDeduction,
                    color: .orange
                )
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
struct CapitalConcentrationCard: View {
    let summary: PortfolioSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Capital Concentration")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            if !summary.largestCategory.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Largest Category")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Spacer()
                        Text("\(summary.largestCategoryPercent, format: .number.precision(.fractionLength(1)))%")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.accent)
                    }
                    
                    Text(summary.largestCategory)
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.primaryText.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.accent)
                                .frame(width: geometry.size.width * CGFloat(summary.largestCategoryPercent / 100), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
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
                .padding(.top, 8)
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
            
            VStack(spacing: 12) {
                HStack {
                    Text("Unrealized Gains")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(summary.unrealizedGains, format: .currency(code: "AUD"))
                            .font(Theme.headline)
                            .foregroundStyle(summary.unrealizedGains >= 0 ? .green : .red)
                        Text("\(summary.unrealizedGainsPercent >= 0 ? "+" : "")\(summary.unrealizedGainsPercent, format: .number.precision(.fractionLength(1)))%")
                            .font(Theme.caption)
                            .foregroundStyle(summary.unrealizedGainsPercent >= 0 ? .green : .red)
                    }
                }
                
                Divider()
                    .background(Theme.separator)
                
                HStack(spacing: 16) {
                    MetricTile(
                        title: "Total Head",
                        value: "\(summary.totalHeadCount)",
                        icon: "person.3.fill"
                    )
                    
                    MetricTile(
                        title: "Active Mobs",
                        value: "\(summary.activeHerdCount)",
                        icon: "square.stack.3d.up.fill"
                    )
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

// MARK: - Cost to Carry Card
struct CostToCarryCard: View {
    let summary: PortfolioSummary
    
    var netMargin: Double {
        summary.totalNetWorth
    }
    
    var marginPercent: Double {
        summary.totalGrossValue > 0 ? (netMargin / summary.totalGrossValue) * 100 : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Profitability Analysis")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            VStack(spacing: 12) {
                ProfitabilityRow(
                    label: "Gross Value",
                    value: summary.totalGrossValue,
                    color: Theme.primaryText
                )
                
                ProfitabilityRow(
                    label: "Cost to Carry",
                    value: -summary.totalCostToCarry,
                    color: .red
                )
                
                ProfitabilityRow(
                    label: "Mortality Deduction",
                    value: -summary.totalMortalityDeduction,
                    color: .orange
                )
                
                Divider()
                    .background(Theme.separator)
                
                ProfitabilityRow(
                    label: "Net Realizable Value",
                    value: netMargin,
                    color: netMargin >= 0 ? .green : .red
                )
                
                HStack {
                    Text("Net Margin")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text("\(marginPercent >= 0 ? "+" : "")\(marginPercent, format: .number.precision(.fractionLength(1)))%")
                        .font(Theme.headline)
                        .foregroundStyle(marginPercent >= 0 ? .green : .red)
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

struct ProfitabilityRow: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
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
// Debug: Individual herd card with valuation display
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
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(herd.name)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Text("\(herd.headCount) head • \(herd.breed) \(herd.category)")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Spacer()
                
                if let valuation = valuation {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(valuation.netRealizableValue, format: .currency(code: "AUD"))
                            .font(Theme.headline)
                            .foregroundStyle(Theme.accent)
                        Text("\(Int(valuation.projectedWeight))kg avg")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                } else if isLoading {
                    ProgressView()
                        .tint(Theme.accent)
                }
            }
            
            Divider()
                .background(Theme.separator)
            
            // Valuation Details
            if let valuation = valuation {
                VStack(spacing: 10) {
                    ValuationDetailRow(
                        label: "Physical Value",
                        value: valuation.physicalValue,
                        color: Theme.accent
                    )
                    
                    if valuation.breedingAccrual > 0 {
                        ValuationDetailRow(
                            label: "Breeding Accrual",
                            value: valuation.breedingAccrual,
                            color: .green
                        )
                    }
                    
                    ValuationDetailRow(
                        label: "Price Source",
                        value: valuation.priceSource,
                        isText: true
                    )
                    
                    HStack {
                        Text("Price")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Spacer()
                        Text("\(valuation.pricePerKg, format: .number.precision(.fractionLength(2))) $/kg")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.primaryText)
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                NavigationLink(destination: HerdDetailView(herd: herd)) {
                    HStack {
                        Text("View Details")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.accent)
                    }
                }
                
                NavigationLink(destination: EditHerdView(herd: herd)) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accent)
                        .padding(8)
                        .background(Theme.accent.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(Theme.cardPadding)
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
            
            Button(action: {
                HapticManager.tap()
                showingAddAssetMenu = true
            }) {
                Text("Add Asset")
                    .font(Theme.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            }
            .buttonBorderShape(.roundedRectangle)
            .accessibilityLabel("Add asset")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

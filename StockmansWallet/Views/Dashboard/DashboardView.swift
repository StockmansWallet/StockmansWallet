//
//  DashboardView.swift
//  StockmansWallet
//
//  Main Dashboard with Portfolio Value and Interactive Chart
//  Debug: Uses @Observable pattern, proper error handling, and comprehensive accessibility
//

import SwiftUI
import SwiftData
import Charts
import Foundation

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var herds: [HerdGroup]
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject (modern pattern)
    let valuationEngine = ValuationEngine.shared
    
    // Debug: State management for dashboard data
    @State private var portfolioValue: Double = 0.0
    @State private var portfolioChange: Double = 0.0
    @State private var baseValue: Double = 0.0
    @State private var dayAgoValue: Double = 0.0
    @State private var valuationHistory: [ValuationDataPoint] = []
    @State private var selectedDate: Date?
    @State private var selectedValue: Double?
    @State private var isScrubbing: Bool = false
    @State private var isLoading = true
    @State private var loadError: String? = nil
    @State private var timeRange: TimeRange = .all
    @State private var capitalConcentration: [CapitalConcentrationBreakdown] = []
    @State private var unrealizedGains: Double = 0.0
    @State private var totalCostToCarry: Double = 0.0
    @State private var performanceMetrics: PerformanceMetrics?
    
    @State private var showingAddAssetMenu = false
    @State private var backgroundImageTrigger = false // Debug: Trigger to force view refresh on background change
    
    var body: some View {
        NavigationStack {
            mainContentWithModifiers
        }
    }
    
    // Debug: Separate view with all modifiers to reduce complexity
    @ViewBuilder
    private var mainContentWithModifiers: some View {
        let contentWithNav = mainContent
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Dashboard")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
            }
        
        contentWithNav
            .task {
                await loadValuations()
            }
            .refreshable {
                await loadValuations()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DataCleared"))) { _ in
                Task {
                    await MainActor.run {
                        self.valuationHistory = []
                        self.portfolioValue = 0.0
                        self.baseValue = 0.0
                    }
                    await loadValuations()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BackgroundImageChanged"))) { _ in
                // Debug: Toggle state to force view refresh when background image changes
                Task { @MainActor in
                    print("🖼️ DashboardView: Background image changed notification received")
                    backgroundImageTrigger.toggle()
                    print("🖼️ DashboardView: backgroundImageTrigger is now \(backgroundImageTrigger)")
                }
            }
            .onChange(of: herds.count) { _, _ in
                Task {
                    await loadValuations()
                }
            }
            .sheet(isPresented: $showingAddAssetMenu) {
                AddAssetMenuView(isPresented: $showingAddAssetMenu)
                    .transition(.move(edge: .trailing))
                    .presentationBackground(Theme.sheetBackground)
            }
            .background(Theme.backgroundColor.ignoresSafeArea())
    }
    
    // Debug: Extract main content to reduce body complexity
    @ViewBuilder
    private var mainContent: some View {
        Group {
            let activeHerds = herds.filter { !$0.isSold }
            
            // Debug: Handle empty, error, and loaded states
            if activeHerds.isEmpty {
                EmptyDashboardView(showingAddAssetMenu: $showingAddAssetMenu)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Empty dashboard")
                    .accessibilityHint("Add your first herd to get started.")
            } else if let error = loadError {
                // Debug: Error state with retry option
                ErrorStateView(errorMessage: error) {
                    Task {
                        await loadValuations()
                    }
                }
                .accessibilityLabel("Error loading dashboard")
                .accessibilityHint(error)
            } else {
                dashboardContentView
            }
        }
    }
    
    // Debug: Dashboard content with parallax background and fixed header
    @ViewBuilder
    private var dashboardContentView: some View {
        let userPrefs = preferences.first ?? UserPreferences()
        let backgroundImageName = userPrefs.backgroundImageName ?? "BackgroundDefault"
        // Debug: Force view update when backgroundImageTrigger changes
        let _ = backgroundImageTrigger
        let _ = print("🖼️ DashboardView: Rendering with background=\(backgroundImageName), isCustom=\(userPrefs.isCustomBackground), trigger=\(backgroundImageTrigger)")
        
        ZStack(alignment: .top) {
            // Debug: Background image with parallax effect (like iOS home screen wallpapers)
            // Uses user's selected background from preferences (built-in or custom)
            if userPrefs.isCustomBackground {
                // Debug: Load custom background from document directory
                CustomParallaxImageView(
                    imageName: backgroundImageName,
                    intensity: 25,           // Movement amount (20-40)
                    opacity: 0.2,            // Background opacity
                    scale: 0.5,              // Image takes 50% of screen height
                    verticalOffset: -60,     // Move image up to show more middle/lower area
                    blur: 0                  // BG Image Blur radius
                )
                .id("custom_\(backgroundImageName)_\(backgroundImageTrigger)") // Debug: Force view recreation on background change
            } else {
                // Debug: Load built-in background from Assets
                ParallaxImageView(
                    imageName: backgroundImageName,
                    intensity: 25,           // Movement amount (20-40)
                    opacity: 0.2,            // Background opacity
                    scale: 0.5,              // Image takes 50% of screen height
                    verticalOffset: -60,     // Move image up to show more middle/lower area
                    blur: 0                  // BG Image Blur radius
                )
                .id("builtin_\(backgroundImageName)_\(backgroundImageTrigger)") // Debug: Force view recreation on background change
            }
            
            // Debug: Fixed portfolio value - stays in place while content scrolls over it
            VStack {
                PortfolioValueCard(
                    value: selectedValue ?? portfolioValue,
                    change: isScrubbing ? portfolioChange : (portfolioValue - dayAgoValue),
                    isLoading: isLoading,
                    isScrubbing: isScrubbing
                  
                )
                .padding(.horizontal, Theme.cardPadding)
                .padding(.top, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total portfolio value")
                .accessibilityValue("\(portfolioValue.formatted(.currency(code: "AUD")))")
                
                
                Spacer()
            }
            
            // Debug: Scrollable content panel - starts lower to show more background
            ScrollView {
                VStack(spacing: 0) {
                    // Debug: Top spacing to position content panel lower and clear the fixed header
                    Color.clear
                        .frame(height: 210) // Adjust this to control how much background shows
                    
                    contentPanel
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    // Debug: Rounded panel with all dashboard content
    @ViewBuilder
    private var contentPanel: some View {
        VStack(spacing: Theme.sectionSpacing) {
            InteractiveChartView(
                data: filteredHistory,
                selectedDate: $selectedDate,
                selectedValue: $selectedValue,
                isScrubbing: $isScrubbing,
                timeRange: $timeRange,
                baseValue: baseValue,
                onValueChange: { newValue, change in
                    portfolioChange = change
                }
            )
            .padding(.horizontal, Theme.cardPadding)
            .accessibilityHint("Drag your finger across the chart to explore values over time.")
            
            TimeRangeSelector(timeRange: $timeRange)
                .padding(.horizontal, Theme.cardPadding)
                .padding(.top, -Theme.sectionSpacing)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Time range selector")
            
            QuickStatsView(herds: herds)
                .padding(.horizontal, Theme.cardPadding)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Quick stats")
            
            if let metrics = performanceMetrics {
                PerformanceMetricsView(metrics: metrics)
                    .padding(.horizontal, Theme.cardPadding)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Performance metrics")
            }
            
            MarketPulseView()
                .padding(.horizontal, Theme.cardPadding)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Market pulse")
            
            
            if !capitalConcentration.isEmpty {
                CapitalConcentrationView(breakdown: capitalConcentration, totalValue: portfolioValue)
                    .padding(.horizontal, Theme.cardPadding)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Capital concentration")
            }
            
        
         
            
        
        }
        .padding(.top, -12)
        .padding(.bottom, 100)
        .background(
            // Debug: Dark panel background with gradient and prominent drop shadow for better separation
            ZStack {
                RoundedTopCornersShape(radius: 24)
                    .fill(Theme.backgroundColor)
                    .ignoresSafeArea()
                
                RoundedTopCornersShape(radius: 24)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "FFA042").opacity(0.15),  // Orange accent
                                Color(hex: "1E1815").opacity(0)      // Fade to transparent
                            ],
                            center: .top,
                            startRadius: 0,
                            endRadius: 500
                        )
                    )
                    .ignoresSafeArea()
            }
            .shadow(color: .black.opacity(0.8), radius: 30, y: -8)
        )
    }
    
    private var filteredHistory: [ValuationDataPoint] {
        guard !valuationHistory.isEmpty else { return [] }
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate: Date
        
        switch timeRange {
        case .week:
            cutoffDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            cutoffDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return valuationHistory
        }
        
        return valuationHistory.filter { $0.date >= cutoffDate }
    }
    
    // Debug: Async data loading with proper error handling
    private func loadValuations() async {
        await MainActor.run {
            self.isLoading = true
            self.loadError = nil
            self.valuationHistory = []
        }
        
        // Debug: Fetch preferences and active herds
        let prefs = preferences.first ?? UserPreferences()
        let currentHerds = herds
        let activeHerds = currentHerds.filter { !$0.isSold }
        
        // Debug: Early return if no active herds
        guard !activeHerds.isEmpty else {
            await MainActor.run {
                self.portfolioValue = 0.0
                self.baseValue = 0.0
                self.valuationHistory = []
                self.capitalConcentration = []
                self.unrealizedGains = 0.0
                self.totalCostToCarry = 0.0
                self.performanceMetrics = nil
                self.isLoading = false
            }
            return
        }
        
        // Debug: Wrap in do-catch for proper error handling
        do {
            try await performValuationCalculations(activeHerds: activeHerds, prefs: prefs)
        } catch {
            await MainActor.run {
                self.loadError = "Failed to load valuations: \(error.localizedDescription)"
                self.isLoading = false
            }
            HapticManager.error()
        }
    }
    
    // Debug: Extracted calculation logic for better organization
    private func performValuationCalculations(activeHerds: [HerdGroup], prefs: UserPreferences) async throws {
        // Debug: Parallel calculation of herd valuations using task groups
        let results = await withTaskGroup(of: (netValue: Double, category: String, cost: Double, breeding: Double, initial: Double).self) { group in
            var results: [(netValue: Double, category: String, cost: Double, breeding: Double, initial: Double)] = []
            for herd in activeHerds {
                group.addTask { @MainActor [modelContext] in
                    let valuation = await self.valuationEngine.calculateHerdValue(
                        herd: herd,
                        preferences: prefs,
                        modelContext: modelContext
                    )
                    
                    let initialValuation = await self.valuationEngine.calculateHerdValue(
                        herd: herd,
                        preferences: prefs,
                        modelContext: modelContext,
                        asOfDate: herd.createdAt
                    )
                    
                    return (
                        netValue: valuation.netRealizableValue,
                        category: herd.category,
                        cost: valuation.costToCarry,
                        breeding: valuation.breedingAccrual,
                        initial: initialValuation.netRealizableValue
                    )
                }
            }
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        var valuations: Double = 0.0
        var categoryTotals: [String: Double] = [:]
        var totalCost: Double = 0.0
        var totalBreedingAccrual: Double = 0.0
        var initialValue: Double = 0.0
        
        for result in results {
            valuations += result.netValue
            categoryTotals[result.category, default: 0.0] += result.netValue
            totalCost += result.cost
            totalBreedingAccrual += result.breeding
            initialValue += result.initial
        }
        
        // Guard against division by zero when computing percentages
        let concentration: [CapitalConcentrationBreakdown]
        if valuations > 0 {
            concentration = categoryTotals.map { category, value in
                CapitalConcentrationBreakdown(category: category, value: value, percentage: (value / valuations) * 100)
            }
            .sorted { $0.value > $1.value }
        } else {
            concentration = categoryTotals.map { category, value in
                CapitalConcentrationBreakdown(category: category, value: value, percentage: 0.0)
            }
            .sorted { $0.value > $1.value }
        }
        
        let totalChange = valuations - initialValue
        let percentChange = initialValue > 0 ? (totalChange / initialValue) * 100 : 0.0
        
        // Debug: Update UI state on main actor
        await MainActor.run {
            self.portfolioValue = valuations
            self.baseValue = initialValue
            self.portfolioChange = totalChange
            self.capitalConcentration = concentration
            self.unrealizedGains = totalBreedingAccrual
            self.totalCostToCarry = totalCost
            self.performanceMetrics = PerformanceMetrics(
                totalChange: totalChange,
                percentChange: percentChange,
                unrealizedGains: totalBreedingAccrual,
                initialValue: initialValue
            )
            self.isLoading = false
        }
        
        HapticManager.tap()
        
        // Debug: Load historical data in background (lower priority)
        Task(priority: .utility) {
            let freshHerds = self.herds
            let freshActiveHerds = freshHerds.filter { !$0.isSold }
            
            guard !freshActiveHerds.isEmpty else {
                await MainActor.run {
                    self.valuationHistory = []
                }
                return
            }
            
            var history: [ValuationDataPoint] = []
            let calendar = Calendar.current
            
            let startDate = Date(timeIntervalSince1970: 1672531200) // Jan 1, 2023
            let endDate = Date()
            let earliestHerdDate = freshActiveHerds.map { $0.createdAt }.min() ?? startDate
            let historyStartDate = min(startDate, earliestHerdDate)
            let daysFromStart = calendar.dateComponents([.day], from: historyStartDate, to: endDate).day ?? 0
            let totalDays = min(daysFromStart + 1, 1095)
            
            for dayOffset in (0..<totalDays).reversed() {
                if dayOffset > 7 && dayOffset % 7 != 0 {
                    continue
                }
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { continue }
                guard date >= historyStartDate else { continue }
                
                let activeHerdsForDate = freshActiveHerds.filter { $0.createdAt <= date }
                let dayValuations = await withTaskGroup(of: (physical: Double, breeding: Double, total: Double).self, returning: (physical: Double, breeding: Double, total: Double).self) { group in
                    var totals = (physical: 0.0, breeding: 0.0, total: 0.0)
                    for herd in activeHerdsForDate {
                        group.addTask { @MainActor [modelContext] in
                            let valuation = await self.valuationEngine.calculateHerdValue(
                                herd: herd,
                                preferences: prefs,
                                modelContext: modelContext,
                                asOfDate: date
                            )
                            return (valuation.physicalValue, valuation.breedingAccrual, valuation.netRealizableValue)
                        }
                    }
                    for await values in group {
                        totals.physical += values.physical
                        totals.breeding += values.breeding
                        totals.total += values.total
                    }
                    return totals
                }
                
                history.append(ValuationDataPoint(
                    date: date,
                    value: dayValuations.total,
                    physicalValue: dayValuations.physical,
                    breedingAccrual: dayValuations.breeding
                ))
            }
            
            let dayAgo = calendar.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
            let dayAgoDataPoint = history.last { dataPoint in
                dataPoint.date <= dayAgo
            } ?? history.first
            
            let currentPortfolioValue = self.portfolioValue
            
            await MainActor.run {
                self.valuationHistory = history
                self.dayAgoValue = dayAgoDataPoint?.value ?? currentPortfolioValue
                HapticManager.success()
            }
        }
    }
}

// MARK: - Portfolio Value Card
struct PortfolioValueCard: View {
    let value: Double
    let change: Double
    let isLoading: Bool
    let isScrubbing: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Total Portfolio Value")
                .font(Theme.caption)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
            
            if isLoading {
                ProgressView()
                    .tint(Theme.accent)
            } else {
                AnimatedCurrencyValue(value: value, isScrubbing: isScrubbing)
                    .padding(.bottom, 8)
            }
            
            if !isLoading {
                // Debug: Change ticker in glass pill with fully rounded capsule shape
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(change >= 0 ? .green : .red)
                        .accessibilityHidden(true)
                    Text(change, format: .currency(code: "AUD"))
                        .font(.system(size: 11, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(change >= 0 ? .green : .red)
                        .accessibilityLabel("Change since yesterday")
                        .accessibilityValue("\(change.formatted(.currency(code: "AUD")))")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassEffect(.regular.interactive(), in: Capsule())
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                .animation(UIAccessibility.isReduceMotionEnabled ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: change)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.cardPadding)
    }
}

// MARK: - Animated Currency Value with Native SwiftUI Animations
struct AnimatedCurrencyValue: View {
    let value: Double
    let isScrubbing: Bool
    @State private var previousValue: Double = 0.0
    @State private var initialLoad = true
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    private var formattedValue: (whole: String, decimal: String) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        
        let whole = formatter.string(from: NSNumber(value: abs(value))) ?? "0"
        let decimal = String(format: "%02d", Int((abs(value) - floor(abs(value))) * 100))
        
        return (whole: whole, decimal: decimal)
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("$")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .tracking(-2)
                .baselineOffset(4)
                .padding(.trailing, 8)
                .accessibilityHidden(true)
            
            let useAnimations = !UIAccessibility.isReduceMotionEnabled && isScrubbing
            
            Text(formattedValue.whole)
                .font(.system(size: 40, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .tracking(-2)
                .if(useAnimations) { view in
                    view
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: formattedValue.whole)
                }
            
            Text(".")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(-2)
                .accessibilityHidden(true)
            
            Text(formattedValue.decimal)
                .font(.system(size: 24, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.6))
                .tracking(-1)
                .if(useAnimations) { view in
                    view
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: formattedValue.decimal)
                }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onChange(of: value) { oldValue, newValue in
            previousValue = oldValue
        }
        .onAppear {
            previousValue = value
            if initialLoad {
                if UIAccessibility.isReduceMotionEnabled {
                    scale = 1.0
                    opacity = 1.0
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                }
                initialLoad = false
            }
        }
        .accessibilityLabel("Portfolio value")
        .accessibilityValue(value.formatted(.currency(code: "AUD")))
    }
}

// Small helper to conditionally apply modifiers.
private extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Interactive Chart View
enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case all = "All"
}

struct InteractiveChartView: View {
    let data: [ValuationDataPoint]
    @Binding var selectedDate: Date?
    @Binding var selectedValue: Double?
    @Binding var isScrubbing: Bool
    @Binding var timeRange: TimeRange
    let baseValue: Double
    let onValueChange: (Double, Double) -> Void
    
    @State private var dragLocation: CGPoint?
    @State private var scrubberX: CGFloat?
    @State private var chartRevealProgress: CGFloat = 0.0
    @State private var pillScale: CGFloat = 0.0
    @State private var pillOpacity: Double = 0.0
    
    private let gridSpacing: CGFloat = 15
    
    private var timeRangeSelector: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        HapticManager.tap()
                        timeRange = range
                    }) {
                        Text(range.rawValue)
                            .font(Theme.caption)
                            .foregroundStyle(timeRange == range ? Theme.accent : Theme.secondaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                timeRange == range ? Theme.accent.opacity(0.15) : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .accessibilityLabel("Show \(range.rawValue) range")
                }
            }
            Spacer()
        }
    }
    
    private var fullOpacityGradient: LinearGradient {
        LinearGradient(
            colors: [Theme.accent.opacity(0.3), Theme.accent.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var dimmedGradient: LinearGradient {
        LinearGradient(
            colors: [Theme.accent.opacity(0.09), Theme.accent.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func edgeExtendedData(for data: [ValuationDataPoint], in range: TimeRange) -> [ValuationDataPoint] {
        guard !data.isEmpty else { return data }
        let sorted = Array(data.sorted { $1.date > $0.date }.reversed())
        let first = sorted[0]
        
        let epsilon: TimeInterval
        switch range {
        case .week, .month:
            epsilon = 60 * 60 * 12
        case .year:
            epsilon = 60 * 60 * 24
        case .all:
            return data
        }
        
        let leading = ValuationDataPoint(
            date: first.date.addingTimeInterval(-epsilon),
            value: first.value,
            physicalValue: first.physicalValue,
            breedingAccrual: first.breedingAccrual
        )
        
        var out = data
        out.insert(leading, at: 0)
        return out
    }
    
    private var chartGrid: some View {
        GeometryReader { geo in
            let size = geo.size
            Path { path in
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += gridSpacing
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += gridSpacing
                }
            }
            .stroke(Theme.primaryText.opacity(0.03), lineWidth: 0.5)
        }
    }
    
    private func chartContent() -> some View {
        let renderData = edgeExtendedData(for: data, in: timeRange)
        let yRange = valueRange(data: data)
        let xRange = dataRange(data: renderData)
        let cutoff = selectedDate
        
        return Chart {
            ForEach(renderData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Theme.accent)
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .butt, lineJoin: .round))
                .opacity({
                    guard let cutoff = cutoff else { return 1.0 }
                    return point.date > cutoff ? 0.3 : 1.0
                }())
            }
            
            ForEach(renderData) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Value", yRange.lowerBound),
                    yEnd: .value("Value", point.value)
                )
                .foregroundStyle({
                    guard let cutoff = cutoff else { return fullOpacityGradient }
                    return point.date > cutoff ? dimmedGradient : fullOpacityGradient
                }())
                .interpolationMethod(.monotone)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXScale(domain: xRange, range: .plotDimension(padding: 0))
        .chartYScale(domain: yRange, range: .plotDimension(padding: 0))
        .chartPlotStyle { plotArea in
            plotArea
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Portfolio value chart")
    }
    
    private var dateHoverPill: some View {
        Group {
            if isScrubbing, let selectedDate = selectedDate, let scrubberX = scrubberX {
                GeometryReader { geometry in
                    // Debug: Date pill with fully rounded capsule shape
                    let content = Text(selectedDate, format: .dateTime.day(.twoDigits).month(.abbreviated).year())
                        .font(.system(size: 11, weight: .regular)).monospacedDigit()
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassEffect(.regular.interactive(), in: Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                        .scaleEffect(pillScale, anchor: .center)
                        .opacity(pillOpacity)
                    
                    let pillWidth: CGFloat = 100
                    let pillOffset = scrubberX - (pillWidth / 2)
                    let clampedOffset = max(0, min(pillOffset, geometry.size.width - pillWidth))
                    
                    content
                        .offset(x: clampedOffset)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Selected date")
                        .accessibilityValue(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .onAppear {
                            if UIAccessibility.isReduceMotionEnabled {
                                pillScale = 1.0
                                pillOpacity = 1.0
                            } else {
                                pillScale = 0.0
                                pillOpacity = 0.0
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                                    pillScale = 1.0
                                    pillOpacity = 1.0
                                }
                            }
                        }
                }
                .frame(height: 32)
            } else {
                Color.clear
                    .frame(height: 32)
            }
        }
        .onChange(of: isScrubbing) { oldValue, newValue in
            if !newValue {
                if UIAccessibility.isReduceMotionEnabled {
                    pillScale = 0.0
                    pillOpacity = 0.0
                } else {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        pillScale = 0.0
                        pillOpacity = 0.0
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            dateHoverPill
                .padding(.bottom, 0)
            
            GeometryReader { geometry in
                ZStack {
                    chartGrid
                    
                    chartContent()
                        .mask(
                            Rectangle()
                                .frame(width: geometry.size.width * chartRevealProgress)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                        .chartOverlay { proxy in
                            GeometryReader { geo in
                                Rectangle()
                                    .fill(.clear)
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                guard !data.isEmpty else { return }
                                                
                                                let location = value.location
                                                self.dragLocation = location
                                                
                                                if let date: Date = proxy.value(atX: location.x) {
                                                    let sorted = data.sorted { $0.date < $1.date }
                                                    
                                                    if let plotFrameAnchor = proxy.plotFrame {
                                                        let plotFrame = geo[plotFrameAnchor]
                                                        
                                                        if let first = sorted.first, date <= first.date {
                                                            selectedDate = first.date
                                                            selectedValue = first.value
                                                            if let xPlot = proxy.position(forX: first.date) {
                                                                scrubberX = plotFrame.origin.x + xPlot
                                                            } else {
                                                                scrubberX = location.x
                                                            }
                                                            isScrubbing = true
                                                            onValueChange(first.value, first.value - baseValue)
                                                            return
                                                        }
                                                        if let last = sorted.last, date >= last.date {
                                                            selectedDate = last.date
                                                            selectedValue = last.value
                                                            if let xPlot = proxy.position(forX: last.date) {
                                                                scrubberX = plotFrame.origin.x + xPlot
                                                            } else {
                                                                scrubberX = location.x
                                                            }
                                                            isScrubbing = true
                                                            onValueChange(last.value, last.value - baseValue)
                                                            return
                                                        }
                                                        
                                                        var before: ValuationDataPoint?
                                                        var after: ValuationDataPoint?
                                                        
                                                        for i in 0..<sorted.count {
                                                            if sorted[i].date <= date {
                                                                before = sorted[i]
                                                            } else {
                                                                after = sorted[i]
                                                                break
                                                            }
                                                        }
                                                        
                                                        if let b = before, let a = after {
                                                            let timeDiff = a.date.timeIntervalSince(b.date)
                                                            let timeFromB = date.timeIntervalSince(b.date)
                                                            let t = timeDiff > 0 ? timeFromB / timeDiff : 0.0
                                                            let interpolated = b.value + (a.value - b.value) * t
                                                            
                                                            selectedDate = date
                                                            selectedValue = interpolated
                                                            
                                                            if let xPlot = proxy.position(forX: date) {
                                                                scrubberX = plotFrame.origin.x + xPlot
                                                            } else if let xB = proxy.position(forX: b.date),
                                                                      let xA = proxy.position(forX: a.date) {
                                                                let xInterp = xB + (xA - xB) * CGFloat(t)
                                                                scrubberX = plotFrame.origin.x + xInterp
                                                            } else {
                                                                scrubberX = location.x
                                                            }
                                                            
                                                            isScrubbing = true
                                                            onValueChange(interpolated, interpolated - baseValue)
                                                        }
                                                    }
                                                }
                                            }
                                            .onEnded { _ in
                                                isScrubbing = false
                                                selectedDate = nil
                                                selectedValue = nil
                                                scrubberX = nil
                                                onValueChange(baseValue, 0)
                                            }
                                    )
                                
                                if isScrubbing,
                                   let date = selectedDate,
                                   let value = selectedValue,
                                   let xInPlot = proxy.position(forX: date),
                                   let yInPlot = proxy.position(forY: value) {
                                    
                                    if let plotFrameAnchor = proxy.plotFrame {
                                        let plotFrame = geo[plotFrameAnchor]
                                        
                                        let x = plotFrame.origin.x + xInPlot
                                        let y = plotFrame.origin.y + yInPlot
                                        
                                        Group {
                                            Path { p in
                                                p.move(to: CGPoint(x: x, y: plotFrame.minY))
                                                p.addLine(to: CGPoint(x: x, y: plotFrame.maxY))
                                            }
                                            .stroke(.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                            
                                            Circle()
                                                .fill(.white)
                                                .frame(width: 12, height: 12)
                                                .shadow(color: Theme.accent.opacity(1), radius: 6)
                                                .shadow(color: Theme.accent.opacity(0.4), radius: 12)
                                                .position(x: x, y: y)
                                                .accessibilityHidden(true)
                                        }
                                    }
                                }
                            }
                        }
                }
            }
            .frame(height: 200)
            .clipped()
            .stitchedCard() // No padding - chart content fills to card edges
            .accessibilityLabel("Portfolio value chart")
            
            ChartDateLabelsView(
                data: data,
                timeRange: timeRange
            )
            .padding(.horizontal, Theme.cardPadding)
            .padding(.top, 10)
            .padding(.bottom, 4)
        }
        .onAppear {
            chartRevealProgress = 0
            if UIAccessibility.isReduceMotionEnabled {
                chartRevealProgress = 1.0
            } else {
                withAnimation(.easeInOut(duration: 1.2)) {
                    chartRevealProgress = 1.0
                }
            }
        }
        .onChange(of: data.count) { _, _ in
            chartRevealProgress = 0
            if UIAccessibility.isReduceMotionEnabled {
                chartRevealProgress = 1.0
            } else {
                withAnimation(.easeInOut(duration: 1.2)) {
                    chartRevealProgress = 1.0
                }
            }
        }
    }
}

// MARK: - Data Models
struct CapitalConcentrationBreakdown: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    let percentage: Double
}

struct PerformanceMetrics {
    let totalChange: Double
    let percentChange: Double
    let unrealizedGains: Double
    let initialValue: Double
}

// MARK: - Capital Concentration View
struct CapitalConcentrationView: View {
    let breakdown: [CapitalConcentrationBreakdown]
    let totalValue: Double
    
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
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(breakdown.prefix(5))) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.category)
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            Text(item.value, format: .currency(code: "AUD"))
                                .font(Theme.callout) // HIG: callout (16pt) for list values with many digits
                                .foregroundStyle(Theme.primaryText)
                                .accessibilityLabel("\(item.category) value")
                                .accessibilityValue(item.value.formatted(.currency(code: "AUD")))
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.primaryText.opacity(0.1))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.accent)
                                    .frame(width: geometry.size.width * CGFloat(item.percentage / 100), height: 8)
                                    .accessibilityLabel("\(item.category) percentage")
                                    .accessibilityValue("\(item.percentage.formatted(.number.precision(.fractionLength(1)))) percent")
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(item.percentage, format: .number.precision(.fractionLength(1)))%")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Performance Metrics View
struct PerformanceMetricsView: View {
    let metrics: PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Change")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(metrics.totalChange, format: .currency(code: "AUD"))
                            .font(Theme.title3) // HIG: title3 (20pt) - primary emphasis without overwhelming
                            .foregroundStyle(metrics.totalChange >= 0 ? .green : .red)
                            .accessibilityLabel("Total change")
                            .accessibilityValue(metrics.totalChange.formatted(.currency(code: "AUD")))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Percent Change")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text("\(metrics.percentChange >= 0 ? "+" : "")\(metrics.percentChange, format: .number.precision(.fractionLength(1)))%")
                            .font(Theme.title3) // HIG: title3 (20pt) - primary emphasis without overwhelming
                            .foregroundStyle(metrics.percentChange >= 0 ? .green : .red)
                            .accessibilityLabel("Percent change")
                            .accessibilityValue("\(metrics.percentChange.formatted(.number.precision(.fractionLength(1)))) percent")
                    }
                }
                
                Divider()
                    .background(Theme.separator)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unrealized Gains")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(metrics.unrealizedGains, format: .currency(code: "AUD"))
                            .font(Theme.callout) // HIG: callout (16pt) for secondary metrics
                            .foregroundStyle(Theme.accent)
                            .accessibilityLabel("Unrealized gains")
                            .accessibilityValue(metrics.unrealizedGains.formatted(.currency(code: "AUD")))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Initial Value")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(metrics.initialValue, format: .currency(code: "AUD"))
                            .font(Theme.callout) // HIG: callout (16pt) for secondary metrics
                            .foregroundStyle(Theme.primaryText)
                            .accessibilityLabel("Initial value")
                            .accessibilityValue(metrics.initialValue.formatted(.currency(code: "AUD")))
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
        .accessibilityElement(children: .contain)
    }
}


// MARK: - Empty Dashboard View
struct EmptyDashboardView: View {
    @Binding var showingAddAssetMenu: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 80))
                    .foregroundStyle(Theme.accent.opacity(0.5))
                    .accessibilityHidden(true)
                
                Text("Add your first herd or individual animals to start tracking your livestock portfolio value in real-time")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                HapticManager.tap()
                showingAddAssetMenu = true
            }) {
                Text("Add Your First Herd")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(Theme.PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .accessibilityLabel("Add your first herd")
            .accessibilityHint("Opens the asset menu to add a herd.")
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Error State View
// Debug: Reusable error state component with retry action
struct ErrorStateView: View {
    let errorMessage: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red.opacity(0.7))
                .accessibilityHidden(true)
            
            Text("Something went wrong")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
            
            Text(errorMessage)
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                HapticManager.tap()
                retryAction()
            }) {
                Text("Try Again")
                    .font(Theme.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            }
            .buttonBorderShape(.roundedRectangle)
            .accessibilityLabel("Try again")
            .accessibilityHint("Retry loading the dashboard data")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Custom Shape for Rounded Top Corners
// Debug: Custom shape to create rounded top corners only for the sliding panel
struct RoundedTopCornersShape: Shape {
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Debug: Start from top left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        
        // Top left arc
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                    radius: radius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)
        
        // Top edge to top right corner
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        
        // Top right arc
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                    radius: radius,
                    startAngle: .degrees(270),
                    endAngle: .degrees(0),
                    clockwise: false)
        
        // Right edge to bottom right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        
        // Bottom edge to bottom left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        path.closeSubpath()
        
        return path
    }
}


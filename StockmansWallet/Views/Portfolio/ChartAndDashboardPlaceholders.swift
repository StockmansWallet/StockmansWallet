//
//  ChartAndDashboardPlaceholders.swift
//  StockmansWallet
//
//  Temporary placeholders for chart utilities and dashboard components to unblock the build.
//  Replace these with full implementations when ready.
//

import SwiftUI
import Charts
import SwiftData

// MARK: - Chart Helpers (Placeholders)
func valueRange(data: [ValuationDataPoint]) -> ClosedRange<Double> {
    guard let minVal = data.map({ $0.value }).min(),
          let maxVal = data.map({ $0.value }).max(),
          minVal.isFinite, maxVal.isFinite else {
        return 0...1
    }
    // Add padding to prevent clipping (5% top and bottom)
    let range = maxVal - minVal
    let padding = max(range * 0.05, maxVal * 0.01) // At least 5% or 1% of max value
    return (minVal - padding)...(maxVal + padding)
}

func dataRange(data: [ValuationDataPoint]) -> ClosedRange<Date> {
    guard let minDate = data.map({ $0.date }).min(),
          let maxDate = data.map({ $0.date }).max() else {
        let now = Date()
        return now...now
    }
    // Use exact date range - Swift Charts will handle edge alignment
    return minDate...maxDate
}

func calculateYPosition(for value: Double, in height: CGFloat, data: [ValuationDataPoint]) -> CGFloat {
    let range = valueRange(data: data)
    let minV = range.lowerBound
    let maxV = range.upperBound
    guard maxV > minV else { return height / 2 }
    // Invert Y (top is 0)
    let normalized = (value - minV) / (maxV - minV)
    return height * CGFloat(1.0 - normalized)
}

// Note: Drag handlers are now implemented directly in InteractiveChartView

// MARK: - Chart Date Labels View
struct ChartDateLabelsView: View {
    let data: [ValuationDataPoint]
    let timeRange: TimeRange
    // Debug: Use custom date picker values when applicable
    let customStartDate: Date?
    let customEndDate: Date?
    
    private var startDate: Date? {
        if timeRange == .custom, let customStartDate {
            return customStartDate
        }
        return data.first?.date
    }
    
    private var endDate: Date? {
        if timeRange == .custom, let customEndDate {
            return customEndDate
        }
        return data.last?.date
    }
    
    var body: some View {
        HStack {
            if let startDate = startDate {
                if timeRange == .all || timeRange == .year {
                    Text(startDate, format: .dateTime.day().month(.abbreviated).year(.twoDigits))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Text(startDate, format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondaryText)
                }
            } else {
                Text("Start")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            if let endDate = endDate {
                if timeRange == .all || timeRange == .year {
                    Text(endDate, format: .dateTime.day().month(.abbreviated).year(.twoDigits))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondaryText)
                } else {
                    Text(endDate, format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondaryText)
                }
            } else {
                Text("End")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}

// MARK: - Time Range Selector (Placeholder)
struct TimeRangeSelector: View {
    @Binding var timeRange: TimeRange
    @Binding var customStartDate: Date?
    @Binding var customEndDate: Date?
    @Binding var showingCustomDatePicker: Bool
    
    // Debug: Format custom date range for button label (e.g., "Jan 1 - Feb 15")
    private var customDateRangeLabel: String {
        guard let start = customStartDate, let end = customEndDate else {
            return "Custom"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    var body: some View {
        // Debug: Reduced spacing and padding for smaller screens (iPhone 17 Pro compatibility)
        HStack(spacing: 6) {
            Spacer()
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    HapticManager.tap()
                    // Debug: Custom range opens date picker sheet instead of direct selection
                    if range == .custom {
                        showingCustomDatePicker = true
                    } else {
                        timeRange = range
                    }
                } label: {
                    // Debug: Keep "Custom" label when active for clear state
                    Text(range.rawValue)
                        .font(Theme.caption)
                        .foregroundStyle(timeRange == range ? Theme.accentColor : Theme.secondaryText)
                        .padding(.horizontal, 10) // Reduced from 12 for smaller screens
                        .padding(.vertical, 6)
                        .background(
                            timeRange == range ? Theme.accentColor.opacity(0.15) : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .accessibilityLabel(range == .custom ? "Custom date range" : "Show \(range.rawValue) range")
            }
            Spacer()
        }
    }
}

// MARK: - Herd Performance View
// Debug: Shows performance by herd category with percentage changes over selected time range
struct MarketPulseView: View {
    // Debug: Enable dashboard-style title bar when embedded in dashboard.
    var showsDashboardHeader: Bool = false
    @Environment(\.modelContext) private var modelContext
    // Performance: Only query herds (headCount > 1), not individual animals
    @Query(filter: #Predicate<HerdGroup> { $0.headCount > 1 }) private var herds: [HerdGroup]
    @Query private var preferences: [UserPreferences]
    @State private var categoryPerformance: [HerdCategoryPerformance] = []
    @State private var isLoading = true
    @State private var performanceTimeRange: PerformanceTimeRange = .week
    @State private var showingCustomDatePicker = false
    @State private var customStartDate: Date?
    @State private var customEndDate: Date?
    
    // Debug: Access ValuationEngine for calculating performance changes
    let valuationEngine = ValuationEngine.shared
    
    // Debug: Time range options for performance tracking
    enum PerformanceTimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case custom = "Custom"
        
        // Debug: Display label for each range
        var displayLabel: String {
            switch self {
            case .week: return "7d"
            case .month: return "1m"
            case .year: return "1y"
            case .custom: return "Custom"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showsDashboardHeader {
                // Debug: Dashboard-style header with icon, time range, and drag handle.
                DashboardCardHeader(
                    title: "Herd Performance",
                    iconName: "chart.line.uptrend.xyaxis",
                    iconColor: Theme.dashboardMarketAccent,
                    timeRangeLabel: customDateRangeLabel
                ) {
                    ForEach(PerformanceTimeRange.allCases, id: \.self) { range in
                        Button {
                            HapticManager.tap()
                            if range == .custom {
                                showingCustomDatePicker = true
                            } else {
                                performanceTimeRange = range
                            }
                        } label: {
                            HStack {
                                Text(range.rawValue)
                                if performanceTimeRange == range {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            } else {
                HStack {
                    Text("Herd Performance")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    
                    // Debug: Time range selector menu
                    Menu {
                        ForEach(PerformanceTimeRange.allCases, id: \.self) { range in
                            Button {
                                HapticManager.tap()
                                if range == .custom {
                                    showingCustomDatePicker = true
                                } else {
                                    performanceTimeRange = range
                                }
                            } label: {
                                HStack {
                                    Text(range.rawValue)
                                    if performanceTimeRange == range {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            // Debug: Show custom date range or standard label
                            Text(customDateRangeLabel)
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.accentColor)
                        }
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Select performance time range")
                    .accessibilityValue(performanceTimeRange.rawValue)
                }
            }
            
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Theme.accentColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if categoryPerformance.isEmpty {
                    Text("No herd data available")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(categoryPerformance) { performance in
                            IndicatorRow(
                                title: performance.category,
                                value: "\(performance.percentChange >= 0 ? "+" : "")\(performance.percentChange.formatted(.number.precision(.fractionLength(2))))%",
                                trend: performance.trend
                            )
                        }
                    }
                }
            }
            // Debug: Slightly more horizontal padding for bottom content area.
            .padding(.horizontal, showsDashboardHeader ? Theme.dashboardCardPadding + 4 : 0)
            .padding(.bottom, showsDashboardHeader ? Theme.dashboardCardPadding : 0)
        }
        // Debug: Use standard padding for non-dashboard usage.
        .padding(showsDashboardHeader ? 0 : Theme.cardPadding)
        // Debug: No card background/stroke for cleaner dashboard look
        // .cardStyle()
        .sheet(isPresented: $showingCustomDatePicker) {
            CustomDateRangeSheet(
                startDate: $customStartDate,
                endDate: $customEndDate,
                timeRange: Binding(
                    get: { 
                        // Debug: Map PerformanceTimeRange to TimeRange for sheet compatibility
                        performanceTimeRange == .custom ? .custom : .week 
                    },
                    set: { _ in 
                        performanceTimeRange = .custom 
                    }
                )
            )
        }
        .task {
            await loadCategoryPerformance()
        }
        .onChange(of: herds.count) { _, _ in
            // Debug: Reload when herds change
            Task {
                await loadCategoryPerformance()
            }
        }
        .onChange(of: performanceTimeRange) { _, _ in
            // Debug: Reload when time range changes
            Task {
                await loadCategoryPerformance()
            }
        }
        .onChange(of: customStartDate) { _, _ in
            // Debug: Reload when custom start date changes
            if performanceTimeRange == .custom {
                Task {
                    await loadCategoryPerformance()
                }
            }
        }
        .onChange(of: customEndDate) { _, _ in
            // Debug: Reload when custom end date changes
            if performanceTimeRange == .custom {
                Task {
                    await loadCategoryPerformance()
                }
            }
        }
    }
    
    // Debug: Format custom date range label (e.g., "Jan 1 - Feb 15")
    private var customDateRangeLabel: String {
        if performanceTimeRange == .custom,
           let start = customStartDate,
           let end = customEndDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
        return performanceTimeRange.displayLabel
    }
    
    // Debug: Calculate performance for each herd category over selected time range
    private func loadCategoryPerformance() async {
        isLoading = true
        
        let prefs = preferences.first ?? UserPreferences()
        let activeHerds = herds.filter { !$0.isSold }
        
        // Debug: Early return if no herds
        guard !activeHerds.isEmpty else {
            await MainActor.run {
                self.categoryPerformance = []
                self.isLoading = false
            }
            return
        }
        
        // Debug: Calculate comparison date based on selected time range
        let calendar = Calendar.current
        let now = Date()
        let comparisonDate: Date
        
        switch performanceTimeRange {
        case .week:
            guard let date = calendar.date(byAdding: .day, value: -7, to: now) else {
                await MainActor.run {
                    self.categoryPerformance = []
                    self.isLoading = false
                }
                return
            }
            comparisonDate = date
        case .month:
            guard let date = calendar.date(byAdding: .month, value: -1, to: now) else {
                await MainActor.run {
                    self.categoryPerformance = []
                    self.isLoading = false
                }
                return
            }
            comparisonDate = date
        case .year:
            guard let date = calendar.date(byAdding: .year, value: -1, to: now) else {
                await MainActor.run {
                    self.categoryPerformance = []
                    self.isLoading = false
                }
                return
            }
            comparisonDate = date
        case .custom:
            // Debug: Use custom start date if available, otherwise default to 7 days ago
            if let startDate = customStartDate {
                comparisonDate = startDate
            } else {
                guard let date = calendar.date(byAdding: .day, value: -7, to: now) else {
                    await MainActor.run {
                        self.categoryPerformance = []
                        self.isLoading = false
                    }
                    return
                }
                comparisonDate = date
            }
        }
        
        // Group herds by category
        let categoryGroups = Dictionary(grouping: activeHerds) { $0.category }
        
        var performances: [HerdCategoryPerformance] = []
        
        for (category, categoryHerds) in categoryGroups {
            // Debug: Calculate current value for category
            var currentValue: Double = 0.0
            var comparisonValue: Double = 0.0
            
            for herd in categoryHerds {
                // Only include herds that existed at comparison date
                guard herd.createdAt <= comparisonDate else { continue }
                
                let currentValuation = await valuationEngine.calculateHerdValue(
                    herd: herd,
                    preferences: prefs,
                    modelContext: modelContext
                )
                
                let pastValuation = await valuationEngine.calculateHerdValue(
                    herd: herd,
                    preferences: prefs,
                    modelContext: modelContext,
                    asOfDate: comparisonDate
                )
                
                currentValue += currentValuation.netRealizableValue
                comparisonValue += pastValuation.netRealizableValue
            }
            
            // Debug: Calculate percentage change
            guard comparisonValue > 0 else { continue }
            
            let change = currentValue - comparisonValue
            let percentChange = (change / comparisonValue) * 100
            
            // Debug: Determine trend based on percentage change threshold
            let trend: PriceTrend = {
                if percentChange > 0.1 {
                    return .up
                } else if percentChange < -0.1 {
                    return .down
                } else {
                    return .neutral
                }
            }()
            
            performances.append(HerdCategoryPerformance(
                category: category,
                percentChange: percentChange,
                trend: trend
            ))
        }
        
        // Debug: Sort by absolute percentage change (largest movements first)
        performances.sort { abs($0.percentChange) > abs($1.percentChange) }
        
        await MainActor.run {
            self.categoryPerformance = performances
            self.isLoading = false
        }
    }
}

// Debug: Data model for herd category performance
struct HerdCategoryPerformance: Identifiable {
    let id = UUID()
    let category: String
    let percentChange: Double
    let trend: PriceTrend
}

// Simple indicator row used by MarketPulseView
// Debug: Uses body font for both title and value to maintain visual hierarchy
struct IndicatorRow: View {
    let title: String
    let value: String
    let trend: PriceTrend

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText)
            Spacer()
            Text(value)
                .font(Theme.body) // HIG: Use body font for consistent hierarchy
                .foregroundStyle(Theme.primaryText)
            Image(systemName: trend == .up ? "arrow.up.right" : trend == .down ? "arrow.down.right" : "minus")
                .foregroundStyle(trend == .up ? Theme.positiveChange : trend == .down ? Theme.negativeChange : .gray)
                .font(.system(size: 14))
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Growth & Mortality View (Biological Adjustments)
// Debug: Shows biological changes affecting herd value - weight gain, mortality, breeding
struct HerdDynamicsView: View {
    // Debug: Enable dashboard-style title bar when embedded in dashboard.
    var showsDashboardHeader: Bool = false
    let herds: [HerdGroup]
    @State private var dynamicsTimeRange: DynamicsTimeRange = .week
    @State private var showingCustomDatePicker = false
    @State private var customStartDate: Date?
    @State private var customEndDate: Date?
    
    // Debug: Time range options for dynamics tracking
    enum DynamicsTimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
        case custom = "Custom"
        
        // Debug: Display label for each range
        var displayLabel: String {
            switch self {
            case .week: return "7d"
            case .month: return "1m"
            case .year: return "1y"
            case .all: return "All"
            case .custom: return "Custom"
            }
        }
        
        // Debug: Calculate days for each range
        func days(from customStart: Date?) -> Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            case .all: return Int.max // Use all days
            case .custom:
                if let startDate = customStart {
                    return Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 30
                }
                return 30
            }
        }
    }
    
    var body: some View {
        if showsDashboardHeader {
            // Debug: Dashboard layout with header at top level
            VStack(alignment: .leading, spacing: 16) {
                DashboardCardHeader(
                    title: "Growth & Mortality",
                    iconName: "heart.fill",
                    iconColor: Theme.dashboardDynamicsAccent,
                    timeRangeLabel: customDateRangeLabel
                ) {
                    ForEach(DynamicsTimeRange.allCases, id: \.self) { range in
                        Button {
                            HapticManager.tap()
                            if range == .custom {
                                showingCustomDatePicker = true
                            } else {
                                dynamicsTimeRange = range
                            }
                        } label: {
                            HStack {
                                Text(range.rawValue)
                                if dynamicsTimeRange == range {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    // Weight Gain Impact
                    if let weightGainMetrics = calculateWeightGainMetrics() {
                        BiologicalMetricRow(
                            title: "Weight Gain",
                            middleValue: "\(weightGainMetrics.totalKgGained.formatted(.number.precision(.fractionLength(0))))kg",
                            value: weightGainMetrics.valueImpact,
                            trend: .up
                        )
                    }
                    
                    // Calf Accrual
                    if let breedingMetrics = calculateBreedingMetrics() {
                        BiologicalMetricRow(
                            title: "Calf Accrual",
                            middleValue: "\(breedingMetrics.expectedProgeny)",
                            value: breedingMetrics.valueImpact,
                            trend: .up
                        )
                    }
                    
                    // Mortality Impact - always show, even if zero
                    let mortalityMetrics = calculateMortalityMetrics()
                    BiologicalMetricRow(
                        title: "Mortality",
                        middleValue: "\(mortalityMetrics.projectedLosses.formatted(.number.precision(.fractionLength(1))))",
                        value: -mortalityMetrics.valueImpact,
                        trend: mortalityMetrics.projectedLosses > 0 ? .down : .neutral
                    )
                    
                    // Show message if no biological data is available
                    if calculateWeightGainMetrics() == nil &&
                       calculateBreedingMetrics() == nil {
                        Text("No growth or breeding data tracked")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, Theme.dashboardCardPadding + 4)
                .padding(.bottom, Theme.dashboardCardPadding)
            }
            .sheet(isPresented: $showingCustomDatePicker) {
                CustomDateRangeSheet(
                    startDate: $customStartDate,
                    endDate: $customEndDate,
                    timeRange: Binding(
                        get: { 
                            dynamicsTimeRange == .custom ? .custom : .week 
                        },
                        set: { _ in 
                            dynamicsTimeRange = .custom 
                        }
                    )
                )
            }
        } else {
            // Debug: Herd detail layout - wrap everything in card structure
            VStack(alignment: .leading, spacing: 0) {
                // Header bar with icon and background
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Theme.dashboardIconBackground)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.dashboardDynamicsAccent)
                    }
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
                    
                    Text("Growth & Mortality")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Spacer(minLength: 8)
                    
                    // Time range selector pill - matches dashboard style
                    DashboardTimeRangePill(label: customDateRangeLabel) {
                        ForEach(DynamicsTimeRange.allCases, id: \.self) { range in
                            Button {
                                HapticManager.tap()
                                if range == .custom {
                                    showingCustomDatePicker = true
                                } else {
                                    dynamicsTimeRange = range
                                }
                            } label: {
                                HStack {
                                    Text(range.rawValue)
                                    if dynamicsTimeRange == range {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.dashboardCardPadding)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Theme.tertiaryBackground)
                
                // Content area
                VStack(alignment: .leading, spacing: 12) {
                    // Weight Gain Impact
                    if let weightGainMetrics = calculateWeightGainMetrics() {
                        BiologicalMetricRow(
                            title: "Weight Gain",
                            middleValue: "\(weightGainMetrics.totalKgGained.formatted(.number.precision(.fractionLength(0))))kg",
                            value: weightGainMetrics.valueImpact,
                            trend: .up
                        )
                    }
                    
                    // Calf Accrual
                    if let breedingMetrics = calculateBreedingMetrics() {
                        BiologicalMetricRow(
                            title: "Calf Accrual",
                            middleValue: "\(breedingMetrics.expectedProgeny)",
                            value: breedingMetrics.valueImpact,
                            trend: .up
                        )
                    }
                    
                    // Mortality Impact - always show, even if zero
                    let mortalityMetrics = calculateMortalityMetrics()
                    BiologicalMetricRow(
                        title: "Mortality",
                        middleValue: "\(mortalityMetrics.projectedLosses.formatted(.number.precision(.fractionLength(1))))",
                        value: -mortalityMetrics.valueImpact,
                        trend: mortalityMetrics.projectedLosses > 0 ? .down : .neutral
                    )
                    
                    // Show message if no biological data is available
                    if calculateWeightGainMetrics() == nil &&
                       calculateBreedingMetrics() == nil {
                        Text("No growth or breeding data tracked")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .padding(.vertical, 4)
                    }
                }
                .padding(Theme.dashboardCardPadding)
            }
            .sheet(isPresented: $showingCustomDatePicker) {
                CustomDateRangeSheet(
                    startDate: $customStartDate,
                    endDate: $customEndDate,
                    timeRange: Binding(
                        get: { 
                            dynamicsTimeRange == .custom ? .custom : .week 
                        },
                        set: { _ in 
                            dynamicsTimeRange = .custom 
                        }
                    )
                )
            }
        }
    }
    
    // Debug: Format custom date range label (e.g., "Jan 1 - Feb 15")
    private var customDateRangeLabel: String {
        if dynamicsTimeRange == .custom,
           let start = customStartDate,
           let end = customEndDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
        return dynamicsTimeRange.displayLabel
    }
    
    // MARK: - Weight Gain Calculations
    // Debug: Calculate total weight gained across all herds with active DWG over selected time range
    private func calculateWeightGainMetrics() -> (totalKgGained: Double, valueImpact: Double)? {
        let activeHerds = herds.filter { $0.isTrackingWeightGain }
        guard !activeHerds.isEmpty else { return nil }
        
        // Debug: Calculate days to consider based on time range
        let daysToConsider = dynamicsTimeRange.days(from: customStartDate)
        
        var totalKgGained: Double = 0
        
        for herd in activeHerds {
            // Debug: Use minimum of days held and selected time range
            let actualDaysHeld = Double(herd.daysHeld)
            let effectiveDays = min(actualDaysHeld, Double(daysToConsider))
            
            let weightPerHead = herd.dailyWeightGain * effectiveDays
            let totalWeight = weightPerHead * Double(herd.headCount)
            totalKgGained += totalWeight
        }
        
        // Debug: Estimate value impact at average market rate (~$4.50/kg)
        let estimatedValue = totalKgGained * 4.50
        
        return (totalKgGained: totalKgGained, valueImpact: estimatedValue)
    }
    
    // MARK: - Breeding Accrual Calculations
    // Debug: Calculate expected progeny value from pregnant herds
    private func calculateBreedingMetrics() -> (expectedProgeny: Int, valueImpact: Double)? {
        let breedingHerds = herds.filter { $0.hasValidBreedingData }
        guard !breedingHerds.isEmpty else { return nil }
        
        var totalExpectedProgeny: Double = 0
        
        for herd in breedingHerds {
            // Debug: Expected progeny = head count × calving rate
            let expected = Double(herd.headCount) * herd.calvingRate
            totalExpectedProgeny += expected
        }
        
        // Debug: Estimate value based on species (cattle ~$1200/calf, sheep ~$150/lamb)
        var estimatedValue: Double = 0
        for herd in breedingHerds {
            let progeny = Double(herd.headCount) * herd.calvingRate
            let valuePerHead = herd.species == "Cattle" ? 1200.0 : 150.0
            estimatedValue += progeny * valuePerHead
        }
        
        return (expectedProgeny: Int(totalExpectedProgeny), valueImpact: estimatedValue)
    }
    
    // MARK: - Mortality Impact Calculations
    // Debug: Calculate projected losses from mortality rates over selected time range
    // Always returns a value (even if 0) so the row always displays
    private func calculateMortalityMetrics() -> (projectedLosses: Double, valueImpact: Double) {
        let herdsWithMortality = herds.filter { ($0.mortalityRate ?? 0) > 0 }
        
        // Debug: Return 0 if no mortality data
        guard !herdsWithMortality.isEmpty else { 
            return (projectedLosses: 0.0, valueImpact: 0.0) 
        }
        
        // Debug: Calculate days to consider based on time range
        let daysToConsider = dynamicsTimeRange.days(from: customStartDate)
        
        var totalProjectedLosses: Double = 0
        var totalValueImpact: Double = 0
        
        for herd in herdsWithMortality {
            guard let annualRate = herd.mortalityRate else { continue }
            
            // Debug: Calculate daily mortality rate from annual rate
            let dailyRate = annualRate / 365.0
            
            // Debug: Use minimum of days held and selected time range
            let actualDaysHeld = Double(herd.daysHeld)
            let effectiveDays = min(actualDaysHeld, Double(daysToConsider))
            
            // Debug: Projected losses = head count × daily rate × effective days
            let projectedLosses = Double(herd.headCount) * dailyRate * effectiveDays
            totalProjectedLosses += projectedLosses
            
            // Debug: Value impact = losses × current weight × avg price
            let avgWeight = herd.approximateCurrentWeight
            let avgPrice = 4.50 // Approximate market price per kg
            totalValueImpact += projectedLosses * avgWeight * avgPrice
        }
        
        return (projectedLosses: totalProjectedLosses, valueImpact: totalValueImpact)
    }
}

// MARK: - Biological Metric Row Component
// Debug: Reusable row component for biological metrics display
struct BiologicalMetricRow: View {
    let title: String
    let middleValue: String
    let value: Double
    let trend: PriceTrend
    
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText)
            
            Spacer(minLength: 8)
            
            Text(middleValue)
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
                .frame(minWidth: 60, alignment: .trailing)
                .monospacedDigit()
            
            HStack(spacing: 6) {
                Text(value.formatted(.currency(code: "AUD").precision(.fractionLength(0))))
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
                
                Image(systemName: trend == .up ? "arrow.up.right" : trend == .down ? "arrow.down.right" : "minus")
                    .foregroundStyle(trend == .up ? Theme.positiveChange : trend == .down ? Theme.negativeChange : .gray)
                    .font(.system(size: 14))
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Quick Stats View (Placeholder)
// Debug: Simplified horizontal stat bar without card - compact layout per user request
struct QuickStatsView: View {
    let herds: [HerdGroup]
    
    var body: some View {
        HStack(spacing: 32) {
            // Total Herds stat
            HStack(spacing: 8) {
                Text("Total Herds")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                Text("\(herds.count)")
                    .font(Theme.title3) // HIG: title3 (20pt) for stat values
                    .foregroundStyle(Theme.primaryText)
            }
            
            Spacer()
            
            // Head stat
            HStack(spacing: 8) {
                Text("Head")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                Text("\(herds.reduce(0) { $0 + $1.headCount })")
                    .font(Theme.title3) // HIG: title3 (20pt) for stat values
                    .foregroundStyle(Theme.accentColor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quick stats: \(herds.count) herds, \(herds.reduce(0) { $0 + $1.headCount }) total head")
    }
}

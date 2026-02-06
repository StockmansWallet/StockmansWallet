//
//  HerdDetailView.swift
//  StockmansWallet
//
//  Detailed view of a single herd with valuation and management options
//  Debug: Optimized layout with chart and efficient data organization
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Saleyard Comparison Model
struct SaleyardComparison: Identifiable {
    let id = UUID()
    let saleyardName: String
    let value: Double
    let freightCost: Double
    let netValue: Double // value - freight
    let difference: Double // compared to default saleyard
    let isDefault: Bool
}

struct HerdDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    // Performance: Query all herds and individuals - needed to find specific herd by ID
    // SwiftData doesn't support querying single object by ID efficiently
    @Query private var allHerds: [HerdGroup]
    
    // Debug: Use 'let' with @Observable instead of @StateObject
    let valuationEngine = ValuationEngine.shared
    
    // Debug: Pass herd ID instead of object to avoid SwiftData context issues
    let herdId: UUID
    
    @State private var valuation: HerdValuation?
    @State private var isLoading = true
    
    // Debug: Error types for herd detail loading
    enum HerdDetailLoadError: Error, Equatable {
        case timeout
    }
    
    // Debug: Sell functionality for this herd
    @State private var showingSellSheet = false
    
    // Debug: Historical valuation data for chart (same as dashboard but for single herd)
    @State private var valuationHistory: [ValuationDataPoint] = []
    @State private var selectedDate: Date?
    @State private var selectedValue: Double?
    @State private var isScrubbing: Bool = false
    @State private var timeRange: TimeRange = .all
    @State private var customStartDate: Date?
    @State private var customEndDate: Date?
    @State private var baseValue: Double = 0.0
    @State private var showingCustomDatePicker = false
    @State private var isLoadingChart = false // Debug: Loading state for chart (Apple HIG)
    
    // Debug: Saleyard comparison state
    @State private var selectedComparisonSaleyards: Set<String> = []
    @State private var showingSaleyardSelector = false
    @State private var saleyardComparisons: [SaleyardComparison] = []
    
    // Debug: Fetch herd from current context using ID - safest SwiftData pattern
    private var herd: HerdGroup? {
        let foundHerd = allHerds.first(where: { $0.id == herdId })
        // Debug: Log if herd not found to help diagnose issues
        if foundHerd == nil {
            print("⚠️ HerdDetailView: Herd with ID \(herdId) not found in context")
            print("   Total herds in context: \(allHerds.count)")
        }
        return foundHerd
    }
    
    // Convenience initializer for backward compatibility
    init(herd: HerdGroup) {
        self.herdId = herd.id
    }
    
    // Primary initializer using herd ID
    init(herdId: UUID) {
        self.herdId = herdId
    }
    
    var body: some View {
        // Debug: Guard against nil herd to prevent crashes from stale SwiftData references
        if let activeHerd = herd {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                    // Debug: Show skeleton loaders while loading
                    if isLoading {
                        // Total value skeleton
                        HerdValueCardSkeleton()
                            .padding(.horizontal)
                        
                        // Detail cards skeletons
                        ForEach(0..<3, id: \.self) { _ in
                            HerdDetailCardSkeleton()
                                .padding(.horizontal)
                        }
                    } else {
                        // Debug: Total value card with herd name at the very top
                        if let valuation = valuation {
                            TotalValueCard(herd: activeHerd, valuation: valuation)
                                .padding(.horizontal)
                        }
                        
                        // Debug: Head count text below value
                        // Only show for herds (headCount > 1), not for individual animals to avoid duplication
                        if activeHerd.headCount > 1 {
                            HerdStatsCard(herd: activeHerd)
                                .padding(.horizontal)
                                .padding(.top, -12) // Debug: Reduce spacing from value above
                        }
                            
                        // Debug: Herd Value Chart - shows value over time (same as dashboard but for single herd)
                        // Replaces weight growth chart; weight info already shown in cards below
                        // Apple HIG: Show loading skeleton while chart data loads asynchronously
                        if isLoadingChart {
                            ChartSkeletonLoader()
                                .padding(.horizontal)
                        } else if !valuationHistory.isEmpty {
                            HerdValueChartCard(
                                data: filteredHistory,
                                selectedDate: $selectedDate,
                                selectedValue: $selectedValue,
                                isScrubbing: $isScrubbing,
                                timeRange: $timeRange,
                                customStartDate: customStartDate,
                                customEndDate: customEndDate,
                                baseValue: baseValue,
                                showingCustomDatePicker: $showingCustomDatePicker,
                                herdName: activeHerd.name
                            )
                            .padding(.horizontal)
                        }
                        
                        // Debug: Growth & Mortality card (same as dashboard but for single herd)
                        HerdDynamicsView(
                            showsDashboardHeader: false,
                            herds: [activeHerd]
                        )
                        .cardStyle()
                        .padding(.horizontal)
                        
                        // Debug: Primary valuation metrics
                        if let valuation = valuation {
                            PrimaryMetricsCard(herd: activeHerd, valuation: valuation)
                                .padding(.horizontal)
                        }
                        
                        // Debug: Saleyard Comparison card
                        SaleyardComparisonCard(
                            herd: activeHerd,
                            valuation: valuation,
                            selectedComparisonSaleyards: $selectedComparisonSaleyards,
                            showingSaleyardSelector: $showingSaleyardSelector,
                            saleyardComparisons: $saleyardComparisons,
                            valuationEngine: valuationEngine,
                            modelContext: modelContext,
                            preferences: preferences.first ?? UserPreferences()
                        )
                        .padding(.horizontal)
                        
                        // Debug: Consolidated herd details - all key info in one card
                        HerdDetailsCard(herd: activeHerd, valuation: valuation)
                            .padding(.horizontal)
                        
                        // Debug: Breeding info only if applicable - shown before other records
                        if activeHerd.isBreeder {
                            BreedingDetailsCard(herd: activeHerd)
                                .padding(.horizontal)
                        }
                        
                        // Debug: Mustering records card - always shown so users know this feature exists
                        MusteringHistoryCard(herd: activeHerd)
                            .padding(.horizontal)
                        
                        // Debug: Health records card - always shown so users know this feature exists
                        HealthRecordsCard(herd: activeHerd)
                            .padding(.horizontal)
                        
                    }
                    
                    // Debug: Record Sale button at bottom of detail page (not floating, just regular button)
                    if !isLoading && !activeHerd.isSold {
                        Button {
                            HapticManager.tap()
                            showingSellSheet = true
                        } label: {
                            Text("Record Sale")
                                .font(Theme.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .accessibilityLabel("Record sale")
                    }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 100)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Herd Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: EditHerdView(herd: activeHerd)) {
                        Text("Edit")
                            .foregroundStyle(Theme.accentColor)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingSellSheet) {
                SellStockView(preselectedHerdId: activeHerd.id)
                    .transition(.move(edge: .trailing))
                    .presentationBackground(Theme.sheetBackground)
            }
            .sheet(isPresented: $showingCustomDatePicker) {
                CustomDateRangeSheet(
                    startDate: $customStartDate,
                    endDate: $customEndDate,
                    timeRange: $timeRange
                )
            }
            .onChange(of: timeRange) { _, _ in
                // Debug: Reset scrubbing state when time range changes
                isScrubbing = false
                selectedDate = nil
                selectedValue = nil
            }
            .task {
                await loadValuation()
            }
        } else {
            // Debug: Show error if herd can't be found in context
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                
                Text("Herd Not Found")
                    .font(Theme.title)
                    .foregroundStyle(Theme.primaryText)
                
                Text("This herd may have been deleted or is no longer available.")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.backgroundGradient)
        }
    }
    
    // Debug: Filter history based on selected time range (same as dashboard)
    private var filteredHistory: [ValuationDataPoint] {
        let now = Date()
        let calendar = Calendar.current
        
        switch timeRange {
        case .custom:
            // Debug: Use custom date range if specified
            guard let startDate = customStartDate, let endDate = customEndDate else {
                return valuationHistory
            }
            return valuationHistory.filter { point in
                point.date >= startDate && point.date <= endDate
            }
        case .day:
            guard let startDate = calendar.date(byAdding: .day, value: -1, to: now) else {
                return valuationHistory
            }
            return valuationHistory.filter { $0.date >= startDate }
        case .week:
            guard let startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else {
                return valuationHistory
            }
            return valuationHistory.filter { $0.date >= startDate }
        case .month:
            guard let startDate = calendar.date(byAdding: .month, value: -1, to: now) else {
                return valuationHistory
            }
            return valuationHistory.filter { $0.date >= startDate }
        case .year:
            guard let startDate = calendar.date(byAdding: .year, value: -1, to: now) else {
                return valuationHistory
            }
            return valuationHistory.filter { $0.date >= startDate }
        case .all:
            return valuationHistory
        }
    }
    
    private func loadValuation() async {
        print("🔄 HerdDetailView: Starting loadValuation for herd ID: \(herdId)")
        await MainActor.run { isLoading = true }
        
        // Debug: Check if herd exists in current context
        guard let activeHerd = herd else {
            print("❌ HerdDetailView: Failed to find herd in context")
            await MainActor.run {
                self.isLoading = false
            }
            return
        }
        
        // Debug: Log herd details safely
        let herdName = activeHerd.name
        print("✅ HerdDetailView: Found herd: \(herdName)")
        
        let prefs = preferences.first ?? UserPreferences()
        
        // Debug: Wrap in do-catch with timeout for proper error handling (prevents skeleton loader from hanging)
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                // Add calculation task
                group.addTask {
                    try await self.performHerdValuationCalculation(herd: activeHerd, prefs: prefs)
                }
                
                // Add timeout task (30 seconds - reasonable for slow networks)
                group.addTask {
                    try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                    throw HerdDetailLoadError.timeout
                }
                
                // Wait for first task to complete (either calculation or timeout)
                try await group.next()
                
                // Cancel remaining tasks
                group.cancelAll()
            }
            
            // Debug: Load historical valuation data AFTER main valuation completes
            // This runs outside the timeout so older herds with long histories can complete loading
            // The chart will appear once the data finishes loading (even if it takes >30 seconds)
            // Apple HIG: Show loading skeleton while data loads
            await MainActor.run { isLoadingChart = true }
            print("📊 HerdDetailView: Loading historical valuation data (background)...")
            await loadHistoricalValuationData(herd: activeHerd, prefs: prefs)
            await MainActor.run { isLoadingChart = false }
            
        } catch is CancellationError {
            print("⚠️ HerdDetailView: Load cancelled by user navigation")
            await MainActor.run {
                self.isLoading = false
            }
        } catch let error as HerdDetailLoadError where error == .timeout {
            print("⏱️ HerdDetailView: Load timed out after 30 seconds")
            await MainActor.run {
                self.isLoading = false
            }
            HapticManager.error()
            
            // Debug: Still load historical data even after timeout - chart will appear when ready
            // Apple HIG: Show loading skeleton while data loads
            await MainActor.run { isLoadingChart = true }
            print("📊 HerdDetailView: Loading historical valuation data (after timeout)...")
            await loadHistoricalValuationData(herd: activeHerd, prefs: prefs)
            await MainActor.run { isLoadingChart = false }
        } catch {
            print("❌ HerdDetailView: Failed to load valuation - \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
            HapticManager.error()
        }
    }
    
    // Debug: Extracted calculation logic for better error handling
    private func performHerdValuationCalculation(herd: HerdGroup, prefs: UserPreferences) async throws {
        print("🔄 HerdDetailView: Calculating valuation...")
        
        // Debug: Prefetch prices to avoid redundant queries
        await valuationEngine.prefetchPricesForHerds([herd])
        
        let calculatedValuation = await valuationEngine.calculateHerdValue(
            herd: herd,
            preferences: prefs,
            modelContext: modelContext
        )
        print("✅ HerdDetailView: Valuation calculated: \(calculatedValuation.netRealizableValue)")
        await MainActor.run {
            self.valuation = calculatedValuation
            self.isLoading = false
        }
        
        // Debug: Historical data loading moved outside this function to avoid timeout issues
    }
    
    // Debug: Load historical valuation data for a single herd (similar to dashboard but for one herd)
    // Performance: Uses smart sampling - daily for last 30 days, weekly for older data
    private func loadHistoricalValuationData(herd: HerdGroup, prefs: UserPreferences) async {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.startOfDay(for: herd.createdAt)
        let endDate = calendar.startOfDay(for: today)
        
        // Debug: Calculate number of days of history
        let dayComponents = calendar.dateComponents([.day], from: startDate, to: endDate)
        let totalDays = (dayComponents.day ?? 0) + 1 // +1 to include today
        
        // Debug: CRITICAL - Prefetch prices ONCE before looping through all days
        // This prevents hundreds of redundant database queries
        print("📊 Prefetching prices for historical calculations...")
        await valuationEngine.prefetchPricesForHerds([herd])
        print("📊 Prefetch complete, now calculating history...")
        
        var history: [ValuationDataPoint] = []
        
        // Debug: Smart sampling based on herd age (performance optimization)
        // - Last 30 days: Daily data points (max 30 points)
        // - Older than 30 days: Weekly data points (1 point per 7 days)
        // This dramatically reduces calculations for older herds (e.g. 180 days = 30 daily + 21 weekly = 51 points vs 180)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        
        var datesToCalculate: [Date] = []
        
        // Generate dates to calculate
        for dayOffset in 0..<totalDays {
            guard let dateAtStartOfDay = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }
            
            // Last 30 days: Calculate every day
            if dateAtStartOfDay >= thirtyDaysAgo {
                datesToCalculate.append(dateAtStartOfDay)
            }
            // Older than 30 days: Calculate weekly (every 7th day)
            else if dayOffset % 7 == 0 {
                datesToCalculate.append(dateAtStartOfDay)
            }
        }
        
        // Always include today if not already included
        if !datesToCalculate.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            datesToCalculate.append(today)
        }
        
        print("📊 Generating \(datesToCalculate.count) sampled data points for herd: \(herd.name) (total days: \(totalDays))")
        
        // Debug: Generate data points for sampled dates
        for (index, dateAtStartOfDay) in datesToCalculate.enumerated() {
            // Debug: Set time to end of day (11:59:59 PM) for accurate daily valuations
            let dateAtEndOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: dateAtStartOfDay) ?? dateAtStartOfDay
            
            // Debug: Calculate valuation for this specific date
            let valuation = await valuationEngine.calculateHerdValue(
                herd: herd,
                preferences: prefs,
                modelContext: modelContext,
                asOfDate: dateAtEndOfDay
            )
            
            history.append(ValuationDataPoint(
                date: dateAtEndOfDay,
                value: valuation.netRealizableValue,
                physicalValue: valuation.physicalValue,
                breedingAccrual: valuation.breedingAccrual
            ))
            
            // Debug: Log progress for longer histories (every 10 points or first/last)
            #if DEBUG
            if datesToCalculate.count > 10 && (index == 0 || index % 10 == 0 || index == datesToCalculate.count - 1) {
                print("📊 Point \(index + 1)/\(datesToCalculate.count): \(dateAtStartOfDay.formatted(.dateTime.month().day())) = $\(String(format: "%.0f", valuation.netRealizableValue))")
            }
            #endif
        }
        
        // Debug: Ensure chart has at least 2 points to display a line
        // If we only have 1 point (brand new herd), add a starting point at $0
        if history.count == 1, let firstPoint = history.first {
            let dayBefore = calendar.date(byAdding: .day, value: -1, to: firstPoint.date) ?? firstPoint.date
            history.insert(ValuationDataPoint(
                date: dayBefore,
                value: 0.0,
                physicalValue: 0.0,
                breedingAccrual: 0.0
            ), at: 0)
            print("📊 Added starting point at $0 for single-day herd")
        }
        
        await MainActor.run {
            self.valuationHistory = history
            // Debug: Set base value to first data point for change calculations
            self.baseValue = history.first?.value ?? 0.0
            
            #if DEBUG
            print("📊 ============================================")
            print("📊 Herd history loaded: \(history.count) data points")
            if let first = history.first, let last = history.last {
                print("📊 Date range: \(first.date.formatted(.dateTime.month().day())) ($\(String(format: "%.0f", first.value))) to \(last.date.formatted(.dateTime.month().day())) ($\(String(format: "%.0f", last.value)))")
                let totalChange = last.value - first.value
                let percentChange = first.value > 0 ? (totalChange / first.value * 100) : 0
                print("📊 Total change: $\(String(format: "%.0f", totalChange)) (\(String(format: "%.1f", percentChange))%)")
            }
            print("📊 ============================================")
            #endif
        }
    }
}

// MARK: - Total Value Card
// Debug: Prominent total value display with herd name at the top - no background for cleaner look
struct TotalValueCard: View {
    let herd: HerdGroup
    let valuation: HerdValuation
    
    // Debug: Format currency value with grey decimal portion
    private var formattedValue: (whole: String, decimal: String) {
        let value = valuation.netRealizableValue
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        numberFormatter.groupingSeparator = ","
        numberFormatter.usesGroupingSeparator = true
        
        let whole = numberFormatter.string(from: NSNumber(value: abs(value))) ?? "0"
        let decimal = String(format: "%02d", Int((abs(value) - floor(abs(value))) * 100))
        
        return (whole: whole, decimal: decimal)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Debug: Herd name centered and smaller
            HStack {
                Spacer()
                Text(herd.name)
                    .font(Theme.headline)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Debug: SOLD badge inline with name if applicable
                if herd.isSold {
                    Text("SOLD")
                        .font(Theme.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.red)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            
            // Debug: Total value with grey decimal - matches Dashboard/Portfolio styling
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("$")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(-2)
                    .baselineOffset(3)
                    .padding(.trailing, 6)
                
                Text(formattedValue.whole)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(-2)
                    .monospacedDigit()
                
                Text(".")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "9E9E9E"))
                    .tracking(-2)
                
                Text(formattedValue.decimal)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "9E9E9E"))
                    .tracking(-1)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

// MARK: - Herd Stats Card
// Debug: Simple text showing head count below main value
struct HerdStatsCard: View {
    let herd: HerdGroup
    
    var body: some View {
        Text("\(herd.headCount) Head")
            .font(Theme.subheadline)
            .foregroundStyle(Theme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Herd Value Chart Card
// Debug: Shows herd value over time with interactive scrubbing (same as dashboard chart)
// Replaces weight growth chart; weight info already shown in cards below
struct HerdValueChartCard: View {
    let data: [ValuationDataPoint]
    @Binding var selectedDate: Date?
    @Binding var selectedValue: Double?
    @Binding var isScrubbing: Bool
    @Binding var timeRange: TimeRange
    let customStartDate: Date?
    let customEndDate: Date?
    let baseValue: Double
    @Binding var showingCustomDatePicker: Bool
    let herdName: String
    
    // Debug: Format time range label for the pill menu
    private var timeRangeLabel: String {
        if timeRange == .custom, let startDate = customStartDate, let endDate = customEndDate {
            return "\(startDate.formatted(.dateTime.month().day())) - \(endDate.formatted(.dateTime.month().day()))"
        }
        return timeRange.rawValue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Debug: Range selector pill only (no header bar - matches dashboard chart)
            HStack {
                Spacer()
                DashboardTimeRangePill(label: timeRangeLabel) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button {
                            HapticManager.tap()
                            if range == .custom {
                                showingCustomDatePicker = true
                            } else {
                                timeRange = range
                            }
                        } label: {
                            HStack {
                                Text(range.rawValue)
                                if timeRange == range {
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
            .background(Color.clear)
            
            // Debug: Interactive chart (reuses dashboard chart component)
            InteractiveChartView(
                data: data,
                selectedDate: $selectedDate,
                selectedValue: $selectedValue,
                isScrubbing: $isScrubbing,
                timeRange: $timeRange,
                customStartDate: customStartDate,
                customEndDate: customEndDate,
                baseValue: baseValue,
                onValueChange: { _, _ in
                    // Debug: No-op for herd chart; value display handled in header
                }
            )
            .clipped()
            .padding(.top, -32) // Debug: Compensate for internal date hover pill spacer
            .padding(.horizontal, 0) // Debug: Chart line should reach card edges
        }
        .cardStyle()
    }
}

// MARK: - Primary Metrics Card
// Debug: Key valuation metrics in list format to match Physical Attributes style
struct PrimaryMetricsCard: View {
    let herd: HerdGroup
    let valuation: HerdValuation
    
    // Format currency values as strings
    private var formattedPricePerKg: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "AUD"
        formatter.maximumFractionDigits = 2
        return (formatter.string(from: NSNumber(value: valuation.pricePerKg)) ?? "$0.00") + "/kg"
    }
    
    private var formattedValuePerHead: String {
        let valuePerHead = valuation.netRealizableValue / Double(herd.headCount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "AUD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: valuePerHead)) ?? "$0.00"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Debug: Header bar with icon and dark background like dashboard cards
            HStack(spacing: 10) {
                // Debug: Icon with circular background
                ZStack {
                    Circle()
                        .fill(Theme.dashboardIconBackground)
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.dashboardPerformanceAccent)
                }
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
                
                Text("Key Metrics")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.tertiaryBackground)
            
            // Debug: Content area
            VStack(alignment: .leading, spacing: 8) {
                // Key metrics in list format
                DetailRow(label: "Price (Per Kilogram)", value: formattedPricePerKg)
                DetailRow(label: "Average Weight", value: "\(Int(valuation.projectedWeight)) kg")
                DetailRow(label: "Value Per Head", value: formattedValuePerHead)
                
                // Debug: Show herd's specific saleyard with consistent icon
                HStack {
                    Image(systemName: "dollarsign.bank.building")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                    Text(herd.selectedSaleyard ?? "No saleyard selected")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.top, 4)
            }
            .padding(Theme.dashboardCardPadding)
        }
        .cardStyle()
    }
}

// MARK: - Herd Details Card
// Debug: Organized herd information into logical sections
struct HerdDetailsCard: View {
    let herd: HerdGroup
    let valuation: HerdValuation?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Debug: Header bar with icon and dark background like dashboard cards
            HStack(spacing: 10) {
                // Debug: Icon with circular background
                ZStack {
                    Circle()
                        .fill(Theme.dashboardIconBackground)
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.sectionRiver)
                }
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
                
                Text("Herd Details")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.tertiaryBackground)
            
            // Debug: Content area with sections
            VStack(alignment: .leading, spacing: 20) {
                // Physical Attributes Section
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Physical Attributes")
                    DetailRow(label: "Species", value: herd.species)
                    DetailRow(label: "Breed", value: herd.breed)
                    DetailRow(label: "Category", value: herd.category)
                    DetailRow(label: "Sex", value: herd.sex)
                    DetailRow(label: "Age", value: "\(herd.ageMonths) months")
                }
            
            Divider()
                .background(Theme.separator.opacity(0.3))
            
            // Herd Size & Location Section
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Herd Size & Location")
                DetailRow(label: "Headcount", value: "\(herd.headCount) head")
                if let paddock = herd.paddockName, !paddock.isEmpty {
                    DetailRow(label: "Paddock", value: paddock)
                }
                // Debug: Show mortality rate if it exists
                if let mortality = herd.mortalityRate, mortality > 0 {
                    DetailRow(label: "Mortality Rate", value: "\(Int(mortality * 100))% annually")
                }
            }
            
            Divider()
                .background(Theme.separator.opacity(0.3))
            
            // Weight Tracking Section
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Weight Tracking")
                DetailRow(label: "Initial Weight", value: "\(Int(herd.initialWeight)) kg")
                DetailRow(label: "Daily Weight Gain", value: String(format: "%.2f kg/day", herd.dailyWeightGain))
            }
            
            Divider()
                .background(Theme.separator.opacity(0.3))
            
            // Timeline Section
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Timeline")
                DetailRow(label: "Days Held", value: "\(herd.daysHeld) days")
                DetailRow(label: "Created", value: herd.createdAt.formatted(date: .abbreviated, time: .omitted))
                DetailRow(label: "Last Updated", value: herd.updatedAt.formatted(date: .abbreviated, time: .omitted))
                // Debug: Show most recent muster date if any muster records exist
                if let lastMuster = herd.lastMusterDate {
                    DetailRow(label: "Last Mustered", value: lastMuster.formatted(date: .abbreviated, time: .omitted))
                }
            }
            
            // Debug: Show notes if they exist - general farmer notes displayed for all herds/animals
            if let notes = herd.notes, !notes.isEmpty {
                Divider()
                    .background(Theme.separator.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Notes")
                    Text(notes)
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Debug: Show additional info if exists (for non-breeders - breeding herds show this in BreedingDetailsCard)
            if let additionalInfo = herd.additionalInfo, !additionalInfo.isEmpty, !herd.isBreeder {
                Divider()
                    .background(Theme.separator.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Additional Information")
                    Text(additionalInfo)
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            }
            .padding(Theme.dashboardCardPadding)
        }
        .cardStyle()
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            // Debug: Promoted to headline style now that main "Animal Details" heading is removed
            .font(Theme.headline)
            .foregroundStyle(Theme.primaryText)
            // Removed uppercase and changed color for better hierarchy
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text(value)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Breeding Details Card
// Debug: Breeding information only shown when herd.isBreeder is true
struct BreedingDetailsCard: View {
    let herd: HerdGroup
    
    // Debug: Parse breeding program information from additionalInfo
    private var breedingProgramInfo: (type: String?, details: String?) {
        guard let additionalInfo = herd.additionalInfo else {
            return (nil, nil)
        }
        
        // Parse breeding program type (AI, Controlled, Uncontrolled)
        if additionalInfo.contains("Breeding: AI") {
            let components = additionalInfo.components(separatedBy: "Insemination Period: ")
            let details = components.count > 1 ? components[1].components(separatedBy: "\n").first : nil
            return ("AI (Artificial Insemination)", details)
        } else if additionalInfo.contains("Breeding: Controlled") {
            let components = additionalInfo.components(separatedBy: "Joining Period: ")
            let details = components.count > 1 ? components[1].components(separatedBy: "\n").first : nil
            return ("Controlled Breeding", details)
        } else if additionalInfo.contains("Breeding: Uncontrolled") {
            return ("Uncontrolled Breeding", nil)
        }
        
        return (nil, nil)
    }
    
    // Debug: Parse calves at foot information from additionalInfo
    private var calvesAtFootInfo: String? {
        guard let additionalInfo = herd.additionalInfo else { return nil }
        
        // Look for "Calves at Foot: X head, Y months" pattern - stop at pipe or newline
        if let range = additionalInfo.range(of: "Calves at Foot: ([^|\\n]+)", options: .regularExpression) {
            let calvesInfo = String(additionalInfo[range])
            // Extract just the numeric part after "Calves at Foot: " and trim whitespace
            return calvesInfo.replacingOccurrences(of: "Calves at Foot: ", with: "").trimmingCharacters(in: .whitespaces)
        }
        
        return nil
    }
    
    // Debug: Extract any other notes from additionalInfo (excluding breeding and calves info)
    private var generalNotes: String? {
        guard let additionalInfo = herd.additionalInfo else { return nil }
        
        // Split by newlines and filter out breeding/calves lines
        let lines = additionalInfo.components(separatedBy: "\n")
            .filter { !$0.contains("Breeding:") && !$0.contains("Calves at Foot:") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return lines.isEmpty ? nil : lines
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Debug: Header bar with icon and dark background like dashboard cards
            HStack(spacing: 10) {
                // Debug: Icon with circular background
                ZStack {
                    Circle()
                        .fill(Theme.dashboardIconBackground)
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.sectionClay)
                }
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
                
                Text("Breeding Information")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.tertiaryBackground)
            
            // Debug: Content area
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 8) {
                    // Debug: Show breeding program type if available
                    if let programType = breedingProgramInfo.type {
                        DetailRow(label: "Breeding Program", value: programType)
                        
                        // Show joining/insemination period if available
                        if let periodDetails = breedingProgramInfo.details {
                            DetailRow(label: "Period", value: periodDetails)
                        }
                    }
                
                DetailRow(label: "Calving Rate", value: "\(Int(herd.calvingRate * 100))%")
                DetailRow(label: "Pregnant", value: herd.isPregnant ? "Yes" : "No")
                
                if let joinedDate = herd.joinedDate {
                    DetailRow(label: "Joined Date", value: joinedDate.formatted(date: .abbreviated, time: .omitted))
                    
                    if herd.isPregnant {
                        let daysSinceJoined = Calendar.current.dateComponents([.day], from: joinedDate, to: Date()).day ?? 0
                        let cycleLength = herd.species == "Cattle" ? 283 : 150
                        let daysRemaining = max(0, cycleLength - daysSinceJoined)
                        
                        DetailRow(label: "Days Since Joined", value: "\(daysSinceJoined)")
                        DetailRow(label: "Est. Days to Calving", value: "\(daysRemaining)")
                    }
                }
                
                if let lactationStatus = herd.lactationStatus {
                    DetailRow(label: "Lactation", value: lactationStatus)
                }
                
                // Debug: Show calves at foot information if available
                if let calvesInfo = calvesAtFootInfo {
                    DetailRow(label: "Calves at Foot", value: calvesInfo)
                }
            }
            
            // Debug: Show general notes in a separate section if they exist
            if let notes = generalNotes {
                Divider()
                    .background(Theme.separator.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Notes")
                    Text(notes)
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            }
            .padding(Theme.dashboardCardPadding)
        }
        .cardStyle()
    }
}

// MARK: - Mustering Records Card
// Debug: Display full mustering records with dates and notes - always shown with empty state
struct MusteringHistoryCard: View {
    let herd: HerdGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Debug: Header bar with icon and dark background like dashboard cards
            HStack(spacing: 10) {
                // Debug: Icon with circular background
                ZStack {
                    Circle()
                        .fill(Theme.dashboardIconBackground)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.sectionPasture)
                }
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
                
                Text("Mustering Records")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Spacer()
                
                // Debug: Show count of muster records (even if 0 to indicate feature exists)
                let recordCount = herd.musterRecords?.count ?? 0
                Text("\(recordCount) record\(recordCount == 1 ? "" : "s")")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.tertiaryBackground)
            
            // Debug: Content area with muster records or empty state
            VStack(spacing: 12) {
                if let records = herd.musterRecords, !records.isEmpty {
                    // Debug: Show existing muster records
                    ForEach(herd.sortedMusterRecords) { record in
                        MusterRecordRow(record: record)
                    }
                } else {
                    // Debug: Empty state - inform user about feature availability
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.secondaryText.opacity(0.5))
                            .padding(.bottom, 4)
                        
                        Text("No records yet")
                            .font(Theme.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.primaryText)
                        
                        Text("Track muster dates, head counts, weaners, branders, and cattle yards")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                        
                        Text("Tap Edit to add mustering records")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.accentColor)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(Theme.dashboardCardPadding)
        }
        .cardStyle()
    }
}

// MARK: - Muster Record Row
// Debug: Individual row displaying a single muster record with all details
struct MusterRecordRow: View {
    let record: MusterRecord
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Debug: Calendar icon for muster date
            ZStack {
                Circle()
                    .fill(Theme.accentColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Muster date
                Text(record.formattedDate)
                    .font(Theme.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.primaryText)
                
                // Debug: Compact layout - Total Head, Weaners, Branders all on same line
                if record.totalHeadCount != nil || record.weanersCount != nil || record.brandersCount != nil {
                    HStack(spacing: 8) {
                        if let headCount = record.totalHeadCount {
                            HStack(spacing: 4) {
                                Text("Total Head:")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                Text("\(headCount)")
                                    .font(Theme.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.primaryText)
                            }
                        }
                        
                        if let weaners = record.weanersCount {
                            HStack(spacing: 4) {
                                Text("Weaners:")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                Text("\(weaners)")
                                    .font(Theme.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.primaryText)
                            }
                        }
                        
                        if let branders = record.brandersCount {
                            HStack(spacing: 4) {
                                Text("Branders:")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                Text("\(branders)")
                                    .font(Theme.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.primaryText)
                            }
                        }
                    }
                }
                
                // Debug: Yard on its own line
                if let yard = record.cattleYard, !yard.isEmpty {
                    HStack(spacing: 4) {
                        Text("Yard:")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(yard)
                            .font(Theme.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.primaryText)
                    }
                }
                
                // Notes if they exist - with "Notes:" label
                if let notes = record.notes, !notes.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Text("Notes:")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(notes)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Theme.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Health Records Card
// Debug: Display health treatment history with dates and treatment types - always shown with empty state
struct HealthRecordsCard: View {
    let herd: HerdGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Debug: Header bar with icon and dark background like dashboard cards
            HStack(spacing: 10) {
                // Debug: Icon with circular background
                ZStack {
                    Circle()
                        .fill(Theme.dashboardIconBackground)
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.red)
                }
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
                
                Text("Health Records")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Spacer()
                
                // Debug: Show count of health records (even if 0 to indicate feature exists)
                let recordCount = herd.healthRecords?.count ?? 0
                Text("\(recordCount) record\(recordCount == 1 ? "" : "s")")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.tertiaryBackground)
            
            // Debug: Content area with health records or empty state
            VStack(spacing: 12) {
                if let records = herd.healthRecords, !records.isEmpty {
                    // Debug: Show existing health records
                    ForEach(herd.sortedHealthRecords) { record in
                        HealthRecordRow(record: record)
                    }
                } else {
                    // Debug: Empty state - inform user about feature availability
                    VStack(spacing: 8) {
                        Image(systemName: "cross.case")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.secondaryText.opacity(0.5))
                            .padding(.bottom, 4)
                        
                        Text("No records yet")
                            .font(Theme.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.primaryText)
                        
                        Text("Track vaccinations, drenching, treatments, and other health interventions")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                        
                        Text("Tap Edit to add health records")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.accentColor)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(Theme.dashboardCardPadding)
        }
        .cardStyle()
    }
}

// MARK: - Health Record Row
// Debug: Individual row displaying a single health record
struct HealthRecordRow: View {
    let record: HealthRecord
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Debug: Treatment type icon
            ZStack {
                Circle()
                    .fill(Theme.accentColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: record.treatmentIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Debug: Match Mustering History format - Date on first line
                Text(record.formattedDate)
                    .font(Theme.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.primaryText)
                
                // Debug: Treatment type on second line with label format
                HStack(spacing: 4) {
                    Text("Treatment:")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Text(record.treatmentDescription)
                        .font(Theme.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.primaryText)
                }
                
                // Debug: Notes on third line with label - matches Mustering History
                if let notes = record.notes, !notes.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Text("Notes:")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(notes)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Theme.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Saleyard Comparison Card
struct SaleyardComparisonCard: View {
    let herd: HerdGroup
    let valuation: HerdValuation?
    @Binding var selectedComparisonSaleyards: Set<String>
    @Binding var showingSaleyardSelector: Bool
    @Binding var saleyardComparisons: [SaleyardComparison]
    let valuationEngine: ValuationEngine
    let modelContext: ModelContext
    let preferences: UserPreferences
    
    // Debug: Calculate estimated freight cost (placeholder until TruckIt API)
    private func estimateFreightCost(to saleyard: String) -> Double {
        // Debug: Realistic placeholder costs based on distance/location patterns
        // NSW regional: $300-800, Interstate: $1000-3000, Remote: $3000+
        let cost: Double
        
        if saleyard.contains("Wagga Wagga") || saleyard.contains("Forbes") {
            cost = Double.random(in: 300...500)
        } else if saleyard.contains("Dubbo") || saleyard.contains("Tamworth") {
            cost = Double.random(in: 400...700)
        } else if saleyard.contains("Roma") || saleyard.contains("Dalby") {
            cost = Double.random(in: 800...1500)
        } else if saleyard.contains("Muchea") || saleyard.contains("Mount Barker") {
            cost = Double.random(in: 2000...3500)
        } else if saleyard.contains("Powranna") || saleyard.contains("Quoiba") {
            cost = Double.random(in: 1500...2500)
        } else {
            cost = Double.random(in: 500...1200)
        }
        
        // Round to nearest $50 for realism
        return (cost / 50).rounded() * 50
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar with icon
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Theme.dashboardIconBackground)
                    Image(systemName: "dollarsign.bank.building")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.sectionAmber)
                }
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
                
                Text("Saleyard Comparison")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Theme.tertiaryBackground)
            
            // Content area
            VStack(alignment: .leading, spacing: 16) {
                // Default saleyard value
                if let defaultSaleyard = herd.selectedSaleyard, let val = valuation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Herd Default Saleyard")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.accentColor)
                        
                        HStack {
                            Text(defaultSaleyard)
                                .font(Theme.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.primaryText)
                            
                            Spacer()
                            
                            Text(val.netRealizableValue.formatted(.currency(code: "AUD").precision(.fractionLength(0))))
                                .font(Theme.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.primaryText)
                        }
                    }
                    .padding(12)
                    .background(Theme.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                
                // Saleyard selector button
                Button {
                    HapticManager.tap()
                    showingSaleyardSelector = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.square")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.accentColor)
                        
                        Text("Select Saleyards to compare")
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .padding(12)
                    .background(Theme.cardBackground.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                
                // Comparison results
                if !saleyardComparisons.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(saleyardComparisons.filter { !$0.isDefault }) { comparison in
                            SaleyardComparisonRow(
                                comparison: comparison,
                                defaultValue: valuation?.netRealizableValue ?? 0
                            )
                        }
                    }
                }
                
                // Footer note about freight
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText.opacity(0.5))
                    Text("Freight estimations provided by TruckIt®")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(Theme.dashboardCardPadding)
        }
        .cardStyle()
        .sheet(isPresented: $showingSaleyardSelector) {
            MultipleSaleyardSelectionSheet(
                selectedSaleyards: $selectedComparisonSaleyards,
                excludeSaleyard: herd.selectedSaleyard
            )
        }
        .onChange(of: selectedComparisonSaleyards) { _, newSaleyards in
            Task {
                await calculateComparisons(for: newSaleyards)
            }
        }
        .task {
            // Auto-select a few nearby saleyards for initial comparison
            if selectedComparisonSaleyards.isEmpty {
                // Pick 2-3 random saleyards for demo
                let availableSaleyards = ReferenceData.saleyards.filter { $0 != herd.selectedSaleyard }
                selectedComparisonSaleyards = Set(availableSaleyards.prefix(2))
            }
        }
    }
    
    // Calculate valuations for comparison saleyards
    private func calculateComparisons(for saleyards: Set<String>) async {
        guard let defaultValue = valuation?.netRealizableValue else { return }
        
        // Debug: Prefetch prices for all comparison saleyards to avoid N+1 queries
        await valuationEngine.prefetchPricesForHerds([herd])
        
        var comparisons: [SaleyardComparison] = []
        
        for saleyardName in saleyards {
            // Calculate valuation for this saleyard
            let comparisonValuation = await valuationEngine.calculateHerdValue(
                herd: herd,
                preferences: preferences,
                modelContext: modelContext,
                saleyardOverride: saleyardName
            )
            
            let freightCost = estimateFreightCost(to: saleyardName)
            let netValue = comparisonValuation.netRealizableValue - freightCost
            let difference = netValue - defaultValue
            
            comparisons.append(SaleyardComparison(
                saleyardName: saleyardName,
                value: comparisonValuation.netRealizableValue,
                freightCost: freightCost,
                netValue: netValue,
                difference: difference,
                isDefault: false
            ))
        }
        
        // Sort by net value (highest first)
        comparisons.sort { $0.netValue > $1.netValue }
        
        await MainActor.run {
            self.saleyardComparisons = comparisons
        }
    }
}

// MARK: - Saleyard Comparison Row
struct SaleyardComparisonRow: View {
    let comparison: SaleyardComparison
    let defaultValue: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Saleyard name
            Text(comparison.saleyardName)
                .font(Theme.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.primaryText)
            
            // Values row
            HStack(spacing: 16) {
                // Value
                VStack(alignment: .leading, spacing: 2) {
                    Text("Value")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Text(comparison.value.formatted(.currency(code: "AUD").precision(.fractionLength(0))))
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                }
                
                // Freight
                VStack(alignment: .leading, spacing: 2) {
                    Text("Freight")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Text(comparison.freightCost.formatted(.currency(code: "AUD").precision(.fractionLength(0))))
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                }
                
                Spacer()
                
                // Difference
                HStack(spacing: 6) {
                    Text(abs(comparison.difference).formatted(.currency(code: "AUD").precision(.fractionLength(0))))
                        .font(Theme.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(comparison.difference >= 0 ? Theme.positiveChange : Theme.negativeChange)
                    
                    Image(systemName: comparison.difference >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(comparison.difference >= 0 ? Theme.positiveChange : Theme.negativeChange)
                }
            }
        }
        .padding(12)
        .background(Theme.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Chart Skeleton Loader
// Debug: Apple HIG compliant loading skeleton for chart area
struct ChartSkeletonLoader: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Debug: Time range pill skeleton
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.secondaryBackground.opacity(0.3))
                    .frame(width: 80, height: 32)
                    .shimmer(isAnimating: isAnimating)
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 10)
            
            // Debug: Chart area skeleton with gradient bars
            VStack(alignment: .leading, spacing: 8) {
                // Value label skeleton
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.secondaryBackground.opacity(0.3))
                    .frame(width: 120, height: 24)
                    .shimmer(isAnimating: isAnimating)
                
                // Chart bars skeleton
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<12, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.secondaryBackground.opacity(0.3))
                            .frame(height: CGFloat.random(in: 80...160))
                            .shimmer(isAnimating: isAnimating, delay: Double(index) * 0.05)
                    }
                }
                .frame(height: 180)
                .padding(.top, 8)
                
                // Date label skeleton
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.secondaryBackground.opacity(0.3))
                    .frame(width: 100, height: 16)
                    .shimmer(isAnimating: isAnimating)
                    .padding(.top, 4)
            }
            .padding(Theme.dashboardCardPadding)
        }
        .cardStyle()
        .onAppear {
            isAnimating = true
        }
    }
}

// Debug: Shimmer effect modifier for skeleton loaders (Apple HIG standard)
extension View {
    func shimmer(isAnimating: Bool, delay: Double = 0) -> some View {
        self.overlay(
            GeometryReader { geometry in
                if isAnimating {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Theme.secondaryBackground.opacity(0.5),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: isAnimating ? geometry.size.width * 2 : -geometry.size.width * 2)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(delay),
                        value: isAnimating
                    )
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Multiple Saleyard Selection Sheet
struct MultipleSaleyardSelectionSheet: View {
    @Binding var selectedSaleyards: Set<String>
    let excludeSaleyard: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredSaleyards: [String] {
        let available = ReferenceData.saleyards.filter { $0 != excludeSaleyard }
        if searchText.isEmpty {
            return available
        } else {
            return available.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredSaleyards, id: \.self) { saleyard in
                    Button {
                        HapticManager.tap()
                        if selectedSaleyards.contains(saleyard) {
                            selectedSaleyards.remove(saleyard)
                        } else {
                            selectedSaleyards.insert(saleyard)
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedSaleyards.contains(saleyard) ? "checkmark.square.fill" : "square")
                                .font(.system(size: 20))
                                .foregroundStyle(selectedSaleyards.contains(saleyard) ? Theme.accentColor : Theme.secondaryText)
                            
                            Text(saleyard)
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search saleyards"
            )
            .navigationTitle("Select Saleyards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accentColor)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.tertiaryBackground)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.tertiaryBackground)
    }
}

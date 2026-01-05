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
    
    private var startDate: Date? {
        data.first?.date
    }
    
    private var endDate: Date? {
        data.last?.date
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
        HStack(spacing: 8) {
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
                    // Debug: Show condensed dates when custom range is active
                    Text(range == .custom && timeRange == .custom && customStartDate != nil && customEndDate != nil 
                        ? customDateRangeLabel 
                        : range.rawValue)
                        .font(Theme.caption)
                        .foregroundStyle(timeRange == range ? Theme.accent : Theme.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            timeRange == range ? Theme.accent.opacity(0.15) : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .accessibilityLabel(range == .custom ? "Custom date range" : "Show \(range.rawValue) range")
            }
            Spacer()
        }
    }
}

// MARK: - Herd Performance View (Weekly)
// Debug: Shows weekly performance by herd category with percentage changes
struct MarketPulseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var herds: [HerdGroup]
    @Query private var preferences: [UserPreferences]
    @State private var categoryPerformance: [HerdCategoryPerformance] = []
    @State private var isLoading = true
    
    // Debug: Access ValuationEngine for calculating weekly changes
    let valuationEngine = ValuationEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Herd Performance")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                HStack(spacing: 4) {
                    Text("7d")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(Theme.accent)
                }
            }
            
            if isLoading {
                ProgressView()
                    .tint(Theme.accent)
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
        .padding(Theme.cardPadding)
        .stitchedCard()
        .task {
            await loadCategoryPerformance()
        }
        .onChange(of: herds.count) { _, _ in
            // Debug: Reload when herds change
            Task {
                await loadCategoryPerformance()
            }
        }
    }
    
    // Debug: Calculate weekly performance for each herd category
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
        
        // Debug: Calculate values for each category
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            await MainActor.run {
                self.categoryPerformance = []
                self.isLoading = false
            }
            return
        }
        
        // Group herds by category
        let categoryGroups = Dictionary(grouping: activeHerds) { $0.category }
        
        var performances: [HerdCategoryPerformance] = []
        
        for (category, categoryHerds) in categoryGroups {
            // Debug: Calculate current value for category
            var currentValue: Double = 0.0
            var weekAgoValue: Double = 0.0
            
            for herd in categoryHerds {
                // Only include herds that existed a week ago
                guard herd.createdAt <= weekAgo else { continue }
                
                let currentValuation = await valuationEngine.calculateHerdValue(
                    herd: herd,
                    preferences: prefs,
                    modelContext: modelContext
                )
                
                let pastValuation = await valuationEngine.calculateHerdValue(
                    herd: herd,
                    preferences: prefs,
                    modelContext: modelContext,
                    asOfDate: weekAgo
                )
                
                currentValue += currentValuation.netRealizableValue
                weekAgoValue += pastValuation.netRealizableValue
            }
            
            // Debug: Calculate percentage change
            guard weekAgoValue > 0 else { continue }
            
            let change = currentValue - weekAgoValue
            let percentChange = (change / weekAgoValue) * 100
            
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
            
            // Total Head stat
            HStack(spacing: 8) {
                Text("Total Head")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                Text("\(herds.reduce(0) { $0 + $1.headCount })")
                    .font(Theme.title3) // HIG: title3 (20pt) for stat values
                    .foregroundStyle(Theme.accent)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quick stats: \(herds.count) herds, \(herds.reduce(0) { $0 + $1.headCount }) total head")
    }
}

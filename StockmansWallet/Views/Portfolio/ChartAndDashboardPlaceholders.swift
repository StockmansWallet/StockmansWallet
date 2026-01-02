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
    
    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    HapticManager.tap()
                    timeRange = range
                } label: {
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
            }
            Spacer()
        }
    }
}

// MARK: - Market Pulse View
struct MarketPulseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @State private var indicators: [MarketIndicator] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Market Pulse")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(Theme.accent)
            }
            
            if isLoading {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if indicators.isEmpty {
                Text("No market data available")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(indicators) { indicator in
                        IndicatorRow(
                            title: indicator.name,
                            value: "$\(indicator.price.formatted(.number.precision(.fractionLength(2))))/kg",
                            trend: indicator.trend
                        )
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
        .task {
            await loadIndicators()
        }
    }
    
    private func loadIndicators() async {
        isLoading = true
        
        // TODO: Implement actual MLA API integration
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        let mockIndicators = [
            MarketIndicator(
                id: UUID(),
                name: "Eastern Young Cattle Indicator",
                price: 6.45,
                change: 0.15,
                trend: .up
            ),
            MarketIndicator(
                id: UUID(),
                name: "Western Young Cattle Indicator",
                price: 6.20,
                change: -0.10,
                trend: .down
            ),
            MarketIndicator(
                id: UUID(),
                name: "National Sheep Indicator",
                price: 8.10,
                change: 0.25,
                trend: .up
            )
        ]
        
        await MainActor.run {
            self.indicators = mockIndicators
            self.isLoading = false
        }
    }
}

struct MarketIndicator: Identifiable {
    let id: UUID
    let name: String
    let price: Double
    let change: Double
    let trend: PriceTrend
}

// Simple indicator row used by MarketPulseView
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
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            Image(systemName: trend == .up ? "arrow.up.right" : trend == .down ? "arrow.down.right" : "minus")
                .foregroundStyle(trend == .up ? .green : trend == .down ? .red : .gray)
                .font(.system(size: 14))
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Quick Stats View (Placeholder)
struct QuickStatsView: View {
    let herds: [HerdGroup]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Herds")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Text("\(herds.count)")
                        .font(Theme.title)
                        .foregroundStyle(Theme.primaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Head")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Text("\(herds.reduce(0) { $0 + $1.headCount })")
                        .font(Theme.title)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

//
//  PriceDetailSheet.swift
//  StockmansWallet
//
//  Price Detail View - Apple HIG Compliant Design
//  Debug: Clean, focused layout with clear visual hierarchy
//

import SwiftUI
import Charts

// MARK: - Price Detail Sheet
struct PriceDetailSheet: View {
    let categoryPrice: CategoryPrice
    let historicalPrices: [HistoricalPricePoint]
    let regionalPrices: [RegionalPrice]
    let isLoadingHistory: Bool
    let isLoadingRegional: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange: HistoricalTimeRange = .threeMonths
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Current Price Hero
                    priceHeroSection
                        .padding(.top, 8)
                    
                    // Historical Chart
                    if !isLoadingHistory || !historicalPrices.isEmpty {
                        historicalChartSection
                    }
                    
                    // Regional Comparison
                    if !isLoadingRegional || !regionalPrices.isEmpty {
                        regionalComparisonSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Theme.sheetBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(categoryPrice.category)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.primaryText)
                        Text(categoryPrice.livestockType.rawValue)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Price Hero Section
    private var priceHeroSection: some View {
        VStack(spacing: 24) {
            // Large Price Display
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$\(categoryPrice.price, format: .number.precision(.fractionLength(2)))")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                    Text("/ kg")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.secondaryText)
                }
                
                // Change Indicator
                HStack(spacing: 6) {
                    Image(systemName: categoryPrice.trend == .up ? "arrow.up" : categoryPrice.trend == .down ? "arrow.down" : "minus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("\(categoryPrice.change >= 0 ? "+" : "")\(categoryPrice.change, format: .number.precision(.fractionLength(2)))")
                        .font(.system(size: 18, weight: .semibold))
                    Text("$/kg today")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.secondaryText)
                }
                .foregroundStyle(categoryPrice.trend == .up ? Theme.positiveChange : categoryPrice.trend == .down ? Theme.negativeChange : Theme.secondaryText)
            }
            
            // Details Row
            HStack(spacing: 40) {
                DetailItem(
                    label: "Weight Range",
                    value: categoryPrice.weightRange
                )
                
                DetailItem(
                    label: "Source",
                    value: categoryPrice.source
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Historical Chart Section
    private var historicalChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Text("Price History")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)
            
            if isLoadingHistory {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
            } else if filteredHistoricalPrices.isEmpty {
                emptyStateView(message: "No historical data available")
            } else {
                VStack(spacing: 16) {
                    // Chart
                    Chart {
                        ForEach(filteredHistoricalPrices) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Price", point.price)
                            )
                            .foregroundStyle(Theme.accent)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                            
                            AreaMark(
                                x: .value("Date", point.date),
                                yStart: .value("Min", minPrice * 0.95),
                                yEnd: .value("Price", point.price)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Theme.accent.opacity(0.25),
                                        Theme.accent.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Theme.primaryText.opacity(0.08))
                            AxisValueLabel()
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Theme.primaryText.opacity(0.08))
                            AxisValueLabel()
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .frame(height: 240)
                    .padding(.vertical, 8)
                    
                    // Time Range Selector
                    HStack(spacing: 8) {
                        ForEach(HistoricalTimeRange.allCases) { range in
                            TimeRangeButton(
                                title: range.rawValue,
                                isSelected: selectedTimeRange == range
                            ) {
                                HapticManager.tap()
                                selectedTimeRange = range
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Regional Comparison Section
    private var regionalComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Text("Regional Comparison")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)
            
            if isLoadingRegional {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
            } else if regionalPrices.isEmpty {
                emptyStateView(message: "No regional data available")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(regionalPrices.enumerated()), id: \.element.id) { index, regional in
                        RegionalPriceRow(regional: regional)
                        
                        if index < regionalPrices.count - 1 {
                            Divider()
                                .background(Theme.separator.opacity(0.3))
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Helper Views
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 32))
                .foregroundStyle(Theme.secondaryText.opacity(0.5))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
    
    // MARK: - Computed Properties
    
    private var filteredHistoricalPrices: [HistoricalPricePoint] {
        guard !historicalPrices.isEmpty else { return [] }
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch selectedTimeRange {
        case .oneMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
        case .oneYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        case .all:
            return historicalPrices
        }
        
        return historicalPrices.filter { $0.date >= startDate }
    }
    
    private var minPrice: Double {
        filteredHistoricalPrices.map { $0.price }.min() ?? 0
    }
}

// MARK: - Detail Item
struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondaryText)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Time Range Button
struct TimeRangeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : Theme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.accent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Regional Price Row
struct RegionalPriceRow: View {
    let regional: RegionalPrice
    
    var body: some View {
        HStack(spacing: 16) {
            // State
            Text(regional.state)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 50, alignment: .leading)
            
            // Price
            Text("$\(regional.price, format: .number.precision(.fractionLength(2)))")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.primaryText)
            
            Spacer()
            
            // Change
            HStack(spacing: 4) {
                Image(systemName: regional.trend == .up ? "arrow.up" : regional.trend == .down ? "arrow.down" : "minus")
                    .font(.system(size: 11, weight: .semibold))
                Text("\(regional.change >= 0 ? "+" : "")\(regional.change, format: .number.precision(.fractionLength(2)))")
                    .font(.system(size: 14, weight: .medium))
                Text(regional.changeDuration)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText.opacity(0.8))
            }
            .foregroundStyle(regional.trend == .up ? Theme.positiveChange : regional.trend == .down ? Theme.negativeChange : Theme.secondaryText)
        }
    }
}

// MARK: - Time Range Enum
enum HistoricalTimeRange: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "All"
    
    var id: String { rawValue }
}

// MARK: - Preview
#Preview {
    PriceDetailSheet(
        categoryPrice: CategoryPrice(
            category: "Feeder Steer",
            livestockType: .cattle,
            price: 6.45,
            change: 0.15,
            trend: .up,
            weightRange: "300-400kg",
            source: "National Average",
            changeDuration: "24h"
        ),
        historicalPrices: [],
        regionalPrices: [],
        isLoadingHistory: false,
        isLoadingRegional: false
    )
}

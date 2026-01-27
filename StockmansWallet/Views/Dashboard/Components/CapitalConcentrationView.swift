//
//  CapitalConcentrationView.swift
//  StockmansWallet
//
//  Herd composition breakdown with pie chart and category list
//  Debug: Time range selector UI implemented - currently shows current composition
//  Note: Historical composition comparison to be implemented in future update
//

import SwiftUI
import Charts

struct CapitalConcentrationView: View {
    let breakdown: [CapitalConcentrationBreakdown]
    let totalValue: Double
    @State private var compositionTimeRange: CompositionTimeRange = .current
    @State private var showingCustomDatePicker = false
    @State private var customStartDate: Date?
    @State private var customEndDate: Date?
    
    // Debug: Time range options for composition tracking
    // Note: Currently all options display the same current data; historical comparison planned
    enum CompositionTimeRange: String, CaseIterable {
        case current = "Current"
        case week = "Week Ago"
        case month = "Month Ago"
        case year = "Year Ago"
        case custom = "Custom"
        
        // Debug: Display label for each range
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
    
    // Debug: Color palette for pie chart segments (darker earthy, muted tones)
    private let chartColors: [Color] = [
        Color(red: 0.70, green: 0.45, blue: 0.30), // Dark terracotta
        Color(red: 0.45, green: 0.55, blue: 0.65), // Muted blue
        Color(red: 0.50, green: 0.60, blue: 0.45), // Dark sage
        Color(red: 0.75, green: 0.63, blue: 0.40), // Dark sand
        Color(red: 0.60, green: 0.50, blue: 0.63), // Deep lavender
        Color(red: 0.70, green: 0.50, blue: 0.45), // Brick rose
        Color(red: 0.45, green: 0.63, blue: 0.63), // Deep teal
        Color(red: 0.67, green: 0.57, blue: 0.43)  // Dark tan
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Herd Composition")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                
                // Debug: Time range selector menu
                Menu {
                    ForEach(CompositionTimeRange.allCases, id: \.self) { range in
                        Button {
                            HapticManager.tap()
                            if range == .custom {
                                showingCustomDatePicker = true
                            } else {
                                compositionTimeRange = range
                            }
                        } label: {
                            HStack {
                                Text(range.rawValue)
                                if compositionTimeRange == range {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        // Debug: Show custom date or standard label
                        Text(customDateRangeLabel)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Select composition time view")
                .accessibilityValue(compositionTimeRange.rawValue)
            }
            
            // Debug: Pie chart showing category distribution
            if !breakdown.isEmpty {
                Chart {
                    ForEach(Array(breakdown.enumerated()), id: \.element.id) { index, item in
                        SectorMark(
                            angle: .value("Value", item.value),
                            innerRadius: .ratio(0.618), // Golden ratio for elegant donut
                            angularInset: 2.0 // Small gap between segments
                        )
                        .foregroundStyle(chartColors[index % chartColors.count])
                        .cornerRadius(4)
                        .accessibilityLabel("\(item.category)")
                        .accessibilityValue("\(item.percentage.formatted(.number.precision(.fractionLength(1)))) percent")
                    }
                }
                .frame(height: 200)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Category distribution chart")
            }
            
            // Debug: Category list with bars (existing design)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(breakdown.enumerated()), id: \.element.id) { index, item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            // Debug: Color indicator matching pie chart
                            RoundedRectangle(cornerRadius: 3)
                                .fill(chartColors[index % chartColors.count])
                                .frame(width: 12, height: 12)
                                .accessibilityHidden(true)
                            
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
                                    .fill(chartColors[index % chartColors.count])
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
        // Debug: No card background/stroke for cleaner dashboard look
        // .stitchedCard()
        .sheet(isPresented: $showingCustomDatePicker) {
            CustomDateRangeSheet(
                startDate: $customStartDate,
                endDate: $customEndDate,
                timeRange: Binding(
                    get: { 
                        // Debug: Map CompositionTimeRange to TimeRange for sheet compatibility
                        compositionTimeRange == .custom ? .custom : .week 
                    },
                    set: { _ in 
                        compositionTimeRange = .custom 
                    }
                )
            )
        }
        .accessibilityElement(children: .contain)
    }
    
    // Debug: Format custom date range label
    private var customDateRangeLabel: String {
        if compositionTimeRange == .custom,
           let start = customStartDate,
           let end = customEndDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
        return compositionTimeRange.displayLabel
    }
}

#Preview {
    CapitalConcentrationView(
        breakdown: [
            CapitalConcentrationBreakdown(category: "Beef Cattle", value: 150000, percentage: 60),
            CapitalConcentrationBreakdown(category: "Dairy Cattle", value: 75000, percentage: 30),
            CapitalConcentrationBreakdown(category: "Sheep", value: 25000, percentage: 10)
        ],
        totalValue: 250000
    )
    .padding()
}


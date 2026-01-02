//
//  MarketView.swift
//  StockmansWallet
//
//  Live Market Pricing and Market Pulse Ticker
//

import SwiftUI
import SwiftData

struct MarketView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    @State private var selectedSaleyard: String?
    @State private var marketPrices: [MarketPriceData] = []
    @State private var isLoading = false
    @State private var lastUpdated: Date? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    // Compact filter bar (Menu-based saleyard picker)
                    FilterBarView(selectedSaleyard: $selectedSaleyard)
                        .padding(.horizontal)
                    
                    // Key indicators in an adaptive grid (glanceable)
                    KeyIndicatorsGrid()
                        .padding(.horizontal)
                    
                    // Live Prices
                    LivePricesView(
                        prices: marketPrices,
                        isLoading: isLoading,
                        lastUpdated: lastUpdated
                    )
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 100)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Market")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await loadMarketPrices() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Refresh prices")
                }
            }
            .task {
                if selectedSaleyard == nil {
                    selectedSaleyard = preferences.first?.defaultSaleyard
                }
                await loadMarketPrices()
            }
            .refreshable {
                await loadMarketPrices()
            }
            .onChange(of: selectedSaleyard) { _, _ in
                Task { await loadMarketPrices() }
            }
        }
    }
    
    private func loadMarketPrices() async {
        await MainActor.run { isLoading = true }
        HapticManager.tap()
        
        // TODO: Replace with actual MLA API integration.
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Could vary prices by selectedSaleyard if desired.
        let mockPrices = [
            MarketPriceData(category: "Feeder Steer",   price: 6.45, change:  0.15, trend: PriceTrend.up),
            MarketPriceData(category: "Yearling Steer", price: 6.80, change: -0.10, trend: PriceTrend.down),
            MarketPriceData(category: "Breeding Cow",   price: 4.20, change:  0.05, trend: PriceTrend.up),
            MarketPriceData(category: "Cull Cow",       price: 3.50, change:  0.00, trend: PriceTrend.neutral),
            MarketPriceData(category: "Weaner Steer",   price: 7.20, change:  0.25, trend: PriceTrend.up),
            MarketPriceData(category: "Heifer",         price: 6.30, change:  0.12, trend: PriceTrend.up),
            MarketPriceData(category: "Grown Steer",    price: 6.15, change: -0.05, trend: PriceTrend.down),
        ]
        
        await MainActor.run {
            self.marketPrices = mockPrices
            self.isLoading = false
            self.lastUpdated = Date()
            HapticManager.success()
        }
    }
}

// MARK: - Filter Bar (compact Menu-based)
struct FilterBarView: View {
    @Binding var selectedSaleyard: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Filters")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            HStack(spacing: 12) {
                Menu {
                    Button {
                        HapticManager.tap()
                        selectedSaleyard = nil
                    } label: {
                        Label("All Saleyards", systemImage: selectedSaleyard == nil ? "checkmark" : "circle")
                    }
                    
                    ForEach(ReferenceData.saleyards, id: \.self) { yard in
                        Button {
                            HapticManager.tap()
                            selectedSaleyard = yard
                        } label: {
                            Label(yard, systemImage: selectedSaleyard == yard ? "checkmark" : "circle")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Theme.accent)
                        Text(selectedSaleyard ?? "All Saleyards")
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                        Image(systemName: "chevron.down")
                            .foregroundStyle(Theme.secondaryText)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select saleyard")
                
                Spacer(minLength: 0)
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

// MARK: - Key Indicators (Adaptive Grid)
struct KeyIndicatorsGrid: View {
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12, alignment: .top)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Market Pulse")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                IndicatorTile(title: "Eastern Young Cattle Indicator", value: "$6.45/kg", trend: .up, changeText: "+0.08")
                IndicatorTile(title: "Western Young Cattle Indicator", value: "$6.20/kg", trend: .down, changeText: "-0.04")
                IndicatorTile(title: "National Sheep Indicator", value: "$8.10/kg", trend: .up, changeText: "+0.05")
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

struct IndicatorTile: View {
    let title: String
    let value: String
    let trend: PriceTrend
    let changeText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                HStack(spacing: 4) {
                    Image(systemName: trend == .up ? "arrow.up.right" : trend == .down ? "arrow.down.right" : "minus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(trend == .up ? .green : trend == .down ? .red : Theme.primaryText.opacity(0.6))
                        .accessibilityHidden(true)
                    Text(changeText)
                        .font(Theme.caption)
                        .foregroundStyle(trend == .up ? .green : trend == .down ? .red : Theme.secondaryText)
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value), \(trend == .up ? "up" : trend == .down ? "down" : "no change") \(changeText)")
    }
}

// MARK: - Live Prices View
struct LivePricesView: View {
    let prices: [MarketPriceData]
    let isLoading: Bool
    let lastUpdated: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Live Prices")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    if let lastUpdated {
                        Text("Updated \(lastUpdated, style: .relative) ago")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .accessibilityLabel("Last updated \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                    }
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            if isLoading {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if prices.isEmpty {
                Text("No prices available")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(prices.enumerated()), id: \.element.id) { index, item in
                        PriceRow(data: item)
                        
                        if index < prices.count - 1 {
                            Divider()
                                .background(Theme.separator)
                        }
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

struct PriceRow: View {
    let data: MarketPriceData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.category)
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
                Text("\(data.price, format: .number.precision(.fractionLength(2))) $/kg")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: data.trend == PriceTrend.up ? "arrow.up.right" : data.trend == PriceTrend.down ? "arrow.down.right" : "minus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(data.trend == PriceTrend.up ? .green : data.trend == PriceTrend.down ? .red : Theme.primaryText.opacity(0.6))
                    .accessibilityHidden(true)
                
                Text("\(data.change >= 0 ? "+" : "")\(data.change, format: .number.precision(.fractionLength(2)))")
                    .font(Theme.caption)
                    .foregroundStyle(data.trend == PriceTrend.up ? .green : data.trend == PriceTrend.down ? .red : Theme.secondaryText)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(data.category), \(data.price, format: .number.precision(.fractionLength(2))) dollars per kilogram, \(data.trend == .up ? "up" : data.trend == .down ? "down" : "no change") \(abs(data.change), format: .number.precision(.fractionLength(2)))")
    }
}

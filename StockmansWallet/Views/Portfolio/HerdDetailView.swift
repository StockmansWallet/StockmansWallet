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

struct HerdDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject
    let valuationEngine = ValuationEngine.shared
    let herd: HerdGroup
    
    @State private var valuation: HerdValuation?
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Debug: Total value card with herd name at the very top
                if let valuation = valuation {
                    TotalValueCard(herd: herd, valuation: valuation)
                        .padding(.horizontal)
                } else if isLoading {
                    ProgressView()
                        .tint(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                
                // Debug: Weight Growth Chart for visual insight
                if herd.dailyWeightGain > 0, let valuation = valuation {
                    WeightGrowthChart(herd: herd, projectedWeight: valuation.projectedWeight)
                        .padding(.horizontal)
                }
                
                // Debug: Primary valuation metrics
                if let valuation = valuation {
                    PrimaryMetricsCard(herd: herd, valuation: valuation)
                        .padding(.horizontal)
                }
                
                // Debug: Consolidated herd details - all key info in one card
                HerdDetailsCard(herd: herd, valuation: valuation)
                    .padding(.horizontal)
                
                // Debug: Breeding info only if applicable
                if herd.isBreeder {
                    BreedingDetailsCard(herd: herd)
                        .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Herd Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: EditHerdView(herd: herd)) {
                    Text("Edit")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .task {
            await loadValuation()
        }
    }
    
    private func loadValuation() async {
        await MainActor.run { isLoading = true }
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

// MARK: - Total Value Card
// Debug: Prominent total value display with herd name at the top
struct TotalValueCard: View {
    let herd: HerdGroup
    let valuation: HerdValuation
    
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
            
            // Debug: Total value without label
            Text(valuation.netRealizableValue, format: .currency(code: "AUD"))
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Weight Growth Chart
// Debug: Visual representation of weight gain over time
struct WeightGrowthChart: View {
    let herd: HerdGroup
    let projectedWeight: Double
    
    // Debug: Generate weight progression data points
    private var weightData: [WeightDataPoint] {
        let daysHeld = herd.daysHeld
        let startWeight = herd.initialWeight
        let dwg = herd.dailyWeightGain
        
        // Generate data points for the chart
        var points: [WeightDataPoint] = []
        let intervals = min(daysHeld, 30) // Show up to 30 data points
        let step = max(1, daysHeld / intervals)
        
        for day in stride(from: 0, through: daysHeld, by: step) {
            let weight = startWeight + (dwg * Double(day))
            let date = Calendar.current.date(byAdding: .day, value: day, to: herd.createdAt) ?? herd.createdAt
            points.append(WeightDataPoint(date: date, weight: weight))
        }
        
        return points
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight Growth")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text("\(Int(herd.initialWeight)) → \(Int(projectedWeight)) kg")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Text("+\(Int(projectedWeight - herd.initialWeight)) kg")
                    .font(Theme.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.positiveChange)
            }
            
            // Debug: Simple line chart showing weight progression
            Chart(weightData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(Theme.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.accent.opacity(0.3), Theme.accent.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 120)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Theme.separator.opacity(0.3))
                    AxisValueLabel()
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(Theme.separator.opacity(0.3))
                    AxisValueLabel(format: .dateTime.month().day())
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

// MARK: - Primary Metrics Card
// Debug: Key valuation metrics in compact layout
struct PrimaryMetricsCard: View {
    let herd: HerdGroup
    let valuation: HerdValuation
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Key Metrics")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
            }
            
            // Key metrics in grid layout
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Price/kg")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    // Debug: iOS 26 - Use attributed string for mixed styling
                    Text("\(valuation.pricePerKg, format: .currency(code: "AUD"))/kg")
                        .font(Theme.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                    .background(Theme.separator.opacity(0.3))
                
                VStack(spacing: 4) {
                    Text("Avg Weight")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    // Debug: iOS 26 - Use string interpolation instead of Text concatenation
                    Text("\(Int(valuation.projectedWeight)) kg")
                        .font(Theme.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                    .background(Theme.separator.opacity(0.3))
                
                VStack(spacing: 4) {
                    Text("Per Head")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Text(valuation.netRealizableValue / Double(herd.headCount), format: .currency(code: "AUD"))
                        .font(Theme.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Debug: Show herd's specific saleyard
            HStack {
                Image(systemName: "building.2")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
                Text(herd.selectedSaleyard ?? "No saleyard selected")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

// MARK: - Herd Details Card
// Debug: Organized herd information into logical sections
struct HerdDetailsCard: View {
    let herd: HerdGroup
    let valuation: HerdValuation?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Herd Details")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            // Debug: Organized into clear sections for better readability
            
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
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(Theme.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Theme.secondaryText)
            .textCase(.uppercase)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
            Spacer()
            Text(value)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText)
        }
    }
}

// MARK: - Breeding Details Card
// Debug: Breeding information only shown when relevant
struct BreedingDetailsCard: View {
    let herd: HerdGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breeding Information")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            VStack(spacing: 8) {
                DetailRow(label: "Pregnant", value: herd.isPregnant ? "Yes" : "No")
                DetailRow(label: "Calving Rate", value: "\(Int(herd.calvingRate * 100))%")
                
                if let joinedDate = herd.joinedDate {
                    DetailRow(label: "Joined Date", value: joinedDate.formatted(date: .abbreviated, time: .omitted))
                    
                    if herd.isPregnant {
                        let daysSinceJoined = Calendar.current.dateComponents([.day], from: joinedDate, to: Date()).day ?? 0
                        let cycleLength = herd.species == "Cattle" ? 283 : 150
                        let daysRemaining = max(0, cycleLength - daysSinceJoined)
                        
                        DetailRow(label: "Days Since Joined", value: "\(daysSinceJoined)")
                        DetailRow(label: "Est. Days to Calving", value: "\(daysRemaining)")
                        
                        // Progress bar for pregnancy
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.primaryText.opacity(0.1))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.accent)
                                    .frame(
                                        width: geometry.size.width * CGFloat(daysSinceJoined) / CGFloat(cycleLength),
                                        height: 6
                                    )
                            }
                        }
                        .frame(height: 6)
                    }
                }
                
                if let lactationStatus = herd.lactationStatus {
                    DetailRow(label: "Lactation", value: lactationStatus)
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

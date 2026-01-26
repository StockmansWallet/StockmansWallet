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
    // Performance: Query all herds and individuals - needed to find specific herd by ID
    // SwiftData doesn't support querying single object by ID efficiently
    @Query private var allHerds: [HerdGroup]
    
    // Debug: Use 'let' with @Observable instead of @StateObject
    let valuationEngine = ValuationEngine.shared
    
    // Debug: Pass herd ID instead of object to avoid SwiftData context issues
    let herdId: UUID
    
    @State private var valuation: HerdValuation?
    @State private var isLoading = true
    @State private var showingAnimalsList = false
    
    // Debug: Sell functionality for this herd
    @State private var showingSellSheet = false
    
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
                    // Debug: Total value card with herd name at the very top
                    if let valuation = valuation {
                        TotalValueCard(herd: activeHerd, valuation: valuation)
                            .padding(.horizontal)
                    } else if isLoading {
                        ProgressView()
                            .tint(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    
                    // Debug: Horizontal stats card for herd type and head count
                    // Only show for herds (headCount > 1), not for individual animals to avoid duplication
                    if !isLoading && activeHerd.headCount > 1 {
                        HerdStatsCard(herd: activeHerd)
                            .padding(.horizontal)
                    }
                        
                    // Debug: Weight Growth Chart for visual insight
                    // Pass data directly to avoid SwiftData access issues
                    if !isLoading, let valuation = valuation, activeHerd.dailyWeightGain > 0 {
                        WeightGrowthChart(
                            initialWeight: activeHerd.initialWeight,
                            dailyWeightGain: activeHerd.dailyWeightGain,
                            daysHeld: activeHerd.daysHeld,
                            createdAt: activeHerd.createdAt,
                            projectedWeight: valuation.projectedWeight
                        )
                        .padding(.horizontal)
                    }
                    
                    // Debug: Primary valuation metrics
                    if let valuation = valuation {
                        PrimaryMetricsCard(herd: activeHerd, valuation: valuation)
                            .padding(.horizontal)
                    }
                    
                    // Debug: Consolidated herd details - all key info in one card
                    if !isLoading {
                        HerdDetailsCard(herd: activeHerd, valuation: valuation)
                            .padding(.horizontal)
                    }
                    
                    // Debug: Breeding info only if applicable - shown before other records
                    if !isLoading, activeHerd.isBreeder {
                        BreedingDetailsCard(herd: activeHerd)
                            .padding(.horizontal)
                    }
                    
                    // Debug: Mustering records card - only show if there are muster records
                    if !isLoading, let musterRecords = activeHerd.musterRecords, !musterRecords.isEmpty {
                        MusteringHistoryCard(herd: activeHerd)
                            .padding(.horizontal)
                    }
                    
                    // Debug: Health records card - only show if there are health records
                    if !isLoading, let healthRecords = activeHerd.healthRecords, !healthRecords.isEmpty {
                        HealthRecordsCard(herd: activeHerd)
                            .padding(.horizontal)
                    }
                    
                    // Debug: Button to open searchable animal list sheet - only show for herds (not individual animals)
                    if !isLoading && activeHerd.headCount > 1 {
                        Button {
                            HapticManager.tap()
                            showingAnimalsList = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View Individual Animals")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                    Text("Browse all individually tagged animals")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.secondaryText.opacity(0.6))
                            }
                            .padding(Theme.cardPadding)
                        }
                        .buttonStyle(PlainButtonStyle())
                        // Debug: Card temporarily removed to test cleaner look
                        // .stitchedCard()
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
                                .background(Theme.accent)
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
            .navigationTitle(activeHerd.headCount == 1 ? "Individual Animal" : "Herd Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: EditHerdView(herd: activeHerd)) {
                        Text("Edit")
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAnimalsList) {
                AnimalListSheet(herd: activeHerd)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Theme.sheetBackground)
            }
            .fullScreenCover(isPresented: $showingSellSheet) {
                SellStockView(preselectedHerdId: activeHerd.id)
                    .transition(.move(edge: .trailing))
                    .presentationBackground(Theme.sheetBackground)
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
        
        print("🔄 HerdDetailView: Calculating valuation...")
        let calculatedValuation = await valuationEngine.calculateHerdValue(
            herd: activeHerd,
            preferences: prefs,
            modelContext: modelContext
        )
        print("✅ HerdDetailView: Valuation calculated: \(calculatedValuation.netRealizableValue)")
        await MainActor.run {
            self.valuation = calculatedValuation
            self.isLoading = false
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
// Debug: Simplified to show only head count in accent-colored rounded rectangle
struct HerdStatsCard: View {
    let herd: HerdGroup
    
    var body: some View {
        Text("\(herd.headCount) Head")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.accent)
            )
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Weight Growth Chart
// Debug: Visual representation of weight gain over time
// Pass data directly instead of HerdGroup object to avoid SwiftData access issues
struct WeightGrowthChart: View {
    let initialWeight: Double
    let dailyWeightGain: Double
    let daysHeld: Int
    let createdAt: Date
    let projectedWeight: Double
    
    // Debug: Generate weight progression data points from passed-in data
    private var weightData: [WeightDataPoint] {
        // Debug: Generate data points for the chart
        var points: [WeightDataPoint] = []
        
        // Debug: For new herds with no history, create a line from 0 to current weight
        if daysHeld == 0 {
            // Add starting point at 0kg
            points.append(WeightDataPoint(date: createdAt, weight: 0))
            // Add current point at initial weight
            points.append(WeightDataPoint(date: createdAt, weight: initialWeight))
            return points
        }
        
        let intervals = min(daysHeld, 30) // Show up to 30 data points
        let step = max(1, daysHeld / intervals)
        
        for day in stride(from: 0, through: daysHeld, by: step) {
            let weight = initialWeight + (dailyWeightGain * Double(day))
            let date = Calendar.current.date(byAdding: .day, value: day, to: createdAt) ?? createdAt
            points.append(WeightDataPoint(date: date, weight: weight))
        }
        
        return points
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Debug: Weight header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight Growth")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text("\(Int(initialWeight)) → \(Int(projectedWeight)) kg")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                if projectedWeight > initialWeight {
                    Text("+\(Int(projectedWeight - initialWeight)) kg")
                        .font(Theme.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.positiveChange)
                }
            }
            
            // Debug: Always show chart with at least 2 data points for line rendering
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
        // Debug: Card temporarily removed to test cleaner look
        // .stitchedCard()
    }
}

struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
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
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("Key Metrics")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
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
        .padding(Theme.cardPadding)
        // Debug: Card temporarily removed to test cleaner look
        // .stitchedCard()
    }
}

// MARK: - Herd Details Card
// Debug: Organized herd information into logical sections
struct HerdDetailsCard: View {
    let herd: HerdGroup
    let valuation: HerdValuation?
    
    // Debug: Check if this is an individual animal for title display
    private var isIndividualAnimal: Bool {
        herd.headCount == 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Debug: Removed "Animal Details" heading since there's no card background
            
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
        .padding(Theme.cardPadding)
        // Debug: Card temporarily removed to test cleaner look
        // .stitchedCard()
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

// MARK: - Animal List Sheet
// Debug: Searchable sheet showing actual animals from database
struct AnimalListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let herd: HerdGroup
    
    @State private var searchText = ""
    
    // Performance: Query only individual animals (headCount == 1)
    @Query(filter: #Predicate<HerdGroup> { $0.headCount == 1 && !$0.isSold }, sort: \HerdGroup.name) private var allIndividualAnimals: [HerdGroup]
    
    private var relatedAnimals: [HerdGroup] {
        // Debug: For now, show ALL individual animals to verify they exist
        // TODO: Re-enable filtering once confirmed animals are in database
        // allIndividualAnimals.filter { animal in
        //     animal.species == herd.species &&
        //     animal.breed == herd.breed &&
        //     animal.category == herd.category
        // }
        return allIndividualAnimals
    }
    
    private var filteredAnimals: [HerdGroup] {
        if searchText.isEmpty {
            return relatedAnimals
        }
        return relatedAnimals.filter { animal in
            animal.name.localizedCaseInsensitiveContains(searchText) ||
            (animal.additionalInfo?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Debug: Search bar at the top
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.secondaryText)
                        .font(.system(size: 16))
                    
                    TextField("Search by name or tag...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Theme.primaryText)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.secondaryText)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding()
                .background(Theme.inputFieldBackground)
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                // Debug: Results count with debug info
                HStack {
                    Text("\(filteredAnimals.count) of \(allIndividualAnimals.count) total individual animals")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Debug: Scrollable list of animals
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAnimals) { animal in
                            IndividualAnimalRow(animal: animal)
                        }
                        
                        if filteredAnimals.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: searchText.isEmpty ? "tag.slash" : "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Theme.secondaryText.opacity(0.5))
                                
                                if searchText.isEmpty {
                                    Text("No Individual Animals Found")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                    
                                    VStack(spacing: 8) {
                                        Text("Individual animals: \(allIndividualAnimals.count)")
                                            .font(Theme.caption)
                                            .foregroundStyle(Theme.secondaryText)
                                        
                                        if allIndividualAnimals.isEmpty {
                                            Text("Go to Settings → Generate Mock Data to create individual animals")
                                                .font(Theme.caption)
                                                .foregroundStyle(Theme.accent)
                                                .multilineTextAlignment(.center)
                                                .padding(.top, 8)
                                        }
                                    }
                                    .padding(.horizontal)
                                } else {
                                    Text("No animals match your search")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                    
                                    Text("Try adjusting your search terms")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                .background(Theme.backgroundGradient.ignoresSafeArea())
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Animals in \(herd.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Individual Animal Row
// Debug: Row displaying individual animal details from database
struct IndividualAnimalRow: View {
    let animal: HerdGroup
    
    var body: some View {
        // Debug: Capture animal properties early to avoid SwiftData access issues
        let animalId = animal.id
        let animalName = animal.name
        let animalBreed = animal.breed
        let animalWeight = animal.currentWeight
        let animalPaddock = animal.paddockName
        
        NavigationLink(destination: HerdDetailView(herdId: animalId)) {
            HStack(spacing: 12) {
                // Tag icon
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "tag.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.accent)
                }
                
                // Animal info
                VStack(alignment: .leading, spacing: 4) {
                    Text(animalName)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    HStack(spacing: 8) {
                        Text(animalBreed)
                            .font(Theme.subheadline) // Debug: Bigger font for better readability
                            .foregroundStyle(Theme.secondaryText)
                        
                        Text("•")
                            .font(Theme.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                        
                        Text("\(Int(animalWeight)) kg")
                            .font(Theme.subheadline) // Debug: Bigger font for better readability
                            .foregroundStyle(Theme.secondaryText)
                        
                        if let paddock = animalPaddock, !paddock.isEmpty {
                            Text("•")
                                .font(Theme.subheadline)
                                .foregroundStyle(Theme.secondaryText)
                            
                            Text(paddock)
                                .font(Theme.subheadline) // Debug: Bigger font for better readability
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText.opacity(0.6))
            }
            .padding(Theme.cardPadding)
        }
        .buttonStyle(PlainButtonStyle())
        // Debug: Card temporarily removed to test cleaner look
        // .stitchedCard()
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Breeding Information")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
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
        .padding(Theme.cardPadding)
        // Debug: Card temporarily removed to test cleaner look
        // .stitchedCard()
    }
}

// MARK: - Mustering Records Card
// Debug: Display full mustering records with dates and notes
struct MusteringHistoryCard: View {
    let herd: HerdGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Mustering Records")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Spacer()
                
                // Debug: Show count of muster records
                if let recordCount = herd.musterRecords?.count, recordCount > 0 {
                    Text("\(recordCount) record\(recordCount == 1 ? "" : "s")")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            
            // Debug: Display muster records in chronological order (most recent first)
            VStack(spacing: 12) {
                ForEach(herd.sortedMusterRecords) { record in
                    MusterRecordRow(record: record)
                }
            }
        }
        .padding(Theme.cardPadding)
        // Debug: Card temporarily removed to test cleaner look
        // .stitchedCard()
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
                    .fill(Theme.accent.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accent)
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
// Debug: Display health treatment history with dates and treatment types
struct HealthRecordsCard: View {
    let herd: HerdGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Health Records")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Spacer()
                
                // Debug: Show count of health records
                if let recordCount = herd.healthRecords?.count, recordCount > 0 {
                    Text("\(recordCount) record\(recordCount == 1 ? "" : "s")")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            
            // Debug: Display health records in chronological order (most recent first)
            VStack(spacing: 12) {
                ForEach(herd.sortedHealthRecords) { record in
                    HealthRecordRow(record: record)
                }
            }
        }
        .padding(Theme.cardPadding)
        // Debug: Card temporarily removed to test cleaner look
        // .stitchedCard()
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
                    .fill(Theme.accent.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: record.treatmentIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accent)
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

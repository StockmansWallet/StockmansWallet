//
//  HerdDetailView.swift
//  StockmansWallet
//
//  Detailed view of a single herd with valuation and management options
//  Debug: Uses @Observable pattern for ValuationEngine
//

import SwiftUI
import SwiftData

struct HerdDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject
    let valuationEngine = ValuationEngine.shared
    let herd: HerdGroup
    
    @State private var valuation: HerdValuation?
    @State private var isLoading = true
    
    var body: some View {
        // Debug: Background image removed for cleaner design
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                // Herd Header (without card for cleaner design)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(herd.name)
                                .font(Theme.title)
                                .foregroundStyle(Theme.primaryText)
                            
                            Text("\(herd.headCount) head • \(herd.breed) \(herd.category)")
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        // Debug: Display SOLD badge if applicable
                        if herd.isSold {
                            Text("SOLD")
                                .font(Theme.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.red)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                    
                    // Current Valuation
                    if let valuation = valuation {
                        ValuationCard(valuation: valuation)
                            .padding(.horizontal)
                    } else if isLoading {
                        ProgressView()
                            .tint(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    
                    // Herd Information
                    HerdInfoCard(herd: herd)
                        .padding(.horizontal)
                    
                    // Breeding Information (if applicable)
                    if herd.isBreeder {
                        BreedingInfoCard(herd: herd)
                            .padding(.horizontal)
                    }
                    
                    // Location Information
                    if let paddock = herd.paddockName {
                        LocationCard(paddock: paddock, saleyard: herd.selectedSaleyard)
                            .padding(.horizontal)
                    }
            }
            // Prevent width expansion from any child view.
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundColor) // Debug: Use theme background color
        .navigationTitle(herd.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: EditHerdView(herd: herd)) {
                    Image(systemName: "pencil")
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

// MARK: - Valuation Card
struct ValuationCard: View {
    let valuation: HerdValuation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Valuation")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Net Realizable Value")
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText.opacity(0.8))
                    Spacer()
                    Text(valuation.netRealizableValue, format: .currency(code: "AUD"))
                        .font(Theme.title)
                        .foregroundStyle(Theme.accent)
                }
                
                Divider()
                    .background(Theme.primaryText.opacity(0.3))
                
               
                
                if valuation.breedingAccrual > 0 {
                    ValuationRow(label: "Breeding Accrual", value: valuation.breedingAccrual, color: Theme.positiveChange)
                }
                
                ValuationRow(label: "Gross Value", value: valuation.grossValue, color: Theme.primaryText)
                
                ValuationRow(label: "Mortality Deduction", value: -valuation.mortalityDeduction, color: .orange)
                
               
                
                Divider()
                    .background(Theme.primaryText.opacity(0.3))
                
                HStack {
                    Text("Price Source")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.primaryText.opacity(0.7))
                    Spacer()
                    Text(valuation.priceSource)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.primaryText.opacity(0.8))
                }
                
                HStack {
                    Text("Price per kg")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.primaryText.opacity(0.7))
                    Spacer()
                    Text("\(valuation.pricePerKg, format: .number.precision(.fractionLength(2))) $/kg")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.primaryText.opacity(0.8))
                }
                
               
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

struct ValuationRow: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText.opacity(0.8))
            Spacer()
            Text(value, format: .currency(code: "AUD"))
                .font(Theme.headline)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Herd Info Card
struct HerdInfoCard: View {
    let herd: HerdGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Herd Information")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            VStack(spacing: 12) {
                InfoRow(label: "Species", value: herd.species)
                InfoRow(label: "Breed", value: herd.breed)
                InfoRow(label: "Category", value: herd.category)
                InfoRow(label: "Sex", value: herd.sex)
                InfoRow(label: "Age", value: "\(herd.ageMonths) months")
                InfoRow(label: "Head Count", value: "\(herd.headCount)")
                InfoRow(label: "Initial Weight", value: "\(Int(herd.initialWeight)) kg")
                InfoRow(label: "Daily Weight Gain", value: String(format: "%.2f kg/day", herd.dailyWeightGain))
                InfoRow(label: "Created", value: herd.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

// InfoRow is defined in ReportsView.swift

// MARK: - Breeding Info Card
struct BreedingInfoCard: View {
    let herd: HerdGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breeding Information")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            VStack(spacing: 12) {
                InfoRow(label: "Breeding Stock", value: "Yes")
                InfoRow(label: "Pregnant", value: herd.isPregnant ? "Yes" : "No")
                InfoRow(label: "Calving Rate", value: "\(Int(herd.calvingRate * 100))%")
                
                if let joinedDate = herd.joinedDate {
                    InfoRow(label: "Joined Date", value: joinedDate.formatted(date: .abbreviated, time: .omitted))
                    
                    if herd.isPregnant {
                        let daysSinceJoined = Calendar.current.dateComponents([.day], from: joinedDate, to: Date()).day ?? 0
                        let cycleLength = herd.species == "Cattle" ? 283 : 150
                        let daysRemaining = max(0, cycleLength - daysSinceJoined)
                        
                        InfoRow(label: "Days Since Joined", value: "\(daysSinceJoined)")
                        InfoRow(label: "Days Until Calving", value: "\(daysRemaining)")
                    }
                }
                
                if let lactationStatus = herd.lactationStatus {
                    InfoRow(label: "Lactation Status", value: lactationStatus)
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

// MARK: - Location Card
struct LocationCard: View {
    let paddock: String
    let saleyard: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            VStack(spacing: 12) {
                InfoRow(label: "Paddock", value: paddock)
                if let saleyard = saleyard {
                    InfoRow(label: "Saleyard", value: saleyard)
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

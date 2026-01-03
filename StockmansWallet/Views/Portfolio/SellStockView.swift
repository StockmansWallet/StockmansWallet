//
//  SellStockView.swift
//  StockmansWallet
//
//  Record sales and realized prices for livestock
//  Debug: Matches AddHerdFlowView styling with custom header and clean layout
//

import SwiftUI
import SwiftData

struct SellStockView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<HerdGroup> { !$0.isSold }, sort: \HerdGroup.updatedAt, order: .reverse) private var activeHerds: [HerdGroup]
    
    @State private var selectedHerd: HerdGroup?
    @State private var saleDate = Date()
    @State private var salePrice: Double = 0
    @State private var pricePerKg: Double = 0
    @State private var notes: String = ""
    @State private var headSold: Int = 0
    @State private var freightCost: Double = 0
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    // Debug: Back button meets iOS 26 HIG minimum touch target of 44x44pt
                    Button(action: {
                        HapticManager.tap()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.primaryText)
                            .frame(width: 44, height: 44) // iOS 26 HIG: Minimum 44x44pt
                            .background(Theme.inputFieldBackground)
                            .clipShape(Circle())
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .accessibilityLabel("Back")
                    
                    Spacer()
                    
                    Text("Sell Stock")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        if activeHerds.isEmpty {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "chart.line.downtrend.xyaxis")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Theme.secondaryText)
                                
                                Text("No Active Stock")
                                    .font(Theme.title)
                                    .foregroundStyle(Theme.primaryText)
                                
                                Text("Add some stock to your portfolio before recording sales")
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        } else {
                            // Sale form
                            VStack(alignment: .leading, spacing: 24) {
                                // Select Herd
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Select Herd/Mob")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                    
                                    Picker("Select Herd", selection: $selectedHerd) {
                                        Text("Choose herd to sell").tag(nil as HerdGroup?)
                                        ForEach(activeHerds, id: \.id) { herd in
                                            Text(herd.name).tag(herd as HerdGroup?)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding()
                                    .background(Theme.inputFieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .onChange(of: selectedHerd) { _, newValue in
                                        HapticManager.tap()
                                        if let herd = newValue {
                                            headSold = herd.headCount
                                        }
                                    }
                                }
                                
                                if let herd = selectedHerd {
                                    // Herd details
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Current Head Count:")
                                                .font(Theme.body)
                                                .foregroundStyle(Theme.secondaryText)
                                            Spacer()
                                            Text("\(herd.headCount)")
                                                .font(Theme.headline)
                                                .foregroundStyle(Theme.accent)
                                        }
                                        .padding()
                                        .background(Theme.inputFieldBackground.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    
                                    // Head sold
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Head Sold")
                                            .font(Theme.headline)
                                            .foregroundStyle(Theme.primaryText)
                                        
                                        Stepper(value: $headSold, in: 1...herd.headCount, step: 1) {
                                            Text("\(headSold) head")
                                                .font(Theme.headline)
                                                .foregroundStyle(Theme.primaryText)
                                        }
                                        .padding()
                                        .background(Theme.inputFieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .onChange(of: headSold) { _, _ in
                                            calculateTotalPrice()
                                        }
                                    }
                                    
                                    // Sale date
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Sale Date")
                                            .font(Theme.headline)
                                            .foregroundStyle(Theme.primaryText)
                                        
                                        DatePicker("", selection: $saleDate, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .padding()
                                            .background(Theme.inputFieldBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    
                                    // Price per kg
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Price per kg ($/kg)")
                                            .font(Theme.headline)
                                            .foregroundStyle(Theme.primaryText)
                                        
                                        TextField("0.00", value: $pricePerKg, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.plain)
                                            .padding()
                                            .background(Theme.inputFieldBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .onChange(of: pricePerKg) { _, _ in
                                                calculateTotalPrice()
                                            }
                                    }
                                    
                                    // Calculated total price
                                    if pricePerKg > 0, let herd = selectedHerd {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Text("Estimated Total:")
                                                    .font(Theme.body)
                                                    .foregroundStyle(Theme.secondaryText)
                                                Spacer()
                                                Text("$\(String(format: "%.2f", salePrice))")
                                                    .font(Theme.title3)
                                                    .foregroundStyle(Theme.accent)
                                            }
                                            .padding()
                                            .background(Theme.inputFieldBackground.opacity(0.5))
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        }
                                    }
                                    
                                    // Freight cost (optional)
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 4) {
                                            Text("Freight Cost ($)")
                                                .font(Theme.headline)
                                                .foregroundStyle(Theme.primaryText)
                                            Text("Optional")
                                                .font(Theme.caption)
                                                .foregroundStyle(Theme.secondaryText)
                                        }
                                        
                                        TextField("0.00", value: $freightCost, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.plain)
                                            .padding()
                                            .background(Theme.inputFieldBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    
                                    // Notes (optional)
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 4) {
                                            Text("Notes")
                                                .font(Theme.headline)
                                                .foregroundStyle(Theme.primaryText)
                                            Text("Optional")
                                                .font(Theme.caption)
                                                .foregroundStyle(Theme.secondaryText)
                                        }
                                        
                                        TextField("Sale notes or additional details", text: $notes, axis: .vertical)
                                            .textFieldStyle(.plain)
                                            .lineLimit(3...6)
                                            .padding()
                                            .background(Theme.inputFieldBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                
                // Bottom controls
                // Debug: No background on bottom controls for cleaner design
                if !activeHerds.isEmpty && selectedHerd != nil {
                    VStack(spacing: 16) {
                        Button(action: {
                            HapticManager.tap()
                            showingConfirmation = true
                        }) {
                            Text("Record Sale")
                        }
                        .buttonStyle(Theme.PrimaryButtonStyle())
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.5)
                        .padding(.horizontal, 20)
                        .accessibilityLabel("Record sale")
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .background(Theme.sheetBackground.ignoresSafeArea())
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
            .alert("Confirm Sale", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) {
                    HapticManager.tap()
                }
                Button("Confirm", role: .destructive) {
                    HapticManager.success()
                    recordSale()
                }
            } message: {
                if let herd = selectedHerd {
                    Text("Record sale of \(headSold) head from \(herd.name) at $\(String(format: "%.2f", pricePerKg))/kg (Total: $\(String(format: "%.2f", salePrice)))?")
                }
            }
        }
    }
    
    // Debug: Validation for form fields
    private var isValid: Bool {
        guard let _ = selectedHerd else { return false }
        return pricePerKg > 0 && headSold > 0
    }
    
    // Debug: Calculate total price based on weight and price per kg
    private func calculateTotalPrice() {
        guard let herd = selectedHerd else { return }
        // Calculate current weight (initial weight + growth)
        let daysSinceAcquisition = Calendar.current.dateComponents([.day], from: herd.createdAt, to: Date()).day ?? 0
        let currentWeight = herd.initialWeight + (herd.dailyWeightGain * Double(daysSinceAcquisition))
        let totalWeight = currentWeight * Double(headSold)
        salePrice = totalWeight * pricePerKg
    }
    
    // Debug: Record the sale and update the herd
    private func recordSale() {
        guard let herd = selectedHerd else { return }
        
        // Calculate current weight (initial weight + growth)
        let daysSinceAcquisition = Calendar.current.dateComponents([.day], from: herd.createdAt, to: Date()).day ?? 0
        let currentWeight = herd.initialWeight + (herd.dailyWeightGain * Double(daysSinceAcquisition))
        
        // Calculate net value (total price - freight)
        let netValue = salePrice - freightCost
        
        // Create sales record
        let saleRecord = SalesRecord(
            herdGroupId: herd.id,
            saleDate: saleDate,
            headCount: headSold,
            averageWeight: currentWeight,
            pricePerKg: pricePerKg,
            totalGrossValue: salePrice,
            freightCost: freightCost,
            freightDistance: 0, // Can be added later if needed
            netValue: netValue,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(saleRecord)
        
        // Mark herd as sold or reduce head count
        if headSold == herd.headCount {
            herd.isSold = true
            herd.soldDate = saleDate
            herd.soldPrice = pricePerKg
        } else {
            // Partial sale - reduce head count
            herd.headCount -= headSold
        }
        
        herd.updatedAt = Date()
        
        do {
            try modelContext.save()
            HapticManager.success()
            dismiss()
        } catch {
            HapticManager.error()
            print("Error recording sale: \(error)")
        }
    }
}


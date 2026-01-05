//
//  AddAssetMenuView.swift
//  StockmansWallet
//
//  ADD / MANAGE ASSETS Full Page (slides in from right)
//

import SwiftUI

struct AddAssetMenuView: View {
    @Binding var isPresented: Bool
    @State private var showingAddHerd = false
    @State private var showingAddIndividual = false
    @State private var showingCSVImport = false
    @State private var showingSellAssets = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Debug: Background gradient treatment for visual consistency with main pages
                Theme.backgroundGradient
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .center, spacing: 8) {
                            Text("Add & Sell Stock")
                                .font(Theme.title)
                                .foregroundStyle(.white)
                            
                            Text("Manage your livestock portfolio")
                                .font(Theme.body)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                        
                        // Individual Option Buttons
                        VStack(spacing: 16) {
                            
                            
                            // Add Individual
                            AssetMenuRow(
                                iconColor: Theme.accent,
                                iconSymbol: "plus.app",
                                customImageName: "cattle_tag",
                                title: "Add Individual",
                                subtitle: "Track a single tagged animal"
                            ) {
                                HapticManager.tap()
                                showingAddIndividual = true
                            }
                            
                            
                            // Add Herd / Mob
                            AssetMenuRow(
                                iconColor: Theme.accent,
                                iconSymbol: "plus.app",
                                customImageName: "cattle_tags",
                                title: "Add Herd",
                                subtitle: "Record a new herd"
                            ) {
                                HapticManager.tap()
                                showingAddHerd = true
                            }
                            
                            
                            // Import CSV
                            AssetMenuRow(
                                iconColor: Theme.positiveChange,
                                iconSymbol: "square.and.arrow.down",
                                title: "Import CSV",
                                subtitle: "Bulk import from spreadsheet"
                            ) {
                                HapticManager.tap()
                                showingCSVImport = true
                            }
                            
                            // Sell Assets
                            AssetMenuRow(
                                iconColor: .blue,
                                iconSymbol: "dollarsign",
                                title: "Sell Stock",
                                subtitle: "Record sales and realised prices"
                            ) {
                                HapticManager.tap()
                                showingSellAssets = true
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticManager.tap()
                        isPresented = false
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
            .sheet(isPresented: $showingAddHerd) {
                AddHerdFlowView()
                    .presentationBackground(Theme.sheetBackground)
            }
            .sheet(isPresented: $showingAddIndividual) {
                AddIndividualAnimalView()
                    .presentationBackground(Theme.sheetBackground)
            }
            .sheet(isPresented: $showingCSVImport) {
                CSVImportView()
                    .presentationBackground(Theme.sheetBackground)
            }
            .sheet(isPresented: $showingSellAssets) {
                SellStockView()
                    .presentationBackground(Theme.sheetBackground)
            }
        }
    }
}

// MARK: - Asset Menu Row
struct AssetMenuRow: View {
    let iconColor: Color
    let iconSymbol: String
    var customImageName: String? = nil // Debug: Optional custom image from Assets
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        // Debug: iOS 26 HIG - Menu row button meets minimum touch target (20pt vertical padding = 40pt + content)
        Button(action: action) {
            HStack(spacing: 16) {
                // Square Icon with darker colored background and bright colored icon
                ZStack {
                    // Darker variant of the icon color as background
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconColor.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    // Debug: Use custom image if provided, otherwise SF Symbol
                    if let customImageName = customImageName {
                        Image(customImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundStyle(iconColor)
                    } else {
                        Image(systemName: iconSymbol)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.headline)
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(Theme.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Right chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(minHeight: Theme.minimumTouchTarget) // iOS 26 HIG: Ensure 44pt minimum
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonBorderShape(.roundedRectangle)
    }
}

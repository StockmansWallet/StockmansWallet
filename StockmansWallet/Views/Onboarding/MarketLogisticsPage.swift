//
//  MarketLogisticsPage.swift
//  StockmansWallet
//
//  Page 4: Market & Logistics Preferences
//

import SwiftUI

struct MarketLogisticsPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    @State private var searchText = ""
    
    private var filteredSaleyards: [String] {
        if searchText.isEmpty {
            return ReferenceData.saleyards
        }
        return ReferenceData.saleyards.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Market & Logistics",
            subtitle: "Configure your market preferences",
            currentPage: $currentPage,
            nextPage: 4
        ) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Reference Saleyard")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 0) {
                        // Debug: iOS 26 HIG - Search field uses Theme.buttonHeight for consistency
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.secondaryText)
                            TextField("Search saleyards...", text: $searchText)
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(height: Theme.buttonHeight)
                        .background(Theme.inputFieldBackground)
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(filteredSaleyards, id: \.self) { saleyard in
                                    Button(action: {
                                        HapticManager.tap()
                                        userPrefs.defaultSaleyard = saleyard
                                        searchText = ""
                                    }) {
                                        HStack {
                                            Text(saleyard)
                                                .font(Theme.body)
                                                .foregroundStyle(Theme.primaryText)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                            if userPrefs.defaultSaleyard == saleyard {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Theme.accent)
                                            }
                                        }
                                    }
                                    .buttonStyle(Theme.RowButtonStyle())
                                    .accessibilityLabel(saleyard)
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                            .stroke(Theme.separator, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                }
                
                Toggle(isOn: $userPrefs.truckItEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "truck.box.fill")
                                .foregroundStyle(Theme.accent)
                            Text("Enable TruckIt API")
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                        }
                        Text("Automatically calculate freight deductions from gross valuations")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: Theme.buttonHeight) // iOS 26 HIG: Consistent with button heights
                .stitchedCard()
                .padding(.horizontal, 20)
            }
        }
    }
}


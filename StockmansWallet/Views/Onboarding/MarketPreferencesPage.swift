//
//  MarketPreferencesPage.swift
//  StockmansWallet
//
//  Page 5: Market Preferences
//

import SwiftUI

struct MarketPreferencesPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    @State private var searchText = ""
    
    // Debug: iOS 26 HIG - Focus state for search field keyboard management
    @FocusState private var isSearchFocused: Bool
    
    private var filteredSaleyards: [String] {
        if searchText.isEmpty {
            return ReferenceData.saleyards
        }
        return ReferenceData.saleyards.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Debug: Validation - saleyard selection is required
    private var isValid: Bool {
        userPrefs.defaultSaleyard != nil && !(userPrefs.defaultSaleyard ?? "").isEmpty
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Market Preferences",
            subtitle: "Set up your preferred saleyard",
            currentPage: $currentPage,
            nextPage: 5,
            isValid: isValid
        ) {
            // Debug: iOS 26 HIG - Organized layout with cleaner UI (removed section headings)
            VStack(spacing: 24) {
                // Saleyard Selection
                // Debug: Removed "Primary Reference Saleyard" heading - cleaner UI
                VStack(alignment: .leading, spacing: 12) {
                    VStack(spacing: 0) {
                        // Debug: iOS 26 HIG - Search field uses Theme.buttonHeight for consistency
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.secondaryText)
                                .frame(width: 20)
                            TextField("Search saleyards...", text: $searchText)
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                                .submitLabel(.search) // Debug: iOS 26 HIG - Proper return key label for search
                                .focused($isSearchFocused)
                                .onSubmit {
                                    // Debug: iOS 26 HIG - Dismiss keyboard when search submitted
                                    isSearchFocused = false
                                }
                                .accessibilityLabel("Search saleyards")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(height: Theme.buttonHeight)
                        .background(Theme.inputFieldBackground)
                        
                        // Debug: Scrollable list with proper spacing
                        ScrollView {
                            VStack(spacing: 0) {
                                if filteredSaleyards.isEmpty {
                                    // Empty state when search returns no results
                                    VStack(spacing: 8) {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundStyle(Theme.secondaryText)
                                            .font(.title2)
                                        Text("No saleyards found")
                                            .font(Theme.body)
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    ForEach(filteredSaleyards, id: \.self) { saleyard in
                                        Button(action: {
                                            HapticManager.tap()
                                            userPrefs.defaultSaleyard = saleyard
                                            searchText = "" // Clear search after selection
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
                                        .accessibilityAddTraits(userPrefs.defaultSaleyard == saleyard ? [.isSelected] : [])
                                    }
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
                    
                    // Debug: Show validation hint if no saleyard selected
                    if userPrefs.defaultSaleyard == nil || (userPrefs.defaultSaleyard ?? "").isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Theme.secondaryText)
                                .font(.caption)
                            Text("Please select a saleyard to continue")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .padding(.top, 8)
                    }
                }
                
                // Logistics Options
                // Debug: Removed "Logistics Options" heading - cleaner UI
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $userPrefs.truckItEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 12) {
                                Image(systemName: "truck.box.fill")
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 24)
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
                    .cardStyle()
                    .padding(.horizontal, 20)
                    .accessibilityLabel("TruckIt API")
                    .accessibilityValue(userPrefs.truckItEnabled ? "Enabled" : "Disabled")
                }
            }
            .padding(.top, 8)
        }
    }
}


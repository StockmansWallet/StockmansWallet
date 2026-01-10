//
//  SaleLocationSelectionSheet.swift
//  StockmansWallet
//
//  Sheet for selecting sale location (saleyard or custom location)
//  Debug: Simplified version for sale recording with "None" option
//

import SwiftUI
import SwiftData

struct SaleLocationSelectionSheet: View {
    @Binding var selectedLocation: String?
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]
    @Query private var customLocations: [CustomSaleLocation]
    @State private var searchText = ""
    
    // Debug: Get user preferences for filtered saleyards
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    // Debug: Filter saleyards based on search text and user preferences
    private var filteredSaleyards: [String] {
        let enabledSaleyards = userPrefs.filteredSaleyards
        if searchText.isEmpty {
            return enabledSaleyards
        } else {
            return enabledSaleyards.filter { 
                $0.localizedCaseInsensitiveContains(searchText) 
            }
        }
    }
    
    // Debug: Get enabled private locations
    private var enabledPrivateLocations: [CustomSaleLocation] {
        let locations = customLocations.filter { $0.category == "Private" && $0.isEnabled }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        if searchText.isEmpty {
            return locations
        } else {
            return locations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // Debug: Get enabled other locations
    private var enabledOtherLocations: [CustomSaleLocation] {
        let locations = customLocations.filter { $0.category == "Other" && $0.isEnabled }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        if searchText.isEmpty {
            return locations
        } else {
            return locations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Debug: None option - always visible at top
                Section {
                    Button(action: {
                        HapticManager.tap()
                        selectedLocation = nil
                        dismiss()
                    }) {
                        HStack {
                            Text("None")
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                            
                            Spacer()
                            
                            if selectedLocation == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accent)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Default")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                
                // Debug: Private locations section
                if !enabledPrivateLocations.isEmpty {
                    Section {
                        ForEach(enabledPrivateLocations) { location in
                            Button(action: {
                                HapticManager.tap()
                                selectedLocation = location.name
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(location.name)
                                            .font(Theme.body)
                                            .foregroundStyle(Theme.primaryText)
                                        
                                        if let address = location.address, !address.isEmpty {
                                            Text(address)
                                                .font(Theme.caption)
                                                .foregroundStyle(Theme.secondaryText)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedLocation == location.name {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.accent)
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text("Private Locations")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                
                // Debug: Other locations section
                if !enabledOtherLocations.isEmpty {
                    Section {
                        ForEach(enabledOtherLocations) { location in
                            Button(action: {
                                HapticManager.tap()
                                selectedLocation = location.name
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(location.name)
                                            .font(Theme.body)
                                            .foregroundStyle(Theme.primaryText)
                                        
                                        if let address = location.address, !address.isEmpty {
                                            Text(address)
                                                .font(Theme.caption)
                                                .foregroundStyle(Theme.secondaryText)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedLocation == location.name {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.accent)
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text("Other Locations")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                
                // Debug: All saleyards section - filterable by search
                Section {
                    ForEach(filteredSaleyards, id: \.self) { saleyard in
                        Button(action: {
                            HapticManager.tap()
                            selectedLocation = saleyard
                            dismiss()
                        }) {
                            HStack {
                                Text(saleyard)
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                if selectedLocation == saleyard {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.accent)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("Saleyards")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                
                // Debug: Show helpful message if no results at all
                if filteredSaleyards.isEmpty && enabledPrivateLocations.isEmpty && enabledOtherLocations.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.secondaryText.opacity(0.5))
                            
                            Text("No locations found")
                                .font(Theme.body)
                                .foregroundStyle(Theme.secondaryText)
                            
                            Text("Try a different search term")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search locations"
            )
            .navigationTitle("Select Location")
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
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundColor)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SaleLocationSelectionSheet(selectedLocation: .constant(nil))
}

//
//  SaleLocationsSettingsView.swift
//  StockmansWallet
//
//  Sale Location Preferences - Manage saleyards, private locations, and other venues
//  Debug: Three categories with segmented control - Saleyards, Private, Other
//

import SwiftUI
import SwiftData

// Debug: View for managing sale locations across three categories
struct SaleLocationsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @Query private var customLocations: [CustomSaleLocation]
    
    // Debug: Get or create user preferences
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    // Debug: Segmented control state
    @State private var selectedCategory: LocationCategory = .saleyards
    
    // Debug: Saleyard management state
    @State private var searchText = ""
    @State private var enabledSaleyards: Set<String> = []
    
    // Debug: Sheet presentation state
    @State private var showingAddLocation = false
    @State private var locationToEdit: CustomSaleLocation? = nil
    
    // Debug: Filter private locations
    private var privateLocations: [CustomSaleLocation] {
        customLocations.filter { $0.category == "Private" }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    // Debug: Filter other locations
    private var otherLocations: [CustomSaleLocation] {
        customLocations.filter { $0.category == "Other" }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    // Debug: Filter saleyards based on search text
    private var filteredSaleyards: [String] {
        let yards = ReferenceData.saleyards
        guard !searchText.isEmpty else { return yards }
        return yards.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Debug: Check if all saleyards are enabled
    private var allSaleyardsEnabled: Bool {
        enabledSaleyards.count == ReferenceData.saleyards.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Debug: Segmented control for category selection
            Picker("Category", selection: $selectedCategory) {
                ForEach(LocationCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Debug: Category-specific content
            switch selectedCategory {
            case .saleyards:
                saleyardsContent
            case .private:
                customLocationsContent(category: "Private", locations: privateLocations)
            case .other:
                customLocationsContent(category: "Other", locations: otherLocations)
            }
        }
        .background(Theme.backgroundGradient)
        .navigationTitle("Sale Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingAddLocation) {
            AddCustomLocationSheet(
                category: selectedCategory == .private ? "Private" : "Other",
                locationToEdit: locationToEdit
            )
        }
        .onAppear {
            loadEnabledSaleyards()
        }
        .onChange(of: selectedCategory) { _, _ in
            // Debug: Clear search when switching categories
            searchText = ""
        }
    }
    
    // MARK: - Saleyards Content
    
    private var saleyardsContent: some View {
        VStack(spacing: 0) {
            // Debug: Header section with description and bulk actions
            VStack(alignment: .leading, spacing: 16) {
                Text("Select which saleyards you want to see throughout the app. You must have at least one saleyard enabled.")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal)
                
                // Debug: Bulk action buttons
                HStack(spacing: 12) {
                    Button {
                        HapticManager.tap()
                        selectAllSaleyards()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Select All")
                                .font(Theme.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Theme.accentColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Theme.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    
                    Button {
                        HapticManager.tap()
                        deselectAllSaleyards()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Deselect All")
                                .font(Theme.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Theme.secondaryText)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Theme.secondaryText.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .disabled(enabledSaleyards.count <= 1) // Debug: Prevent disabling all
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Debug: Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.secondaryText)
                    TextField("Search saleyards", text: $searchText)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                    
                    if !searchText.isEmpty {
                        Button {
                            HapticManager.tap()
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
                .padding(12)
                .background(Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
            }
            .padding(.vertical)
            
            Divider()
                .background(Theme.separator)
            
            // Debug: Saleyards list with toggles
            List {
                Section {
                    ForEach(filteredSaleyards, id: \.self) { saleyard in
                        SaleyardToggleRow(
                            saleyard: saleyard,
                            isEnabled: enabledSaleyards.contains(saleyard),
                            isLastEnabled: enabledSaleyards.count == 1 && enabledSaleyards.contains(saleyard),
                            onToggle: {
                                toggleSaleyard(saleyard)
                            }
                        )
                    }
                } header: {
                    HStack {
                        Text("\(enabledSaleyards.count) of \(ReferenceData.saleyards.count) enabled")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .textCase(nil)
                    }
                }
                .listRowBackground(Theme.cardBackground)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
    
    // MARK: - Custom Locations Content
    
    private func customLocationsContent(category: String, locations: [CustomSaleLocation]) -> some View {
        VStack(spacing: 0) {
            // Debug: Header section with description
            VStack(alignment: .leading, spacing: 16) {
                Text("Manage your \(category.lowercased()) sale locations. Toggle them on or off, or tap to edit details.")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal)
                
                // Debug: Add new location button
                Button {
                    HapticManager.tap()
                    locationToEdit = nil
                    showingAddLocation = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add \(category) Location")
                            .font(Theme.body)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Theme.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            
            Divider()
                .background(Theme.separator)
            
            // Debug: Locations list or empty state
            if locations.isEmpty {
                // Debug: Empty state
                VStack(spacing: 16) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Theme.secondaryText.opacity(0.5))
                    
                    Text("No \(category) Locations")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Text("Add your first \(category.lowercased()) sale location to get started")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Debug: Locations list
                List {
                    Section {
                        ForEach(locations) { location in
                            CustomLocationRow(
                                location: location,
                                onToggle: {
                                    toggleCustomLocation(location)
                                },
                                onEdit: {
                                    locationToEdit = location
                                    showingAddLocation = true
                                }
                            )
                        }
                        .onDelete { indexSet in
                            deleteLocations(at: indexSet, from: locations)
                        }
                    } header: {
                        HStack {
                            let enabledCount = locations.filter { $0.isEnabled }.count
                            Text("\(enabledCount) of \(locations.count) enabled")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                                .textCase(nil)
                        }
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }
    
    // MARK: - Helper Functions - Saleyards
    
    // Debug: Load enabled saleyards from preferences
    private func loadEnabledSaleyards() {
        let prefs = userPrefs
        if prefs.enabledSaleyards.isEmpty {
            // Debug: Empty array means all enabled (default behavior)
            enabledSaleyards = Set(ReferenceData.saleyards)
        } else {
            enabledSaleyards = Set(prefs.enabledSaleyards)
        }
    }
    
    // Debug: Toggle a specific saleyard on/off
    private func toggleSaleyard(_ saleyard: String) {
        // Debug: Prevent disabling the last saleyard (must have at least 1)
        if enabledSaleyards.contains(saleyard) && enabledSaleyards.count == 1 {
            HapticManager.warning()
            return
        }
        
        if enabledSaleyards.contains(saleyard) {
            enabledSaleyards.remove(saleyard)
            HapticManager.tap()
        } else {
            enabledSaleyards.insert(saleyard)
            HapticManager.tap()
        }
        
        saveSaleyardChanges()
    }
    
    // Debug: Enable all saleyards
    private func selectAllSaleyards() {
        enabledSaleyards = Set(ReferenceData.saleyards)
        saveSaleyardChanges()
        HapticManager.success()
    }
    
    // Debug: Disable all saleyards except one (keep at least 1 enabled)
    private func deselectAllSaleyards() {
        // Debug: Keep the first saleyard enabled to maintain minimum requirement
        if let firstYard = ReferenceData.saleyards.first {
            enabledSaleyards = Set([firstYard])
            saveSaleyardChanges()
            HapticManager.success()
        }
    }
    
    // Debug: Save saleyard changes to preferences
    private func saveSaleyardChanges() {
        let prefs = userPrefs
        
        // Debug: If all saleyards are enabled, store empty array (default behavior)
        if enabledSaleyards.count == ReferenceData.saleyards.count {
            prefs.enabledSaleyards = []
        } else {
            prefs.enabledSaleyards = Array(enabledSaleyards).sorted()
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Helper Functions - Custom Locations
    
    // Debug: Toggle a custom location on/off
    private func toggleCustomLocation(_ location: CustomSaleLocation) {
        location.isEnabled.toggle()
        try? modelContext.save()
        HapticManager.tap()
    }
    
    // Debug: Delete custom locations
    private func deleteLocations(at offsets: IndexSet, from locations: [CustomSaleLocation]) {
        for index in offsets {
            modelContext.delete(locations[index])
        }
        try? modelContext.save()
        HapticManager.success()
    }
}

// MARK: - Location Category Enum

enum LocationCategory: String, CaseIterable, Identifiable {
    case saleyards = "Saleyards"
    case `private` = "Private"
    case other = "Other"
    
    var id: String { rawValue }
}

// MARK: - Saleyard Toggle Row
// Debug: Individual row component for each saleyard with toggle
struct SaleyardToggleRow: View {
    let saleyard: String
    let isEnabled: Bool
    let isLastEnabled: Bool // Debug: True if this is the only enabled saleyard
    let onToggle: () -> Void
    
    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: 12) {
                // Debug: Toggle indicator
                ZStack {
                    Circle()
                        .fill(isEnabled ? Theme.accentColor : Theme.secondaryText.opacity(0.2))
                        .frame(width: 24, height: 24)
                    
                    if isEnabled {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                
                // Debug: Saleyard name
                Text(saleyard)
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Debug: Show warning icon if this is the last enabled saleyard
                if isLastEnabled {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isLastEnabled ? 0.6 : 1.0) // Debug: Dim the last enabled item
    }
}

// MARK: - Custom Location Row
// Debug: Row component for custom locations with toggle and edit functionality
struct CustomLocationRow: View {
    let location: CustomSaleLocation
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        Button {
            onEdit()
        } label: {
            HStack(spacing: 12) {
                // Debug: Toggle indicator (separate button to prevent propagation)
                Button {
                    onToggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(location.isEnabled ? Theme.accentColor : Theme.secondaryText.opacity(0.2))
                            .frame(width: 24, height: 24)
                        
                        if location.isEnabled {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                // Debug: Location details
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                    
                    if let address = location.address, !address.isEmpty {
                        Text(address)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }
                    
                    if let contact = location.contactName, !contact.isEmpty {
                        Text(contact)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Debug: Edit indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SaleLocationsSettingsView()
    }
}

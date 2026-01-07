//
//  SaleyardsSettingsView.swift
//  StockmansWallet
//
//  Saleyard Preferences - Allow users to enable/disable specific saleyards
//  Debug: Filters saleyards throughout the app based on user selection
//

import SwiftUI
import SwiftData

// Debug: View for managing which saleyards are visible throughout the app
struct SaleyardsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: Get or create user preferences
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    @State private var searchText = ""
    @State private var enabledSaleyards: Set<String> = []
    
    // Debug: Filter saleyards based on search text
    private var filteredSaleyards: [String] {
        let yards = ReferenceData.saleyards
        guard !searchText.isEmpty else { return yards }
        return yards.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Debug: Check if all saleyards are enabled
    private var allEnabled: Bool {
        enabledSaleyards.count == ReferenceData.saleyards.count
    }
    
    var body: some View {
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
                        selectAll()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Select All")
                                .font(Theme.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Theme.accent)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Theme.accent.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    
                    Button {
                        HapticManager.tap()
                        deselectAll()
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
        .background(Theme.backgroundGradient)
        .navigationTitle("Saleyards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            loadEnabledSaleyards()
        }
    }
    
    // MARK: - Helper Functions
    
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
        
        saveChanges()
    }
    
    // Debug: Enable all saleyards
    private func selectAll() {
        enabledSaleyards = Set(ReferenceData.saleyards)
        saveChanges()
        HapticManager.success()
    }
    
    // Debug: Disable all saleyards except one (keep at least 1 enabled)
    private func deselectAll() {
        // Debug: Keep the first saleyard enabled to maintain minimum requirement
        if let firstYard = ReferenceData.saleyards.first {
            enabledSaleyards = Set([firstYard])
            saveChanges()
            HapticManager.success()
        }
    }
    
    // Debug: Save changes to preferences
    private func saveChanges() {
        let prefs = userPrefs
        
        // Debug: If all saleyards are enabled, store empty array (default behavior)
        if enabledSaleyards.count == ReferenceData.saleyards.count {
            prefs.enabledSaleyards = []
        } else {
            prefs.enabledSaleyards = Array(enabledSaleyards).sorted()
        }
        
        try? modelContext.save()
    }
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
                        .fill(isEnabled ? Theme.accent : Theme.secondaryText.opacity(0.2))
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





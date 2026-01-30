import SwiftUI
import SwiftData

struct LivestockPreferencesDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allPrefs: [UserPreferences]

    let prefs: UserPreferences

    @State private var defaultState: String = "NSW"
    @State private var defaultMortality: Double = 0.05
    @State private var defaultCalving: Double = 0.85
    @State private var selectedSaleyard: String = ""
    @State private var showSaleyardSheet = false
    @State private var saleyardSearch = ""

    private var persistedPrefs: UserPreferences {
        allPrefs.first ?? prefs
    }

    var body: some View {
        List {
            Section("Defaults") {
                Picker("State", selection: $defaultState) {
                    ForEach(ReferenceData.states, id: \.self) { Text($0).tag($0) }
                }
                .onChange(of: defaultState) { _, newValue in
                    update { $0.defaultState = newValue }
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Mortality")
                        Spacer()
                        Text("\(Int(defaultMortality * 100))%")
                            .foregroundStyle(Theme.secondaryText)
                            .accessibilityHidden(true)
                    }
                    Slider(value: $defaultMortality, in: 0...0.2, step: 0.005)
                        .accessibilityLabel("Default mortality rate")
                        .onChange(of: defaultMortality) { _, newValue in
                            update { $0.defaultMortalityRate = newValue }
                        }
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Calving")
                        Spacer()
                        Text("\(Int(defaultCalving * 100))%")
                            .foregroundStyle(Theme.secondaryText)
                            .accessibilityHidden(true)
                    }
                    Slider(value: $defaultCalving, in: 0.5...1.0, step: 0.01)
                        .accessibilityLabel("Default calving rate")
                        .onChange(of: defaultCalving) { _, newValue in
                            update { $0.defaultCalvingRate = newValue }
                        }
                }
            }
            .listRowBackground(Theme.cardBackground)

            Section("Market") {
                Button {
                    HapticManager.tap()
                    showSaleyardSheet = true
                } label: {
                    HStack {
                        Text("Default Saleyard")
                        Spacer()
                        Text(selectedSaleyard.isEmpty ? "None" : selectedSaleyard)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .sheet(isPresented: $showSaleyardSheet) {
                    SaleyardSearchSheet(
                        title: "Select Saleyard",
                        // Debug: Use filtered saleyards from user preferences
                        allOptions: persistedPrefs.filteredSaleyards,
                        selected: $selectedSaleyard,
                        searchText: $saleyardSearch,
                        onSelect: { yard in
                            selectedSaleyard = yard
                            update { $0.defaultSaleyard = yard.isEmpty ? nil : yard }
                        }
                    )
                    .presentationBackground(Theme.sheetBackground)
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Livestock Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            let p = persistedPrefs
            defaultState = p.defaultState
            defaultMortality = p.defaultMortalityRate
            defaultCalving = p.defaultCalvingRate
            selectedSaleyard = p.defaultSaleyard ?? ""
        }
    }

    private func update(_ mutate: (UserPreferences) -> Void) {
        let p = persistedPrefs
        mutate(p)
        try? modelContext.save()
        HapticManager.tap()
    }
}

// MARK: - Searchable saleyard sheet
private struct SaleyardSearchSheet: View {
    let title: String
    let allOptions: [String]
    @Binding var selected: String
    @Binding var searchText: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private var filtered: [String] {
        guard !searchText.isEmpty else { return allOptions }
        return allOptions.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.secondaryText)
                    TextField("Search saleyards", text: $searchText)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                }
                .padding(12)
                .background(Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
                .padding(.top)

                // Results list
                List {
                    Section {
                        Button {
                            HapticManager.tap()
                            onSelect("")
                            dismiss()
                        } label: {
                            HStack {
                                Text("None")
                                Spacer()
                                if selected.isEmpty {
                                    Image(systemName: "checkmark").foregroundStyle(Theme.accentColor)
                                }
                            }
                        }
                        .listRowBackground(Theme.cardBackground)

                        ForEach(filtered, id: \.self) { yard in
                            Button {
                                HapticManager.tap()
                                onSelect(yard)
                                dismiss()
                            } label: {
                                HStack(alignment: .top) {
                                    Text(yard)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    if selected == yard {
                                        Image(systemName: "checkmark").foregroundStyle(Theme.accentColor)
                                    }
                                }
                            }
                            .listRowBackground(Theme.cardBackground)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Theme.backgroundGradient)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

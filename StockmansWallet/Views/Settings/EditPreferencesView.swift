import SwiftUI
import SwiftData

struct EditPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]

    @State private var defaultState: String = "NSW"
    @State private var defaultMortality: Double = 0.05
    @State private var defaultCalving: Double = 0.85

    var body: some View {
        NavigationStack {
            Form {
                Section("Defaults") {
                    Picker("State", selection: $defaultState) {
                        ForEach(["NSW","VIC","QLD","SA","WA","TAS","NT","ACT"], id: \.self) { Text($0) }
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
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient)
            .navigationTitle("Edit Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndDismiss() }
                        .accessibilityHint("Saves your preferences")
                }
            }
            .onAppear {
                let prefs = preferences.first ?? UserPreferences()
                if preferences.isEmpty {
                    modelContext.insert(prefs)
                }
                defaultState = prefs.defaultState
                defaultMortality = prefs.defaultMortalityRate
                defaultCalving = prefs.defaultCalvingRate
            }
        }
    }

    private func saveAndDismiss() {
        let prefs = preferences.first ?? UserPreferences()
        if preferences.isEmpty {
            modelContext.insert(prefs)
        }
        prefs.defaultState = defaultState
        prefs.defaultMortalityRate = defaultMortality
        prefs.defaultCalvingRate = defaultCalving
        try? modelContext.save()
        HapticManager.success()
        dismiss()
    }
}


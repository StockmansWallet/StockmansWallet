import SwiftUI

struct DataSyncSettingsView: View {
    @State private var iCloudSync = true
    @State private var useCellular = false
    @State private var lastSyncDate: Date? = nil
    @State private var autoSync = true

    var body: some View {
        List {
            Section("Sync") {
                Toggle("iCloud Sync", isOn: $iCloudSync)
                Toggle("Use Cellular Data", isOn: $useCellular)
                    .disabled(!iCloudSync)
                Toggle("Auto Sync", isOn: $autoSync)
                    .disabled(!iCloudSync)
                Button {
                    HapticManager.tap()
                    lastSyncDate = Date()
                } label: {
                    HStack {
                        Text("Sync Now")
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        if let last = lastSyncDate {
                            Text("Last: \(relativeDate(last))")
                                .foregroundStyle(Theme.secondaryText)
                                .font(Theme.caption)
                        }
                    }
                }
                .disabled(!iCloudSync)
            }
            .listRowBackground(Theme.cardBackground)

            Section("Storage") {
                HStack {
                    Text("Local Cache")
                    Spacer()
                    Text("Approx. 12 MB")
                        .foregroundStyle(Theme.secondaryText)
                }
                Button(role: .destructive) {
                    HapticManager.tap()
                    // Hook up to your cache clearing later
                } label: {
                    Text("Clear Local Cache")
                        .foregroundStyle(.red)
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Data & Sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

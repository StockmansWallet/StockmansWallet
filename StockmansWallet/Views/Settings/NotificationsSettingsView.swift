import SwiftUI

struct NotificationsSettingsView: View {
    @State private var notificationsEnabled = true
    @State private var priceAlertsEnabled = true
    @State private var herdEventsEnabled = false
    @State private var dailySummaryEnabled = false
    @State private var quietHoursEnabled = false
    @State private var quietStart = DateComponents(hour: 21, minute: 0)
    @State private var quietEnd = DateComponents(hour: 7, minute: 0)

    var body: some View {
        List {
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                Toggle("Price Alerts", isOn: $priceAlertsEnabled)
                    .disabled(!notificationsEnabled)
                Toggle("Herd Events", isOn: $herdEventsEnabled)
                    .disabled(!notificationsEnabled)
                Toggle("Daily Summary", isOn: $dailySummaryEnabled)
                    .disabled(!notificationsEnabled)
            }
            .listRowBackground(Theme.cardBackground)

            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
                if quietHoursEnabled {
                    HStack {
                        Text("Start")
                        Spacer()
                        Text(timeString(from: quietStart))
                            .foregroundStyle(Theme.secondaryText)
                    }
                    HStack {
                        Text("End")
                        Spacer()
                        Text(timeString(from: quietEnd))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: notificationsEnabled) { HapticManager.tap() }
        .onChange(of: priceAlertsEnabled) { HapticManager.tap() }
        .onChange(of: herdEventsEnabled) { HapticManager.tap() }
        .onChange(of: dailySummaryEnabled) { HapticManager.tap() }
        .onChange(of: quietHoursEnabled) { HapticManager.tap() }
    }

    private func timeString(from comps: DateComponents) -> String {
        var calendar = Calendar.current
        calendar.locale = .current
        let date = calendar.date(from: comps) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

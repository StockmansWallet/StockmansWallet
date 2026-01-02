import SwiftUI

struct SupportView: View {
    var body: some View {
        List {
            Section("Help") {
                Link(destination: URL(string: "https://example.com/support")!) {
                    HStack {
                        Text("Support Website")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                Link(destination: URL(string: "mailto:support@example.com")!) {
                    HStack {
                        Text("Email Support")
                        Spacer()
                        Image(systemName: "envelope")
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .listRowBackground(Theme.cardBackground)

            Section("Resources") {
                Button {
                    // Hook to in-app FAQ screen if you add one
                } label: {
                    Text("FAQ")
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

import SwiftUI

// Debug: Help & Support view with nested legal documents
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
            
            // Debug: Legal documents section nested within Help & Support
            Section("Legal") {
                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                
                NavigationLink(destination: TermsOfServiceView()) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

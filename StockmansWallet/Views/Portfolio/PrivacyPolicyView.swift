import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Privacy Policy")
                        .font(Theme.title)
                        .foregroundStyle(Theme.primaryText)

                    // Replace with your actual policy content
                    Text(bodyText)
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
            .listRowBackground(Theme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private let bodyText =
    """
    This is placeholder text for the Privacy Policy. Replace with your real policy content. Make sure to cover data collection, usage, storage, third-party services, and user rights. Keep it readable and concise.

    1. Information We Collect
    2. How We Use Information
    3. Data Retention
    4. Third-Party Services
    5. Security
    6. Your Rights
    7. Contact
    """
}

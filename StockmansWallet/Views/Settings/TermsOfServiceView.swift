import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Terms of Service")
                        .font(Theme.title)
                        .foregroundStyle(Theme.primaryText)

                    // Replace with your actual terms content
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
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private let bodyText =
    """
    This is placeholder text for the Terms of Service. Replace with your real terms. Clearly outline acceptable use, subscriptions/payments (if any), limitations of liability, warranty disclaimers, termination, and governing law.

    1. Acceptance of Terms
    2. Use of the Service
    3. Accounts and Security
    4. Intellectual Property
    5. Disclaimers and Limitation of Liability
    6. Termination
    7. Changes to These Terms
    8. Contact
    """
}

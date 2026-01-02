import SwiftUI

struct AboutView: View {
    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "—"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("About Stockman's Wallet")
                    .font(Theme.title)
                    .foregroundStyle(Theme.primaryText)

                Text("Stockman's Wallet helps you track livestock, markets, and profitability with clarity and speed.")
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Version")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text(versionString)
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Acknowledgements")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text("Thanks to the producers and industry partners who provided insight.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .padding()
        }
        .background(Theme.backgroundGradient)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

import SwiftUI

struct AppVersionFooter: View {
    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "—"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(versionString)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
            Text("© \(Calendar.current.component(.year, from: Date()))")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(versionString)
    }
}


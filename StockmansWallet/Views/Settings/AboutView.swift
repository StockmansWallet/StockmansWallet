import SwiftUI

struct AboutView: View {
    @State private var showCopiedAlert = false
    
    // Debug: Version string for display
    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "—"
        return "Version \(version) (\(build))"
    }
    
    // Debug: Environment string for display
    private var environmentString: String {
        return Config.environment.shouldShowBadge ? Config.environment.displayName : "Production"
    }
    
    // Debug: Full debug info string for copying to clipboard
    private var debugInfoString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "Unknown"
        let iosVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        let deviceName = UIDevice.current.name
        
        return """
        Stockman's Wallet \(environmentString)
        Version \(version) (\(build))
        iOS \(iosVersion)
        Device: \(deviceModel)
        Name: \(deviceName)
        """
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

                // Debug: Version & Environment Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Build Information")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Version:")
                                .font(Theme.body)
                                .foregroundStyle(Theme.secondaryText)
                            Text(versionString)
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                        }
                        
                        // Debug: Show environment if not production
                        if Config.environment.shouldShowBadge {
                            HStack {
                                Text("Environment:")
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.secondaryText)
                                HStack(spacing: 4) {
                                    EnvironmentBadge()
                                }
                            }
                        }
                    }
                    
                    // Debug: Copy Debug Info button for testers
                    Button {
                        HapticManager.tap()
                        UIPasteboard.general.string = debugInfoString
                        showCopiedAlert = true
                        
                        // Debug: Auto-dismiss alert after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopiedAlert = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Debug Info")
                        }
                        .font(Theme.body)
                        .foregroundStyle(Theme.accentColor)
                    }
                    .padding(.top, 4)
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
        // Debug: Show copied confirmation overlay
        .overlay(alignment: .top) {
            if showCopiedAlert {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Debug info copied to clipboard")
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(.top, 60)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: showCopiedAlert)
            }
        }
    }
}

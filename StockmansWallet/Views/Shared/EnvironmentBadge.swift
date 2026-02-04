//
//  EnvironmentBadge.swift
//  StockmansWallet
//
//  Debug: Environment badge for non-production builds (DEVELOPMENT, BETA, STAGING)
//  Helps testers and developers identify which build they're using
//

import SwiftUI

struct EnvironmentBadge: View {
    var body: some View {
        // Debug: Only show badge for non-production environments
        if Config.environment.shouldShowBadge {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                Text(badgeText)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.accentColor)
            .clipShape(Capsule())
        }
    }
    
    // Debug: Badge text with version number from Info.plist
    private var badgeText: String {
        let envName = Config.environment.displayName
        
        // Get version from Info.plist automatically
        if let version = appVersion {
            return "\(envName) v\(version)"
        }
        
        // Fallback if version not found
        return envName
    }
    
    // Debug: Read app version from Info.plist (CFBundleShortVersionString)
    private var appVersion: String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

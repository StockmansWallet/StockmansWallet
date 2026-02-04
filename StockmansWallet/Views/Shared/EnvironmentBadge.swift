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
            Text(Config.environment.displayName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    // Debug: Color based on environment
                    badgeColor
                        .opacity(0.9)
                )
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }
    
    // Debug: Badge color based on environment type
    private var badgeColor: Color {
        switch Config.environment {
        case .development:
            return Color.orange
        case .beta:
            return Color.blue
        case .staging:
            return Color.purple
        case .production:
            return Color.clear
        }
    }
}

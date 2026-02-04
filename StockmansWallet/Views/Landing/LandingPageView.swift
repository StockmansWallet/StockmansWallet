//
//  LandingPageView.swift
//  StockmansWallet
//
//  Landing screen: full-bleed background, logo, Skip / Continue. Composed by WelcomeFeaturesPage.
//

import SwiftUI

struct LandingPageView: View {
    /// Called when user taps "Continue" – coordinator slides landing left to reveal features.
    var onContinue: () -> Void
    var body: some View {
        ZStack {
            // Background base – shows through transparent parts of bg_landing
            Theme.background
                .ignoresSafeArea()

            // Full-bleed background image to bottom (iOS 26 HIG: content can extend edge-to-edge)
            Image("bg_landing")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
            
            // Content: logo larger and lower; bottom CTAs via safeAreaInset
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image("stockmanswallet")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        // Debug: Match logo tint to tertiary background for landing look.
                        .foregroundStyle(Theme.tertiaryBackground)
                        .frame(maxWidth: 220)
                        .accessibilityLabel("Stockman's Wallet")
                    
                    // Debug: Environment badge for non-production builds (under logo)
                    if Config.environment.shouldShowBadge {
                        EnvironmentBadge()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)

                Spacer(minLength: 0)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                landingBottomBar
            }
        }
    }

    private var landingBottomBar: some View {
        VStack(spacing: 12) {
            Button {
                // Debug: Track continue taps on landing.
                print("LandingPageView: Continue tapped")
                HapticManager.tap()
                onContinue()
            } label: {
                Text("Continue")
            }
            .buttonStyle(Theme.PrimaryButtonStyle())
            .padding(.horizontal, 24)

            Text("Powered by MLA Market Data")
                .font(Theme.caption)
                // Debug: Use primary text color for landing credit.
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
}

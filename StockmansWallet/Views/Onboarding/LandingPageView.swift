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
    /// Debug: Skip onboarding (development only).
    var onSkipToDashboard: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Cream base – shows through transparent top of bg_landing
            Theme.backgroundColor
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
                VStack(spacing: 8) {
                    Image("stockmanswallet")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(Theme.primaryText)
                        .frame(maxWidth: 220)
                        .accessibilityLabel("Stockman's Wallet")
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)

                Spacer(minLength: 0)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                landingBottomBar
            }
        }
    }

    private var landingBottomBar: some View {
        VStack(spacing: 12) {
            if let onSkip = onSkipToDashboard {
                Button {
                    HapticManager.tap()
                    onSkip()
                } label: {
                    Text("Skip to Dashboard")
                        .font(.caption)
                        .foregroundStyle(Theme.background)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Theme.primaryText))
                }
                .padding(.bottom, 4)
            }

            Button {
                HapticManager.tap()
                onContinue()
            } label: {
                Text("Continue")
            }
            .buttonStyle(Theme.LandingButtonStyle())
            .padding(.horizontal, 24)

            Text("Powered by MLA Market Data")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
}

//
//  LandingPageView.swift
//  StockmansWallet
//
//  Landing screen: full-bleed background, logo, Skip / Continue. Composed by WelcomeFeaturesPage.
//

import SwiftUI
import Lottie

struct LandingPageView: View {
    /// Called when user taps "Continue" – coordinator slides landing left to reveal features.
    var onContinue: () -> Void
    
    // Debug: Control Lottie animation playback state
    @State private var isAnimationPlaying = false
    // Debug: Track if animation has played once to prevent replay on view updates
    @State private var hasPlayedOnce = false
    
    var body: some View {
        ZStack {
            // Background base – shows through transparent parts of bg_landing
            Theme.background
                .ignoresSafeArea()

            // Full-bleed background image (iOS 26 HIG: content can extend edge-to-edge)
            Image("bg_landing")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Content: Proper VStack structure following iOS HIG
            VStack(spacing: 0) {
                // Debug: Logo and badge at top of screen
                VStack(spacing: 16) {
                    // Debug: Lottie logo animation - plays once and holds on final frame
                    LottieView(
                        animationName: "StockmansLogoAnim",
                        loopMode: .playOnce,
                        contentMode: .scaleAspectFit,
                        speed: 1.0,
                        isPlaying: $isAnimationPlaying
                    )
                    .frame(maxWidth: 350, maxHeight: 250)
                    .accessibilityLabel("Stockman's Wallet")
                    .onAppear {
                        // Debug: Start animation only on first appearance
                        if !hasPlayedOnce {
                            print("LandingPageView: Starting logo animation (first time)")
                            isAnimationPlaying = true
                            hasPlayedOnce = true
                        }
                    }
                    
                    // Debug: Environment badge for non-production builds (directly under logo)
                    if Config.environment.shouldShowBadge {
                        EnvironmentBadge()
                    }
                }
                .padding(.top, 100)
                
                Spacer()
                
                // Debug: Bottom bar with Continue button
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
    }
}

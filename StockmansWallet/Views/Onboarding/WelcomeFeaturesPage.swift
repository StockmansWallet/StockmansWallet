//
//  WelcomeFeaturesPage.swift
//  StockmansWallet
//
//  Welcome and features introduction page
//

import SwiftUI

// MARK: - Welcome + Features Pages
enum OnboardingStep {
    case landing
    case features
}

struct WelcomeFeaturesPage: View {
    @Binding var onboardingStep: OnboardingView.OnboardingStep
    @Binding var showingSignIn: Bool
    
    // Start child motion only after parent fade
    var introComplete: Bool = true

    @State private var step: OnboardingStep = .landing
    @State private var showHeaderText = false
    @State private var showTiles = false
    
    // Lottie control (fallback uses the same state)
    @State private var playLogo = false
    @State private var logoScale: CGFloat = 1.0 // Keep landing at final size to avoid first-frame motion

    var body: some View {
        ZStack {
            // Debug: Dark brown gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.15, blue: 0.1),
                    Color(red: 0.129, green: 0.102, blue: 0.086)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    VStack(spacing: 16) {
                        // Logo area: prefer Lottie when motion is allowed, fall back to static image
                        Group {
                            if UIAccessibility.isReduceMotionEnabled {
                                // Fallback image only when Reduce Motion is enabled
                                Image("sw_logoanim_fallback")
                                    .resizable()
                                    .scaledToFit()
                                    .accessibilityLabel("Stockman's Wallet")
                            } else {
                                // Lottie animation layer
                                LottieView(
                                    animationName: "sw_logoanim_c",
                                    isPlaying: $playLogo
                                )
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                            }
                        }
                        // Debug: Stable landing layout; only change when user taps to show features
                        .frame(height: step == .features ? 240 : 320) // Increased logo size for better visual hierarchy
                        .padding(.top, step == .features ? 0 : 40) // Push logo down from dynamic island on landing
                        .offset(y: step == .features ? 20 : 0)
                        .scaleEffect(logoScale)
                        .onAppear {
                            // No motion on first frame; start Lottie after the parent fade
                            if !UIAccessibility.isReduceMotionEnabled {
                                let delay: TimeInterval = introComplete ? 0.2 : 0.35
                                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                    playLogo = true
                                }
                            }
                        }

                        if step == .features {
                            VStack(spacing: 14) {
                                Text("Livestock Management")
                                    .font(.title2.weight(.bold)) // Debug: Increased to title2 for proper hierarchy
                                    .foregroundStyle(Theme.primaryText)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.8)
                                    .opacity(showHeaderText ? 1 : 0)
                                    .offset(y: showHeaderText ? 0 : 8)

                                Text("Manage your livestock assets like a share trading exchange. Real-time valuations, comprehensive reporting, and insights designed for primary producers.")
                                    .font(.subheadline) // Debug: Smaller font size for better hierarchy
                                    .foregroundStyle(Theme.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .frame(maxWidth: .infinity)
                                    .opacity(showHeaderText ? 1 : 0)
                                    .offset(y: showHeaderText ? 0 : 8)
                            }
                            .padding(.top, 10)
                            .animation(.easeOut(duration: 0.30), value: showHeaderText)

                            featureTiles
                                .padding(.top, 18)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Primary CTA with centralized style
                    VStack(spacing: 16) {
                        Button {
                            HapticManager.tap()

                            if step == .landing {
                                // Transition to features (user initiated)
                                withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                                    step = .features
                                    // Slightly reduce logo to create hierarchy with text below
                                    if !UIAccessibility.isReduceMotionEnabled {
                                        logoScale = 0.9
                                    }
                                }

                                showHeaderText = false
                                showTiles = false

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                                    showHeaderText = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                    showTiles = true
                                }
                            } else {
                                showingSignIn = true
                            }
                        } label: {
                            Text(step == .landing ? "Get Started" : "Continue")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(Theme.PrimaryButtonStyle())
                        .padding(.horizontal, 20)

                        Text("Powered by MLA Market Data")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.automatic) // cancel any parent buttonStyle override
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea(.all)
    }

    private var featureTiles: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                FeatureTile(icon: "chart.bar.fill", title: "Live Pricing")
                FeatureTile(icon: "shield.fill", title: "Secure Tracking")
            }

            HStack(spacing: 16) {
                FeatureTile(icon: "chart.line.uptrend.xyaxis", title: "Portfolio Insights")
                FeatureTile(icon: "doc.text.fill", title: "Bank Reports")
            }
        }
        .padding(.horizontal, 0)
        .opacity(showTiles ? 1 : 0)
        .offset(y: showTiles ? 0 : 10)
        .animation(.easeOut(duration: 0.25), value: showTiles)
    }
}

// MARK: - Feature Tile (non-interactive)
struct FeatureTile: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(Theme.accent)
            
            Text(title)
                .font(.callout.weight(.medium)) // Debug: Increased to callout for better readability
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.9)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .padding(.horizontal, 0)
        .stitchedCard() // Uses stitched design with transparent background and dashed border
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

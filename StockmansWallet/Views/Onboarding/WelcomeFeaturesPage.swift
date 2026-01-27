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
    @Binding var showingTermsPrivacy: Bool // Debug: Show Terms sheet after "Continue"
    @Binding var hasAcceptedTerms: Bool // Debug: Track if terms have been accepted
    
    // Start child motion only after parent fade
    var introComplete: Bool = true
    
    // Debug: TEMPORARY - Skip onboarding callbacks for development (DELETE BEFORE LAUNCH)
    var onSkipAsFarmer: (() -> Void)? = nil
    var onSkipAsAdvisor: (() -> Void)? = nil

    @State private var step: OnboardingStep = .landing
    @State private var playVideo = false
    @State private var showFeaturesPage = false // Debug: Controls slide-in animation

    var body: some View {
        ZStack {
            // Debug: Video background on landing page only
            if step == .landing && !UIAccessibility.isReduceMotionEnabled {
                // Debug: Animated video background with branding iron
                LandingVideoPlayer(
                    videoName: "LandingAnimation",
                    videoExtension: "mp4",
                    isPlaying: $playVideo
                )
            } else if step == .landing {
                // Debug: Static background image for landing page (Reduce Motion)
                Image("landingBG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
            
            // TEMPORARY: Dev skip button for testing (DELETE BEFORE LAUNCH) ⚠️
            VStack {
                HStack {
                    Spacer()
                    
                    // Debug: Skip to Dashboard - goes to farmer dashboard for testing
                    Button(action: {
                        HapticManager.tap()
                        onSkipAsFarmer?()
                    }) {
                        Text("Skip to Dashboard")
                            .font(.caption2)
                            .foregroundStyle(Theme.primaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(Theme.accent)
                            )
                    }
                    
                    Spacer()
                }
                .padding(.top, 50)
                Spacer()
            }

            // Debug: Features page slides in from right with solid background
            if step == .features {
                ZStack {
                    // Solid background for features page
                    Theme.backgroundColor
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                    
                    VStack(spacing: 0) {
                        Spacer()

                        VStack(spacing: 0) {
                            // Stockman's Wallet logo
                            Image("stockmanswallet")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(height: 90)
                                .foregroundStyle(Theme.primaryText)
                                .accessibilityLabel("Stockman's Wallet")
                                .padding(.bottom, 40)
                            
                            VStack(spacing: 16) {
                                Text("Live. Stock. Value.")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(Theme.accent)
                                    .multilineTextAlignment(.center)

                                Text("Manage your livestock assets like a share trading exchange. Real-time valuations, comprehensive reporting, and insights designed for primary producers.")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                            .padding(.bottom, 40)

                            featureTiles
                        }
                        .padding(.horizontal, 24)

                        Spacer()

                        // Primary CTA with centralized style
                        VStack(spacing: 16) {
                            Button {
                                HapticManager.tap()
                                // Debug: Show Terms & Privacy sheet after "Continue" on features page
                                showingTermsPrivacy = true
                            } label: {
                                Text("Continue")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(Theme.LandingButtonStyle())
                            .padding(.horizontal, 20)

                            Text("Powered by MLA Market Data")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.primaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .buttonStyle(.automatic) // cancel any parent buttonStyle override
                        .padding(.horizontal, 24)
                        .padding(.bottom, 60)
                    }
                }
                .offset(x: showFeaturesPage ? 0 : UIScreen.main.bounds.width)
                .animation(.spring(response: 0.55, dampingFraction: 0.9), value: showFeaturesPage)
            }
            
            // Debug: Landing page content
            if step == .landing {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        VStack(spacing: 16) {
                            Spacer()
                                .frame(height: 200)
                        }
                        .padding(.horizontal, 24)

                        Spacer()

                        // Primary CTA for landing
                        VStack(spacing: 16) {
                            Button {
                                HapticManager.tap()
                                
                                // Transition to features (user initiated)
                                withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                                    step = .features
                                }
                                
                                showFeaturesPage = false

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    showFeaturesPage = true
                                }
                            } label: {
                                Text("Get Started")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(Theme.LandingButtonStyle())
                            .padding(.horizontal, 20)

                            Text("Powered by MLA Market Data")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.primaryText)
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
        }
        .ignoresSafeArea(.all)
        .onAppear {
            // Debug: Start video playback when landing page appears
            if step == .landing && !UIAccessibility.isReduceMotionEnabled {
                // Small delay to ensure smooth transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    playVideo = true
                }
            }
        }
        .onChange(of: step) { _, newValue in
            // Debug: Stop video when transitioning to features page
            if newValue == .features {
                playVideo = false
            }
        }
        .onChange(of: hasAcceptedTerms) { oldValue, newValue in
            // Debug: After user accepts terms (from features page), transition to full-screen sign-in
            if newValue && step == .features {
                onboardingStep = .signIn
            }
        }
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
                .font(.callout.weight(.medium))
                .foregroundStyle(Theme.primaryText.opacity(0.9))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.9)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .padding(.horizontal, 0)
        .background(Theme.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

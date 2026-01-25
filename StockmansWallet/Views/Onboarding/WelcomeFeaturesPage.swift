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
    @State private var showHeaderText = false
    @State private var showTiles = false
    @State private var playVideo = false

    var body: some View {
        ZStack {
            // Debug: Video background on landing page, static image on features page
            if step == .landing && !UIAccessibility.isReduceMotionEnabled {
                // Debug: Animated video background with branding iron
                LandingVideoPlayer(
                    videoName: "LandingAnimation",
                    videoExtension: "mp4",
                    isPlaying: $playVideo
                )
            } else {
                // Debug: Static background image (features page or Reduce Motion)
                Image("landingBG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .blur(radius: step == .features ? 20 : 0)
            }
            
            // Debug: Dark brown overlay on features page for better text legibility
            if step == .features {
                Color(hex: "1A1412").opacity(0.8)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            
            // TEMPORARY: Dev skip buttons for Farmer/Advisor testing (DELETE BEFORE LAUNCH) ⚠️
            VStack {
                HStack(spacing: 12) {
                    Spacer()
                    
                    // Debug: Skip as Farmer - goes to farmer dashboard (no icon, stroke style)
                    Button(action: {
                        HapticManager.tap()
                        onSkipAsFarmer?()
                    }) {
                        Text("Farmer")
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryText.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .strokeBorder(Theme.secondaryText.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Debug: Skip as Advisor - goes to advisory dashboard (no icon, stroke style)
                    Button(action: {
                        HapticManager.tap()
                        onSkipAsAdvisor?()
                    }) {
                        Text("Advisor")
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryText.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .strokeBorder(Theme.secondaryText.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                }
                .padding(.top, 50)
                Spacer()
            }

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    VStack(spacing: 16) {
                        // Debug: Spacer to push content down on landing page
                        if step == .landing {
                            Spacer()
                                .frame(height: 200)
                        }
                        
                        if step == .features {
                            // Wallet logo
                            Image("wallet")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .padding(.bottom, 8)
                                .accessibilityLabel("Stockman's Wallet")
                            
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
                                // Debug: Show Terms & Privacy sheet after "Continue" on features page (Option 2)
                                showingTermsPrivacy = true
                            }
                        } label: {
                            Text(step == .landing ? "Get Started" : "Continue")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(Theme.LandingButtonStyle())
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

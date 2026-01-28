//
//  WelcomeFeaturesPage.swift
//  StockmansWallet
//
//  Coordinator: Landing page on top, features page underneath. Continue slides landing left to reveal features.
//

import SwiftUI

/// Local step for the welcome flow (landing → features). Distinct from OnboardingView.OnboardingStep.
private enum WelcomeStep {
    case landing
    case features
}

struct WelcomeFeaturesPage: View {
    @Binding var onboardingStep: OnboardingView.OnboardingStep
    @Binding var showingTermsPrivacy: Bool
    @Binding var hasAcceptedTerms: Bool

    var introComplete: Bool = true
    var onSkipAsFarmer: (() -> Void)? = nil
    var onSkipAsAdvisor: (() -> Void)? = nil

    @State private var step: WelcomeStep = .landing

    var body: some View {
        // iOS 26 HIG: Container respects safe areas; child views manage their own backgrounds
        GeometryReader { geo in
            ZStack {
                // 1. Features page underneath (always present; revealed when landing slides left)
                FeaturesPageView(
                    onContinue: {
                        showingTermsPrivacy = true
                    },
                    onBack: {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                            step = .landing
                        }
                    }
                )

                // 2. Landing page on top; animates off to the left when user taps Continue
                LandingPageView(
                    onContinue: {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                            step = .features
                        }
                    },
                    onSkipToDashboard: onSkipAsFarmer
                )
                .offset(x: step == .landing ? 0 : -geo.size.width)
                .animation(.spring(response: 0.55, dampingFraction: 0.9), value: step)
            }
        }
        .onChange(of: hasAcceptedTerms) { oldValue, newValue in
            if newValue && step == .features {
                onboardingStep = .signIn
            }
        }
    }
}

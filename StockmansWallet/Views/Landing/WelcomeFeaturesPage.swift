//
//  WelcomeFeaturesPage.swift
//  StockmansWallet
//
//  Card-based welcome flow: horizontal paging cards with fixed bottom CTA.
//

import SwiftUI

// MARK: - Card Pages
// Debug: Removed landing card - now shown as separate full-screen view before this
private enum WelcomeCardPage: Int, CaseIterable, Identifiable {
    case welcome
    case beta
    case feedback
    case terms

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome:
            return "Welcome to\nStockman's Wallet"
        case .beta:
            return "Early Access\nBeta Testing"
        case .feedback:
            return "Your Testing\nFeedback"
        case .terms:
            return "Terms, Conditions\n& Your Privacy"
        }
    }
}

struct WelcomeFeaturesPage: View {
    @Binding var onboardingStep: OnboardingView.OnboardingStep
    @Binding var hasAcceptedTerms: Bool

    var introComplete: Bool = true
    var onSkipAsFarmer: (() -> Void)? = nil

    @State private var currentPage: Int = 0
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var showingAPPs = false
    @State private var hasAcceptedTermsInCard = false

    var body: some View {
        ZStack {
            // Debug: Global background for all welcome cards.
            Theme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 16)

                TabView(selection: $currentPage) {
                    ForEach(WelcomeCardPage.allCases) { page in
                        welcomeCard(for: page)
                            .tag(page.rawValue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                .accessibilityLabel("Welcome onboarding pages")
                .onChange(of: currentPage) { _, newValue in
                    // Debug: Track page changes for onboarding analytics.
                    print("WelcomeFeaturesPage: Swiped to page \(newValue)")
                }

                Spacer(minLength: 0)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .onChange(of: hasAcceptedTerms) { _, newValue in
            if newValue {
                // Debug: Terms accepted - move into sign-in flow with smooth transition.
                withAnimation(.easeInOut(duration: 0.3)) {
                    onboardingStep = .signIn
                }
            }
        }
        .sheet(isPresented: $showingTerms) {
            TermsDetailView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyDetailView()
        }
        .sheet(isPresented: $showingAPPs) {
            APPsDetailView()
        }
    }

    // MARK: - Fixed Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 12) {
            // Debug: Page indicator dots for pagination feedback.
            HStack(spacing: 8) {
                ForEach(WelcomeCardPage.allCases) { page in
                    Circle()
                        .fill(page.rawValue == currentPage ? Theme.accentColor : Theme.secondaryText.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }
            }
            .padding(.top, 6)

            Button {
                HapticManager.tap()
                print("WelcomeFeaturesPage: Next tapped on page \(currentPage)")
                advanceToNextPage()
            } label: {
                Text(currentPage == WelcomeCardPage.terms.rawValue ? "Continue" : "Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(Theme.PrimaryButtonStyle())
            .disabled(isTermsPage && !hasAcceptedTermsInCard)
            .opacity(isTermsPage && !hasAcceptedTermsInCard ? 0.5 : 1.0)
            .padding(.horizontal, 24)

        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    private func advanceToNextPage() {
        let lastIndex = WelcomeCardPage.allCases.count - 1
        if currentPage < lastIndex {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                currentPage += 1
            }
        } else {
            // Debug: Accept terms on final card and continue onboarding.
            guard hasAcceptedTermsInCard else {
                HapticManager.error()
                return
            }
            HapticManager.success()
            hasAcceptedTerms = true
        }
    }

    // MARK: - Card Content
    // Debug: Apple-style card with generous padding for breathing room
    private func welcomeCard(for page: WelcomeCardPage) -> some View {
        OnboardingWelcomeCard {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch page {
                    case .welcome:
                        welcomeCardContent
                    case .beta:
                        betaCardContent
                    case .feedback:
                        feedbackCardContent
                    case .terms:
                        termsCardContent
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 32)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Page Sections
    private var welcomeCardContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            cardHeader(
                title: WelcomeCardPage.welcome.title,
                subtitle: "Stockman's Wallet helps you track livestock like a financial asset."
            )

            VStack(alignment: .center, spacing: 8) {
                Text("Not just head count. Real value.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.accentColor)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                KeyPointRow(icon: "checkmark.circle.fill", text: "Record herds in minutes")
                KeyPointRow(icon: "chart.line.uptrend.xyaxis", text: "See live value based on real market data")
                KeyPointRow(icon: "arrow.up.arrow.down.circle.fill", text: "Track changes over time as weights, numbers, and markets move")
                KeyPointRow(icon: "tray.full.fill", text: "Keep everything in one place instead of notebooks and spreadsheets")
            }

            Text("This version focuses on the core experience. It's about getting the foundations right.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            
            // Debug: Skip button for internal testing - allows quick dashboard access
            if let onSkipAsFarmer {
                Button {
                    print("WelcomeFeaturesPage: Skip to dashboard tapped")
                    HapticManager.tap()
                    onSkipAsFarmer()
                } label: {
                    Text("Skip to Dashboard")
                        .font(.caption)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Theme.Accent.quaternary))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
            }
        }
    }

    private var betaCardContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            cardHeader(
                title: WelcomeCardPage.beta.title,
                subtitle: "This is an early beta build for testing purposes only."
            )

            VStack(alignment: .leading, spacing: 20) {
                Text("This release is for")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)

                VStack(spacing: 16) {
                    KeyPointRow(icon: "sparkles", text: "Testing the overall experience")
                    KeyPointRow(icon: "rectangle.grid.2x2.fill", text: "Checking layouts and navigation")
                    KeyPointRow(icon: "bolt.fill", text: "Trying the core features")
                    KeyPointRow(icon: "ladybug.fill", text: "Finding bugs, errors, or things that feel confusing")
                }
            }

            VStack(alignment: .leading, spacing: 20) {
                Text("Limited features compared to the final product")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)

                VStack(spacing: 16) {
                    KeyPointRow(icon: "minus.circle.fill", text: "Some data may be placeholders or simplified")
                    KeyPointRow(icon: "arrow.triangle.2.circlepath.circle.fill", text: "Things may change or break as we improve the app")
                }
            }
        }
    }

    private var feedbackCardContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            cardHeader(
                title: WelcomeCardPage.feedback.title,
                subtitle: "Your feedback matters."
            )

            VStack(alignment: .leading, spacing: 20) {
                Text("If something feels off, slow, unclear, or broken, that's exactly what we want to know.")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.primaryText)
                    .lineSpacing(4)

                Text("Use the app as you normally would. Think like a stockman, not a tester.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.secondaryText)
                    .lineSpacing(3)
            }

            VStack(spacing: 16) {
                KeyPointRow(icon: "questionmark.circle.fill", text: "What would you expect to see here?")
                KeyPointRow(icon: "exclamationmark.circle.fill", text: "What feels missing?")
                KeyPointRow(icon: "clock.fill", text: "What would save you time in the paddock or the office?")
            }

            Text("Thanks for helping shape Stockman's Wallet.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }

    private var termsCardContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            cardHeader(
                title: WelcomeCardPage.terms.title,
                subtitle: "Please review and accept our terms and conditions to continue."
            )

            VStack(spacing: 16) {
                LegalDocumentRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    description: "Outlines the rules and regulations of using Stockman's Wallet.",
                    backgroundColor: Theme.secondaryBackground
                ) {
                    // Debug: Open Terms detail sheet.
                    HapticManager.tap()
                    showingTerms = true
                }

                LegalDocumentRow(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    description: "Explains how we collect, use, and protect your personal information.",
                    backgroundColor: Theme.secondaryBackground
                ) {
                    // Debug: Open Privacy detail sheet.
                    HapticManager.tap()
                    showingPrivacy = true
                }

                LegalDocumentRow(
                    icon: "building.columns.fill",
                    title: "Australian Privacy Principles",
                    description: "Our commitment to Australian privacy compliance standards.",
                    backgroundColor: Theme.secondaryBackground
                ) {
                    // Debug: Open APPs detail sheet.
                    HapticManager.tap()
                    showingAPPs = true
                }
            }

            Button {
                // Debug: Toggle acceptance to unlock Continue.
                HapticManager.tap()
                hasAcceptedTermsInCard.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: hasAcceptedTermsInCard ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(hasAcceptedTermsInCard ? Theme.accentColor : Theme.secondaryText)

                    Text("I agree to the Terms and Privacy policies")
                        .font(Theme.subheadline)
                        .foregroundStyle(Theme.primaryText)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("I agree to the Terms and Privacy policies")
            .accessibilityAddTraits(hasAcceptedTermsInCard ? [.isSelected] : [])

            Text("By accepting our Terms of Service, Privacy Policy, and acknowledging our compliance with Australian Privacy Principles.")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }

    private var isTermsPage: Bool {
        currentPage == WelcomeCardPage.terms.rawValue
    }

    // Debug: Apple-style card header with generous spacing and clear hierarchy
    private func cardHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text(subtitle)
                .font(.system(size: 17))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Card Container
private struct OnboardingWelcomeCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(Theme.borderColor.opacity(0.6), lineWidth: 1)
                )

            // Debug: Scrollable content for long copy on smaller devices.
            content
        }
        .shadow(color: Theme.background.opacity(0.4), radius: 10, x: 0, y: 8)
    }
}

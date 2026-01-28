//
//  FeaturesPageView.swift
//  StockmansWallet
//
//  Features intro: logo, value prop, feature tiles, Continue. Shown when landing slides left.
//

import SwiftUI

struct FeaturesPageView: View {
    /// Called when user taps "Continue" – coordinator shows Terms & Privacy sheet.
    var onContinue: () -> Void
    /// Called when user taps back (chevron) – coordinator slides landing back in from the left.
    var onBack: () -> Void

    // iOS 26 HIG: 44pt minimum touch target for controls
    private let controlSize: CGFloat = 44

    var body: some View {
        ZStack(alignment: .top) {
            // Background extends behind status bar
            Theme.backgroundColor
                .ignoresSafeArea()
                .accessibilityHidden(true)

            // Main content (centered vertically)
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
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

                VStack(spacing: 16) {
                    Button {
                        HapticManager.tap()
                        onContinue()
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
                .buttonStyle(.automatic)
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }

            // Back button overlay - pinned at top, respects safe area automatically
            VStack(spacing: 0) {
                HStack {
                    Button {
                        HapticManager.tap()
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.primaryText)
                            .frame(width: controlSize, height: controlSize)
                            .contentShape(Circle())
                            .background(
                                // iOS 26+ uses glassEffect, fallback to blur+opacity for iOS 17-25
                                Group {
                                    if #available(iOS 26.0, *) {
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: controlSize, height: controlSize)
                                            .glassEffect(.regular.interactive(), in: Circle())
                                    } else {
                                        // Fallback: Blur + semi-transparent background for iOS 17-25
                                        Circle()
                                            .fill(Color.white.opacity(0.15))
                                            .frame(width: controlSize, height: controlSize)
                                            .background(
                                                Circle()
                                                    .fill(.ultraThinMaterial)
                                                    .frame(width: controlSize, height: controlSize)
                                            )
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Go back")
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Feature Tile (used only on features page)
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

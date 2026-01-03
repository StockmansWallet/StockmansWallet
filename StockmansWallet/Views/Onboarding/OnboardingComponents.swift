//
//  OnboardingComponents.swift
//  StockmansWallet
//
//  Shared components for onboarding pages
//

import SwiftUI

// MARK: - Onboarding Page Template
// iOS 26 HIG-aligned:
// - Content respects top safe area (parent must not ignore top safe area for content).
// - Header is in normal layout flow: back control (circular glass chevron), centered title/subtitle.
// - No overlays or manual safe-area math.
// - Footer actions/progress pinned using safeAreaInset.
struct OnboardingPageTemplate<Content: View>: View {
    let title: String
    let subtitle: String
    @Binding var currentPage: Int
    let nextPage: Int
    var showBack: Bool = true
    var isValid: Bool = true // Default to true for optional pages
    var isLastPage: Bool = false // Set to true for the final page
    var onComplete: (() -> Void)? = nil // Optional completion handler for last page
    @ViewBuilder let content: Content
    
    // Metrics per HIG
    private let controlSize: CGFloat = Theme.minimumTouchTarget // 44
    private let horizontalPadding: CGFloat = 20
    private let headerSpacing: CGFloat = 12
    private let titleSpacing: CGFloat = 8
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: headerSpacing) {
                HStack {
                    if showBack && currentPage > 0 {
                        Button(action: {
                            HapticManager.tap()
                            withAnimation {
                                currentPage = max(0, currentPage - 1)
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.primaryText)
                                .frame(width: controlSize, height: controlSize)
                                .contentShape(Circle())
                                .background(
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: controlSize, height: controlSize)
                                        .glassEffect(.regular.interactive(), in: Circle())
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Go back to previous page")
                    } else {
                        Color.clear
                            .frame(width: controlSize, height: controlSize)
                            .accessibilityHidden(true)
                    }
                    
                    Spacer()
                    
                    // Right-side placeholder keeps title centered
                    Color.clear
                        .frame(width: controlSize, height: controlSize)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, horizontalPadding)
                
                VStack(spacing: titleSpacing) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.primaryText)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 16)
            }
            .padding(.top, 12) // Comfortable default; safe area is respected by default
            
            // Scrollable content
            ScrollView {
                content
                    .padding(.top, 8)
                    .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundGradient) // Background can be extended by parent if needed
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Footer section - pinned to bottom using safeAreaInset
            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(index <= currentPage ? Theme.accent : Theme.secondaryText.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 16)
                .accessibilityLabel("Page \(currentPage + 1) of 6")
                
                // Action buttons
                if isLastPage, let onComplete = onComplete {
                    VStack(spacing: 16) {
                        Button(action: {
                            HapticManager.tap()
                            onComplete()
                        }) {
                            Text("Complete Setup")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(Theme.PrimaryButtonStyle())
                        .accessibilityLabel("Complete onboarding setup")
                        
                        Button(action: {
                            HapticManager.tap()
                            onComplete()
                        }) {
                            Text("Skip for Now")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(Theme.SecondaryButtonStyle())
                        .accessibilityLabel("Skip and complete setup")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                } else {
                    Button(action: {
                        HapticManager.tap()
                        guard isValid else {
                            HapticManager.error()
                            return
                        }
                        withAnimation {
                            currentPage = nextPage
                        }
                    }) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .disabled(!isValid)
                    .opacity(isValid ? 1.0 : 0.6)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .accessibilityLabel("Continue to next page")
                    .accessibilityHint(isValid ? "" : "Please complete all required fields")
                }
            }
            .background(Theme.backgroundGradient)
        }
    }
}

// MARK: - Text Field Styles
struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(Theme.primaryText)
    }
}

struct SignInTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(Theme.primaryText)
    }
}

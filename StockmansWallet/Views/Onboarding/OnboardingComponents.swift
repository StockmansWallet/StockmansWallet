//
//  OnboardingComponents.swift
//  StockmansWallet
//
//  Shared components for onboarding pages
//

import SwiftUI

// MARK: - Onboarding Page Template
// Debug: Updated to support validation - Next button disabled until form is valid
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Main content VStack - fills entire GeometryReader
                VStack(spacing: 0) {
                    // Debug: Header section with iOS 26 HIG standard title positioning and sizing
                    // iOS 26 HIG: Page titles use 17pt with medium weight (not large title)
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 17, weight: .medium)) // iOS 26 HIG: 17pt medium weight for page titles
                            .foregroundStyle(Theme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text(subtitle)
                            .font(.system(size: 15, weight: .regular)) // iOS 26 HIG: 15pt regular for secondary text
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    // iOS 26 HIG: Standard spacing from safe area top (16pt) + back button height (44pt) + spacing (8pt)
                    .padding(.top, showBack && currentPage > 0 ? geometry.safeAreaInsets.top + 68 : geometry.safeAreaInsets.top + 16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                
                    // Debug: Scrollable content area - takes remaining flexible space
                    ScrollView {
                        content
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                    }
                    .frame(minHeight: 0, maxHeight: .infinity) // Allow ScrollView to take available space between header and footer
                    
                    // Debug: Bottom section with progress dots and buttons (fixed at bottom)
                    VStack(spacing: 0) {
                        // Debug: Page indicator showing progress (iOS 26 HIG: clear visual feedback at bottom)
                        // Updated to show 6 pages (Identity, Persona, Security, Property, Market, Financial)
                        // iOS 26 HIG: Progress indicators should be at the bottom of the screen, above buttons
                        if currentPage >= 0 {
                            HStack(spacing: 8) {
                                ForEach(0..<6, id: \.self) { index in
                                    Circle()
                                        .fill(index <= currentPage ? Theme.accent : Theme.secondaryText.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                        .accessibilityHidden(true)
                                }
                            }
                            .padding(.bottom, 16)
                            .accessibilityLabel("Page \(currentPage + 1) of 6")
                        }
                    
                        // Debug: Action buttons with validation enforcement
                        if isLastPage, let onComplete = onComplete {
                            // Last page - show completion buttons
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
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                        } else {
                            // Regular page - show Next button only (back button is in navigation bar)
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
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                            .accessibilityLabel("Continue to next page")
                            .accessibilityHint(isValid ? "" : "Please complete all required fields")
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // VStack fills entire GeometryReader
            
                // Debug: Navigation bar with back button (iOS 26 HIG: proper touch target 44x44pt minimum)
                // Positioned at top left using ZStack overlay, respecting safe area
                if showBack && currentPage > 0 {
                    HStack {
                        Button(action: {
                            HapticManager.tap()
                            withAnimation {
                                currentPage = max(0, currentPage - 1)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium)) // iOS 26 HIG: medium weight for navigation icons
                                Text("Back")
                                    .font(.system(size: 17, weight: .regular)) // iOS 26 HIG: 17pt regular for navigation text
                            }
                            .foregroundStyle(Theme.primaryText)
                            .frame(width: Theme.minimumTouchTarget, height: Theme.minimumTouchTarget) // iOS 26 HIG: 44x44pt minimum touch target
                            .contentShape(Rectangle())
                            .background(
                                // Debug: Liquid glass effect using material with fallback
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Theme.glassMaterial)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(Theme.inputFieldBackground)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 20)
                        .padding(.top, geometry.safeAreaInsets.top + 8) // Position below status bar
                        .accessibilityLabel("Go back to previous page")
                        Spacer()
                    }
                }
        }
        }
        .background(
            Theme.backgroundGradient
                .ignoresSafeArea()
        )
    }
}

// MARK: - Text Field Styles
// Debug: Updated to use Theme.inputFieldBackground for proper field backgrounds
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


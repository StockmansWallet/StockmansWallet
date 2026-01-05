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
    var totalPages: Int = 5 // Debug: Total pages in flow (5 pages for both farmer and advisory paths)
    var onComplete: (() -> Void)? = nil // Optional completion handler for last page
    @ViewBuilder let content: Content
    
    // Metrics per HIG
    private let controlSize: CGFloat = Theme.minimumTouchTarget // 44
    private let horizontalPadding: CGFloat = 20
    private let headerSpacing: CGFloat = 12
    private let titleSpacing: CGFloat = 8
    
    var body: some View {
        // Debug: iOS 26 HIG - Content scrolls under back button (standard iOS pattern)
        ZStack(alignment: .top) {
            // Scrollable content (extends to top edge, scrolls under back button)
            ScrollView {
                VStack(spacing: 0) {
                    // Header (title and subtitle)
                    VStack(spacing: 12) {
                        Text(title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.primaryText)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text(subtitle)
                            .font(Theme.body)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 32)
                    .padding(.top, 80) // Debug: Top padding to account for back button area
                    
                    // Page content
                    content
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                }
            }
            .scrollDismissesKeyboard(.interactively) // Debug: iOS 16+ - Interactive keyboard dismissal on scroll
            
            // Back button overlay - pinned at top (floats above content)
            VStack(spacing: 0) {
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
                    
                    // Right-side placeholder keeps spacing consistent
                    Color.clear
                        .frame(width: controlSize, height: controlSize)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(
                    // Debug: Subtle gradient fade for back button area (content scrolls under)
                    LinearGradient(
                        colors: [
                            Theme.backgroundColor.opacity(0.95),
                            Theme.backgroundColor.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                )
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundGradient) // Background can be extended by parent if needed
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Footer section - pinned to bottom using safeAreaInset
            VStack(spacing: 0) {
                // Debug: Dynamic progress dots based on total pages in flow
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index <= currentPage ? Theme.accent : Theme.secondaryText.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 16)
                .accessibilityLabel("Page \(currentPage + 1) of \(totalPages)")
                
                // Action buttons
                if isLastPage, let onComplete = onComplete {
                    Button(action: {
                        HapticManager.tap()
                        onComplete()
                    }) {
                        Text("Complete Setup")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .accessibilityLabel("Complete onboarding setup")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                } else {
                    // Debug: Removed opacity modifier - disabled state provides sufficient visual feedback
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .accessibilityLabel("Continue to next page")
                    .accessibilityHint(isValid ? "" : "Please complete all required fields")
                }
            }
            // Debug: Removed background to prevent visible line at bottom (background already applied to main view)
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

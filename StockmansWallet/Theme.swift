//
//  Theme.swift
//  StockmansWallet
//
//  Design System: Centralized theming for colors, typography, spacing, and components.
//  Follows Apple Human Interface Guidelines and supports Dynamic Type, accessibility,
//  and dark mode (via Asset Catalog).
//

import SwiftUI

// MARK: - Theme

/// Single source of truth for the app's visual design system.
/// Use semantic color names from the Asset Catalog for automatic dark mode support.
enum Theme {
    
    // MARK: - Semantic Colors (Asset Catalog)
    
    /// Primary background color. Use for main screens.
    static let background = Color("Background")
    
    /// Primary text color. Use for headings and important content.
    static let primaryText = Color("PrimaryText")
    
    /// Secondary text color. Use for subtitles and less prominent content.
    static let secondaryText = Color("SecondaryText")
    
    /// Accent color for interactive elements and highlights.
    static let accent = Color("AccentColor")
    
    /// Destructive action color. Use for delete/remove actions.
    static let destructive = Color("Destructive")
    
    // MARK: - Derived Colors
    
    /// Subtle background for cards and containers.
    static let cardBackground = primaryText.opacity(0.05)
    
    /// Subtle background for input fields.
    static let inputFieldBackground = primaryText.opacity(0.05)
    
    /// Separator and border color.
    static let separator = primaryText.opacity(0.15)
    
    // MARK: - Change Indicator Colors
    
    /// Positive change text color (gains, increases).
    static let positiveChange = Color(hex: "6B8E23")
    
    /// Positive change background for pills/badges.
    static let positiveChangeBg = Color(hex: "E8F5E9")
    
    /// Negative change text color (losses, decreases).
    static let negativeChange = Color(hex: "D32F2F")
    
    /// Negative change background for pills/badges.
    static let negativeChangeBg = Color(hex: "FFEBEE")
    
    // MARK: - Surface Colors
    
    /// Main background color (code-based fallback).
    static let backgroundColor = Color(hex: "E5D3BB")
    
    /// Background when no image is selected.
    static let noBackgroundColor = Color(hex: "D5C9B5")
    
    /// Sheet and modal background.
    static let sheetBackground = Color(hex: "EDE7DC")
    
    /// Background image opacity for parallax effects.
    static let backgroundImageOpacity: CGFloat = 0.4
    
    // MARK: - Typography
    
    /// All fonts use SF Rounded with semantic text styles for Dynamic Type support.
    static let largeTitle = Font.system(.largeTitle, design: .rounded)
    static let title = Font.system(.title, design: .rounded).weight(.semibold)
    static let title2 = Font.system(.title2, design: .rounded).weight(.semibold)
    static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
    static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let callout = Font.system(.callout, design: .rounded)
    static let subheadline = Font.system(.subheadline, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded)
    
    // MARK: - Spacing & Layout
    
    /// Standard corner radius for cards and UI components.
    static let cornerRadius: CGFloat = 16
    
    /// Larger corner radius for sheets and modals.
    static let sheetCornerRadius: CGFloat = 32
    
    /// Standard internal padding for cards.
    static let cardPadding: CGFloat = 20
    
    /// Spacing between sections.
    static let sectionSpacing: CGFloat = 24
    
    /// Standard button height (exceeds 44pt minimum touch target).
    static let buttonHeight: CGFloat = 52
    
    /// Minimum touch target per Apple HIG.
    static let minimumTouchTarget: CGFloat = 44
    
    // MARK: - Materials
    
    /// Adaptive glass material respecting Reduce Transparency.
    static var glassMaterial: Material {
        UIAccessibility.isReduceTransparencyEnabled ? .thickMaterial : .ultraThinMaterial
    }
    
    // MARK: - Background Gradient
    
    /// Radial gradient background for primary screens.
    @ViewBuilder
    static var backgroundGradient: some View {
        RadialGradient(
            colors: [accent.opacity(0.08), backgroundColor],
            center: .top,
            startRadius: 0,
            endRadius: 500
        )
        .ignoresSafeArea()
    }
}

// MARK: - Accessibility Helpers

extension Theme {
    
    /// Check if user prefers larger accessibility text sizes.
    static var prefersLargeText: Bool {
        UIApplication.shared.preferredContentSizeCategory >= .accessibilityMedium
    }
    
    /// Check if high contrast mode is enabled.
    static var prefersHighContrast: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    /// Check if VoiceOver is running.
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    /// Check if Reduce Motion is enabled.
    static var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Returns 0 duration if Reduce Motion is enabled, otherwise the specified duration.
    static func animationDuration(_ duration: Double) -> Double {
        prefersReducedMotion ? 0 : duration
    }
}

// MARK: - Button Styles

extension Theme {
    
    /// Primary call-to-action button. Solid background with contrasting text.
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .foregroundStyle(Theme.background)
                .background(Theme.primaryText.opacity(configuration.isPressed ? 0.85 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    /// Secondary button with outline style.
    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .foregroundStyle(Theme.primaryText)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(Theme.primaryText.opacity(configuration.isPressed ? 0.6 : 1.0), lineWidth: 1.5)
                )
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    /// Row-style button for list items and selectable rows.
    struct RowButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: Theme.buttonHeight)
                .padding(.horizontal, 16)
                .background(Theme.cardBackground.opacity(configuration.isPressed ? 1.6 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    /// Destructive action button. Use for delete/remove with confirmation.
    struct DestructiveButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .foregroundStyle(.white)
                .background(Theme.destructive.opacity(configuration.isPressed ? 0.85 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    /// Alias for PrimaryButtonStyle. Use on landing/onboarding screens.
    typealias LandingButtonStyle = PrimaryButtonStyle
}

// MARK: - View Modifiers

/// Standard card style with background and subtle border.
struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.5), lineWidth: 1)
            )
    }
}

/// Background image modifier for screens with optional background images.
struct BackgroundImageModifier: ViewModifier {
    let imageName: String?
    
    func body(content: Content) -> some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
                .accessibilityHidden(true)
            
            if let imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
            
            content
        }
    }
}

/// Scroll-based blur effect that respects Reduce Motion.
struct ScrollBlurModifier: ViewModifier {
    func body(content: Content) -> some View {
        if Theme.prefersReducedMotion || UIAccessibility.isReduceTransparencyEnabled {
            content
        } else {
            content
                .visualEffect { view, proxy in
                    let scrollOffset = proxy.bounds(of: .scrollView)?.minY ?? 0.0
                    let blurAmount = max(0.0, min(20.0, abs(scrollOffset) / 3.0))
                    let opacityAmount = max(0.7, min(1.0, 1.0 - abs(scrollOffset) / 200.0))
                    return view
                        .blur(radius: blurAmount)
                        .opacity(opacityAmount)
                }
        }
    }
}

/// Standard input field text style.
struct InputFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: Theme.minimumTouchTarget)
            .background(Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(Theme.primaryText)
    }
}

// MARK: - View Extensions

extension View {
    
    /// Apply standard card styling with background and border.
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
    
    /// Apply background image with fallback color.
    func backgroundImage(_ imageName: String?) -> some View {
        modifier(BackgroundImageModifier(imageName: imageName))
    }
    
    /// Apply scroll-based blur effect.
    func scrollBlurEffect() -> some View {
        modifier(ScrollBlurModifier())
    }
    
    /// Apply standard input field styling.
    func inputFieldStyle() -> some View {
        textFieldStyle(InputFieldStyle())
    }
    
    /// Ensure minimum touch target size for accessibility.
    func accessibleTapTarget() -> some View {
        frame(minWidth: Theme.minimumTouchTarget, minHeight: Theme.minimumTouchTarget)
    }
    
    /// Apply animation only if Reduce Motion is disabled.
    @ViewBuilder
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if Theme.prefersReducedMotion {
            self
        } else {
            self.animation(animation, value: value)
        }
    }
}

// MARK: - Color Extension

extension Color {
    
    /// Initialize Color from hex string. Supports RGB (3), RRGGBB (6), and AARRGGBB (8) formats.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RRGGBB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // AARRGGBB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Haptic Feedback

/// Centralized haptic feedback respecting accessibility settings.
enum HapticManager {
    
    private static let impact = UIImpactFeedbackGenerator(style: .light)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()
    
    /// Light haptic for button taps.
    static func tap() {
        guard !Theme.prefersReducedMotion else { return }
        impact.impactOccurred()
    }
    
    /// Success haptic for completed actions.
    static func success() {
        guard !Theme.prefersReducedMotion else { return }
        notification.notificationOccurred(.success)
    }
    
    /// Error haptic for failed actions.
    static func error() {
        guard !Theme.prefersReducedMotion else { return }
        notification.notificationOccurred(.error)
    }
    
    /// Warning haptic for caution states.
    static func warning() {
        guard !Theme.prefersReducedMotion else { return }
        notification.notificationOccurred(.warning)
    }
    
    /// Selection haptic for picker changes.
    static func selectionChanged() {
        guard !Theme.prefersReducedMotion else { return }
        selection.selectionChanged()
    }
}

//
//  Theme.swift
//  StockmansWallet
//
//  Design System: Single color theme with two surface contexts.
//  Dark Surface: Main app pages (Dashboard, Portfolio, Market)
//  Light Surface: Sheets, modals, and landing pages
//

import SwiftUI

// MARK: - Theme

/// Single source of truth for the app's visual design system.
enum Theme {
    
    // MARK: - Color Primitives (from Figma Design Tokens)
    
    /// Brown scale - core palette
    enum Brown {
        static let _10 = Color(hex: "E2D9CF")  // Light cream
        static let _20 = Color(hex: "ECE5DF")  // Lighter cream
        static let _30 = Color(hex: "D9CCBF")
        static let _40 = Color(hex: "C6B29F")
        static let _50 = Color(hex: "B39980")  // Medium brown
        static let _60 = Color(hex: "9F7F60")
        static let _70 = Color(hex: "80664C")
        static let _80 = Color(hex: "604C39")  // Dark brown text
        static let _90 = Color(hex: "403326")
        static let _100 = Color(hex: "201A13") // Darkest brown (main bg)
    }
    
    /// Brand orange scale
    enum BrandOrange {
        static let _20 = Color(hex: "FFE5CC")
        static let _30 = Color(hex: "FFCC99")
        static let _40 = Color(hex: "E8B27D")
        static let _50 = Color(hex: "E09952")
        static let _60 = Color(hex: "D98026")  // Primary accent
        static let _70 = Color(hex: "AD661F")
        static let _80 = Color(hex: "824D17")
    }
    
    // MARK: - Semantic Colors
    
    /// Primary brand accent color.
    static let accent = BrandOrange._60
    
    /// Destructive action color.
    static let destructive = Color(hex: "C36F6F")
    
    /// Success color.
    static let success = Color(hex: "9CA659")
    
    /// Warning color.
    static let warning = Color(hex: "A68C59")
    
    /// Info color.
    static let info = Color(hex: "6FA7C3")
    
    // MARK: - Dark Theme (Main App: Dashboard, Portfolio, Market, Landing)
    
    /// Dark Theme: Dark brown background with cream text. Used for main app pages.
    enum DarkTheme {
        /// Main app background (very dark brown).
        static let background = Brown._100
        
        /// Secondary background for cards/sections.
        static let backgroundSecondary = Brown._90
        
        /// Primary text on dark surface (cream).
        static let primaryText = Brown._10
        
        /// Secondary text on dark surface.
        static let secondaryText = Brown._50
        
        /// Tertiary/disabled text.
        static let tertiaryText = Brown._60
        
        /// Card background.
        static let cardBackground = Brown._10.opacity(0.08)
        
        /// Input field background.
        static let inputBackground = Brown._10.opacity(0.10)
        
        /// Separator and border color.
        static let separator = Brown._10.opacity(0.15)
        
        /// Border color.
        static let border = Brown._90
    }
    
    // MARK: - Light Theme (Sheets, Modals, Features Page)
    
    /// Light Theme: Cream background with dark brown text. Used for sheets and modals.
    enum LightTheme {
        /// Sheet/modal background (cream).
        static let background = Brown._10
        
        /// Secondary background.
        static let backgroundSecondary = Brown._20
        
        /// Primary text on light surface (dark brown).
        static let primaryText = Brown._80
        
        /// Secondary text on light surface.
        static let secondaryText = Brown._60
        
        /// Tertiary/disabled text.
        static let tertiaryText = Brown._50
        
        /// Card background.
        static let cardBackground = Brown._80.opacity(0.05)
        
        /// Input field background.
        static let inputBackground = Brown._80.opacity(0.08)
        
        /// Separator and border color.
        static let separator = Brown._80.opacity(0.12)
        
        /// Border color.
        static let border = Brown._30
    }
    
    // MARK: - Legacy Semantic Colors (defaults to Dark Theme)
    
    static let background = DarkTheme.background
    static let primaryText = DarkTheme.primaryText
    static let secondaryText = DarkTheme.secondaryText
    static let cardBackground = DarkTheme.cardBackground
    static let inputFieldBackground = DarkTheme.inputBackground
    static let separator = DarkTheme.separator
    
    // MARK: - Surface Colors
    
    static let backgroundColor = DarkTheme.background
    static let noBackgroundColor = Brown._90
    static let sheetBackground = LightTheme.background
    
    /// Background image opacity for parallax effects.
    static let backgroundImageOpacity: CGFloat = 0.4
    
    // MARK: - Status Colors (Solid backgrounds - not transparent)
    
    static let positiveChange = success
    static let positiveChangeBg = Color(hex: "2F3526")  // Solid dark green-brown
    static let negativeChange = destructive
    static let negativeChangeBg = Color(hex: "3D2828")  // Solid dark red-brown
    
    // MARK: - Typography
    
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
    
    static let cornerRadius: CGFloat = 16
    static let sheetCornerRadius: CGFloat = 32
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let buttonHeight: CGFloat = 52
    static let minimumTouchTarget: CGFloat = 44
    
    // MARK: - Materials
    
    static var glassMaterial: Material {
        UIAccessibility.isReduceTransparencyEnabled ? .thickMaterial : .ultraThinMaterial
    }
    
    // MARK: - Background (Solid)
    
    @ViewBuilder
    static var backgroundGradient: some View {
        DarkTheme.background.ignoresSafeArea()
    }
}

// MARK: - Accessibility Helpers

extension Theme {
    static var prefersLargeText: Bool {
        UIApplication.shared.preferredContentSizeCategory >= .accessibilityMedium
    }
    
    static var prefersHighContrast: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    static var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    static func animationDuration(_ duration: Double) -> Double {
        prefersReducedMotion ? 0 : duration
    }
}

// MARK: - Button Styles

extension Theme {
    
    /// Primary button for dark theme. Cream background, dark text.
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .foregroundStyle(Theme.Brown._100)
                .background(Theme.Brown._10.opacity(configuration.isPressed ? 0.85 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    /// Dark brown button. Used on Landing page and Features page. Dark brown bg, cream text.
    struct LandingButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .foregroundStyle(Theme.Brown._10)
                .background(Theme.Brown._80.opacity(configuration.isPressed ? 0.7 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    /// Accent orange button. Used on sheets (Terms & Privacy). Orange bg, dark text.
    struct AccentButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .foregroundStyle(Theme.Brown._10)
                .background(Theme.accent.opacity(configuration.isPressed ? 0.85 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    /// Secondary button with outline.
    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .foregroundStyle(Theme.DarkTheme.primaryText)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(Theme.DarkTheme.primaryText.opacity(configuration.isPressed ? 0.6 : 1.0), lineWidth: 1.5)
                )
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    /// Row button for list items.
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
    
    /// Destructive button.
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
}

// MARK: - View Modifiers

struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Theme.separator, lineWidth: 1)
            )
    }
}

struct DarkBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Theme.DarkTheme.background.ignoresSafeArea()
            content
        }
    }
}

struct LightBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Theme.LightTheme.background.ignoresSafeArea()
            content
        }
    }
}

struct BackgroundImageModifier: ViewModifier {
    let imageName: String?
    
    func body(content: Content) -> some View {
        ZStack {
            Theme.DarkTheme.background.ignoresSafeArea()
            
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
                    return view.blur(radius: blurAmount).opacity(opacityAmount)
                }
        }
    }
}

struct InputFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: Theme.minimumTouchTarget)
            .background(Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(Theme.DarkTheme.primaryText)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View { modifier(CardStyleModifier()) }
    func darkBackground() -> some View { modifier(DarkBackgroundModifier()) }
    func lightBackground() -> some View { modifier(LightBackgroundModifier()) }
    func backgroundImage(_ imageName: String?) -> some View { modifier(BackgroundImageModifier(imageName: imageName)) }
    func scrollBlurEffect() -> some View { modifier(ScrollBlurModifier()) }
    func inputFieldStyle() -> some View { textFieldStyle(InputFieldStyle()) }
    func accessibleTapTarget() -> some View { frame(minWidth: Theme.minimumTouchTarget, minHeight: Theme.minimumTouchTarget) }
    
    @ViewBuilder
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if Theme.prefersReducedMotion { self } else { self.animation(animation, value: value) }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Haptic Feedback

enum HapticManager {
    private static let impact = UIImpactFeedbackGenerator(style: .light)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()
    
    static func tap() {
        guard !Theme.prefersReducedMotion else { return }
        impact.impactOccurred()
    }
    
    static func success() {
        guard !Theme.prefersReducedMotion else { return }
        notification.notificationOccurred(.success)
    }
    
    static func error() {
        guard !Theme.prefersReducedMotion else { return }
        notification.notificationOccurred(.error)
    }
    
    static func warning() {
        guard !Theme.prefersReducedMotion else { return }
        notification.notificationOccurred(.warning)
    }
    
    static func selectionChanged() {
        guard !Theme.prefersReducedMotion else { return }
        selection.selectionChanged()
    }
}

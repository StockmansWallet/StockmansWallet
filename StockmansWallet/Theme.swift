//
//  Theme.swift
//  StockmansWallet
//
//  Design System following Apple Human Interface Guidelines
//  Color system optimized for dark mode livestock management app
//

import SwiftUI

// MARK: - Theme

/// Single source of truth for the app's visual design system.
/// Follows Apple HIG principles: https://developer.apple.com/design/human-interface-guidelines/color
enum Theme {
    
    // MARK: - Color Primitives (Design Tokens)
    
    /// Accent color scale - Used for interactive elements and brand identity
    enum Accent {
        static let primaryLight = Color(hex: "F3B887")
        static let primary = Color(hex: "D07321")
        static let secondary = Color(hex: "9A5518")
        static let tertiary = Color(hex: "844915")
        static let quaternary = Color(hex: "6E3D11")
        static let quinary = Color(hex: "4F2F12")
    }
    
    /// Label colors - Used for text content following Apple HIG
    enum Label {
        static let primary = Color(hex: "B8AD9D")
        static let secondary = Color(hex: "7C6F5D")
        static let tertiary = Color(hex: "5E5142")
        static let quaternary = Color(hex: "4A3C2D")
    }
    
    /// Background colors - Used for surfaces and containers
    enum Background {
        static let primary = Color(hex: "211A12")
        static let secondary = Color(hex: "271F16")
        static let tertiary = Color(hex: "2D241A")
        static let quaternary = Color(hex: "3A2F23")
    }
    
    // MARK: - Semantic Colors (Following Apple HIG naming)
    
    /// Primary accent color for interactive elements, buttons, and highlights.
    static let accentColor = Accent.primary
    
    /// Destructive/Error colors.
    static let destructive = Color(hex: "7E2D1C")
    static let destructiveLight = Color(hex: "E59781")
    
    /// Success colors.
    static let success = Color(hex: "384224")
    static let successLight = Color(hex: "BAC99C")
    
    /// Warning/Alert colors.
    static let warning = Color(hex: "D4A944")
    static let warningLight = Color(hex: "F3E8C8")
    
    /// Informational colors.
    static let info = Color(hex: "5B7C8D")
    static let infoLight = Color(hex: "D3DDE2")
    
    // MARK: - System Colors (Apple HIG semantic naming)
    
    /// Primary background color for main app surfaces.
    static let background = Background.primary
    
    /// Secondary background color for grouped content and cards.
    static let secondaryBackground = Background.secondary

    /// Debug: Header background for dashboard cards.
    static let dashboardHeaderBackground = Color(hex: "2A2117")

    /// Debug: Icon background for dashboard card title bars.
    static let dashboardIconBackground = Background.quaternary
    
    /// Tertiary background color for nested grouping.
    static let tertiaryBackground = Background.tertiary
    
    /// Primary text color for main content.
    static let primaryText = Label.primary
    
    /// Secondary text color for supporting content.
    static let secondaryText = Label.secondary
    
    /// Tertiary text color for subtle content.
    static let tertiaryText = Label.tertiary
    
    /// Quaternary text color for disabled states.
    static let quaternaryText = Label.quaternary
    
    /// Card background - solid color for better visibility (Apple HIG).
    static let cardBackground = Background.secondary
    
    /// Input field background.
    static let inputFieldBackground = Label.primary.opacity(0.15)
    
    /// Separator line color.
    static let separator = Label.primary.opacity(0.15)
    
    /// Border color for outlined elements.
    static let borderColor = Background.secondary
    
    /// Sheet and modal presentation background.
    static let sheetBackground = background
    
    /// Background image opacity for parallax effects.
    static let backgroundImageOpacity: CGFloat = 0.4
    
    // MARK: - Status Colors
    
    /// Positive change indicator color.
    static let positiveChange = successLight
    
    /// Positive change background color.
    static let positiveChangeBackground = success
    
    /// Negative change indicator color.
    static let negativeChange = destructiveLight
    
    /// Negative change background color.
    static let negativeChangeBackground = destructive
    
    // MARK: - Typography (Apple HIG Dynamic Type)
    
    /// Large title style for prominent headings.
    static let largeTitle = Font.system(.largeTitle, design: .rounded)
    
    /// Title style for primary section headers.
    static let title = Font.system(.title, design: .rounded).weight(.semibold)
    
    /// Title 2 style for secondary section headers.
    static let title2 = Font.system(.title2, design: .rounded).weight(.semibold)
    
    /// Title 3 style for tertiary section headers.
    static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
    
    /// Headline style for emphasized content.
    static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
    
    /// Body style for primary content.
    static let body = Font.system(.body, design: .rounded)
    
    /// Callout style for secondary content.
    static let callout = Font.system(.callout, design: .rounded)
    
    /// Subheadline style for supporting content.
    static let subheadline = Font.system(.subheadline, design: .rounded)
    
    /// Caption style for metadata and timestamps.
    static let caption = Font.system(.caption, design: .rounded)
    
    // MARK: - Spacing & Layout (Apple HIG Standards)
    
    /// Standard corner radius for cards and buttons.
    static let cornerRadius: CGFloat = 16
    
    /// Corner radius for sheets and modal presentations.
    static let sheetCornerRadius: CGFloat = 32
    
    /// Internal padding for cards and containers.
    static let cardPadding: CGFloat = 20

    /// Debug: Tighter padding for dashboard content cards (matches mockups).
    static let dashboardCardPadding: CGFloat = 12

    // MARK: - Dashboard Accent Colors (Nature/Farm Tone)
    /// Debug: Per-card accent colors for dashboard title bar icons.
    static let dashboardPerformanceAccent = Color(hex: "D1843B") // Warm amber
    static let dashboardMarketAccent = Color(hex: "7FA76A") // Pasture green
    static let dashboardDynamicsAccent = Color(hex: "C36B5A") // Rustic clay
    static let dashboardCompositionAccent = Color(hex: "6E8E9D") // Muted blue/teal
    
    /// Spacing between major sections.
    static let sectionSpacing: CGFloat = 24
    
    /// Standard button height.
    static let buttonHeight: CGFloat = 52
    
    /// Minimum touch target size per Apple HIG (44pt minimum).
    static let minimumTouchTarget: CGFloat = 44
    
    // MARK: - Materials (Apple HIG Visual Effects)
    
    /// Glass material that respects accessibility settings.
    static var glassMaterial: Material {
        UIAccessibility.isReduceTransparencyEnabled ? .thickMaterial : .ultraThinMaterial
    }
    
    // MARK: - Background View
    
    /// Background view for main app surfaces.
    @ViewBuilder
    static var backgroundView: some View {
        background.ignoresSafeArea()
    }
    
    /// Background gradient helper (currently solid color, name kept for semantic clarity).
    @ViewBuilder
    static var backgroundGradient: some View {
        backgroundView
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

// MARK: - Button Styles (Apple HIG Compliant)

extension Theme {
    
    /// Primary button style with filled background.
    /// Use for primary call-to-action buttons.
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .foregroundStyle(Theme.background)
                .background(Theme.accentColor.opacity(configuration.isPressed ? 0.85 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    /// Secondary button style with subtle background.
    /// Use for secondary actions alongside primary buttons.
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
    
    /// Tertiary button style with minimal styling.
    /// Use for tertiary actions or on dark surfaces.
    struct TertiaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .foregroundStyle(Theme.accentColor)
                .background(Theme.secondaryBackground.opacity(configuration.isPressed ? 0.7 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    /// Row button style for list items.
    /// Use for interactive list rows and selectable items.
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
    
    /// Destructive button style for dangerous actions.
    /// Use for delete, remove, or other destructive operations.
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

// MARK: - View Modifiers (Apple HIG Patterns)

/// Modifier for card-style containers with background (no border per Apple HIG).
struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

/// Modifier for standard background application.
struct BackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
    }
}

/// Modifier for background with optional image overlay.
struct BackgroundImageModifier: ViewModifier {
    let imageName: String?
    
    func body(content: Content) -> some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
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

/// Modifier for parallax blur effect on scroll (respects accessibility).
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

/// Text field style following Apple HIG input guidelines.
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

// MARK: - View Extensions (Convenience Methods)

extension View {
    /// Applies card styling with background and border.
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
    
    /// Applies standard app background.
    func appBackground() -> some View {
        modifier(BackgroundModifier())
    }
    
    /// Applies background with optional image overlay.
    func backgroundImage(_ imageName: String?) -> some View {
        modifier(BackgroundImageModifier(imageName: imageName))
    }
    
    /// Applies scroll-based blur effect (accessibility-aware).
    func scrollBlurEffect() -> some View {
        modifier(ScrollBlurModifier())
    }
    
    /// Applies standard input field styling.
    func inputFieldStyle() -> some View {
        textFieldStyle(InputFieldStyle())
    }
    
    /// Ensures minimum touch target size per Apple HIG (44x44pt).
    func accessibleTapTarget() -> some View {
        frame(minWidth: Theme.minimumTouchTarget, minHeight: Theme.minimumTouchTarget)
    }
    
    /// Applies animation only if user hasn't enabled Reduce Motion.
    @ViewBuilder
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if Theme.prefersReducedMotion {
            self
        } else {
            self.animation(animation, value: value)
        }
    }
}

// MARK: - Color Extension (Hex Support)

extension Color {
    /// Initializes a Color from a hex string.
    /// Supports 3, 6, and 8 character hex strings (RGB, RRGGBB, AARRGGBB).
    /// - Parameter hex: Hex color string (e.g., "FF0000", "#FF0000", "F00")
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

// MARK: - Haptic Feedback (Apple HIG)

/// Manager for haptic feedback following Apple HIG guidelines.
/// Automatically respects user's Reduce Motion accessibility setting.
enum HapticManager {
    private static let impact = UIImpactFeedbackGenerator(style: .light)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()
    
    /// Light impact feedback for button taps and selections.
    static func tap() {
        guard !Theme.prefersReducedMotion else { return }
        impact.impactOccurred()
    }
    
    /// Success notification feedback for completed actions.
    static func success() {
        guard !Theme.prefersReducedMotion else { return }
        notification.notificationOccurred(.success)
    }
    
    /// Error notification feedback for failed actions.
    static func error() {
        guard !Theme.prefersReducedMotion else { return }
        notification.notificationOccurred(.error)
    }
    
    /// Warning notification feedback for cautionary actions.
    static func warning() {
        guard !Theme.prefersReducedMotion else { return }
        notification.notificationOccurred(.warning)
    }
    
    /// Selection feedback for picker and segmented control changes.
    static func selectionChanged() {
        guard !Theme.prefersReducedMotion else { return }
        selection.selectionChanged()
    }
}

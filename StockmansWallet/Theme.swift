//
//  Theme.swift
//  StockmansWallet
//
//  Design System: Liquid Glass Aesthetic (Semantic Colors)
//

import SwiftUI

struct Theme {
    // MARK: - Semantic Colors (from Asset Catalog)
    // These colors should have Light/Dark and High-Contrast variants in the asset catalog.
    static let background = Color("Background")
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    static let accent = Color("AccentColor")
    static let destructive = Color("Destructive")
    
    // MARK: - Code-based Colors (not from assets)
    // Debug: Defined in code for maximum flexibility and maintainability
    static let cardBackground = Color.white.opacity(0.03)  // For buttons and UI components
    static let inputFieldBackground = Color.white.opacity(0.03)  // For text fields, pickers, etc.
    static let separator = Color.white.opacity(0.2)  // Subtle divider lines and borders
    
    // Debug: Custom colors for positive/negative change indicators (total change, percent change, tickers)
    // Rule #0: Single source of truth for change colors used throughout change indicators
    static let positiveChange = Color(hex: "9CD563")  // Bright green for positive changes (text)
    static let positiveChangeBg = Color(hex: "29321F")  // Dark green background for positive change pills
    static let negativeChange = Color(hex: "D64F41")  // Bright red for negative changes (text)
    static let negativeChangeBg = Color(hex: "432522")  // Dark red background for negative change pills
   
    // MARK: - Backgrounds
    // Debug: Standardized backgrounds for consistent visual identity across the app
    // Rule #0: Single source of truth for background color used throughout main pages
    
    /// Main solid background color for all primary app screens (Dashboard, Portfolio, Market, etc.)
    /// Dark brown (#1E1815) that creates depth and visual hierarchy
    static let backgroundColor = Color(hex: "1E1815")
    
    /// Debug: Almost black background for when no background image is selected
    /// Much darker than standard backgroundColor to create stronger contrast
    static let noBackgroundColor = Color(hex: "0A0908")
    
    /// Debug: Background image opacity for dashboard parallax images
    /// Rule #0: Single source of truth for background image transparency
    /// Range: 0.0 (fully transparent) to 1.0 (fully opaque)
    static let backgroundImageOpacity: CGFloat = 0.4
    
    /// Main gradient background - brown accent radiating from top
    /// Debug: Simple radial gradient - adjust opacity to control strength of brown glow
    @ViewBuilder
    static var backgroundGradient: some View {
        RadialGradient(
            colors: [
                Color(hex: "7C5134").opacity(0.15),  // Brown accent
                Color(hex: "1E1815")                // Dark brown at edges
            ],
            center: .top,
            startRadius: 0,
            endRadius: 500
        )
        .ignoresSafeArea()
    }
    
    /// Solid background color for sheets, modals, and overlays
    /// Uses #130F0D for consistency
    static let sheetBackground = Color(hex: "1E1815")

    // MARK: - Typography
    // Debug: Using system fonts with .rounded design - the correct Apple HIG way
    // This gives us SF Rounded (SF Pro Rounded), the rounded system font for iOS
    // Prefer semantic SwiftUI text styles to support Dynamic Type automatically.
    static let largeTitle: Font = .system(.largeTitle, design: .rounded)               // ~34pt - For major headings
    static let title: Font = .system(.title, design: .rounded).weight(.semibold)       // ~28pt - For hero values (portfolio total)
    static let title2: Font = .system(.title2, design: .rounded).weight(.semibold)     // ~22pt - For emphasized card values
    static let title3: Font = .system(.title3, design: .rounded).weight(.semibold)     // ~20pt - For primary card values
    static let headline: Font = .system(.headline, design: .rounded).weight(.semibold) // ~17pt - For card headers
    static let body: Font = .system(.body, design: .rounded)                           // ~17pt - For regular content, labels
    static let callout: Font = .system(.callout, design: .rounded)                     // ~16pt - For secondary values in lists
    static let subheadline: Font = .system(.subheadline, design: .rounded)             // ~15pt - For de-emphasized values
    static let caption: Font = .system(.caption, design: .rounded)                     // ~12pt - For metadata and small labels
    
    // MARK: - Spacing
    // iOS 26 HIG - Corner radii for different component types
    static let cornerRadius: CGFloat = 16.0        // Standard cards and UI components
    static let sheetCornerRadius: CGFloat = 32.0   // Sheets, modals, and large panels
    static let cardPadding: CGFloat = 20.0
    static let sectionSpacing: CGFloat = 24.0

    // MARK: - Controls
    // Single source of truth for button height across the app.
    static let buttonHeight: CGFloat = 52.0

    // MARK: - Glass Effect Material
    // Consider providing an opaque fallback when Reduce Transparency is enabled.
    static var glassMaterial: Material {
        if UIAccessibility.isReduceTransparencyEnabled {
            // Fallback to an opaque background when transparency is reduced.
            return .thickMaterial
        } else {
            return .ultraThinMaterial
        }
    }
}

// MARK: - Background Image Modifier
struct BackgroundImageModifier: ViewModifier {
    let imageName: String?
    
    func body(content: Content) -> some View {
        ZStack {
            // Always paint fallback color first - extend to all edges including safe areas
            Theme.background
                .ignoresSafeArea(edges: .all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            
            // Try to paint the image if provided - extend to all edges including safe areas
            if let imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(edges: .all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityHidden(true)
            }
            
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .all)
    }
}

extension View {
    // Idiomatic SwiftUI API for your screens
    func backgroundImage(imageName: String?) -> some View {
        modifier(BackgroundImageModifier(imageName: imageName))
    }
}

// MARK: - Color Extension
extension Color {
    // Hex initializer retained for non-UI/brand-only cases (e.g., charts).
    // Prefer asset colors for UI surfaces and text.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
    
    // Adaptive color for light/dark mode (kept for completeness; prefer asset colors).
    init(light: String, dark: String) {
        self.init(
            UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor(Color(hex: dark))
                } else {
                    return UIColor(Color(hex: light))
                }
            }
        )
    }
}

// MARK: - View Modifiers
// Debug: Legacy SquircleCard - replaced by StitchedCard for new design system
struct SquircleCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

// MARK: - Card Style
struct StitchedCard: ViewModifier {
    var showShadow: Bool = true
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(
                        Theme.separator.opacity(0.2),
                        style: StrokeStyle(
                            lineWidth: 1,
                            lineCap: .round
                        )
                    )
            )
    }
}

struct ProgressiveLensing: ViewModifier {
    func body(content: Content) -> some View {
        // Respect Reduce Motion/Transparency by disabling heavy visual effects
        if UIAccessibility.isReduceMotionEnabled || UIAccessibility.isReduceTransparencyEnabled {
            return AnyView(content)
        }
        
        return AnyView(
            content
                .visualEffect { content, proxy in
                    let scrollOffset = proxy.bounds(of: .scrollView)?.minY ?? 0.0
                    let offsetCGFloat = CGFloat(scrollOffset)
                    return content
                        .blur(radius: max(0.0, min(20.0, abs(offsetCGFloat) / 3.0)))
                        .opacity(max(0.7, min(1.0, 1.0 - abs(offsetCGFloat) / 200.0)))
                }
        )
    }
}

extension View {
    func squircleCard() -> some View {
        modifier(SquircleCard())
    }
    
    /// New card style with subtle stitching effect and drop shadow
    func stitchedCard(showShadow: Bool = true) -> some View {
        modifier(StitchedCard(showShadow: showShadow))
    }
    
    func progressiveLensing() -> some View {
        modifier(ProgressiveLensing())
    }
}

// MARK: - Reusable Button Styles (single source of truth)
extension Theme {
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .contentShape(Rectangle())
                .foregroundStyle(.white)
                .background(Theme.accent.opacity(configuration.isPressed ? 0.85 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .contentShape(Rectangle())
                .foregroundStyle(Theme.accent)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .stroke(Theme.accent.opacity(configuration.isPressed ? 0.6 : 1.0), lineWidth: 1.0)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                                .fill(Theme.cardBackground.opacity(0.6))
                        )
                )
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    // For row-like actions (selectable rows, connect integrations, etc.)
    struct RowButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: Theme.buttonHeight)
                .padding(.horizontal, 16)
                .background(Theme.cardBackground.opacity(configuration.isPressed ? 0.85 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    // Debug: iOS 26 HIG - Destructive button style for delete/remove actions
    // Uses red color to signal danger, requires user confirmation before critical actions
    struct DestructiveButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .contentShape(Rectangle())
                .foregroundStyle(.white)
                .background(Theme.destructive.opacity(configuration.isPressed ? 0.85 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
    
    // Debug: Landing page button style with dark brown color (#392219)
    struct LandingButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.headline)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .contentShape(Rectangle())
                .foregroundStyle(.white)
                .background(Color(hex: "392219").opacity(configuration.isPressed ? 0.85 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}

// Optional convenience modifiers if you prefer chaining
extension View {
    func primaryCTA() -> some View {
        self.buttonStyle(Theme.PrimaryButtonStyle())
    }
    func secondaryCTA() -> some View {
        self.buttonStyle(Theme.SecondaryButtonStyle())
    }
    func rowAction() -> some View {
        self.buttonStyle(Theme.RowButtonStyle())
    }
    func destructiveCTA() -> some View {
        self.buttonStyle(Theme.DestructiveButtonStyle())
    }
    func landingCTA() -> some View {
        self.buttonStyle(Theme.LandingButtonStyle())
    }
}

// MARK: - Haptic Feedback
// Debug: Respects accessibility settings (isReduceMotionEnabled) before triggering haptics
struct HapticManager {
    static let impact = UIImpactFeedbackGenerator(style: .light)
    static let notification = UINotificationFeedbackGenerator()
    static let selectionFeedback = UISelectionFeedbackGenerator()
    
    /// Light haptic for button taps and interactions
    static func tap() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        impact.prepare()
        impact.impactOccurred()
    }
    
    /// Success haptic for completed actions
    static func success() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        notification.prepare()
        notification.notificationOccurred(.success)
    }
    
    /// Error haptic for failed actions
    static func error() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        notification.prepare()
        notification.notificationOccurred(.error)
    }
    
    /// Warning haptic for caution states
    static func warning() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        notification.prepare()
        notification.notificationOccurred(.warning)
    }
    
    /// Selection haptic for picker/segmented control changes
    static func selection() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
    }
}

// MARK: - Accessibility Helpers
// Debug: Comprehensive accessibility support for HIG compliance
extension Theme {
    /// Dynamic Type scaled font - automatically respects user's text size preferences
    static func scaledFont(style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        return Font.system(style).weight(weight)
    }
    
    /// Check if user prefers larger text (for custom layout adjustments)
    static var isLargeTextEnabled: Bool {
        let category = UIApplication.shared.preferredContentSizeCategory
        return category >= .accessibilityMedium
    }
    
    /// Minimum touch target size per Apple HIG (44x44 points)
    static let minimumTouchTarget: CGFloat = 44.0
    
    /// Check if device is in high contrast mode
    static var isHighContrastEnabled: Bool {
        return UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    /// Get appropriate animation duration (0 if Reduce Motion is enabled)
    static func animationDuration(_ duration: Double) -> Double {
        return UIAccessibility.isReduceMotionEnabled ? 0 : duration
    }
    
    /// Check if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        return UIAccessibility.isVoiceOverRunning
    }
}

// MARK: - View Extensions for Accessibility
extension View {
    /// Apply minimum touch target size for better accessibility
    func accessibleTapTarget() -> some View {
        self.frame(minWidth: Theme.minimumTouchTarget, minHeight: Theme.minimumTouchTarget)
    }
    
    /// Conditionally apply animation based on Reduce Motion setting
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            return AnyView(self)
        } else {
            return AnyView(self.animation(animation, value: value))
        }
    }
}

// MARK: - Input Field Style
// Debug: Unified text field style for consistent input backgrounds across the app
struct InputFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: Theme.minimumTouchTarget) // iOS 26 HIG: 44pt minimum
            .background(Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(Theme.primaryText)
    }
}

extension View {
    /// Apply standard input field styling
    func inputFieldStyle() -> some View {
        self.textFieldStyle(InputFieldStyle())
    }
}

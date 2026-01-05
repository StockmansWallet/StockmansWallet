//
//  SignInComponents.swift
//  StockmansWallet
//
//  Sign-in button components (Apple and Google)
//  Custom implementations following Apple & Google branding guidelines
//

import SwiftUI
import AuthenticationServices
import UIKit

// MARK: - Custom Apple Sign In Button (Styled)
// Debug: Custom implementation per Apple HIG - allows squircle shape while maintaining brand compliance
struct CustomAppleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Apple logo (SF Symbol)
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                
                // Text per Apple branding guidelines
                Text("Continue with Apple")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1) // Debug: Subtle semi-transparent stroke
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Native Apple Sign In Button Wrapper (Legacy - kept for reference)
struct AppleSignInButtonRepresentable: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    var cornerRadius: CGFloat = 12
    var action: () -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.cornerRadius = cornerRadius
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTap), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        uiView.cornerRadius = cornerRadius
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    final class Coordinator {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func didTap() { action() }
    }
}

// MARK: - Custom Google Sign-In Button (Styled)
// Debug: Custom implementation per Google branding guidelines - matches Apple button styling
struct CustomGoogleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Google logo (using asset or fallback)
                if let uiImage = UIImage(named: "google_logo") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 20, height: 20)
                } else {
                    // Fallback: colored "G"
                    Text("G")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                // Text per Google branding guidelines
                Text("Continue with Google")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1) // Debug: Subtle semi-transparent stroke
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Google Sign-In Button (UIKit Implementation - Legacy)
// Debug: iOS 26 HIG - Button height is set to 52pt (matching Theme.buttonHeight) for consistency
struct GoogleSignInButtonStyledRepresentable: UIViewRepresentable {
    let title: String
    var cornerRadius: CGFloat = 12
    var buttonHeight: CGFloat = 52.0 // iOS 26 HIG: Match Theme.buttonHeight (exceeds 44pt minimum)
    var action: () -> Void
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        
        // Visuals to match Apple's white style in dark mode
        button.backgroundColor = .white
        button.layer.cornerRadius = cornerRadius
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(white: 0, alpha: 0.06).cgColor // subtle separator like Apple's
        
        // Typography per iOS HIG - 17pt Medium weight for button labels
        let font = UIFont.systemFont(ofSize: 17, weight: .medium) // iOS HIG standard for button text
        let metrics = UIFontMetrics(forTextStyle: .body)
        button.titleLabel?.font = metrics.scaledFont(for: font)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(UIColor.black.withAlphaComponent(0.4), for: .disabled)
        
        // Use UIButtonConfiguration for iOS 15+ which handles layout properly
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
            // Add image to the configuration - resize to 20x20 to match Apple's button icon size
            if let originalImage = UIImage(named: "google_logo")?.withRenderingMode(.alwaysOriginal) {
                // Resize image to 20x20 points
                let size = CGSize(width: 20, height: 20)
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                originalImage.draw(in: CGRect(origin: .zero, size: size))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysOriginal)
                UIGraphicsEndImageContext()
                
                if let image = resizedImage {
                    config.image = image
                    config.imagePlacement = .leading
                    config.imagePadding = 8
                }
            }
            button.configuration = config
        } else {
            // Fallback for iOS 14 - use contentEdgeInsets and position icon manually
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0) // Space for icon
            
            // Google logo view (20x20) with official asset if available
            let iconView = makeGoogleIconView(size: 20)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(iconView)
            
            // Position icon to the left of the title
            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 14),
                iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 20),
                iconView.heightAnchor.constraint(equalToConstant: 20)
            ])
        }
        
        button.titleLabel?.lineBreakMode = .byClipping
        
        // Touch handling (demo: just call action)
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTap), for: .touchUpInside)
        
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {
        uiView.layer.cornerRadius = cornerRadius
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    final class Coordinator {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func didTap() { action() }
    }
    
    // Uses Assets.xcassets "google_logo" if present; ensures original colors
    private func makeGoogleIconView(size: CGFloat = 20) -> UIView {
        if let image = UIImage(named: "google_logo")?.withRenderingMode(.alwaysOriginal) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.isAccessibilityElement = false
            return imageView
        } else {
            // Fallback: Monochrome "G" placeholder
            let label = UILabel()
            label.text = "G"
            label.textAlignment = .center
            label.textColor = .black
            label.font = UIFont.systemFont(ofSize: size * 0.65, weight: .bold)
            label.backgroundColor = .white
            label.layer.cornerRadius = size / 2
            label.layer.masksToBounds = true
            label.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
            label.layer.borderWidth = 0.5
            label.isAccessibilityElement = false
            return label
        }
    }
}


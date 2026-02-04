//
//  SignInPage.swift
//  StockmansWallet
//
//  Profile Setup Page for Beta Testing
//  Debug: Captures user name and optional email for personalization
//  Rule: Simple solution for beta - no authentication, just profile setup
//

import SwiftUI
import AuthenticationServices

struct SignInPage: View {
    @Binding var currentPage: Int
    @Binding var userPrefs: UserPreferences
    var onSignInComplete: (() -> Void)? = nil
    // Debug: Beta testing - only need onEmailSignUp handler (all users are "new")
    var onEmailSignIn: (() -> Void)? = nil // Not used in beta
    var onEmailSignUp: (() -> Void)? = nil // Continues to onboarding
    var onAppleSignIn: (() -> Void)? = nil // Not used in beta
    var onGoogleSignIn: (() -> Void)? = nil // Not used in beta
    
    @State private var fullName = ""
    
    // Debug: iOS 26 HIG - Focus state for proper keyboard navigation between fields
    @FocusState private var focusedField: Field?
    
    // Debug: Enum to track which field is focused for keyboard navigation
    private enum Field: Hashable {
        case fullName
    }
    
    // Debug: Beta validation - only require name (email optional for personalization)
    private var canProceed: Bool {
        return !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        // Debug: Full-screen static page with gradient background (matches onboarding flow)
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Debug: Card container to match onboarding card style, vertically centered.
                SignInCard {
                    VStack(spacing: 24) {
                        // Debug: Profile setup header for beta testing (no icon).
                        VStack(spacing: 10) {
                            Text("Let's Get Started")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Theme.primaryText)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text("Personalise your experience by adding your name.")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Debug: Profile form - name required for beta personalization
                        VStack(spacing: 16) {
                            // Full Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                    .fontWeight(.medium)
                                TextField("Full Name", text: $fullName)
                                    .textFieldStyle(SignInTextFieldStyle())
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .submitLabel(.done)
                                    .focused($focusedField, equals: .fullName)
                                    .onSubmit {
                                        focusedField = nil
                                    }
                            }
                        }
                    }
                    .padding(24)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Debug: Fixed bottom CTA to match onboarding flow.
            VStack(spacing: 12) {
                Button {
                    HapticManager.tap()
                    // Debug: Save profile data to userPrefs
                    let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let parts = trimmedName.split(separator: " ", maxSplits: 1).map(String.init)
                    userPrefs.firstName = parts.first ?? ""
                    userPrefs.lastName = parts.count > 1 ? parts[1] : ""
                    userPrefs.email = ""
                    // Debug: Beta - everyone continues to onboarding (all are "new users")
                    onEmailSignUp?()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
                .disabled(!canProceed)
                .opacity(canProceed ? 1.0 : 0.6)
                .accessibilityLabel("Continue")
                .accessibilityHint("Your name will be used to personalise the app")
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Card Container
private struct SignInCard<Content: View>: View {
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
            
            // Debug: Scrollable content to handle smaller screens.
            content
        }
        .shadow(color: Theme.background.opacity(0.4), radius: 10, x: 0, y: 8)
    }
}

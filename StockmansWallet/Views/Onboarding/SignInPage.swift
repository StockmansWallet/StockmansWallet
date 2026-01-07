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
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    
    // Debug: iOS 26 HIG - Focus state for proper keyboard navigation between fields
    @FocusState private var focusedField: Field?
    
    // Debug: Enum to track which field is focused for keyboard navigation
    private enum Field: Hashable {
        case firstName
        case lastName
        case email
    }
    
    // Debug: Beta validation - only require name (email optional for personalization)
    private var canProceed: Bool {
        return !firstName.isEmpty && !lastName.isEmpty
    }
    
    var body: some View {
        // Debug: Full-screen static page with gradient background (matches onboarding flow)
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            // Debug: Align content to top for better visual hierarchy
            VStack(spacing: 32) {
                // Debug: Profile setup header for beta testing
                VStack(spacing: 16) {
                    // Profile icon
                    Image("farmer_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(Theme.accent)
                        .padding(.bottom, 4)
                    
                    // Header text
                    Text("Let's Get Started")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    
        
                    
                    // Debug: Beta disclaimer badge
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                        Text("Beta Testing - No user authentication")
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                
                // Debug: Profile form - name required, email optional for beta
                VStack(spacing: 16) {
                    // First Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .fontWeight(.medium)
                        TextField("First Name", text: $firstName)
                            .textFieldStyle(SignInTextFieldStyle())
                            .textContentType(.givenName)
                            .autocapitalization(.words)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .firstName)
                            .onSubmit {
                                focusedField = .lastName
                            }
                    }
                    
                    // Last Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Name")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .fontWeight(.medium)
                        TextField("Last Name", text: $lastName)
                            .textFieldStyle(SignInTextFieldStyle())
                            .textContentType(.familyName)
                            .autocapitalization(.words)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .lastName)
                            .onSubmit {
                                focusedField = .email
                            }
                    }
                    
                    // Email field (optional for beta)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Email")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                                .fontWeight(.medium)
                            Text("(Optional)")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText.opacity(0.7))
                        }
                        TextField("Email", text: $email)
                            .textFieldStyle(SignInTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .focused($focusedField, equals: .email)
                            .onSubmit {
                                focusedField = nil
                            }
                    }
                }
                .padding(.horizontal, 4)
                
                // Primary Action - Continue to onboarding
                Button {
                    HapticManager.tap()
                    // Debug: Save profile data to userPrefs
                    userPrefs.firstName = firstName
                    userPrefs.lastName = lastName
                    userPrefs.email = email.isEmpty ? "" : email
                    // Debug: Beta - everyone continues to onboarding (all are "new users")
                    onEmailSignUp?()
                } label: {
                    Text("Continue to App")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
                .disabled(!canProceed)
                .opacity(canProceed ? 1.0 : 0.6)
                .accessibilityLabel("Continue to app")
                .accessibilityHint("Your name will be used to personalize the app")
                
                // Footer - Terms & Privacy (kept for compliance)
                HStack(spacing: 4) {
                    Text("By continuing, you accept our")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText.opacity(0.5))
                    
                    Button {
                        HapticManager.tap()
                        // TODO: Show terms sheet
                    } label: {
                        Text("Terms")
                            .font(.caption)
                            .foregroundStyle(Theme.accent.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    
                    Text("&")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText.opacity(0.5))
                    
                    Button {
                        HapticManager.tap()
                        // TODO: Show privacy sheet
                    } label: {
                        Text("Privacy")
                            .font(.caption)
                            .foregroundStyle(Theme.accent.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 40)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

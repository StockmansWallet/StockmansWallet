//
//  SignInPage.swift
//  StockmansWallet
//
//  Sign In Page (Demo-only: buttons just advance onboarding)
//

import SwiftUI
import AuthenticationServices

struct SignInPage: View {
    @Binding var currentPage: Int
    @Binding var userPrefs: UserPreferences
    var onSignInComplete: (() -> Void)? = nil
    // Debug: Demo sign-in handlers for different methods
    var onEmailSignIn: (() -> Void)? = nil // Existing users → Dashboard
    var onEmailSignUp: (() -> Void)? = nil // New users → Onboarding
    var onAppleSignIn: (() -> Void)? = nil
    var onGoogleSignIn: (() -> Void)? = nil
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    // Debug: iOS 26 HIG - Focus state for proper keyboard navigation between fields
    @FocusState private var focusedField: Field?
    
    // Debug: Enum to track which field is focused for keyboard navigation
    private enum Field: Hashable {
        case firstName
        case lastName
        case email
        case password
        case confirmPassword
    }
    
    // Debug: Demo/Dev mode - simplified validation without password requirements
    private var canProceed: Bool {
        if isSignUp {
            // Debug: For sign up, only require name and valid email (no password for demo)
            return !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && email.contains("@")
        } else {
            // Debug: For sign in, only require email (no password for demo)
            return !email.isEmpty
        }
    }
    
    var body: some View {
        // Debug: Full-screen static page with gradient background (matches onboarding flow)
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            // Debug: Align content to top for better visual hierarchy
            VStack(spacing: 32) {
                        // Debug: Improved header with better visual hierarchy
                        VStack(spacing: 12) {
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Theme.primaryText)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text(isSignUp ? "Get started with Stockman's Wallet (Demo Mode - No password required)" : "Sign in to manage your livestock portfolio")
                                .font(.body)
                                .foregroundStyle(Theme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Debug: Email/password form with proper keyboard navigation
                        VStack(spacing: 14) {
                            if isSignUp {
                                TextField("First Name", text: $firstName)
                                    .textFieldStyle(SignInTextFieldStyle())
                                    .textContentType(.givenName)
                                    .autocapitalization(.words)
                                    .submitLabel(.next) // Debug: iOS 26 HIG - Proper return key label
                                    .focused($focusedField, equals: .firstName)
                                    .onSubmit {
                                        // Debug: iOS 26 HIG - Move to next field on return
                                        focusedField = .lastName
                                    }
                                
                                TextField("Last Name", text: $lastName)
                                    .textFieldStyle(SignInTextFieldStyle())
                                    .textContentType(.familyName)
                                    .autocapitalization(.words)
                                    .submitLabel(.next) // Debug: iOS 26 HIG - Proper return key label
                                    .focused($focusedField, equals: .lastName)
                                    .onSubmit {
                                        // Debug: Demo - Move to email (last field in sign up)
                                        focusedField = .email
                                    }
                            }
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(SignInTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .submitLabel(.done) // Debug: Demo - Email is now the last field for sign up
                                .focused($focusedField, equals: .email)
                                .onSubmit {
                                    // Debug: Demo - Dismiss keyboard after email for sign up
                                    focusedField = nil
                                }
                            
                            // Debug: Password fields hidden for demo/dev - users can sign up with just name and email
                            // TODO: Re-enable for production by removing this condition
                            if !isSignUp {
                                // Debug: Password field only shown for sign in (kept for demo purposes)
                                ZStack(alignment: .trailing) {
                                    Group {
                                        if showPassword {
                                            TextField("Password", text: $password)
                                                .textContentType(.password)
                                                .submitLabel(.done)
                                                .focused($focusedField, equals: .password)
                                                .onSubmit {
                                                    focusedField = nil
                                                }
                                        } else {
                                            SecureField("Password", text: $password)
                                                .textContentType(.password)
                                                .submitLabel(.done)
                                                .focused($focusedField, equals: .password)
                                                .onSubmit {
                                                    focusedField = nil
                                                }
                                        }
                                    }
                                    .textFieldStyle(SignInTextFieldStyle())
                                    
                                    Button {
                                        HapticManager.tap()
                                        showPassword.toggle()
                                    } label: {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Theme.secondaryText)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                                    .padding(.trailing, 8)
                                }
                            }
                        }
                        
                        // Primary Action - Email/Password Sign In
                        Button {
                            HapticManager.tap()
                            // Debug: Save name/email from sign-up form to userPrefs
                            if isSignUp {
                                userPrefs.firstName = firstName
                                userPrefs.lastName = lastName
                                userPrefs.email = email
                                // Debug: Demo - New user goes through onboarding
                                onEmailSignUp?()
                            } else {
                                // Debug: Demo - Existing user goes to dashboard
                                onEmailSignIn?()
                            }
                        } label: {
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(Theme.PrimaryButtonStyle())
                        .disabled(!canProceed)
                        .opacity(canProceed ? 1.0 : 0.6)
                        
                        // Divider
                        HStack(spacing: 16) {
                            Rectangle()
                                .fill(Theme.separator)
                                .frame(height: 1)
                            
                            Text("Or")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                            
                            Rectangle()
                                .fill(Theme.separator)
                                .frame(height: 1)
                        }
                        
                        // Debug: Social sign-in options
                        VStack(spacing: 12) {
                            // Apple Sign In - Custom styled button (required first per HIG)
                            // Debug: Demo - Apple goes to Farmer dashboard
                            CustomAppleSignInButton {
                                HapticManager.tap()
                                onAppleSignIn?()
                            }
                            .accessibilityLabel("Continue with Apple")
                            
                            // Google Sign In - Custom styled button
                            // Debug: Demo - Google goes to Advisor dashboard
                            CustomGoogleSignInButton {
                                HapticManager.tap()
                                onGoogleSignIn?()
                            }
                            .accessibilityLabel("Continue with Google")
                        }
                        
                        // Debug: Prominent mode toggle
                        Button {
                            HapticManager.tap()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSignUp.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .foregroundStyle(Theme.secondaryText)
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .foregroundStyle(Theme.accent)
                                    .fontWeight(.semibold)
                            }
                            .font(.body)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        
                        // Footer - Terms & Privacy
                        // Debug: Very subtle footer with low-opacity accent color links
                        HStack(spacing: 4) {
                            Text("By continuing, you accept our")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText.opacity(0.4))
                            
                            Button {
                                HapticManager.tap()
                            } label: {
                                Text("Terms")
                                    .font(.caption)
                                    .foregroundStyle(Theme.accent.opacity(0.35))
                            }
                            .buttonStyle(.plain)
                            
                            Text("&")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText.opacity(0.4))
                            
                            Button {
                                HapticManager.tap()
                            } label: {
                                Text("Privacy Policy")
                                    .font(.caption)
                                    .foregroundStyle(Theme.accent.opacity(0.35))
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

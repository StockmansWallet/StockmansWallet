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
    @Binding var showingSignIn: Bool
    @Binding var isSigningIn: Bool
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
    
    private var canProceed: Bool {
        if isSignUp {
            return !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword && email.contains("@")
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    var body: some View {
        // Debug: No background color - let ultraThinMaterial blur through to content behind modal
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                        // Debug: Improved header with better visual hierarchy
                        VStack(spacing: 12) {
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Theme.primaryText)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text(isSignUp ? "Get started with Stockman's Wallet" : "Sign in to manage your livestock portfolio")
                                .font(.body)
                                .foregroundStyle(Theme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        
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
                                        // Debug: iOS 26 HIG - Move to next field on return
                                        focusedField = .email
                                    }
                            }
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(SignInTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .submitLabel(.next) // Debug: iOS 26 HIG - Proper return key label
                                .focused($focusedField, equals: .email)
                                .onSubmit {
                                    // Debug: iOS 26 HIG - Move to next field on return
                                    focusedField = .password
                                }
                            
                            // Debug: Password field with integrated eye icon overlay
                            ZStack(alignment: .trailing) {
                                Group {
                                    if showPassword {
                                        TextField("Password", text: $password)
                                            .textContentType(.password)
                                            .submitLabel(isSignUp ? .next : .done) // Debug: iOS 26 HIG - Conditional label
                                            .focused($focusedField, equals: .password)
                                            .onSubmit {
                                                // Debug: iOS 26 HIG - Navigate based on mode
                                                if isSignUp {
                                                    focusedField = .confirmPassword
                                                } else {
                                                    focusedField = nil
                                                }
                                            }
                                    } else {
                                        SecureField("Password", text: $password)
                                            .textContentType(.password)
                                            .submitLabel(isSignUp ? .next : .done) // Debug: iOS 26 HIG - Conditional label
                                            .focused($focusedField, equals: .password)
                                            .onSubmit {
                                                // Debug: iOS 26 HIG - Navigate based on mode
                                                if isSignUp {
                                                    focusedField = .confirmPassword
                                                } else {
                                                    focusedField = nil
                                                }
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
                            
                            if isSignUp {
                                // Debug: Confirm password with integrated eye icon overlay
                                ZStack(alignment: .trailing) {
                                    Group {
                                        if showConfirmPassword {
                                            TextField("Confirm Password", text: $confirmPassword)
                                                .textContentType(.newPassword)
                                                .submitLabel(.done) // Debug: iOS 26 HIG - Done label for last field
                                                .focused($focusedField, equals: .confirmPassword)
                                                .onSubmit {
                                                    // Debug: iOS 26 HIG - Dismiss keyboard on last field
                                                    focusedField = nil
                                                }
                                        } else {
                                            SecureField("Confirm Password", text: $confirmPassword)
                                                .textContentType(.newPassword)
                                                .submitLabel(.done) // Debug: iOS 26 HIG - Done label for last field
                                                .focused($focusedField, equals: .confirmPassword)
                                                .onSubmit {
                                                    // Debug: iOS 26 HIG - Dismiss keyboard on last field
                                                    focusedField = nil
                                                }
                                        }
                                    }
                                    .textFieldStyle(SignInTextFieldStyle())
                                    
                                    Button {
                                        HapticManager.tap()
                                        showConfirmPassword.toggle()
                                    } label: {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Theme.secondaryText)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .accessibilityLabel(showConfirmPassword ? "Hide password" : "Show password")
                                    .padding(.trailing, 8)
                                }
                                
                                if !password.isEmpty && password != confirmPassword {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
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
                        HStack(spacing: 4) {
                            Text("By continuing, you accept our")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText.opacity(0.6)) // Debug: More subtle
                            
                            Button {
                                HapticManager.tap()
                            } label: {
                                Text("Terms")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .tint(Theme.secondaryText.opacity(0.7)) // Debug: Subtle link
                            
                            Text("&")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText.opacity(0.6))
                            
                            Button {
                                HapticManager.tap()
                            } label: {
                                Text("Privacy Policy")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .tint(Theme.secondaryText.opacity(0.7)) // Debug: Subtle link
                        }
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively) // Debug: iOS 26 HIG - Interactive keyboard dismissal on scroll
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.tap()
                        showingSignIn = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.primaryText)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
}

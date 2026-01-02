//
//  AboutYouPage.swift
//  StockmansWallet
//
//  Page 1: About You
//

import SwiftUI

struct AboutYouPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    // Debug: Password fields disabled in demo mode - removed from validation
    // Make validation reactive by computing it in the view body
    private var isValid: Bool {
        let firstName = (userPrefs.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = (userPrefs.lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let email = (userPrefs.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               !email.isEmpty &&
               email.contains("@")
    }
    
    // Debug: Helper to show what's missing for better UX
    private var missingFields: [String] {
        var missing: [String] = []
        if (userPrefs.firstName ?? "").isEmpty {
            missing.append("First Name")
        }
        if (userPrefs.lastName ?? "").isEmpty {
            missing.append("Last Name")
        }
        if (userPrefs.email ?? "").isEmpty {
            missing.append("Email")
        } else if !(userPrefs.email ?? "").contains("@") {
            missing.append("Valid Email")
        }
        return missing
    }
    
    var body: some View {
        // Debug: Force view update when userPrefs changes by using the computed property directly
        let validationState = isValid
        
        return OnboardingPageTemplate(
            title: "About You",
            subtitle: "Let's get you set up",
            currentPage: $currentPage,
            nextPage: 1,
            showBack: false,
            isValid: validationState
        ) {
            // Debug: Organized form layout following HIG - clear hierarchy and spacing
            VStack(spacing: 20) {
                // Personal Information Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Personal Information")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        TextField("First Name", text: Binding(
                            get: { userPrefs.firstName ?? "" },
                            set: { 
                                userPrefs.firstName = $0.isEmpty ? nil : $0
                                // Debug: Force view update when value changes
                            }
                        ))
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .textContentType(.givenName)
                        .autocapitalization(.words)
                        .accessibilityLabel("First name")
                        
                        TextField("Last Name", text: Binding(
                            get: { userPrefs.lastName ?? "" },
                            set: { 
                                userPrefs.lastName = $0.isEmpty ? nil : $0
                                // Debug: Force view update when value changes
                            }
                        ))
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .textContentType(.familyName)
                        .autocapitalization(.words)
                        .accessibilityLabel("Last name")
                        
                        TextField("Email", text: Binding(
                            get: { userPrefs.email ?? "" },
                            set: { 
                                userPrefs.email = $0.isEmpty ? nil : $0
                                // Debug: Force view update when value changes
                            }
                        ))
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Email address")
                    }
                    .padding(.horizontal, 20)
                }
                
                // Security Section - Disabled in demo mode
                VStack(alignment: .leading, spacing: 12) {
                    Text("Create Password")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        // Debug: Password fields disabled in demo mode
                        // Password field with show/hide toggle (disabled)
                        ZStack(alignment: .trailing) {
                            Group {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("Password", text: $password)
                                        .textContentType(.newPassword)
                                }
                            }
                            .textFieldStyle(OnboardingTextFieldStyle())
                            .disabled(true) // Demo mode - password fields inactive
                            .opacity(0.6) // Visual indication of disabled state
                            
                            Button(action: {
                                // Disabled in demo mode
                            }) {
                                Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundStyle(Theme.secondaryText.opacity(0.6))
                                    .frame(width: Theme.minimumTouchTarget, height: Theme.minimumTouchTarget)
                                    .contentShape(Rectangle())
                                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                            }
                            .buttonBorderShape(.roundedRectangle)
                            .disabled(true) // Disabled in demo mode
                            .padding(.trailing, 8)
                        }
                        
                        // Confirm password field with show/hide toggle (disabled)
                        ZStack(alignment: .trailing) {
                            Group {
                                if showConfirmPassword {
                                    TextField("Confirm Password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                }
                            }
                            .textFieldStyle(OnboardingTextFieldStyle())
                            .disabled(true) // Demo mode - password fields inactive
                            .opacity(0.6) // Visual indication of disabled state
                            
                            Button(action: {
                                // Disabled in demo mode
                            }) {
                                Image(systemName: showConfirmPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundStyle(Theme.secondaryText.opacity(0.6))
                                    .frame(width: Theme.minimumTouchTarget, height: Theme.minimumTouchTarget)
                                    .contentShape(Rectangle())
                                    .accessibilityLabel(showConfirmPassword ? "Hide password" : "Show password")
                            }
                            .buttonBorderShape(.roundedRectangle)
                            .disabled(true) // Disabled in demo mode
                            .padding(.trailing, 8)
                        }
                        
                        // Debug: Demo mode notice
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Theme.secondaryText)
                                .font(.caption)
                            Text("Password fields are disabled in demo mode")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                        .padding(.top, 4)
                        .accessibilityLabel("Password fields are disabled in demo mode")
                    }
                    .padding(.horizontal, 20)
                }
                
                // Debug: Show validation feedback when form is invalid
                if !isValid && (!(userPrefs.firstName ?? "").isEmpty || !(userPrefs.lastName ?? "").isEmpty || !(userPrefs.email ?? "").isEmpty) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(Theme.destructive)
                                .font(.caption)
                            Text("Please complete all required fields:")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.destructive)
                        }
                        
                        ForEach(missingFields, id: \.self) { field in
                            HStack(spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(Theme.destructive)
                                    .font(.system(size: 6))
                                Text(field)
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .padding(.leading, 16)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .padding(.top, 8)
        }
    }
}

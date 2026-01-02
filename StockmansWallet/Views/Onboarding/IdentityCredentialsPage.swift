//
//  IdentityCredentialsPage.swift
//  StockmansWallet
//
//  Page 1: Identity & Credentials
//

import SwiftUI

struct IdentityCredentialsPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    private var isValid: Bool {
        !(userPrefs.firstName ?? "").isEmpty &&
        !(userPrefs.lastName ?? "").isEmpty &&
        !(userPrefs.email ?? "").isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        (userPrefs.email ?? "").contains("@")
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Identity & Credentials",
            subtitle: "Let's get you set up",
            currentPage: $currentPage,
            nextPage: 1,
            showBack: false
        ) {
            VStack(spacing: 16) {
                TextField("First Name", text: Binding(
                    get: { userPrefs.firstName ?? "" },
                    set: { userPrefs.firstName = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(OnboardingTextFieldStyle())
                .textContentType(.givenName)
                .autocapitalization(.words)
                
                TextField("Last Name", text: Binding(
                    get: { userPrefs.lastName ?? "" },
                    set: { userPrefs.lastName = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(OnboardingTextFieldStyle())
                .textContentType(.familyName)
                .autocapitalization(.words)
                
                TextField("Email", text: Binding(
                    get: { userPrefs.email ?? "" },
                    set: { userPrefs.email = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(OnboardingTextFieldStyle())
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                
                HStack {
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
                    
                    Button(action: {
                        HapticManager.tap()
                        showPassword.toggle()
                    }) {
                        Image(systemName: "eye.slash.fill")
                            .foregroundStyle(Theme.secondaryText)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .padding(.trailing, 16)
                }
                
                HStack {
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
                    
                    Button(action: {
                        HapticManager.tap()
                        showConfirmPassword.toggle()
                    }) {
                        Image(systemName: "eye.slash.fill")
                            .foregroundStyle(Theme.secondaryText)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                            .accessibilityLabel(showConfirmPassword ? "Hide password" : "Show password")
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .padding(.trailing, 16)
                }
                
                if !password.isEmpty && password != confirmPassword {
                    Text("Passwords do not match")
                        .font(Theme.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}

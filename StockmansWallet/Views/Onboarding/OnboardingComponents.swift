//
//  OnboardingComponents.swift
//  StockmansWallet
//
//  Shared components for onboarding pages
//

import SwiftUI

// MARK: - Onboarding Page Template
struct OnboardingPageTemplate<Content: View>: View {
    let title: String
    let subtitle: String
    @Binding var currentPage: Int
    let nextPage: Int
    var showBack: Bool = true
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 20) {
    
            VStack(spacing: 8) {
                Text(title)
                    .font(Theme.title)
                    .foregroundStyle(Theme.primaryText)
                
                Text(subtitle)
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
            
            content
            
            Spacer()
            
            HStack(spacing: 12) {
                if showBack && currentPage > 0 {
                    Button(action: {
                        HapticManager.tap()
                        withAnimation {
                            currentPage = max(0, currentPage - 1)
                        }
                    }) {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Theme.SecondaryButtonStyle())
                    .accessibilityLabel("Back")
                }
                
                Button(action: {
                    HapticManager.tap()
                    withAnimation {
                        currentPage = nextPage
                    }
                }) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
                .accessibilityLabel("Next")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(
            Theme.backgroundGradient
                .ignoresSafeArea()
        )
    }
}

// MARK: - Text Field Styles
// Debug: Updated to use Theme.inputFieldBackground for proper field backgrounds
struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(Theme.primaryText)
    }
}

struct SignInTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(Theme.primaryText)
    }
}


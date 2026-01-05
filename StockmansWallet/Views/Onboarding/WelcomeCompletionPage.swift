//
//  WelcomeCompletionPage.swift
//  StockmansWallet
//
//  Onboarding completion page - celebrates setup and transitions to subscription
//  Debug: Follows iOS HIG - positive reinforcement before moving to app
//

import SwiftUI

struct WelcomeCompletionPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    
    // Debug: Both paths have 4 pages (About You removed, captured in Sign Up)
    private var totalPages: Int {
        4
    }
    
    // Debug: Personalized greeting
    private var greeting: String {
        if let firstName = userPrefs.firstName, !firstName.isEmpty {
            return "Welcome aboard, \(firstName)!"
        }
        return "Welcome aboard!"
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: greeting,
            subtitle: "You're all set to get started",
            currentPage: $currentPage,
            nextPage: 3, // Next: Subscription page (now page 3 after removing About You)
            showBack: false, // Debug: No back button on success page
            isValid: true,
            totalPages: totalPages
        ) {
            // Debug: Clean success screen with icon, message, and feature highlights
            VStack(spacing: 32) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .regular))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.top, 40)
                
                // Success Message
                VStack(spacing: 12) {
                    Text("Your profile is complete")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Let's choose the right plan to unlock your livestock management dashboard")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Quick Feature Preview
                VStack(spacing: 16) {
                    FeatureCheckmark(text: "Track your livestock portfolio")
                    FeatureCheckmark(text: "Monitor real-time market prices")
                    FeatureCheckmark(text: "Generate detailed reports")
                    FeatureCheckmark(text: "Manage properties and herds")
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Feature Checkmark Component
struct FeatureCheckmark: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(Theme.positiveChange)
            
            Text(text)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


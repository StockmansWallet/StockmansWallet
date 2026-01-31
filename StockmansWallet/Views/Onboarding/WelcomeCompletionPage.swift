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
    var onComplete: () -> Void // Debug: Beta testing - complete onboarding directly
    
    // Debug: Both paths now have 3 pages (Subscription hidden for beta)
    private var totalPages: Int {
        3
    }
    
    // Debug: Personalized greeting
    private var greeting: String {
        if let firstName = userPrefs.firstName, !firstName.isEmpty {
            return "Welcome, \(firstName)!"
        }
        return "Welcome!"
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: greeting,
            subtitle: "You're all set to get started",
            currentPage: $currentPage,
            nextPage: nil, // Debug: Beta testing - no next page, complete directly
            showBack: false, // Debug: No back button on success page
            isValid: true,
            totalPages: totalPages,
            onCustomContinue: onComplete // Debug: Complete onboarding on continue
        ) {
            // Debug: Clean success screen matching onboarding card typography.
            VStack(spacing: 24) {
                Text("Let's choose the right plan to unlock your livestock management dashboard")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                VStack(spacing: 12) {
                    FeatureCheckmark(text: "Track your livestock portfolio")
                    FeatureCheckmark(text: "Monitor real-time market prices")
                    FeatureCheckmark(text: "Generate detailed reports")
                    FeatureCheckmark(text: "Manage properties and herds")
                }
                .padding(.horizontal, 28)
                
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


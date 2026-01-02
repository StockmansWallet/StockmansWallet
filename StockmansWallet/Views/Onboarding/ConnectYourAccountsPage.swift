//
//  ConnectYourAccountsPage.swift
//  StockmansWallet
//
//  Page 6: Connect Your Accounts
//

import SwiftUI

struct ConnectYourAccountsPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    let onComplete: () -> Void
    
    var body: some View {
        // Debug: Use template for consistency - this page is optional so no validation needed
        OnboardingPageTemplate(
            title: "Connect Your Accounts",
            subtitle: "Link your accounting software (optional)",
            currentPage: $currentPage,
            nextPage: 5,
            isValid: true, // Optional page - always valid
            isLastPage: true,
            onComplete: onComplete
        ) {
            // Debug: Organized layout following HIG - clear sections with proper spacing
            VStack(spacing: 24) {
                // Integration Options Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Accounting Software")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        // Xero Integration Button
                        Button(action: {
                            HapticManager.tap()
                            // TODO: Implement actual Xero OAuth flow
                            userPrefs.xeroConnected.toggle()
                            if userPrefs.xeroConnected {
                                HapticManager.success()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.bar.doc.horizontal.fill")
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 24)
                                
                                Text("Connect Xero")
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                
                                Spacer()
                                
                                if userPrefs.xeroConnected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Theme.secondaryText)
                                        .font(.caption)
                                }
                            }
                        }
                        .buttonStyle(Theme.RowButtonStyle())
                        .accessibilityLabel("Connect Xero")
                        .accessibilityValue(userPrefs.xeroConnected ? "Connected" : "Not connected")
                        
                        // MYOB Integration Button
                        Button(action: {
                            HapticManager.tap()
                            // TODO: Implement actual MYOB OAuth flow
                            userPrefs.myobConnected.toggle()
                            if userPrefs.myobConnected {
                                HapticManager.success()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 24)
                                
                                Text("Connect MYOB")
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                
                                Spacer()
                                
                                if userPrefs.myobConnected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Theme.secondaryText)
                                        .font(.caption)
                                }
                            }
                        }
                        .buttonStyle(Theme.RowButtonStyle())
                        .accessibilityLabel("Connect MYOB")
                        .accessibilityValue(userPrefs.myobConnected ? "Connected" : "Not connected")
                    }
                    .padding(.horizontal, 20)
                }
                
                // Info Section
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Theme.secondaryText)
                            .font(.caption)
                        Text("You can connect these services later in Settings")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 8)
        }
    }
}


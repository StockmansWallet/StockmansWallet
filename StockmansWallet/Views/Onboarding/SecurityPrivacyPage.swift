//
//  SecurityPrivacyPage.swift
//  StockmansWallet
//
//  Page 3: Security & Privacy
//

import SwiftUI

struct SecurityPrivacyPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    
    // Debug: Validation - APPs compliance acceptance is required
    private var isValid: Bool {
        userPrefs.appsComplianceAccepted
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Security & Privacy",
            subtitle: "Configure your security preferences",
            currentPage: $currentPage,
            nextPage: 4,
            isValid: isValid,
            totalPages: 6 // Debug: SHARED page - both paths have 6 pages (includes Subscription)
        ) {
            // Debug: Organized layout following HIG - clear sections with proper spacing
            VStack(spacing: 24) {
                // Security Settings Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Security Settings")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        // Two-Factor Authentication Toggle
                        Toggle(isOn: $userPrefs.twoFactorEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Enable Two-Factor Authentication")
                                        .font(Theme.body)
                                        .foregroundStyle(Theme.primaryText)
                                    Text("Add an extra layer of security to your account")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: Theme.buttonHeight)
                        .stitchedCard()
                        .accessibilityLabel("Two-factor authentication")
                        .accessibilityValue(userPrefs.twoFactorEnabled ? "Enabled" : "Disabled")
                    }
                    .padding(.horizontal, 20)
                }
                
                // Privacy & Compliance Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Privacy & Compliance")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    // Match inner content padding with the card above (16), but no card here
                    VStack(spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: {
                                HapticManager.tap()
                                userPrefs.appsComplianceAccepted.toggle()
                            }) {
                                Image(systemName: userPrefs.appsComplianceAccepted ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(userPrefs.appsComplianceAccepted ? Theme.accent : Theme.secondaryText)
                                    .font(.system(size: 24))
                                    .frame(width: Theme.minimumTouchTarget, height: Theme.minimumTouchTarget)
                                    .contentShape(Rectangle())
                            }
                            .buttonBorderShape(.roundedRectangle)
                            .accessibilityLabel(userPrefs.appsComplianceAccepted ? "APPs compliance accepted" : "APPs compliance not accepted")
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("I accept the Australian Privacy Principles (APPs) compliance requirements")
                                    .font(Theme.subheadline) // smaller than body for better balance
                                    .foregroundStyle(Theme.primaryText)
                                    .multilineTextAlignment(.leading)
                                
                                Button(action: {
                                    HapticManager.tap()
                                    // TODO: Show APPs compliance details
                                }) {
                                    Text("Learn more")
                                        .font(Theme.subheadline) // match line height and size
                                        .foregroundStyle(Theme.accent)
                                        .frame(height: Theme.minimumTouchTarget)
                                        .contentShape(Rectangle())
                                }
                                .buttonBorderShape(.roundedRectangle)
                                .accessibilityLabel("Learn more about APPs compliance")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16) // align with the card content above
                        .padding(.vertical, 8)
                        
                        // Debug: Show validation hint if APPs not accepted
                        if !userPrefs.appsComplianceAccepted {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(Theme.destructive)
                                    .font(.caption)
                                Text("APPs compliance acceptance is required to continue")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.destructive)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20) // align with section titles/outer edge
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}

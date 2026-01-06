//
//  SecuritySettingsView.swift
//  StockmansWallet
//
//  Security Settings - Two-Factor Authentication and APPS Compliance
//  Debug: Displays and manages security-related settings
//

import SwiftUI
import SwiftData

// Debug: Security settings view for authentication and compliance
struct SecuritySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Debug: Header section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.positiveChange)
                        Text("Security")
                            .font(Theme.title)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    Text("Manage your security settings and compliance status.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.cardPadding)
                .stitchedCard()
                .padding(.horizontal)
                .padding(.top)
                
                // Debug: Two-Factor Authentication section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.positiveChange.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "key.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.positiveChange)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Two-Factor Authentication")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            Text(userPrefs.twoFactorEnabled ? "Enabled" : "Disabled")
                                .font(Theme.caption)
                                .foregroundStyle(userPrefs.twoFactorEnabled ? Theme.positiveChange : Theme.secondaryText)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: .constant(userPrefs.twoFactorEnabled))
                            .labelsHidden()
                            .disabled(true) // Debug: Will be enabled when backend authentication is implemented
                            .tint(Theme.positiveChange)
                    }
                    
                    Divider()
                        .background(Theme.separator)
                    
                    Text("Add an extra layer of security to your account. When enabled, you'll need to enter a code from your phone in addition to your password.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Theme.cardPadding)
                .stitchedCard()
                .padding(.horizontal)
                
                // Debug: APPS Compliance section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.accent.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("APPS Compliance")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            Text(userPrefs.appsComplianceAccepted ? "Accepted" : "Not Accepted")
                                .font(Theme.caption)
                                .foregroundStyle(userPrefs.appsComplianceAccepted ? Theme.positiveChange : Theme.secondaryText)
                        }
                        
                        Spacer()
                        
                        if userPrefs.appsComplianceAccepted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.positiveChange)
                                .font(.system(size: 24))
                        }
                    }
                    
                    Divider()
                        .background(Theme.separator)
                    
                    Text("Australian Privacy Principles (APPS) compliance status. This indicates your acceptance of privacy and data handling policies.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Theme.cardPadding)
                .stitchedCard()
                .padding(.horizontal)
                
                // Debug: Additional security options (for future implementation)
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(Theme.secondaryText)
                        Text("Additional Security")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    Divider()
                        .background(Theme.separator)
                    
                    SecurityOptionRow(
                        icon: "faceid",
                        title: "Face ID / Touch ID",
                        subtitle: "Coming soon",
                        isEnabled: false
                    )
                    
                    SecurityOptionRow(
                        icon: "clock.arrow.circlepath",
                        title: "Auto-Lock",
                        subtitle: "Coming soon",
                        isEnabled: false
                    )
                }
                .padding(Theme.cardPadding)
                .stitchedCard()
                .padding(.horizontal)
            }
            .padding(.bottom, 100)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Security Option Row
// Debug: Reusable row component for security options
struct SecurityOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
                
                Text(subtitle)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            
            Spacer()
            
            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.positiveChange)
            }
        }
    }
}




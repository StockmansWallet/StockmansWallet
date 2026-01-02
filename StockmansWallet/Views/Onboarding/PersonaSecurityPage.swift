//
//  PersonaSecurityPage.swift
//  StockmansWallet
//
//  Page 2: Persona & Security
//

import SwiftUI

struct PersonaSecurityPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    
    private var isValid: Bool {
        userPrefs.userRole != nil && userPrefs.appsComplianceAccepted
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Persona & Security",
            subtitle: "Tell us about your role",
            currentPage: $currentPage,
            nextPage: 2
        ) {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Role")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Button(action: {
                            HapticManager.tap()
                            userPrefs.userRole = role
                        }) {
                            HStack {
                                Text(role.rawValue)
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                Spacer()
                                if userPrefs.userRole == role {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                        }
                        .buttonStyle(Theme.RowButtonStyle())
                        .padding(.horizontal, 20)
                        .accessibilityLabel(role.rawValue)
                        .accessibilityAddTraits(userPrefs.userRole == role ? [.isSelected] : [])
                    }
                }
                
                VStack(spacing: 12) {
                    Toggle(isOn: $userPrefs.twoFactorEnabled) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(Theme.accent)
                            Text("Enable Two-Factor Authentication")
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 52)
                    .stitchedCard()
                    
                    HStack(alignment: .top, spacing: 12) {
                        Button(action: {
                            HapticManager.tap()
                            userPrefs.appsComplianceAccepted.toggle()
                        }) {
                            Image(systemName: userPrefs.appsComplianceAccepted ? "checkmark.square.fill" : "square")
                                .foregroundStyle(userPrefs.appsComplianceAccepted ? Theme.accent : Theme.secondaryText)
                                .font(.system(size: 24))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonBorderShape(.roundedRectangle)
                        .accessibilityLabel(userPrefs.appsComplianceAccepted ? "APPs accepted" : "APPs not accepted")
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I accept the Australian Privacy Principles (APPs) compliance requirements")
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                            
                            Button(action: {
                                HapticManager.tap()
                                // TODO: Show APPs compliance details
                            }) {
                                Text("Learn more")
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.accent)
                                    .frame(height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonBorderShape(.roundedRectangle)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .stitchedCard()
                }
                .padding(.horizontal, 20)
            }
        }
    }
}


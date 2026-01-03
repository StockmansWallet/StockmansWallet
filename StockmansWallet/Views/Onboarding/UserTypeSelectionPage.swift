//
//  UserTypeSelectionPage.swift
//  StockmansWallet
//
//  Page 0: User Type Selection - First page of onboarding
//  Debug: Determines the onboarding flow path (Green = Farmer, Pink = Advisory)
//

import SwiftUI

// MARK: - User Type Selection Card Component
// Debug: Card-based design similar to RoleSelectionCard for consistency
struct UserTypeSelectionCard: View {
    let userType: UserType
    let isSelected: Bool
    let action: () -> Void
    
    // Debug: Icon and description for each user type
    private var typeIcon: String {
        switch userType {
        case .farmer:
            return "leaf.fill"
        case .advisory:
            return "briefcase.fill"
        }
    }
    
    private var typeDescription: String {
        switch userType {
        case .farmer:
            return "I own or manage livestock and property"
        case .advisory:
            return "I work with farmers and livestock businesses"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon with selection indicator
                ZStack {
                    // Background circle
                    Circle()
                        .fill(isSelected ? Theme.accent.opacity(0.2) : Theme.cardBackground)
                        .frame(width: 64, height: 64)
                    
                    // User type icon
                    Image(systemName: typeIcon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(isSelected ? Theme.accent : Theme.secondaryText)
                    
                    // Selection checkmark overlay
                    if isSelected {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Theme.accent)
                                    .background(
                                        Circle()
                                            .fill(Theme.backgroundGradient)
                                            .frame(width: 26, height: 26)
                                    )
                            }
                        }
                        .frame(width: 64, height: 64)
                    }
                }
                
                // Type label and description
                VStack(spacing: 8) {
                    Text(userType.rawValue)
                        .font(Theme.headline)
                        .foregroundStyle(isSelected ? Theme.primaryText : Theme.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(typeDescription)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(isSelected ? Theme.accent.opacity(0.1) : Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? Theme.accent.opacity(0.5) : Theme.separator.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(userType.rawValue)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(typeDescription)
    }
}

struct UserTypeSelectionPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    
    // Debug: All user roles in order (Farmer first, then advisory roles)
    private var allRoles: [UserRole] {
        [.farmerGrazier, .agribusinessBanker, .insurer, .livestockAgent, .accountant, .successionPlanner]
    }
    
    // Debug: Validation - role selection is required
    private var isValid: Bool {
        userPrefs.userRole != nil
    }
    
    var body: some View {
        // Debug: Use a custom layout instead of OnboardingPageTemplate since this is page 0
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 24) {
                Text("Select User")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
            }
            .padding(.bottom, 32)
            
            // Scrollable content
            ScrollView {
                VStack(spacing: 20) {
                    // Debug: Grid layout for all user roles (2 columns)
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(allRoles, id: \.self) { role in
                            RoleSelectionCard(
                                role: role,
                                isSelected: userPrefs.userRole == role,
                                action: {
                                    HapticManager.tap()
                                    userPrefs.userRole = role
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundGradient)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Footer section
            VStack(spacing: 0) {
                // No progress dots on first page
                
                // Continue button
                Button(action: {
                    HapticManager.tap()
                    guard userPrefs.userRole != nil else {
                        HapticManager.error()
                        return
                    }
                    
                    withAnimation {
                        currentPage = 1
                    }
                }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
                .disabled(!isValid)
                .opacity(isValid ? 1.0 : 0.6)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                .accessibilityLabel("Continue to next page")
                .accessibilityHint(isValid ? "" : "Please select your user type")
                
                // Debug: Show validation hint if invalid
                if !isValid {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Theme.secondaryText)
                            .font(.caption)
                        Text("Please select your user type to continue")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .padding(.bottom, 16)
                }
            }
            .background(Theme.backgroundGradient)
        }
    }
}


//
//  YourRolePage.swift
//  StockmansWallet
//
//  Page 2: Your Role
//

import SwiftUI

// MARK: - Role Selection Card Component
// Debug: Improved card-based design for role selection with icons and better visual feedback
struct RoleSelectionCard: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void
    
    // Debug: Icon mapping for each role type
    private var roleIcon: String {
        switch role {
        case .farmerGrazier:
            return "leaf.fill"
        case .agribusinessBanker:
            return "building.2.fill"
        case .insurer:
            return "shield.checkered"
        case .livestockAgent:
            return "person.2.fill"
        case .accountant:
            return "chart.line.text.clipboard.fill"
        case .successionPlanner:
            return "doc.text.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon with selection indicator
                ZStack {
                    // Background circle
                    Circle()
                        .fill(isSelected ? Theme.accentColor.opacity(0.2) : Theme.cardBackground)
                        .frame(width: 56, height: 56)
                    
                    // Role icon
                    Image(systemName: roleIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(isSelected ? Theme.accentColor : Theme.secondaryText)
                    
                    // Selection checkmark overlay
                    if isSelected {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.accentColor)
                                    .background(
                                        Circle()
                                            .fill(Theme.background) // Debug: Use solid background color instead
                                            .frame(width: 24, height: 24)
                                    )
                            }
                        }
                        .frame(width: 56, height: 56)
                    }
                }
                
                // Role label
                Text(role.rawValue)
                    .font(Theme.body)
                    .foregroundStyle(isSelected ? Theme.primaryText : Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(isSelected ? Theme.accentColor.opacity(0.1) : Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? Theme.accentColor.opacity(0.5) : Theme.separator.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(role.rawValue)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Tap to select this role")
    }
}

struct YourRolePage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    
    // Debug: Validation - role selection is required
    private var isValid: Bool {
        userPrefs.userRole != nil
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Your Role",
            subtitle: "Tell us about your role in the industry",
            currentPage: $currentPage,
            nextPage: 2,
            isValid: isValid
        ) {
            // Debug: Organized layout following HIG - card-based grid layout
            VStack(spacing: 20) {
                // Debug: Grid layout for better visual organization (2 columns)
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(UserRole.allCases, id: \.self) { role in
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
                
                // Debug: Show validation hint if no role selected
                if userPrefs.userRole == nil {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Theme.secondaryText)
                            .font(.caption)
                        Text("Please select your role to continue")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
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


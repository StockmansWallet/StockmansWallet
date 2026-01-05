//
//  UserTypeSelectionPage.swift
//  StockmansWallet
//
//  Page 0: User Type Selection - First page of onboarding
//  Debug: Determines the onboarding flow path (Farmer vs Advisory)
//

import SwiftUI

// MARK: - User Type Selection Card Component
// Debug: Clean card design for primary user type selection (Farmer or Advisory)
// No stroke, no inner box - just large icon and label with solid background fill
struct UserTypeSelectionCard: View {
    let userType: UserType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                // User type icon - no background box, larger icon
                Group {
                    if userType == .farmer {
                        // Debug: Use custom Hoof icon from assets
                        Image("Hoof")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                    } else {
                        // Debug: Use message bubble with "i" for Advisory
                        Image(systemName: "message.fill")
                            .font(.system(size: 64, weight: .medium))
                            .overlay(
                                Text("i")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(isSelected ? Theme.accent : Theme.secondaryText)
                                    .offset(y: -4)
                            )
                    }
                }
                .foregroundStyle(isSelected ? Theme.accent : Theme.secondaryText)
                
                // Type label
                Text(userType == .farmer ? "Farmer" : "Advisory")
                    .font(Theme.headline)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(isSelected ? Color(hex: "FF7F00").opacity(0.15) : Color.white.opacity(0.03))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(userType == .farmer ? "Farmer" : "Advisory")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Advisory Sub-Role Icon Component
// Debug: Informational icons showing different advisory roles (not clickable)
struct AdvisorySubRoleIcon: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Theme.cardBackground)
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
            }
            
            Text(label)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct UserTypeSelectionPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    
    // Debug: Track which user type is selected (Farmer or Advisory)
    @State private var selectedUserType: UserType?
    
    // Debug: Validation - user type selection is required
    private var isValid: Bool {
        selectedUserType != nil
    }
    
    // Debug: Advisory sub-roles with their icons
    private let advisorySubRoles: [(icon: String, label: String)] = [
        ("building.columns.fill", "Banker"),
        ("checkmark.shield.fill", "Insurer"),
        ("figure.2", "Livestock\nAgent"),
        ("doc.text.fill", "Accountant"),
        ("person.2.fill", "Succession\nPlanner"),
        ("chart.line.uptrend.xyaxis", "Valuer")
    ]
    
    var body: some View {
        // Debug: Custom layout for user type selection page
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Button(action: {
                    HapticManager.tap()
                    // Debug: Close button - implement dismissal if needed
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .frame(width: Theme.minimumTouchTarget, height: Theme.minimumTouchTarget)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Scrollable content
            ScrollView {
                VStack(spacing: 32) {
                    // Title and subtitle
                    VStack(spacing: 12) {
                        Text("Select your account type")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Each account type unlocks tools and features specific to how you work with livestock data, valuations, and reports.")
                            .font(Theme.body)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    
                    // User type cards (Farmer and Advisory)
                    HStack(spacing: 16) {
                        UserTypeSelectionCard(
                            userType: .farmer,
                            isSelected: selectedUserType == .farmer,
                            action: {
                                HapticManager.tap()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedUserType = .farmer
                                    // Debug: Set user role to Farmer/Grazier
                                    userPrefs.userRole = .farmerGrazier
                                }
                            }
                        )
                        
                        UserTypeSelectionCard(
                            userType: .advisory,
                            isSelected: selectedUserType == .advisory,
                            action: {
                                HapticManager.tap()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedUserType = .advisory
                                    // Debug: Clear specific role - will be selected on next page
                                    userPrefs.userRole = nil
                                }
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Description text based on selection
                    if let userType = selectedUserType {
                        VStack(spacing: 24) {
                            // Description
                            Text(userType == .farmer
                                ? "Track your livestock as a financial asset.\nSee real-time herd value, performance, and market-driven insights across your operation."
                                : "Access livestock valuations to support lending, insurance, planning, and professional advice.\nView consistent data and generate reports to support confident decisions.")
                                .font(Theme.body)
                                .foregroundStyle(Theme.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 32)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            
                            // Advisory sub-roles (only shown when Advisory is selected)
                            if userType == .advisory {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 20) {
                                    ForEach(advisorySubRoles, id: \.label) { role in
                                        AdvisorySubRoleIcon(icon: role.icon, label: role.label)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: selectedUserType)
                    }
                }
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundGradient)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Footer section
            VStack(spacing: 16) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == 0 ? Theme.accent : Theme.secondaryText.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 16)
                .accessibilityLabel("Page 1 of 3")
                
                // Next button
                Button(action: {
                    HapticManager.tap()
                    guard selectedUserType != nil else {
                        HapticManager.error()
                        return
                    }
                    
                    withAnimation {
                        currentPage = 1
                    }
                }) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
                .disabled(!isValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .accessibilityLabel("Continue to next page")
                .accessibilityHint(isValid ? "" : "Please select your account type")
            }
        }
    }
}


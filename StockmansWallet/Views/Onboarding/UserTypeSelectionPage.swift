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
                        Image("farmer_icon")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                    } else {
                        Image("sprout_icon")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                    }
                }
                .foregroundStyle(isSelected ? Theme.accent : Theme.secondaryText)
                
                // Type label
                Text(userType == .farmer ? "Farmer" : "Advisor")
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

struct UserTypeSelectionPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    
    // Debug: Track which user type is selected (Farmer or Advisory)
    @State private var selectedUserType: UserType?
    
    // Debug: Validation - user type selection is required
    private var isValid: Bool {
        selectedUserType != nil
    }
    
    var body: some View {
        // Debug: Custom layout for user type selection page
        VStack(spacing: 0) {
            // Scrollable content
            ScrollView {
                // Top spacing to replace removed header
                Color.clear
                    .frame(height: 40)
                    .accessibilityHidden(true)
                

                VStack(spacing: 32) {
                    // Title and subtitle
                    VStack(spacing: 12) {
                        Text("Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Stockman's Wallet has two different account types. Each account unlocks tools and views specific to your role. Choose the option that best matches how you work with livestock value and reporting.")
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
                                withAnimation(.easeInOut(duration: 0.3)) {
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
                                withAnimation(.easeInOut(duration: 0.3)) {
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
                        VStack(spacing: 16) {
                            // Heading
                            Text(userType == .farmer ? "Farmers / Graziers" : "Industry Advisors")
                                .font(Theme.title3)
                                .foregroundStyle(Theme.primaryText)
                                .multilineTextAlignment(.center)
                            
                            // Description
                            Text(userType == .farmer
                                ? "Track your livestock as a financial asset.\nSee real-time herd value, performance, and market-driven insights across your operation."
                                : "Access livestock valuations to support lending, insurance, planning, and professional advice.\nView consistent data and generate reports to support confident decisions.")
                                .font(Theme.body)
                                .foregroundStyle(Theme.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 32)
                        .id(userType) // Debug: Force SwiftUI to treat each selection as a separate view
                        .transition(.opacity)
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
                // Debug: Progress dots - updated to show full onboarding flow (4 pages total)
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index == 0 ? Theme.accent : Theme.secondaryText.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.top, 16)
                .accessibilityLabel("Page 1 of 4")
                
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
                .opacity(isValid ? 1.0 : 0.5) // Debug: Visual feedback for disabled state
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .accessibilityLabel("Continue to next page")
                .accessibilityHint(isValid ? "" : "Please select your account type")
            }
        }
    }
}


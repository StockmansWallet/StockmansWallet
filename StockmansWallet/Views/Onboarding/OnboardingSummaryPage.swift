//
//  OnboardingSummaryPage.swift
//  StockmansWallet
//
//  Final onboarding page - Summary and completion
//  Debug: Shows summary of entered information before completing setup
//

import SwiftUI

struct OnboardingSummaryPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    var onComplete: () -> Void
    
    // Debug: Determine if user is farmer or advisory
    private var isFarmer: Bool {
        userPrefs.userRole == .farmerGrazier
    }
    
    // Debug: Both paths now have 5 pages (Security & Summary are shared)
    private var totalPages: Int {
        5
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Summary",
            subtitle: "Review your information",
            currentPage: $currentPage,
            nextPage: 0, // Not used for last page
            isValid: true,
            isLastPage: true,
            totalPages: totalPages,
            onComplete: onComplete
        ) {
            // Debug: Summary cards showing entered information
            VStack(spacing: 20) {
                // Personal Information Summary
                SummaryCard(title: "Personal Information") {
                    VStack(spacing: 12) {
                        SummaryRow(
                            icon: "person.fill",
                            label: "Name",
                            value: "\(userPrefs.firstName ?? "") \(userPrefs.lastName ?? "")"
                        )
                        
                        SummaryRow(
                            icon: "envelope.fill",
                            label: "Email",
                            value: userPrefs.email ?? ""
                        )
                        
                        SummaryRow(
                            icon: isFarmer ? "leaf.fill" : "briefcase.fill",
                            label: "Role",
                            value: userPrefs.userRole?.rawValue ?? "Not set"
                        )
                    }
                }
                
                // Security Summary
                SummaryCard(title: "Security") {
                    VStack(spacing: 12) {
                        SummaryRow(
                            icon: "lock.shield.fill",
                            label: "Two-Factor Auth",
                            value: userPrefs.twoFactorEnabled ? "Enabled" : "Disabled"
                        )
                        
                        SummaryRow(
                            icon: "checkmark.shield.fill",
                            label: "Privacy Compliance",
                            value: userPrefs.appsComplianceAccepted ? "Accepted" : "Not Accepted"
                        )
                    }
                }
                
                // Conditional: Property or Company Information
                if isFarmer {
                    // Property Information Summary
                    SummaryCard(title: "Property Information") {
                        VStack(spacing: 12) {
                            if let propertyName = userPrefs.propertyName {
                                SummaryRow(
                                    icon: "house.fill",
                                    label: "Property Name",
                                    value: propertyName
                                )
                            }
                            
                            if let propertyPIC = userPrefs.propertyPIC {
                                SummaryRow(
                                    icon: "number",
                                    label: "PIC",
                                    value: propertyPIC
                                )
                            }
                            
                            SummaryRow(
                                icon: "map.fill",
                                label: "State",
                                value: userPrefs.defaultState
                            )
                            
                            if userPrefs.latitude != nil && userPrefs.longitude != nil {
                                SummaryRow(
                                    icon: "location.fill",
                                    label: "GPS Location",
                                    value: "Captured"
                                )
                            }
                        }
                    }
                } else {
                    // Company Information Summary
                    SummaryCard(title: "Company Information") {
                        VStack(spacing: 12) {
                            if let companyName = userPrefs.companyName {
                                SummaryRow(
                                    icon: "building.2.fill",
                                    label: "Company",
                                    value: companyName
                                )
                            }
                            
                            if let companyType = userPrefs.companyType {
                                SummaryRow(
                                    icon: "briefcase.fill",
                                    label: "Type",
                                    value: companyType
                                )
                            }
                            
                            if let roleInCompany = userPrefs.roleInCompany {
                                SummaryRow(
                                    icon: "person.text.rectangle.fill",
                                    label: "Your Role",
                                    value: roleInCompany
                                )
                            }
                            
                            if let address = userPrefs.companyAddress, !address.isEmpty {
                                SummaryRow(
                                    icon: "mappin.circle.fill",
                                    label: "Address",
                                    value: address
                                )
                            }
                        }
                    }
                }
                
                // Info message
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Theme.accent)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You're all set!")
                            .font(Theme.subheadline)
                            .foregroundStyle(Theme.primaryText)
                        
                        Text("You can update these details anytime in Settings")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .fill(Theme.accent.opacity(0.1))
                )
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Summary Card Component
struct SummaryCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.separator.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Summary Row Component
struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                
                Text(value)
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


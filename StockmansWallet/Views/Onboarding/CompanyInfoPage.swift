//
//  CompanyInfoPage.swift
//  StockmansWallet
//
//  Company Information Page for Advisory Users
//  Debug: Part of pink path onboarding flow for non-farmer users
//

import SwiftUI

struct CompanyInfoPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    
    // Debug: iOS 26 HIG - Focus state for proper keyboard navigation between fields
    @FocusState private var focusedField: Field?
    
    // Debug: Enum to track which field is focused for keyboard navigation
    private enum Field: Hashable {
        case companyName
        case roleInCompany
        case companyAddress
    }
    
    // Debug: Common company types based on user roles
    private let companyTypes = [
        "Bank/Financial Institution",
        "Insurance Company",
        "Livestock Agency",
        "Accounting Firm",
        "Advisory/Consulting Firm",
        "Other"
    ]
    
    // Debug: Validation - company name and role are required
    private var isValid: Bool {
        !(userPrefs.companyName ?? "").isEmpty && 
        !(userPrefs.roleInCompany ?? "").isEmpty
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Company Information",
            subtitle: "Tell us about your organization",
            currentPage: $currentPage,
            nextPage: 3, // Go to Security/Privacy (shared page)
            isValid: isValid,
            totalPages: 6 // Debug: Both paths now have 6 pages (includes Subscription)
        ) {
            // Debug: iOS 26 HIG - Organized layout with proper keyboard navigation
            VStack(spacing: 24) {
                // Company Details Fields
                // Debug: Removed section headings per user request - cleaner UI
                VStack(spacing: 16) {
                    TextField("Company Name", text: Binding(
                        get: { userPrefs.companyName ?? "" },
                        set: { userPrefs.companyName = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .autocapitalization(.words)
                    .submitLabel(.next) // Debug: iOS 26 HIG - Proper return key label
                    .focused($focusedField, equals: .companyName)
                    .onSubmit {
                        // Debug: iOS 26 HIG - Move to next field on return
                        focusedField = .roleInCompany
                    }
                    .accessibilityLabel("Company name")
                        
                    // Company Type Menu
                    Menu {
                        ForEach(companyTypes, id: \.self) { type in
                            Button(action: {
                                HapticManager.tap()
                                userPrefs.companyType = type
                            }) {
                                HStack {
                                    Text(type)
                                    if userPrefs.companyType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(userPrefs.companyType ?? "Select Company Type")
                                .font(Theme.body)
                                .foregroundStyle((userPrefs.companyType ?? "").isEmpty ? Theme.secondaryText : Theme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(Theme.secondaryText)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(Theme.RowButtonStyle())
                    .accessibilityLabel("Select company type")
                    .accessibilityValue(userPrefs.companyType ?? "Not selected")
                    
                    TextField("Your Role in Company", text: Binding(
                        get: { userPrefs.roleInCompany ?? "" },
                        set: { userPrefs.roleInCompany = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .autocapitalization(.words)
                    .submitLabel(.next) // Debug: iOS 26 HIG - Proper return key label
                    .focused($focusedField, equals: .roleInCompany)
                    .onSubmit {
                        // Debug: iOS 26 HIG - Move to next field on return
                        focusedField = .companyAddress
                    }
                    .accessibilityLabel("Your role in company")
                    .accessibilityHint("e.g., Account Manager, Advisor, Agent")
                    
                    TextField("Full Address (Optional)", text: Binding(
                        get: { userPrefs.companyAddress ?? "" },
                        set: { userPrefs.companyAddress = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .autocapitalization(.words)
                    .submitLabel(.done) // Debug: iOS 26 HIG - Done label for last field
                    .focused($focusedField, equals: .companyAddress)
                    .onSubmit {
                        // Debug: iOS 26 HIG - Dismiss keyboard on last field
                        focusedField = nil
                    }
                    .accessibilityLabel("Company full address")
                    .accessibilityHint("Optional")
                }
                .padding(.horizontal, 20)
                
                // Debug: Show validation feedback when form is invalid
                if !isValid && (!(userPrefs.companyName ?? "").isEmpty || !(userPrefs.roleInCompany ?? "").isEmpty) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Theme.secondaryText)
                            .font(.caption)
                        Text("Company name and your role are required to continue")
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


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
    
    // Debug: State for custom advisory type when "Other" is selected
    @State private var customAdvisoryType: String = ""
    
    // Debug: Enum to track which field is focused for keyboard navigation
    private enum Field: Hashable {
        case customAdvisoryType
        case companyName
        case roleInCompany
        case postCode
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
    
    // Debug: Validation - company name, role, and post code are required
    private var isValid: Bool {
        let hasCompanyName = !(userPrefs.companyName ?? "").isEmpty
        let hasRole = !(userPrefs.roleInCompany ?? "").isEmpty
        let hasPostCode = !(userPrefs.companyAddress ?? "").isEmpty
        let hasCompanyType = !(userPrefs.companyType ?? "").isEmpty
        
        // Debug: If "Other" is selected, custom advisory type must be filled
        let hasValidType = userPrefs.companyType != "Other" || !customAdvisoryType.isEmpty
        
        return hasCompanyName && hasRole && hasPostCode && hasCompanyType && hasValidType
    }
    
    // Debug: Dynamic placeholder for company name based on selected business type
    private var companyNamePlaceholder: String {
        guard let companyType = userPrefs.companyType, !companyType.isEmpty else {
            return "Company Name"
        }
        
        // Debug: If "Other" is selected, use the custom advisory type
        if companyType == "Other" {
            if customAdvisoryType.isEmpty {
                return "Company Name"
            }
            return "\(customAdvisoryType) Name"
        }
        
        // Debug: Use the selected company type
        return "\(companyType) Name"
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Advisory Information",
            subtitle: "Tell us about the business and your role",
            currentPage: $currentPage,
            nextPage: 2, // Go to Welcome/Completion (shared page)
            isValid: isValid,
            totalPages: 4 // Debug: Both paths now have 4 pages (About You removed, captured in Sign Up)
        ) {
            // Debug: iOS 26 HIG - Organized layout with proper keyboard navigation
            VStack(spacing: 24) {
                // Company Details Fields
                // Debug: Removed section headings per user request - cleaner UI
                VStack(spacing: 16) {
                    // Debug: Company Type Menu - NOW FIRST FIELD
                    Menu {
                        ForEach(companyTypes, id: \.self) { type in
                            Button(action: {
                                HapticManager.tap()
                                userPrefs.companyType = type
                                // Debug: Clear custom advisory type if switching away from "Other"
                                if type != "Other" {
                                    customAdvisoryType = ""
                                }
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
                            Text(userPrefs.companyType ?? "Select Business Type")
                                .font(Theme.body)
                                .foregroundStyle((userPrefs.companyType ?? "").isEmpty ? Theme.secondaryText : Theme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(Theme.secondaryText)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(Theme.RowButtonStyle())
                    .accessibilityLabel("Select business type")
                    .accessibilityValue(userPrefs.companyType ?? "Not selected")
                    
                    // Debug: Custom Advisory Type field - only shown when "Other" is selected
                    if userPrefs.companyType == "Other" {
                        TextField("Enter Advisory Type", text: $customAdvisoryType)
                            .textFieldStyle(OnboardingTextFieldStyle())
                            .autocapitalization(.words)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .customAdvisoryType)
                            .onSubmit {
                                // Debug: Move to company name field
                                focusedField = .companyName
                            }
                            .accessibilityLabel("Custom advisory type")
                            .accessibilityHint("e.g., Law Firm, Veterinary Practice")
                    }
                    
                    // Debug: Company Name with dynamic placeholder
                    TextField(companyNamePlaceholder, text: Binding(
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
                    
                    // Debug: Role field with updated placeholder
                    TextField("Your Role", text: Binding(
                        get: { userPrefs.roleInCompany ?? "" },
                        set: { userPrefs.roleInCompany = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .autocapitalization(.words)
                    .submitLabel(.next) // Debug: iOS 26 HIG - Proper return key label
                    .focused($focusedField, equals: .roleInCompany)
                    .onSubmit {
                        // Debug: iOS 26 HIG - Move to next field on return
                        focusedField = .postCode
                    }
                    .accessibilityLabel("Your role")
                    .accessibilityHint("e.g., Account Manager, Advisor, Agent")
                    
                    // Debug: Post Code field (required, numeric keyboard, Australian postcode)
                    TextField("Post Code", text: Binding(
                        get: { userPrefs.companyAddress ?? "" },
                        set: { userPrefs.companyAddress = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .keyboardType(.numberPad) // Debug: Numeric keyboard for postcode
                    .submitLabel(.done) // Debug: iOS 26 HIG - Done label for last field
                    .focused($focusedField, equals: .postCode)
                    .onSubmit {
                        // Debug: iOS 26 HIG - Dismiss keyboard on last field
                        focusedField = nil
                    }
                    .accessibilityLabel("Post code")
                    .accessibilityHint("Australian postcode required")
                }
                .padding(.horizontal, 20)
                
                // Debug: Show validation feedback when form is invalid
                if !isValid && (!(userPrefs.companyName ?? "").isEmpty || !(userPrefs.roleInCompany ?? "").isEmpty || !(userPrefs.companyAddress ?? "").isEmpty) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Theme.secondaryText)
                            .font(.caption)
                        Text("All fields are required to continue")
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


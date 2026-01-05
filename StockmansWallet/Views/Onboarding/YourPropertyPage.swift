//
//  YourPropertyPage.swift
//  StockmansWallet
//
//  Page 4: Your Property
//

import SwiftUI

struct YourPropertyPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    
    // Debug: iOS 26 HIG - Focus state for proper keyboard navigation between fields
    @FocusState private var focusedField: Field?
    
    // Debug: Enum to track which field is focused for keyboard navigation
    private enum Field: Hashable {
        case propertyName
        case propertyPIC
    }
    
    // Debug: Validation - property name and state are required
    private var isValid: Bool {
        !(userPrefs.propertyName ?? "").isEmpty && !userPrefs.defaultState.isEmpty
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Your Property",
            subtitle: "Tell us about your property",
            currentPage: $currentPage,
            nextPage: 3,
            isValid: isValid,
            totalPages: 6 // Debug: Farmer path has 6 pages (includes Subscription)
        ) {
            // Debug: iOS 26 HIG - Organized layout with proper keyboard navigation
            VStack(spacing: 24) {
                // Property Information Fields
                // Debug: Removed section heading per user request - cleaner UI
                VStack(spacing: 16) {
                    TextField("Property Name", text: Binding(
                        get: { userPrefs.propertyName ?? "" },
                        set: { userPrefs.propertyName = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .autocapitalization(.words)
                    .submitLabel(.next) // Debug: iOS 26 HIG - Proper return key label
                    .focused($focusedField, equals: .propertyName)
                    .onSubmit {
                        // Debug: iOS 26 HIG - Move to next field on return
                        focusedField = .propertyPIC
                    }
                    .accessibilityLabel("Property name")
                    
                    TextField("Property Identification Code (PIC)", text: Binding(
                        get: { userPrefs.propertyPIC ?? "" },
                        set: { userPrefs.propertyPIC = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .autocapitalization(.none)
                    .submitLabel(.done) // Debug: iOS 26 HIG - Done label for last field
                    .focused($focusedField, equals: .propertyPIC)
                    .onSubmit {
                        // Debug: iOS 26 HIG - Dismiss keyboard on last field
                        focusedField = nil
                    }
                    .accessibilityLabel("Property Identification Code")
                    .accessibilityHint("Optional")
                }
                .padding(.horizontal, 20)
                
                // State Selection
                // Debug: Removed "Location" heading - cleaner UI
                VStack(spacing: 16) {
                    // State Selection Menu
                    Menu {
                        ForEach(ReferenceData.states, id: \.self) { state in
                            Button(action: {
                                HapticManager.tap()
                                userPrefs.defaultState = state
                            }) {
                                HStack {
                                    Text(state)
                                    if userPrefs.defaultState == state {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(userPrefs.defaultState.isEmpty ? "Select State" : userPrefs.defaultState)
                                .font(Theme.body)
                                .foregroundStyle(userPrefs.defaultState.isEmpty ? Theme.secondaryText : Theme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(Theme.secondaryText)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(Theme.RowButtonStyle())
                    .accessibilityLabel("Select state")
                    .accessibilityValue(userPrefs.defaultState)
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
        }
    }
}


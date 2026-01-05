//
//  YourPropertyPage.swift
//  StockmansWallet
//
//  Page 2 (Farmer): Primary Property
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
        case propertyAddress
    }
    
    // Debug: Farm-specific property roles
    private let propertyRoles = [
        "Owner",
        "Manager"
    ]
    
    // Debug: Track if "Other" is selected for custom role input
    @State private var showingRolePicker = false
    @State private var tempSelectedRole: String?
    @State private var tempCustomRole = ""
    @State private var isOtherSelected = false
    
    // Debug: Validation - property name, role, and state are required
    private var isValid: Bool {
        let hasPropertyName = !(userPrefs.propertyName ?? "").isEmpty
        let hasRole = !(userPrefs.propertyRole ?? "").isEmpty
        let hasState = !userPrefs.defaultState.isEmpty
        
        return hasPropertyName && hasRole && hasState
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Primary Property",
            subtitle: "Tell us about your primary property",
            currentPage: $currentPage,
            nextPage: 3,
            isValid: isValid,
            totalPages: 5 // Debug: Farmer path has 5 pages (Security moved to Terms sheet)
        ) {
            // Debug: iOS 26 HIG - Organized layout with proper keyboard navigation and section groupings
            VStack(spacing: 24) {
                // Property Name & ID Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Property Name & ID")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        TextField("Property Name", text: Binding(
                            get: { userPrefs.propertyName ?? "" },
                            set: { userPrefs.propertyName = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .autocapitalization(.words)
                        .textContentType(.organizationName)
                        .submitLabel(.next) // Debug: iOS 26 HIG - Proper return key label
                        .focused($focusedField, equals: .propertyName)
                        .onSubmit {
                            // Debug: iOS 26 HIG - Move to next field on return
                            focusedField = .propertyPIC
                        }
                        .accessibilityLabel("Property name")
                        
                        TextField("PIC/ID", text: Binding(
                            get: { userPrefs.propertyPIC ?? "" },
                            set: { userPrefs.propertyPIC = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .autocapitalization(.allCharacters)
                        .submitLabel(.next) // Debug: iOS 26 HIG - Proper return key label
                        .focused($focusedField, equals: .propertyPIC)
                        .onSubmit {
                            // Debug: iOS 26 HIG - Move to next field on return
                            focusedField = .propertyAddress
                        }
                        .accessibilityLabel("Property Identification Code")
                        .accessibilityHint("Optional")
                    }
                    .padding(.horizontal, 20)
                }
                
                // Property Address Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Property Address")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        TextField("Address", text: Binding(
                            get: { userPrefs.propertyAddress ?? "" },
                            set: { userPrefs.propertyAddress = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .autocapitalization(.words)
                        .textContentType(.fullStreetAddress)
                        .submitLabel(.done) // Debug: iOS 26 HIG - Done label for last text field
                        .focused($focusedField, equals: .propertyAddress)
                        .onSubmit {
                            // Debug: iOS 26 HIG - Dismiss keyboard on last field
                            focusedField = nil
                        }
                        .accessibilityLabel("Property address")
                        .accessibilityHint("Optional")
                        
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
                                Text(userPrefs.defaultState.isEmpty ? "State" : userPrefs.defaultState)
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
                
                // Your Role Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Role")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        // Debug: iOS 26 HIG - Button that presents sheet for role selection
                        Button(action: {
                            HapticManager.tap()
                            showingRolePicker = true
                            // Initialize temp values with current selection
                            if let currentRole = userPrefs.propertyRole {
                                if propertyRoles.contains(currentRole) {
                                    tempSelectedRole = currentRole
                                    isOtherSelected = false
                                } else {
                                    tempSelectedRole = nil
                                    tempCustomRole = currentRole
                                    isOtherSelected = true
                                }
                            } else {
                                tempSelectedRole = nil
                                tempCustomRole = ""
                                isOtherSelected = false
                            }
                        }) {
                            HStack {
                                Text(userPrefs.propertyRole ?? "*Role")
                                    .font(Theme.body)
                                    .foregroundStyle((userPrefs.propertyRole == nil || userPrefs.propertyRole?.isEmpty == true) ? Theme.secondaryText : Theme.primaryText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Theme.secondaryText)
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(Theme.RowButtonStyle())
                        .accessibilityLabel("Select role")
                        .accessibilityValue(userPrefs.propertyRole ?? "Not selected")
                    }
                    .padding(.horizontal, 20)
                }
                
                // Note about additional properties
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Theme.secondaryText)
                        .font(.caption)
                    Text("Additional properties can be added later in user settings")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(.top, 8)
        }
        .sheet(isPresented: $showingRolePicker) {
            RolePickerSheet(
                propertyRoles: propertyRoles,
                selectedRole: $tempSelectedRole,
                customRole: $tempCustomRole,
                isOtherSelected: $isOtherSelected,
                onSave: {
                    // Debug: Save the selected role when user taps Done
                    if isOtherSelected {
                        userPrefs.propertyRole = tempCustomRole.isEmpty ? nil : tempCustomRole
                    } else if let role = tempSelectedRole {
                        userPrefs.propertyRole = role
                    }
                    showingRolePicker = false
                }
            )
        }
    }
}

// MARK: - Role Picker Sheet
// Debug: iOS 26 HIG-compliant sheet for role selection with inline "Other" text field
struct RolePickerSheet: View {
    let propertyRoles: [String]
    @Binding var selectedRole: String?
    @Binding var customRole: String
    @Binding var isOtherSelected: Bool
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCustomRoleFocused: Bool
    
    var body: some View {
        NavigationStack {
            List {
                // Predefined roles
                ForEach(propertyRoles, id: \.self) { role in
                    Button(action: {
                        HapticManager.tap()
                        selectedRole = role
                        isOtherSelected = false
                        customRole = ""
                    }) {
                        HStack {
                            Text(role)
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            if selectedRole == role && !isOtherSelected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                
                // Other option with inline text field
                Section {
                    Button(action: {
                        HapticManager.tap()
                        isOtherSelected = true
                        selectedRole = nil
                        isCustomRoleFocused = true
                    }) {
                        HStack {
                            Text("Other")
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            if isOtherSelected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .listRowBackground(Theme.cardBackground)
                    
                    // Debug: Show text field inline when Other is selected
                    if isOtherSelected {
                        TextField("Enter your role", text: $customRole)
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                            .focused($isCustomRoleFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                isCustomRoleFocused = false
                            }
                            .listRowBackground(Theme.cardBackground)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient)
            .navigationTitle("Select Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(isOtherSelected && customRole.isEmpty)
                }
            }
        }
    }
}


//
//  PrimaryPropertyPage.swift
//  StockmansWallet
//
//  Page 2 (Farmer): Primary Property - 3-Step Progressive Flow
//  Debug: Step 1: Essentials, Step 2: Optional Details, Step 3: Additional Properties
//

import SwiftUI
import SwiftData

struct PrimaryPropertyPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    @Environment(\.modelContext) private var modelContext
    
    // Debug: 3-step progressive flow
    @State private var propertyStep: PropertyStep = .essentials
    
    // Debug: Local state for property data
    @State private var propertyName: String = ""
    @State private var state: String = "QLD"
    @State private var herdSize: String? = nil
    @State private var propertyPIC: String = ""
    @State private var address: String = ""
    @State private var role: String? = nil
    
    // Debug: Additional properties
    @State private var additionalProperties: [AdditionalPropertyData] = []
    @State private var showingAddProperty = false
    
    // Debug: iOS 26 HIG - Focus state for proper keyboard navigation between fields
    @FocusState private var focusedField: Field?
    
    // Debug: Enum to track which field is focused for keyboard navigation
    private enum Field: Hashable {
        case propertyName
        case propertyPIC
        case propertyAddress
    }
    
    // Debug: Property onboarding steps
    enum PropertyStep {
        case essentials      // Step 1: Name, State
        case details         // Step 2: PIC, Address, Role (optional)
        case additional      // Step 3: Add more properties (optional)
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
    
    // Debug: Step-specific validation
    private var canProceedFromCurrentStep: Bool {
        switch propertyStep {
        case .essentials:
            // Step 1: Only name and state required
            return !propertyName.isEmpty && !state.isEmpty
        case .details:
            // Step 2: All optional, can always proceed
            return true
        case .additional:
            // Step 3: Can always proceed
            return true
        }
    }
    
    var body: some View {
        // Debug: Layout matches UserTypeSelectionPage structure with progress dots and button at bottom
        ZStack(alignment: .top) {
            // Background gradient
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text(stepTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(stepSubtitle)
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 80)
                .padding(.bottom, 32)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        Group {
                            switch propertyStep {
                            case .essentials:
                                step1EssentialsView
                            case .details:
                                step2DetailsView
                            case .additional:
                                step3AdditionalView
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .animation(.easeInOut(duration: 0.3), value: propertyStep)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Debug: Footer section with progress dots and button matching UserTypeSelectionPage
                VStack(spacing: 16) {
                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(index <= propertyStepIndex ? Theme.accentColor : Theme.secondaryText.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.top, 16)
                    .accessibilityLabel("Step \(propertyStepIndex + 1) of 3")
                    
                    // Continue button
                    Button(action: {
                        HapticManager.success()
                        handleNextStep()
                    }) {
                        Text(propertyStep == .additional ? "Finish Setup" : "Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .disabled(!canProceedFromCurrentStep)
                    .opacity(canProceedFromCurrentStep ? 1.0 : 0.5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .accessibilityLabel(propertyStep == .additional ? "Finish Setup" : "Continue to next step")
                    .accessibilityHint(canProceedFromCurrentStep ? "" : "Please complete required fields")
                }
            }
            
            // Back button (top left)
            if propertyStep != .essentials || currentPage > 0 {
                HStack {
                    Button(action: {
                        HapticManager.tap()
                        if propertyStep == .essentials {
                            currentPage -= 1
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                moveBackStep()
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(Theme.body)
                        }
                        .foregroundStyle(Theme.primaryText)
                        .frame(minWidth: 44, minHeight: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingRolePicker) {
            RolePickerSheet(
                propertyRoles: propertyRoles,
                selectedRole: $tempSelectedRole,
                customRole: $tempCustomRole,
                isOtherSelected: $isOtherSelected,
                onSave: {
                    // Debug: Save the selected role when user taps Done
                    if isOtherSelected {
                        role = tempCustomRole.isEmpty ? nil : tempCustomRole
                    } else if let selectedRole = tempSelectedRole {
                        role = selectedRole
                    }
                    showingRolePicker = false
                }
            )
        }
        .sheet(isPresented: $showingAddProperty) {
            AddAdditionalPropertySheet(
                onSave: { newProperty in
                    additionalProperties.append(newProperty)
                }
            )
        }
    }
    
    // MARK: - Step Views
    
    // Debug: Step 1 - Essential Information (Required)
    private var step1EssentialsView: some View {
        VStack(spacing: 24) {
            // Property Name Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Property Name")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                    .padding(.horizontal, 20)
                
                TextField("Enter property name", text: $propertyName)
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .autocapitalization(.words)
                    .textContentType(.organizationName)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .propertyName)
                    .onSubmit {
                        focusedField = nil
                    }
                    .accessibilityLabel("Property name")
                    .padding(.horizontal, 20)
            }
            
            // State Section
            VStack(alignment: .leading, spacing: 12) {
                Text("State")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                    .padding(.horizontal, 20)
                
                Menu {
                    ForEach(ReferenceData.states, id: \.self) { stateOption in
                        Button(action: {
                            HapticManager.tap()
                            state = stateOption
                        }) {
                            HStack {
                                Text(stateOption)
                                if state == stateOption {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(state.isEmpty ? "Select state" : state)
                            .font(Theme.body)
                            .foregroundStyle(state.isEmpty ? Theme.secondaryText : Theme.primaryText)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(Theme.secondaryText)
                            .font(.caption)
                    }
                }
                .buttonStyle(Theme.RowButtonStyle())
                .accessibilityLabel("Select state")
                .accessibilityValue(state)
                .padding(.horizontal, 20)
            }
            
            // Your Role Section
            VStack(alignment: .leading, spacing: 12) {
                // Debug: Label with smaller optional indicator
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Your Role")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text("*Optional")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.horizontal, 20)
                
                Button(action: {
                    HapticManager.tap()
                    showingRolePicker = true
                    // Initialize temp values with current selection
                    if let currentRole = role {
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
                        Text(role ?? "Select role")
                            .font(Theme.body)
                            .foregroundStyle(role == nil ? Theme.secondaryText : Theme.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Theme.secondaryText)
                            .font(.caption)
                    }
                }
                .buttonStyle(Theme.RowButtonStyle())
                .accessibilityLabel("Select role")
                .accessibilityValue(role ?? "Not selected")
                .padding(.horizontal, 20)
            }
        }
    }
    
    // Debug: Step 2 - Optional Property Details
    private var step2DetailsView: some View {
        VStack(spacing: 24) {
            // PIC/ID Section
            VStack(alignment: .leading, spacing: 12) {
                // Debug: Label with smaller optional indicator
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("PIC/ID")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text("*Optional")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.horizontal, 20)
                
                TextField("Property Identification Code", text: $propertyPIC)
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .autocapitalization(.allCharacters)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .propertyPIC)
                    .onSubmit {
                        focusedField = .propertyAddress
                    }
                    .accessibilityLabel("Property Identification Code")
                    .accessibilityHint("Optional")
                    .padding(.horizontal, 20)
            }
            
            // Address Section
            VStack(alignment: .leading, spacing: 12) {
                // Debug: Label with smaller optional indicator
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Property Address")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text("*Optional")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.horizontal, 20)
                
                TextField("Address", text: $address)
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .autocapitalization(.words)
                    .textContentType(.fullStreetAddress)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .propertyAddress)
                    .onSubmit {
                        focusedField = nil
                    }
                    .accessibilityLabel("Property address")
                    .accessibilityHint("Optional")
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // Debug: Step 3 - Additional Properties
    private var step3AdditionalView: some View {
        VStack(spacing: 24) {
            // Primary property summary
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Primary Property")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.accentColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image("property_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Theme.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(propertyName)
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            Text("PRIMARY")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Text(state)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.positiveChange)
                        .font(.system(size: 24))
                }
                .padding(16)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(Theme.accentColor.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
            
            // Additional properties list
            if !additionalProperties.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Additional Properties (\(additionalProperties.count))")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    ForEach(additionalProperties) { property in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.secondaryText.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image("property_icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(property.name)
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                Text(property.state)
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            
                            Spacer()
                            
                            Button {
                                HapticManager.tap()
                                additionalProperties.removeAll { $0.id == property.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Theme.secondaryText)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(16)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                        .padding(.horizontal, 20)
                    }
                }
            }
            
            // Add property button
            Button(action: {
                HapticManager.tap()
                showingAddProperty = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add Another Property")
                        .font(Theme.body)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Theme.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 20)
            
            // Info message
            // Debug: Horizontally centered info text
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Theme.secondaryText)
                    .font(.caption)
                Text("You can add and manage properties later in settings")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Properties
    
    private var stepTitle: String {
        switch propertyStep {
        case .essentials:
            return "Primary Property"
        case .details:
            return "Property Details"
        case .additional:
            return "Additional Properties"
        }
    }
    
    private var stepSubtitle: String {
        switch propertyStep {
        case .essentials:
            return "Tell us about your primary property"
        case .details:
            return "Additional Information"
        case .additional:
            return "Manage additional properties"
        }
    }
    
    private var propertyStepIndex: Int {
        switch propertyStep {
        case .essentials:
            return 0
        case .details:
            return 1
        case .additional:
            return 2
        }
    }
    
    // MARK: - Navigation Methods
    
    private func moveBackStep() {
        switch propertyStep {
        case .essentials:
            break // Can't go back from first step
        case .details:
            propertyStep = .essentials
        case .additional:
            propertyStep = .details
        }
    }
    
    private func handleNextStep() {
        switch propertyStep {
        case .essentials:
            // Move to step 2
            withAnimation(.easeInOut(duration: 0.3)) {
                propertyStep = .details
            }
        case .details:
            // Move to step 3
            withAnimation(.easeInOut(duration: 0.3)) {
                propertyStep = .additional
            }
        case .additional:
            // Final step - save everything and continue to next page
            saveAllProperties()
            currentPage = 2
        }
    }
    
    // MARK: - Save Methods
    
    private func saveAllProperties() {
        // Debug: Save primary property to UserPreferences
        userPrefs.propertyName = propertyName
        userPrefs.defaultState = state
        userPrefs.farmSize = herdSize
        userPrefs.propertyPIC = propertyPIC.isEmpty ? nil : propertyPIC
        userPrefs.propertyAddress = address.isEmpty ? nil : address
        userPrefs.propertyRole = role
        
        // Debug: Create primary Property object (will be created in OnboardingView completion)
        // Additional properties will be created here
        for additionalProp in additionalProperties {
            let property = Property(
                propertyName: additionalProp.name,
                propertyPIC: additionalProp.pic.isEmpty ? nil : additionalProp.pic,
                state: additionalProp.state,
                isDefault: false,
                isSimulated: false
            )
            modelContext.insert(property)
        }
        
        try? modelContext.save()
        print("✅ Saved \(additionalProperties.count) additional properties")
    }
}

// MARK: - Additional Property Data Model
struct AdditionalPropertyData: Identifiable {
    let id = UUID()
    var name: String
    var state: String
    var pic: String
}

// MARK: - Add Additional Property Sheet
struct AddAdditionalPropertySheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (AdditionalPropertyData) -> Void
    
    @State private var propertyName = ""
    @State private var state = "QLD"
    @State private var pic = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Property Name")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    TextField("Enter property name", text: $propertyName)
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .autocapitalization(.words)
                }
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("State")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Menu {
                        ForEach(ReferenceData.states, id: \.self) { stateOption in
                            Button(action: {
                                HapticManager.tap()
                                state = stateOption
                            }) {
                                HStack {
                                    Text(stateOption)
                                    if state == stateOption {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(state)
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(Theme.secondaryText)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(Theme.RowButtonStyle())
                }
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("PIC/ID (Optional)")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    TextField("Property Identification Code", text: $pic)
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .autocapitalization(.allCharacters)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        HapticManager.success()
                        onSave(AdditionalPropertyData(name: propertyName, state: state, pic: pic))
                        dismiss()
                    }
                    .disabled(propertyName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
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
                                    .foregroundStyle(Theme.accentColor)
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
                                    .foregroundStyle(Theme.accentColor)
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


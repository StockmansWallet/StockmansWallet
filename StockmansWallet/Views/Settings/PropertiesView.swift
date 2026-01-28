//
//  PropertiesView.swift
//  StockmansWallet
//
//  Properties Management - Manage multiple farm properties and their preferences
//  Debug: Lists properties with add, edit, and default selection capabilities
//

import SwiftUI
import SwiftData

// Debug: Properties management view for multiple farms
struct PropertiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Property.propertyName) private var allProperties: [Property]
    
    // Debug: Computed property to sort with default properties first
    private var properties: [Property] {
        allProperties.sorted { lhs, rhs in
            if lhs.isDefault != rhs.isDefault {
                return lhs.isDefault // Default properties first
            }
            return lhs.propertyName < rhs.propertyName
        }
    }
    
    // Debug: Separate real and simulated properties
    private var realProperties: [Property] {
        properties.filter { !$0.isSimulated }
    }
    
    private var simulatedProperties: [Property] {
        properties.filter { $0.isSimulated }
    }
    
    @State private var showingAddProperty = false
    @State private var showingAddSimulatedProperty = false
    @State private var selectedProperty: Property?
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                // Debug: Header section
                VStack(alignment: .leading, spacing: 12) {
              
                    
                    Button {
                        HapticManager.tap()
                        showingAddProperty = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add Property")
                                .font(Theme.body)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.cardPadding)
                .cardStyle()
                .padding(.horizontal)
                .padding(.top)
                
                // Debug: Real Properties Section
                VStack(alignment: .leading, spacing: 12) {
                    // Section header
                    HStack {
                        Text("Real Properties")
                            .font(Theme.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        Text("\(realProperties.count)")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .padding(.horizontal)
                    
                    // Real properties list
                    if realProperties.isEmpty {
                        VStack(spacing: 12) {
                            Image("property_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundStyle(Theme.secondaryText.opacity(0.5))
                            
                            Text("No Real Properties")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(realProperties) { property in
                                PropertyCard(
                                    property: property,
                                    onTap: {
                                        HapticManager.tap()
                                        selectedProperty = property
                                    },
                                    onSetDefault: {
                                        HapticManager.success()
                                        setDefaultProperty(property)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Debug: Simulated Properties Section
                VStack(alignment: .leading, spacing: 12) {
                    // Section header
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "flask.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.accent)
                            Text("Simulated Properties")
                                .font(Theme.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.primaryText)
                        }
                        Spacer()
                        Text("\(simulatedProperties.count)")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .padding(.horizontal)
                    
                    // Simulated properties list
                    if simulatedProperties.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "flask")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.secondaryText.opacity(0.5))
                            
                            Text("No Simulated Properties")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            
                            Text("Add test properties for development and experimentation")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(simulatedProperties) { property in
                                PropertyCard(
                                    property: property,
                                    onTap: {
                                        HapticManager.tap()
                                        selectedProperty = property
                                    },
                                    onSetDefault: {
                                        HapticManager.success()
                                        setDefaultProperty(property)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Debug: Add Simulated Property button
                    Button {
                        HapticManager.tap()
                        showingAddSimulatedProperty = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add Simulated Property")
                                .font(Theme.body)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, 100)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Your Properties")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingAddProperty) {
            AddPropertyView(isSimulated: false)
        }
        .sheet(isPresented: $showingAddSimulatedProperty) {
            AddPropertyView(isSimulated: true)
        }
        .sheet(item: $selectedProperty) { property in
            EditPropertyView(property: property)
        }
    }
    
    // Debug: Set a property as the default/primary
    private func setDefaultProperty(_ property: Property) {
        // Debug: Only real properties can be primary
        guard !property.isSimulated else {
            print("⚠️ Cannot set simulated property as primary")
            return
        }
        
        // Debug: Remove default status from ALL properties (use allProperties, not filtered)
        for prop in allProperties {
            prop.isDefault = false
        }
        
        // Debug: Set this property as default/primary
        property.isDefault = true
        property.markUpdated()
        
        do {
            try modelContext.save()
            print("✅ Set \(property.propertyName) as primary property")
        } catch {
            print("❌ Error saving primary property: \(error)")
        }
    }
}

// MARK: - Property Card
// Debug: Card component for displaying a property
struct PropertyCard: View {
    let property: Property
    let onTap: () -> Void
    let onSetDefault: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Property icon and name
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.accent.opacity(0.15))
                                .frame(width: 44, height: 44)
                            // Debug: Different icons for real vs simulated properties
                            if property.isSimulated {
                                Image(systemName: "flask.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                            } else {
                                Image("property_icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(property.propertyName)
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                
                                // Debug: Simulated badge
                                if property.isSimulated {
                                    Text("SIMULATED")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(Theme.accent)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Theme.accent.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            
                            if let pic = property.propertyPIC {
                                Text("PIC: \(pic)")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Primary badge
                    if property.isDefault {
                        Text("Primary")
                            .font(Theme.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(Theme.accent)
                            .clipShape(Capsule())
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Divider()
                    .background(Theme.separator)
                
                // Property details with inline "Set as Primary" button
                VStack(spacing: 8) {
                    // Location row with optional "Set as Primary" button
                    HStack {
                        PropertyDetailRow(
                            icon: "location.fill",
                            text: property.locationDescription
                        )
                        
                        Spacer()
                        
                        // Set as Primary button (only show if not already default AND not simulated)
                        if !property.isDefault && !property.isSimulated {
                            Button {
                                HapticManager.tap()
                                onSetDefault()
                            } label: {
                                Text("Set as Primary")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if let saleyard = property.defaultSaleyard {
                        PropertyDetailRow(
                            icon: "mappin.circle.fill",
                            text: saleyard
                        )
                    }
                    
                    if let acreage = property.acreage {
                        PropertyDetailRow(
                            icon: "square.grid.3x3.fill",
                            text: "\(Int(acreage)) acres"
                        )
                    }
                }
            }
            .padding(Theme.cardPadding)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Property Detail Row
// Debug: Small row for property details
struct PropertyDetailRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 16)
            Text(text)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Add Property View
// Debug: Sheet for adding a new property (real or simulated)
struct AddPropertyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allProperties: [Property]
    
    let isSimulated: Bool // Debug: Whether this is a simulated property
    
    @State private var propertyName = ""
    @State private var propertyPIC = ""
    @State private var state = "QLD"
    @State private var region = ""
    @State private var address = ""
    @State private var acreage = ""
    @State private var isDefault = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Debug: Show simulated property notice
                if isSimulated {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "flask.fill")
                                .foregroundStyle(Theme.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Simulated Property")
                                    .font(Theme.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.primaryText)
                                Text("For testing and development purposes only")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.accent.opacity(0.1))
                }
                
                Section("Property Details") {
                    TextField("Property Name", text: $propertyName)
                    TextField("PIC (optional)", text: $propertyPIC)
                    
                    Picker("State", selection: $state) {
                        ForEach(ReferenceData.states, id: \.self) { state in
                            Text(state).tag(state)
                        }
                    }
                    
                    TextField("Region (optional)", text: $region)
                    TextField("Address (optional)", text: $address)
                    TextField("Acreage (optional)", text: $acreage)
                        .keyboardType(.decimalPad)
                }
                .listRowBackground(Theme.cardBackground)
                
                Section {
                    Toggle("Set as Default Property", isOn: $isDefault)
                } footer: {
                    Text("The default property will be used for new herds and preferences.")
                }
                .listRowBackground(Theme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient)
            .navigationTitle(isSimulated ? "Add Simulated Property" : "Add Property")
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
                        addProperty()
                        dismiss()
                    }
                    .disabled(propertyName.isEmpty)
                }
            }
        }
    }
    
    // Debug: Add the new property (real or simulated)
    private func addProperty() {
        // Debug: Determine if this should be primary
        let shouldBePrimary: Bool
        if isSimulated {
            // Simulated properties can never be primary
            shouldBePrimary = false
        } else {
            // Real properties: make primary if user selected OR if no real properties exist
            let existingRealProperties = allProperties.filter { !$0.isSimulated }
            shouldBePrimary = isDefault || existingRealProperties.isEmpty
        }
        
        let property = Property(
            propertyName: propertyName,
            propertyPIC: propertyPIC.isEmpty ? nil : propertyPIC,
            state: state,
            isDefault: shouldBePrimary,
            isSimulated: isSimulated
        )
        
        property.region = region.isEmpty ? nil : region
        property.address = address.isEmpty ? nil : address
        if let acreageValue = Double(acreage) {
            property.acreage = acreageValue
        }
        
        // Debug: If setting as primary, remove primary from all other properties
        if property.isDefault {
            for existingProp in allProperties {
                existingProp.isDefault = false
            }
            print("✅ Set \(property.propertyName) as primary property")
        }
        
        modelContext.insert(property)
        
        do {
            try modelContext.save()
            print("✅ Added new property: \(property.propertyName) (Primary: \(property.isDefault), Simulated: \(property.isSimulated))")
        } catch {
            print("❌ Error adding property: \(error)")
        }
    }
}

// MARK: - Edit Property View
// Debug: Sheet for editing an existing property
struct EditPropertyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @Query private var allProperties: [Property]
    
    let property: Property
    
    @State private var propertyName: String
    @State private var propertyPIC: String
    @State private var state: String
    @State private var region: String
    @State private var address: String
    @State private var acreage: String
    @State private var defaultSaleyard: String
    @State private var isPrimary: Bool
    
    @State private var showingDeleteAlert = false
    
    // Debug: Get user preferences for filtered saleyards
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    init(property: Property) {
        self.property = property
        _propertyName = State(initialValue: property.propertyName)
        _propertyPIC = State(initialValue: property.propertyPIC ?? "")
        _state = State(initialValue: property.state)
        _region = State(initialValue: property.region ?? "")
        _address = State(initialValue: property.address ?? "")
        _acreage = State(initialValue: property.acreage.map { String($0) } ?? "")
        _defaultSaleyard = State(initialValue: property.defaultSaleyard ?? "")
        _isPrimary = State(initialValue: property.isDefault)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Property Details") {
                    TextField("Property Name", text: $propertyName)
                    TextField("PIC", text: $propertyPIC)
                    
                    Picker("State", selection: $state) {
                        ForEach(ReferenceData.states, id: \.self) { state in
                            Text(state).tag(state)
                        }
                    }
                    
                    TextField("Region", text: $region)
                    TextField("Address", text: $address)
                    TextField("Acreage", text: $acreage)
                        .keyboardType(.decimalPad)
                }
                .listRowBackground(Theme.cardBackground)
                
                Section("Market Preferences") {
                    Picker("Default Saleyard", selection: $defaultSaleyard) {
                        Text("Select...").tag("")
                        // Debug: Use filtered saleyards from user preferences
                        ForEach(userPrefs.filteredSaleyards, id: \.self) { saleyard in
                            Text(saleyard).tag(saleyard)
                        }
                    }
                }
                .listRowBackground(Theme.cardBackground)
                
                // Debug: Primary property toggle (only for real properties, not simulated)
                if !property.isSimulated {
                    Section {
                        Toggle("Set as Primary Property", isOn: $isPrimary)
                    } footer: {
                        Text("Your primary property is used as the default for new herds and preferences. Only one property can be primary.")
                            .font(Theme.caption)
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                
                Section {
                    Button(role: .destructive) {
                        HapticManager.warning()
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Property")
                        }
                    }
                }
                .listRowBackground(Theme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient)
            .navigationTitle("Edit Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.success()
                        saveChanges()
                        dismiss()
                    }
                    .disabled(propertyName.isEmpty)
                }
            }
            .alert("Delete Property", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteProperty()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete \(property.propertyName)? This action cannot be undone.")
            }
        }
    }
    
    // Debug: Save changes to the property
    private func saveChanges() {
        property.propertyName = propertyName
        property.propertyPIC = propertyPIC.isEmpty ? nil : propertyPIC
        property.state = state
        property.region = region.isEmpty ? nil : region
        property.address = address.isEmpty ? nil : address
        property.acreage = Double(acreage)
        property.defaultSaleyard = defaultSaleyard.isEmpty ? nil : defaultSaleyard
        
        // Debug: Handle primary property status
        if isPrimary != property.isDefault {
            if isPrimary {
                // Debug: User wants to make this property primary
                // Unset all other properties first
                for prop in allProperties where prop.id != property.id {
                    prop.isDefault = false
                }
                property.isDefault = true
                print("✅ Set \(property.propertyName) as primary property")
            } else {
                // Debug: User wants to remove primary status
                // Only allow if there's at least one other real property that can be primary
                let otherRealProperties = allProperties.filter { !$0.isSimulated && $0.id != property.id }
                if !otherRealProperties.isEmpty {
                    property.isDefault = false
                    // Debug: Optionally set first other real property as primary
                    if let firstOther = otherRealProperties.first {
                        firstOther.isDefault = true
                        print("✅ Moved primary status to \(firstOther.propertyName)")
                    }
                } else {
                    // Debug: Can't unset primary if this is the only real property
                    print("⚠️ Cannot unset primary - this is the only real property")
                    isPrimary = true // Reset toggle
                }
            }
        }
        
        property.markUpdated()
        
        do {
            try modelContext.save()
            print("✅ Property saved successfully")
        } catch {
            print("❌ Error saving property: \(error)")
        }
    }
    
    // Debug: Delete the property
    private func deleteProperty() {
        // Debug: If deleting primary property, move primary status to another real property
        if property.isDefault {
            let otherRealProperties = allProperties.filter { 
                !$0.isSimulated && $0.id != property.id 
            }
            if let newPrimary = otherRealProperties.first {
                newPrimary.isDefault = true
                print("✅ Moved primary status to \(newPrimary.propertyName) before deletion")
            }
        }
        
        modelContext.delete(property)
        
        do {
            try modelContext.save()
            print("✅ Property deleted successfully")
        } catch {
            print("❌ Error deleting property: \(error)")
        }
    }
}


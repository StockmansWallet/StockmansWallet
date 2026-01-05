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
    
    @State private var showingAddProperty = false
    @State private var selectedProperty: Property?
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                // Debug: Header section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                        Text("Properties")
                            .font(Theme.title)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    Text("Manage your farm properties and their individual preferences.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    
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
                .stitchedCard()
                .padding(.horizontal)
                .padding(.top)
                
                // Debug: Properties list
                if properties.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "building.2.crop.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.secondaryText.opacity(0.5))
                        
                        Text("No Properties Added")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                        
                        Text("Add your first property to get started managing your farm details and preferences.")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        ForEach(properties) { property in
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
            .padding(.bottom, 100)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Properties")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingAddProperty) {
            AddPropertyView()
        }
        .sheet(item: $selectedProperty) { property in
            EditPropertyView(property: property)
        }
    }
    
    // Debug: Set a property as the default
    private func setDefaultProperty(_ property: Property) {
        // Remove default status from all properties
        for prop in properties {
            prop.isDefault = false
        }
        // Set this property as default
        property.isDefault = true
        property.markUpdated()
        
        try? modelContext.save()
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
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(property.propertyName)
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            if let pic = property.propertyPIC {
                                Text("PIC: \(pic)")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Default badge
                    if property.isDefault {
                        Text("Default")
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
                
                // Property details
                VStack(spacing: 8) {
                    PropertyDetailRow(
                        icon: "location.fill",
                        text: property.locationDescription
                    )
                    
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
                
                // Set default button (only show if not already default)
                if !property.isDefault {
                    Button {
                        HapticManager.tap()
                        onSetDefault()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                            Text("Set as Default")
                                .font(Theme.caption)
                        }
                        .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.cardPadding)
            .stitchedCard()
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
// Debug: Sheet for adding a new property
struct AddPropertyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allProperties: [Property]
    
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
                        addProperty()
                        dismiss()
                    }
                    .disabled(propertyName.isEmpty)
                }
            }
        }
    }
    
    // Debug: Add the new property
    private func addProperty() {
        let property = Property(
            propertyName: propertyName,
            propertyPIC: propertyPIC.isEmpty ? nil : propertyPIC,
            state: state,
            isDefault: isDefault || allProperties.isEmpty // First property is always default
        )
        
        property.region = region.isEmpty ? nil : region
        property.address = address.isEmpty ? nil : address
        if let acreageValue = Double(acreage) {
            property.acreage = acreageValue
        }
        
        // If setting as default, remove default from other properties
        if property.isDefault {
            for existingProp in allProperties {
                existingProp.isDefault = false
            }
        }
        
        modelContext.insert(property)
        try? modelContext.save()
    }
}

// MARK: - Edit Property View
// Debug: Sheet for editing an existing property
struct EditPropertyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    let property: Property
    
    @State private var propertyName: String
    @State private var propertyPIC: String
    @State private var state: String
    @State private var region: String
    @State private var address: String
    @State private var acreage: String
    @State private var defaultSaleyard: String
    
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
        
        property.markUpdated()
        try? modelContext.save()
    }
    
    // Debug: Delete the property
    private func deleteProperty() {
        modelContext.delete(property)
        try? modelContext.save()
    }
}


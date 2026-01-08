//
//  AddCustomLocationSheet.swift
//  StockmansWallet
//
//  Sheet for adding/editing custom sale locations (Private & Other categories)
//  Debug: Form-based input with validation
//

import SwiftUI
import SwiftData

struct AddCustomLocationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let category: String // "Private" or "Other"
    let locationToEdit: CustomSaleLocation? // Debug: nil for new location, set for editing
    
    // Debug: Form state
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var contactName: String = ""
    @State private var contactPhone: String = ""
    @State private var contactEmail: String = ""
    @State private var notes: String = ""
    
    // Debug: Validation state
    @State private var showingEmptyNameAlert = false
    
    // Debug: Check if form is valid (name is required)
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Debug: Required fields section
                Section {
                    HStack {
                        Text("Name")
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        TextField("Required", text: $name)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.words)
                            .foregroundStyle(Theme.primaryText)
                    }
                } header: {
                    Text("Location Details")
                        .foregroundStyle(Theme.secondaryText)
                } footer: {
                    Text("Enter a name for this \(category.lowercased()) sale location")
                        .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.cardBackground)
                
                // Debug: Address section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Address")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        TextEditor(text: $address)
                            .frame(minHeight: 80)
                            .textInputAutocapitalization(.words)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(Theme.primaryText)
                    }
                } header: {
                    Text("Address (Optional)")
                        .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.cardBackground)
                
                // Debug: Contact information section
                Section {
                    HStack {
                        Text("Contact Name")
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        TextField("Optional", text: $contactName)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.words)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    HStack {
                        Text("Phone")
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        TextField("Optional", text: $contactPhone)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.phonePad)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    HStack {
                        Text("Email")
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        TextField("Optional", text: $contactEmail)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(Theme.primaryText)
                    }
                } header: {
                    Text("Contact Information (Optional)")
                        .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.cardBackground)
                
                // Debug: Notes section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(Theme.primaryText)
                    }
                } header: {
                    Text("Notes (Optional)")
                        .foregroundStyle(Theme.secondaryText)
                } footer: {
                    Text("Add any additional details or notes about this location")
                        .foregroundStyle(Theme.secondaryText)
                }
                .listRowBackground(Theme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient)
            .navigationTitle(locationToEdit == nil ? "Add \(category) Location" : "Edit Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Debug: Cancel button
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.secondaryText)
                }
                
                // Debug: Save button
                ToolbarItem(placement: .confirmationAction) {
                    Button(locationToEdit == nil ? "Add" : "Save") {
                        saveLocation()
                    }
                    .foregroundStyle(isValid ? Theme.accent : Theme.secondaryText)
                    .disabled(!isValid)
                }
            }
            .alert("Name Required", isPresented: $showingEmptyNameAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a name for this location")
            }
        }
        .onAppear {
            loadLocationData()
        }
    }
    
    // MARK: - Helper Functions
    
    // Debug: Load existing location data if editing
    private func loadLocationData() {
        guard let location = locationToEdit else { return }
        name = location.name
        address = location.address ?? ""
        contactName = location.contactName ?? ""
        contactPhone = location.contactPhone ?? ""
        contactEmail = location.contactEmail ?? ""
        notes = location.notes ?? ""
    }
    
    // Debug: Save or update location
    private func saveLocation() {
        // Debug: Validate name
        guard isValid else {
            showingEmptyNameAlert = true
            HapticManager.warning()
            return
        }
        
        if let location = locationToEdit {
            // Debug: Update existing location
            location.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            location.address = address.isEmpty ? nil : address
            location.contactName = contactName.isEmpty ? nil : contactName
            location.contactPhone = contactPhone.isEmpty ? nil : contactPhone
            location.contactEmail = contactEmail.isEmpty ? nil : contactEmail
            location.notes = notes.isEmpty ? nil : notes
        } else {
            // Debug: Create new location
            let newLocation = CustomSaleLocation(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                address: address.isEmpty ? nil : address,
                contactName: contactName.isEmpty ? nil : contactName,
                contactPhone: contactPhone.isEmpty ? nil : contactPhone,
                contactEmail: contactEmail.isEmpty ? nil : contactEmail,
                notes: notes.isEmpty ? nil : notes,
                isEnabled: true // Debug: New locations are enabled by default
            )
            modelContext.insert(newLocation)
        }
        
        // Debug: Save changes
        try? modelContext.save()
        HapticManager.success()
        dismiss()
    }
}

#Preview {
    AddCustomLocationSheet(category: "Private", locationToEdit: nil)
}

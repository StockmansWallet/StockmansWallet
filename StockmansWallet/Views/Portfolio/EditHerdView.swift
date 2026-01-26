//
//  EditHerdView.swift
//  StockmansWallet
//
//  Edit existing herd/animal
//

import SwiftUI
import SwiftData

struct EditHerdView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]
    
    @Bindable var herd: HerdGroup
    
    @State private var herdName: String
    @State private var selectedSpecies: String
    @State private var selectedBreed: String
    @State private var selectedCategory: String
    @State private var sex: String
    @State private var ageMonths: Int
    @State private var headCount: Int
    @State private var initialWeight: Double
    @State private var dailyWeightGain: Double
    @State private var isBreeder: Bool
    @State private var isPregnant: Bool
    @State private var joinedDate: Date
    @State private var calvingRate: Double
    @State private var selectedSaleyard: String?
    @State private var paddockName: String
    @State private var useCreationDateForWeight: Bool
    @State private var notes: String
    // Debug: State for managing muster records
    @State private var showingAddMusterRecord = false
    @State private var newMusterDate = Date()
    @State private var newMusterNotes = ""
    @State private var newMusterHeadCount: Int?
    @State private var newMusterCattleYard = ""
    @State private var newMusterWeaners: Int?
    @State private var newMusterBranders: Int?
    // Debug: State for managing health records
    @State private var showingAddHealthRecord = false
    @State private var newHealthDate = Date()
    @State private var newHealthTreatmentType: HealthTreatmentType = .vaccination
    @State private var newHealthNotes = ""
    
    private let speciesOptions = ["Cattle", "Sheep", "Pigs", "Goats"]
    
    // Debug: Get user preferences for filtered saleyards
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    private var breedOptions: [String] {
        switch selectedSpecies {
        case "Cattle":
            return ReferenceData.cattleBreeds
        case "Sheep":
            return ReferenceData.sheepBreeds
        case "Pigs":
            return ReferenceData.pigBreeds
        case "Goats":
            return ReferenceData.goatBreeds
        default:
            return []
        }
    }
    
    private var categoryOptions: [String] {
        switch selectedSpecies {
        case "Cattle":
            return ReferenceData.cattleCategories
        case "Sheep":
            return ReferenceData.sheepCategories
        case "Pigs":
            return ReferenceData.pigCategories
        case "Goats":
            return ReferenceData.goatCategories
        default:
            return []
        }
    }
    
    init(herd: HerdGroup) {
        self.herd = herd
        _herdName = State(initialValue: herd.name)
        _selectedSpecies = State(initialValue: herd.species)
        _selectedBreed = State(initialValue: herd.breed)
        _selectedCategory = State(initialValue: herd.category)
        _sex = State(initialValue: herd.sex)
        _ageMonths = State(initialValue: herd.ageMonths)
        _headCount = State(initialValue: herd.headCount)
        _initialWeight = State(initialValue: herd.initialWeight)
        _dailyWeightGain = State(initialValue: herd.dailyWeightGain)
        _isBreeder = State(initialValue: herd.isBreeder)
        _isPregnant = State(initialValue: herd.isPregnant)
        _joinedDate = State(initialValue: herd.joinedDate ?? Date())
        _calvingRate = State(initialValue: herd.calvingRate)
        _selectedSaleyard = State(initialValue: herd.selectedSaleyard)
        _paddockName = State(initialValue: herd.paddockName ?? "")
        _useCreationDateForWeight = State(initialValue: herd.useCreationDateForWeight)
        _notes = State(initialValue: herd.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Debug: Gradient background for navigation destination views
                Theme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.sectionSpacing) {
                        // Basic Information
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Basic Information")
                                .font(Theme.title)
                                .foregroundStyle(Theme.primaryText)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Herd/Animal Name")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                TextField("e.g. North Paddock Herd", text: $herdName)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Theme.inputFieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Species")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                
                                // Debug: Grid of species cards with emoji icons
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    // Cattle - Available
                                    SpeciesCard(
                                        emoji: "🐄",
                                        name: "Cattle",
                                        isAvailable: true,
                                        isSelected: selectedSpecies == "Cattle"
                                    ) {
                                        HapticManager.tap()
                                        selectedSpecies = "Cattle"
                                        if !breedOptions.contains(selectedBreed) {
                                            selectedBreed = ""
                                        }
                                        if !categoryOptions.contains(selectedCategory) {
                                            selectedCategory = ""
                                        }
                                    }
                                    
                                    // Sheep - Coming Soon
                                    SpeciesCard(
                                        emoji: "🐑",
                                        name: "Sheep",
                                        isAvailable: false,
                                        isSelected: false
                                    ) {
                                        // Disabled - no action
                                    }
                                    
                                    // Pigs - Coming Soon
                                    SpeciesCard(
                                        emoji: "🐷",
                                        name: "Pigs",
                                        isAvailable: false,
                                        isSelected: false
                                    ) {
                                        // Disabled - no action
                                    }
                                    
                                    // Goats - Coming Soon
                                    SpeciesCard(
                                        emoji: "🐐",
                                        name: "Goats",
                                        isAvailable: false,
                                        isSelected: false
                                    ) {
                                        // Disabled - no action
                                    }
                                }
                                
                                // Debug: Helper text for coming soon animals
                                Text("Support for Sheep, Pigs, and Goats coming soon!")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 4)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Breed")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                Picker("Breed", selection: $selectedBreed) {
                                    Text("Select Breed").tag("")
                                    ForEach(breedOptions, id: \.self) { breed in
                                        Text(breed).tag(breed)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Category")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                Picker("Category", selection: $selectedCategory) {
                                    Text("Select Category").tag("")
                                    ForEach(categoryOptions, id: \.self) { category in
                                        Text(category).tag(category)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sex")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                Picker("Sex", selection: $sex) {
                                    Text("Male").tag("Male")
                                    Text("Female").tag("Female")
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding(Theme.cardPadding)
                        .stitchedCard()
                        
                        // Physical Attributes
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Physical Attributes")
                                .font(Theme.title)
                                .foregroundStyle(Theme.primaryText)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Head")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                Stepper(value: $headCount, in: 1...10000, step: 1) {
                                    Text("\(headCount) head")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                }
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Initial Weight (kg)")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                HStack {
                                    Slider(value: $initialWeight, in: 50...1000, step: 5)
                                    Text("\(Int(initialWeight)) kg")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                        .frame(width: 80)
                                }
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Daily Weight Gain (kg/day)")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                HStack {
                                    Slider(value: $dailyWeightGain, in: 0...2.0, step: 0.1)
                                    Text(String(format: "%.2f kg/day", dailyWeightGain))
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                        .frame(width: 100)
                                }
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            
                            // Debug: Weight gain calculation method toggle
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Weight Gain Calculation")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                
                                Toggle(isOn: $useCreationDateForWeight) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Calculate from creation date")
                                            .font(Theme.body)
                                            .foregroundStyle(Theme.primaryText)
                                        Text(useCreationDateForWeight 
                                             ? "Weight calculated from entry date (\(herd.createdAt.formatted(date: .abbreviated, time: .omitted)))"
                                             : "Weight calculated from today's date (dynamic)")
                                            .font(Theme.caption)
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                }
                                .tint(Theme.accent)
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Age (months)")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                Stepper(value: $ageMonths, in: 1...120, step: 1) {
                                    Text("\(ageMonths) months")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                }
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .padding(Theme.cardPadding)
                        .stitchedCard()
                        
                        // Additional Details
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Additional Details")
                                .font(Theme.title)
                                .foregroundStyle(Theme.primaryText)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Paddock Name (Optional)")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                TextField("e.g. North Paddock", text: $paddockName)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Theme.inputFieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Saleyard (Optional)")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                Picker("Saleyard", selection: $selectedSaleyard) {
                                    Text("Use Default").tag(nil as String?)
                                    // Debug: Use filtered saleyards from user preferences
                                    ForEach(userPrefs.filteredSaleyards, id: \.self) { saleyard in
                                        Text(saleyard).tag(saleyard as String?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            
                            // Debug: Notes field for farmer to add custom observations, reminders, etc.
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notes (Optional)")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                Text("Add custom notes about this herd/animal (e.g., health observations, feeding schedule, etc.)")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                                TextEditor(text: $notes)
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(Theme.inputFieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .scrollContentBackground(.hidden)
                            }
                            
                            // Debug: Mustering History management section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Mustering History")
                                            .font(Theme.headline)
                                            .foregroundStyle(Theme.primaryText)
                                        Text("Track muster dates and notes for this herd/animal")
                                            .font(Theme.caption)
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    // Add button
                                    Button {
                                        HapticManager.tap()
                                        newMusterDate = Date()
                                        newMusterNotes = ""
                                        newMusterHeadCount = nil
                                        newMusterCattleYard = ""
                                        newMusterWeaners = nil
                                        newMusterBranders = nil
                                        showingAddMusterRecord = true
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundStyle(Theme.accent)
                                    }
                                }
                                
                                // Debug: Show existing muster records with all details
                                if let records = herd.musterRecords, !records.isEmpty {
                                    VStack(spacing: 8) {
                                        ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                                            HStack(alignment: .top, spacing: 12) {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(record.formattedDate)
                                                        .font(Theme.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(Theme.primaryText)
                                                    
                                                    // Debug: Match main view formatting - all counts on same line with full labels
                                                    if record.totalHeadCount != nil || record.weanersCount != nil || record.brandersCount != nil {
                                                        HStack(spacing: 8) {
                                                            if let headCount = record.totalHeadCount {
                                                                HStack(spacing: 4) {
                                                                    Text("Total Head:")
                                                                        .font(Theme.caption)
                                                                        .foregroundStyle(Theme.secondaryText)
                                                                    Text("\(headCount)")
                                                                        .font(Theme.caption)
                                                                        .fontWeight(.semibold)
                                                                        .foregroundStyle(Theme.primaryText)
                                                                }
                                                            }
                                                            if let weaners = record.weanersCount {
                                                                HStack(spacing: 4) {
                                                                    Text("Weaners:")
                                                                        .font(Theme.caption)
                                                                        .foregroundStyle(Theme.secondaryText)
                                                                    Text("\(weaners)")
                                                                        .font(Theme.caption)
                                                                        .fontWeight(.semibold)
                                                                        .foregroundStyle(Theme.primaryText)
                                                                }
                                                            }
                                                            if let branders = record.brandersCount {
                                                                HStack(spacing: 4) {
                                                                    Text("Branders:")
                                                                        .font(Theme.caption)
                                                                        .foregroundStyle(Theme.secondaryText)
                                                                    Text("\(branders)")
                                                                        .font(Theme.caption)
                                                                        .fontWeight(.semibold)
                                                                        .foregroundStyle(Theme.primaryText)
                                                                }
                                                            }
                                                        }
                                                    }
                                                    
                                                    // Debug: Yard on its own line - match main view format
                                                    if let yard = record.cattleYard, !yard.isEmpty {
                                                        HStack(spacing: 4) {
                                                            Text("Yard:")
                                                                .font(Theme.caption)
                                                                .foregroundStyle(Theme.secondaryText)
                                                            Text(yard)
                                                                .font(Theme.caption)
                                                                .fontWeight(.semibold)
                                                                .foregroundStyle(Theme.primaryText)
                                                        }
                                                    }
                                                    
                                                    // Debug: Notes with label - match main view format
                                                    if let notes = record.notes, !notes.isEmpty {
                                                        HStack(alignment: .top, spacing: 4) {
                                                            Text("Notes:")
                                                                .font(Theme.caption)
                                                                .foregroundStyle(Theme.secondaryText)
                                                            Text(notes)
                                                                .font(Theme.caption)
                                                                .foregroundStyle(Theme.secondaryText)
                                                                .fixedSize(horizontal: false, vertical: true)
                                                        }
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                // Delete button
                                                Button {
                                                    HapticManager.tap()
                                                    deleteMusterRecord(record)
                                                } label: {
                                                    Image(systemName: "trash")
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(.red)
                                                }
                                            }
                                            .padding(12)
                                            .background(Theme.cardBackground.opacity(0.5))
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        }
                                    }
                                } else {
                                    // Empty state
                                    Text("No muster records yet. Tap + to add one.")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                            }
                            .padding()
                            .background(Theme.inputFieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            
                            // Debug: Health Records management section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Health Records")
                                            .font(Theme.headline)
                                            .foregroundStyle(Theme.primaryText)
                                        Text("Track vaccinations, drenching, and treatments")
                                            .font(Theme.caption)
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    // Add button
                                    Button {
                                        HapticManager.tap()
                                        newHealthDate = Date()
                                        newHealthTreatmentType = .vaccination
                                        newHealthNotes = ""
                                        showingAddHealthRecord = true
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundStyle(Theme.accent)
                                    }
                                }
                                
                                // Debug: Show existing health records
                                if let records = herd.healthRecords, !records.isEmpty {
                                    VStack(spacing: 8) {
                                        ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                                            HStack(alignment: .top, spacing: 12) {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    // Debug: Match main view - Date on first line
                                                    Text(record.formattedDate)
                                                        .font(Theme.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(Theme.primaryText)
                                                    
                                                    // Debug: Treatment type with label format
                                                    HStack(spacing: 4) {
                                                        Text("Treatment:")
                                                            .font(Theme.caption)
                                                            .foregroundStyle(Theme.secondaryText)
                                                        Text(record.treatmentDescription)
                                                            .font(Theme.caption)
                                                            .fontWeight(.semibold)
                                                            .foregroundStyle(Theme.primaryText)
                                                    }
                                                    
                                                    // Debug: Notes with label - matches main view
                                                    if let notes = record.notes, !notes.isEmpty {
                                                        HStack(alignment: .top, spacing: 4) {
                                                            Text("Notes:")
                                                                .font(Theme.caption)
                                                                .foregroundStyle(Theme.secondaryText)
                                                            Text(notes)
                                                                .font(Theme.caption)
                                                                .foregroundStyle(Theme.secondaryText)
                                                                .fixedSize(horizontal: false, vertical: true)
                                                        }
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                // Delete button
                                                Button {
                                                    HapticManager.tap()
                                                    deleteHealthRecord(record)
                                                } label: {
                                                    Image(systemName: "trash")
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(.red)
                                                }
                                            }
                                            .padding(12)
                                            .background(Theme.cardBackground.opacity(0.5))
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        }
                                    }
                                } else {
                                    // Empty state
                                    Text("No health records yet. Tap + to add one.")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                            }
                            .padding()
                            .background(Theme.inputFieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            
                            Toggle(isOn: $isBreeder) {
                                Text("Breeding Stock")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                            }
                            .tint(Theme.accent)
                            .padding()
                            .background(Theme.inputFieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            
                            if isBreeder {
                                VStack(alignment: .leading, spacing: 12) {
                                    Toggle(isOn: $isPregnant) {
                                        Text("Currently Pregnant")
                                            .font(Theme.headline)
                                            .foregroundStyle(Theme.primaryText)
                                    }
                                    .tint(Theme.accent)
                                    
                                    if isPregnant {
                                        DatePicker("Joined Date", selection: $joinedDate, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Calving Rate: \(Int(calvingRate * 100))%")
                                                .font(Theme.caption)
                                                .foregroundStyle(Theme.primaryText.opacity(0.7))
                                            Slider(value: $calvingRate, in: 0.5...1.0, step: 0.05)
                                        }
                                        .padding()
                                        .background(Theme.inputFieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }
                                .padding()
                                .background(Theme.cardBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .padding(Theme.cardPadding)
                        .stitchedCard()
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Herd")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        HapticManager.tap()
                        saveChanges()
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .foregroundStyle(Theme.accent)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingAddMusterRecord) {
                AddMusterRecordSheet(
                    date: $newMusterDate,
                    notes: $newMusterNotes,
                    headCount: $newMusterHeadCount,
                    cattleYard: $newMusterCattleYard,
                    weaners: $newMusterWeaners,
                    branders: $newMusterBranders,
                    onSave: {
                        addMusterRecord()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.sheetBackground)
            }
            .sheet(isPresented: $showingAddHealthRecord) {
                AddHealthRecordSheet(
                    date: $newHealthDate,
                    treatmentType: $newHealthTreatmentType,
                    notes: $newHealthNotes,
                    onSave: {
                        addHealthRecord()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.sheetBackground)
            }
        }
    }
    
    private var isValid: Bool {
        !herdName.isEmpty && !selectedBreed.isEmpty && !selectedCategory.isEmpty && headCount > 0 && initialWeight > 0
    }
    
    private func saveChanges() {
        // Check if DWG changed
        if herd.dailyWeightGain != dailyWeightGain {
            herd.previousDWG = herd.dailyWeightGain
            herd.dwgChangeDate = Date()
        }
        
        herd.name = herdName
        herd.species = selectedSpecies
        herd.breed = selectedBreed
        herd.category = selectedCategory
        herd.sex = sex
        herd.ageMonths = ageMonths
        herd.headCount = headCount
        herd.initialWeight = initialWeight
        herd.dailyWeightGain = dailyWeightGain
        herd.useCreationDateForWeight = useCreationDateForWeight
        herd.isBreeder = isBreeder
        herd.isPregnant = isBreeder && isPregnant
        herd.calvingRate = calvingRate
        herd.selectedSaleyard = selectedSaleyard
        herd.paddockName = paddockName.isEmpty ? nil : paddockName
        herd.notes = notes.isEmpty ? nil : notes
        
        if herd.isPregnant {
            herd.joinedDate = joinedDate
        } else {
            herd.joinedDate = nil
        }
        
        // Debug: Update the updatedAt timestamp whenever changes are saved
        herd.updatedAt = Date()
        
        do {
            try modelContext.save()
            HapticManager.success()
            dismiss()
        } catch {
            HapticManager.error()
            print("Error saving changes: \(error)")
        }
    }
    
    // Debug: Add a new muster record to the herd with all optional details
    private func addMusterRecord() {
        let record = MusterRecord(
            date: newMusterDate,
            notes: newMusterNotes.isEmpty ? nil : newMusterNotes,
            totalHeadCount: newMusterHeadCount,
            cattleYard: newMusterCattleYard.isEmpty ? nil : newMusterCattleYard,
            weanersCount: newMusterWeaners,
            brandersCount: newMusterBranders
        )
        record.herd = herd
        
        if herd.musterRecords == nil {
            herd.musterRecords = []
        }
        herd.musterRecords?.append(record)
        
        // Update the herd's updatedAt timestamp
        herd.updatedAt = Date()
        
        // Save to context
        modelContext.insert(record)
        
        do {
            try modelContext.save()
            HapticManager.success()
            showingAddMusterRecord = false
        } catch {
            HapticManager.error()
            print("Error adding muster record: \(error)")
        }
    }
    
    // Debug: Delete a muster record from the herd
    private func deleteMusterRecord(_ record: MusterRecord) {
        herd.musterRecords?.removeAll(where: { $0.id == record.id })
        herd.updatedAt = Date()
        
        modelContext.delete(record)
        
        do {
            try modelContext.save()
            HapticManager.success()
        } catch {
            HapticManager.error()
            print("Error deleting muster record: \(error)")
        }
    }
    
    // Debug: Add a new health record to the herd
    private func addHealthRecord() {
        let record = HealthRecord(
            date: newHealthDate,
            treatmentType: newHealthTreatmentType,
            notes: newHealthNotes.isEmpty ? nil : newHealthNotes
        )
        record.herd = herd
        
        if herd.healthRecords == nil {
            herd.healthRecords = []
        }
        herd.healthRecords?.append(record)
        
        // Update the herd's updatedAt timestamp
        herd.updatedAt = Date()
        
        // Save to context
        modelContext.insert(record)
        
        do {
            try modelContext.save()
            HapticManager.success()
            showingAddHealthRecord = false
        } catch {
            HapticManager.error()
            print("Error adding health record: \(error)")
        }
    }
    
    // Debug: Delete a health record from the herd
    private func deleteHealthRecord(_ record: HealthRecord) {
        herd.healthRecords?.removeAll(where: { $0.id == record.id })
        herd.updatedAt = Date()
        
        modelContext.delete(record)
        
        do {
            try modelContext.save()
            HapticManager.success()
        } catch {
            HapticManager.error()
            print("Error deleting health record: \(error)")
        }
    }
}

// MARK: - Add Muster Record Sheet
// Debug: Sheet for adding a new muster record with date, notes, and optional details
struct AddMusterRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    @Binding var notes: String
    @Binding var headCount: Int?
    @Binding var cattleYard: String
    @Binding var weaners: Int?
    @Binding var branders: Int?
    let onSave: () -> Void
    
    @State private var headCountText = ""
    @State private var weanersText = ""
    @State private var brandersText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Date Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Muster Date")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            DatePicker("Select Date", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        // Debug: Additional optional muster details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Muster Details (Optional)")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            // Total Head Count
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Total Head Count")
                                    .font(Theme.subheadline)
                                    .foregroundStyle(Theme.primaryText)
                                
                                TextField("e.g., 150", text: $headCountText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Theme.inputFieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .onChange(of: headCountText) { oldValue, newValue in
                                        headCount = Int(newValue)
                                    }
                            }
                            
                            // Cattle Yard
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cattle Yard")
                                    .font(Theme.subheadline)
                                    .foregroundStyle(Theme.primaryText)
                                
                                TextField("e.g., Snake Paddock Yards", text: $cattleYard)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Theme.inputFieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            
                            // Weaners and Branders side by side
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("# Weaners")
                                        .font(Theme.subheadline)
                                        .foregroundStyle(Theme.primaryText)
                                    
                                    TextField("0", text: $weanersText)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(Theme.inputFieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .onChange(of: weanersText) { oldValue, newValue in
                                            weaners = Int(newValue)
                                        }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("# Branders")
                                        .font(Theme.subheadline)
                                        .foregroundStyle(Theme.primaryText)
                                    
                                    TextField("0", text: $brandersText)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(Theme.inputFieldBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .onChange(of: brandersText) { oldValue, newValue in
                                            branders = Int(newValue)
                                        }
                                }
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes (Optional)")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            Text("e.g., 'Drenched', 'Tagged 5 new calves', 'Moved to South paddock'")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .scrollContentBackground(.hidden)
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Muster Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        HapticManager.tap()
                        onSave()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Add Health Record Sheet
// Debug: Sheet for adding a new health record with date, treatment type, and notes
struct AddHealthRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    @Binding var treatmentType: HealthTreatmentType
    @Binding var notes: String
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Date Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Treatment Date")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            DatePicker("Select Date", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        // Treatment Type Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Treatment Type")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            // Debug: Grid of treatment type cards
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(HealthTreatmentType.allCases, id: \.self) { type in
                                    TreatmentTypeCard(
                                        type: type,
                                        isSelected: treatmentType == type
                                    ) {
                                        HapticManager.tap()
                                        treatmentType = type
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes (Optional)")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            Text("e.g., '5-in-1 vaccine', 'Ivomec drench', 'Cydectin pour-on'")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .scrollContentBackground(.hidden)
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Health Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        HapticManager.tap()
                        onSave()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Treatment Type Card
// Debug: Selectable card for treatment type selection
struct TreatmentTypeCard: View {
    let type: HealthTreatmentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.secondaryText)
                
                Text(type.rawValue)
                    .font(Theme.subheadline)
                    .foregroundStyle(isSelected ? Theme.primaryText : Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Theme.accent.opacity(0.15) : Theme.inputFieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Theme.accent : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

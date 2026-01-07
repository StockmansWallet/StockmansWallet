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
                                TextField("e.g., North Paddock Herd", text: $herdName)
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
                                TextField("e.g., North Paddock", text: $paddockName)
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
        
        if herd.isPregnant {
            herd.joinedDate = joinedDate
        } else {
            herd.joinedDate = nil
        }
        
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
}

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
    @State private var ageMonths: Int?
    @State private var headCount: Int?
    @State private var initialWeight: Int?
    @State private var dailyWeightGain: Double
    @State private var isBreeder: Bool
    @State private var isPregnant: Bool
    @State private var joinedDate: Date
    @State private var calvingRate: Double
    @State private var selectedSaleyard: String?
    @State private var paddockName: String
    @State private var useCreationDateForWeight: Bool
    @State private var notes: String
    @State private var showingSaleyardSheet = false
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
        _initialWeight = State(initialValue: Int(herd.initialWeight))
        _dailyWeightGain = State(initialValue: herd.dailyWeightGain)
        _isBreeder = State(initialValue: herd.isBreeder)
        _isPregnant = State(initialValue: herd.isPregnant)
        _joinedDate = State(initialValue: herd.joinedDate ?? Date())
        // Debug: Convert decimal (0.85) to percentage (85.0) for display
        _calvingRate = State(initialValue: herd.calvingRate * 100.0)
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
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: Theme.sectionSpacing) {
                        // Basic Information
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Basic Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.primaryText)
                            
                            // Debug: Layout and styling matching Physical Sales Report format exactly
                            VStack(alignment: .leading, spacing: 12) {
                                // Full width: Herd Name / Animal Name
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(herd.headCount == 1 ? "Animal Name" : "Herd Name")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                    TextField("", text: $herdName)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.primaryText)
                                        .textFieldStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.cardBackground)
                                // Debug: iOS 26 HIG - continuous curve for form fields.
                                .clipShape(Theme.continuousRoundedRect(8))
                                
                                // Row 1: Species | Breed
                                HStack(spacing: 12) {
                                    // Species picker
                                    Menu {
                                        ForEach(speciesOptions, id: \.self) { species in
                                            Button(species) {
                                                HapticManager.tap()
                                                selectedSpecies = species
                                                if !breedOptions.contains(selectedBreed) {
                                                    selectedBreed = ""
                                                }
                                                if !categoryOptions.contains(selectedCategory) {
                                                    selectedCategory = ""
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Species")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                                Text(selectedSpecies)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundStyle(Theme.primaryText)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Theme.secondaryText)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(Theme.cardBackground)
                                        .clipShape(Theme.continuousRoundedRect(8))
                                    }
                                    
                                    // Breed picker
                                    Menu {
                                        ForEach(breedOptions, id: \.self) { breed in
                                            Button(breed) {
                                                HapticManager.tap()
                                                selectedBreed = breed
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Breed")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                                Text(selectedBreed.isEmpty ? "Select" : selectedBreed)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundStyle(Theme.primaryText)
                                                    .lineLimit(1)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Theme.secondaryText)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(Theme.cardBackground)
                                        .clipShape(Theme.continuousRoundedRect(8))
                                    }
                                }
                                
                                // Row 2: Category | Sex
                                HStack(spacing: 12) {
                                    // Category picker
                                    Menu {
                                        ForEach(categoryOptions, id: \.self) { category in
                                            Button(category) {
                                                HapticManager.tap()
                                                selectedCategory = category
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Category")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                                Text(selectedCategory.isEmpty ? "Select" : selectedCategory)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundStyle(Theme.primaryText)
                                                    .lineLimit(1)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Theme.secondaryText)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(Theme.cardBackground)
                                        .clipShape(Theme.continuousRoundedRect(8))
                                    }
                                    
                                    // Sex picker
                                    Menu {
                                        Button("Male") {
                                            HapticManager.tap()
                                            sex = "Male"
                                        }
                                        Button("Female") {
                                            HapticManager.tap()
                                            sex = "Female"
                                        }
                                        Button("Mixed") {
                                            HapticManager.tap()
                                            sex = "Mixed"
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Sex")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                                Text(sex)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundStyle(Theme.primaryText)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Theme.secondaryText)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(Theme.cardBackground)
                                        .clipShape(Theme.continuousRoundedRect(8))
                                    }
                                }
                            }
                        }
                        .padding(Theme.cardPadding)
                        .cardStyle()
                        
                        // Physical Attributes
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Physical Attributes")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.primaryText)
                            
                            // Debug: Head and Age side-by-side (matches Physical Sales Report styling)
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Head")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                    if herd.headCount == 1 {
                                        Text("1")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Theme.secondaryText)
                                    } else {
                                        TextField("", value: $headCount, format: .number)
                                            .keyboardType(.numberPad)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Theme.primaryText)
                                            .textFieldStyle(.plain)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.cardBackground)
                                .clipShape(Theme.continuousRoundedRect(8))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Age (months)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                    TextField("", value: $ageMonths, format: .number)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.primaryText)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.cardBackground)
                                .clipShape(Theme.continuousRoundedRect(8))
                            }
                            
                            // Row 2: Initial Weight | Daily Weight Gain (matches mockup)
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Initial Weight")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                    TextField("", value: $initialWeight, format: .number)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.primaryText)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.cardBackground)
                                .clipShape(Theme.continuousRoundedRect(8))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Daily Weight Gain (kg/day)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                    TextField("", value: Binding(
                                        get: { dailyWeightGain },
                                        set: { dailyWeightGain = $0 }
                                    ), format: .number.precision(.fractionLength(2)))
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.primaryText)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.cardBackground)
                                .clipShape(Theme.continuousRoundedRect(8))
                            }
                            
                            // Debug: Weight gain calculation method toggle
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $useCreationDateForWeight) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Calculate from creation date")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Theme.primaryText)
                                        Text(useCreationDateForWeight 
                                             ? "Weight calculated from entry date (\(herd.createdAt.formatted(date: .abbreviated, time: .omitted)))"
                                             : "Weight calculated from today's date (dynamic)")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                    }
                                }
                                .tint(Theme.accentColor)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Theme.cardBackground)
                            .clipShape(Theme.continuousRoundedRect(8))
                            
                            // Breeding Stock toggle
                            Toggle(isOn: $isBreeder) {
                                Text("Breeding Stock")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.primaryText)
                            }
                            .tint(Theme.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Theme.cardBackground)
                            .clipShape(Theme.continuousRoundedRect(8))
                            
                            // Show breeding-related fields only when Breeding Stock is enabled
                            if isBreeder {
                                // Currently Pregnant toggle
                                Toggle(isOn: $isPregnant) {
                                    Text("Currently Pregnant")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.primaryText)
                                }
                                .tint(Theme.accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Theme.cardBackground)
                                .clipShape(Theme.continuousRoundedRect(8))
                                
                                // Show pregnancy-related fields only when Currently Pregnant is enabled
                                if isPregnant {
                                    // Row 3: Joined Date | Calving Rate
                                    HStack(spacing: 12) {
                                        Menu {
                                            Button("Select Date") {
                                                // Date picker will be shown
                                            }
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Joined Date")
                                                        .font(.system(size: 10))
                                                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                                    Text(joinedDate.formatted(date: .abbreviated, time: .omitted))
                                                        .font(.system(size: 13, weight: .medium))
                                                        .foregroundStyle(Theme.primaryText)
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(Theme.secondaryText)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                            .background(Theme.cardBackground)
                                            .clipShape(Theme.continuousRoundedRect(8))
                                        }
                                        .buttonStyle(.plain)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Calving Rate (%)")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                            TextField("", value: $calvingRate, format: .number)
                                                .keyboardType(.numberPad)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(Theme.primaryText)
                                                .textFieldStyle(.plain)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Theme.cardBackground)
                                        .clipShape(Theme.continuousRoundedRect(8))
                                    }
                                }
                            }
                        }
                        .padding(Theme.cardPadding)
                        .cardStyle()
                        
                        // Location (Optional)
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Location")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.primaryText)
                            + Text(" (Optional)")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Theme.secondaryText.opacity(0.6))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Paddock/Location")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                TextField("", text: $paddockName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.primaryText)
                                    .textFieldStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.cardBackground)
                            .clipShape(Theme.continuousRoundedRect(8))
                            
                            // Debug: Location Notes field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Location Notes")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                TextEditor(text: $notes)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.primaryText)
                                    .frame(minHeight: 80)
                                    .scrollContentBackground(.hidden)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Theme.cardBackground)
                            .clipShape(Theme.continuousRoundedRect(8))
                        }
                        .padding(Theme.cardPadding)
                        .cardStyle()
                        
                        // Saleyard (Optional)
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Saleyard")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.primaryText)
                            + Text(" (Optional)")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Theme.secondaryText.opacity(0.6))
                            
                            // Debug: Saleyard selector matching Physical Sales Report style
                            Button(action: {
                                HapticManager.tap()
                                showingSaleyardSheet = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Saleyard")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                        Text(selectedSaleyard ?? "Use Default")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Theme.primaryText)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Theme.cardBackground)
                                .clipShape(Theme.continuousRoundedRect(8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(Theme.cardPadding)
                        .cardStyle()
                        
                        // Mustering Records
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Mustering Records")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                    Text(herd.headCount == 1 ? "Track muster dates and notes for this animal" : "Track muster dates and notes for this herd")
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
                                        .font(.system(size: 28))
                                        .foregroundStyle(Theme.accentColor)
                                }
                            }
                                
                            // Debug: Show existing muster records with all details
                            if let records = herd.musterRecords, !records.isEmpty {
                                VStack(spacing: 12) {
                                    ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                                        HStack(spacing: 12) {
                                            // Document icon on the left
                                            Image(systemName: "doc.text.fill")
                                                .font(.system(size: 28))
                                                .foregroundStyle(Theme.accentColor)
                                            
                                            // Record details
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(record.formattedDate)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundStyle(Theme.primaryText)
                                                
                                                // Counts on same line
                                                if record.totalHeadCount != nil || record.weanersCount != nil || record.brandersCount != nil {
                                                    HStack(spacing: 0) {
                                                        if let headCount = record.totalHeadCount {
                                                            Text("Head: ")
                                                                .font(.system(size: 13))
                                                                .foregroundStyle(Theme.secondaryText)
                                                            + Text("\(headCount)")
                                                                .font(.system(size: 13, weight: .semibold))
                                                                .foregroundStyle(Theme.primaryText)
                                                        }
                                                        if let weaners = record.weanersCount {
                                                            Text("  Weaners: ")
                                                                .font(.system(size: 13))
                                                                .foregroundStyle(Theme.secondaryText)
                                                            + Text("\(weaners)")
                                                                .font(.system(size: 13, weight: .semibold))
                                                                .foregroundStyle(Theme.primaryText)
                                                        }
                                                        if let branders = record.brandersCount {
                                                            Text("  Branders: ")
                                                                .font(.system(size: 13))
                                                                .foregroundStyle(Theme.secondaryText)
                                                            + Text("\(branders)")
                                                                .font(.system(size: 13, weight: .semibold))
                                                                .foregroundStyle(Theme.primaryText)
                                                        }
                                                    }
                                                }
                                                
                                                // Yard
                                                if let yard = record.cattleYard, !yard.isEmpty {
                                                    Text("Yard: ")
                                                        .font(.system(size: 13))
                                                        .foregroundStyle(Theme.secondaryText)
                                                    + Text(yard)
                                                        .font(.system(size: 13, weight: .semibold))
                                                        .foregroundStyle(Theme.primaryText)
                                                }
                                                
                                                // Notes
                                                if let notes = record.notes, !notes.isEmpty {
                                                    Text("Notes:")
                                                        .font(.system(size: 13))
                                                        .foregroundStyle(Theme.secondaryText)
                                                } else {
                                                    Text("Notes:")
                                                        .font(.system(size: 13))
                                                        .foregroundStyle(Theme.secondaryText)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            // Edit and Delete buttons
                                            HStack(spacing: 8) {
                                                Button {
                                                    HapticManager.tap()
                                                    // Load record data for editing
                                                    newMusterDate = record.date
                                                    newMusterNotes = record.notes ?? ""
                                                    newMusterHeadCount = record.totalHeadCount
                                                    newMusterCattleYard = record.cattleYard ?? ""
                                                    newMusterWeaners = record.weanersCount
                                                    newMusterBranders = record.brandersCount
                                                    showingAddMusterRecord = true
                                                } label: {
                                                    Circle()
                                                        .fill(Theme.accentColor)
                                                        .frame(width: 36, height: 36)
                                                        .overlay(
                                                            Image(systemName: "pencil")
                                                                .font(.system(size: 14))
                                                                .foregroundStyle(Theme.background)
                                                        )
                                                }
                                                
                                                Button {
                                                    HapticManager.error()
                                                    deleteMusterRecord(record)
                                                } label: {
                                                    Circle()
                                                        .fill(Theme.accentColor)
                                                        .frame(width: 36, height: 36)
                                                        .overlay(
                                                            Image(systemName: "trash")
                                                                .font(.system(size: 14))
                                                                .foregroundStyle(Theme.background)
                                                        )
                                                }
                                            }
                                        }
                                        .padding(16)
                                        .background(Theme.cardBackground)
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
                        
                        // Health Records
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Health Records")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                    Text(herd.headCount == 1 ? "Track vaccinations, drenching, and treatments" : "Track vaccinations, drenching, and treatments etc")
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
                                        .font(.system(size: 28))
                                        .foregroundStyle(Theme.accentColor)
                                }
                            }
                                
                            // Debug: Show existing health records
                            if let records = herd.healthRecords, !records.isEmpty {
                                VStack(spacing: 12) {
                                    ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                                        HStack(spacing: 12) {
                                            // Treatment type icon on the left
                                            Image(systemName: record.treatmentType.icon)
                                                .font(.system(size: 28))
                                                .foregroundStyle(Theme.accentColor)
                                            
                                            // Record details
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(record.formattedDate)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundStyle(Theme.primaryText)
                                                
                                                Text("Treatment: ")
                                                    .font(.system(size: 13))
                                                    .foregroundStyle(Theme.secondaryText)
                                                + Text(record.treatmentDescription)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(Theme.primaryText)
                                                
                                                // Notes
                                                if let notes = record.notes, !notes.isEmpty {
                                                    Text("Notes:")
                                                        .font(.system(size: 13))
                                                        .foregroundStyle(Theme.secondaryText)
                                                } else {
                                                    Text("Notes:")
                                                        .font(.system(size: 13))
                                                        .foregroundStyle(Theme.secondaryText)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            // Edit and Delete buttons
                                            HStack(spacing: 8) {
                                                Button {
                                                    HapticManager.tap()
                                                    // Load record data for editing
                                                    newHealthDate = record.date
                                                    newHealthTreatmentType = record.treatmentType
                                                    newHealthNotes = record.notes ?? ""
                                                    showingAddHealthRecord = true
                                                } label: {
                                                    Circle()
                                                        .fill(Theme.accentColor)
                                                        .frame(width: 36, height: 36)
                                                        .overlay(
                                                            Image(systemName: "pencil")
                                                                .font(.system(size: 14))
                                                                .foregroundStyle(Theme.background)
                                                        )
                                                }
                                                
                                                Button {
                                                    HapticManager.error()
                                                    deleteHealthRecord(record)
                                                } label: {
                                                    Circle()
                                                        .fill(Theme.accentColor)
                                                        .frame(width: 36, height: 36)
                                                        .overlay(
                                                            Image(systemName: "trash")
                                                                .font(.system(size: 14))
                                                                .foregroundStyle(Theme.background)
                                                        )
                                                }
                                            }
                                        }
                                        .padding(16)
                                        .background(Theme.cardBackground)
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
                    }
                    .padding()
                }
            }
            .navigationTitle(herd.headCount == 1 ? "Edit Animal" : "Edit Herd")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .foregroundStyle(Theme.accentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        HapticManager.tap()
                        saveChanges()
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .foregroundStyle(Theme.accentColor)
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
            .sheet(isPresented: $showingSaleyardSheet) {
                SaleyardSelectionSheet(selectedSaleyard: $selectedSaleyard)
                    .presentationBackground(Theme.sheetBackground)
            }
        }
    }
    
    private var isValid: Bool {
        !herdName.isEmpty && !selectedBreed.isEmpty && !selectedCategory.isEmpty && (headCount ?? 0) > 0 && (initialWeight ?? 0) > 0
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
        herd.ageMonths = ageMonths ?? 0
        herd.headCount = headCount ?? 1
        herd.initialWeight = Double(initialWeight ?? 300)
        herd.dailyWeightGain = dailyWeightGain
        herd.useCreationDateForWeight = useCreationDateForWeight
        herd.isBreeder = isBreeder
        herd.isPregnant = isBreeder && isPregnant
        // Debug: Convert percentage (85.0) back to decimal (0.85) for storage
        herd.calvingRate = calvingRate / 100.0
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
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Row 1: Muster Date | Head Count
                        HStack(spacing: 12) {
                            Button(action: {
                                HapticManager.tap()
                                showingDatePicker = true
                            }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Muster Date")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.primaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 50)
                                .background(Theme.cardBackground)
                                .clipShape(Theme.continuousRoundedRect(8))
                            }
                            .buttonStyle(.plain)
                            
                            ZStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Head Count")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                    TextField("", text: $headCountText)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.primaryText)
                                        .textFieldStyle(.plain)
                                        .onChange(of: headCountText) { oldValue, newValue in
                                            headCount = Int(newValue)
                                        }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 50)
                            .background(Theme.cardBackground)
                            .clipShape(Theme.continuousRoundedRect(8))
                        }
                        
                        // Row 2: Weaners | Branders
                        HStack(spacing: 12) {
                            ZStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Weaners")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                    TextField("", text: $weanersText)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.primaryText)
                                        .textFieldStyle(.plain)
                                        .onChange(of: weanersText) { oldValue, newValue in
                                            weaners = Int(newValue)
                                        }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 50)
                            .background(Theme.cardBackground)
                            .clipShape(Theme.continuousRoundedRect(8))
                            
                            ZStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Branders")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                    TextField("", text: $brandersText)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.primaryText)
                                        .textFieldStyle(.plain)
                                        .onChange(of: brandersText) { oldValue, newValue in
                                            branders = Int(newValue)
                                        }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 50)
                            .background(Theme.cardBackground)
                            .clipShape(Theme.continuousRoundedRect(8))
                        }
                        
                        // Cattle Yard (full width)
                        ZStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cattle Yard")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                TextField("", text: $cattleYard)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.primaryText)
                                    .textFieldStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 50)
                        .background(Theme.cardBackground)
                        .clipShape(Theme.continuousRoundedRect(8))
                        
                        // Notes (full width)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.secondaryText.opacity(0.7))
                            TextEditor(text: $notes)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.primaryText)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Theme.cardBackground)
                        .clipShape(Theme.continuousRoundedRect(8))
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
                    .foregroundStyle(Theme.accentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        HapticManager.tap()
                        onSave()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accentColor)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(date: $date, title: "Select Muster Date")
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
    
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Row 1: Treatment Date | Treatment Type
                        HStack(spacing: 12) {
                            Button(action: {
                                HapticManager.tap()
                                showingDatePicker = true
                            }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Treatment Date")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.primaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 50)
                                .background(Theme.cardBackground)
                                .clipShape(Theme.continuousRoundedRect(8))
                            }
                            .buttonStyle(.plain)
                            
                            // Treatment Type Picker (Menu-based)
                            Menu {
                                ForEach(HealthTreatmentType.allCases, id: \.self) { type in
                                    Button(action: {
                                        HapticManager.tap()
                                        treatmentType = type
                                    }) {
                                        HStack {
                                            Image(systemName: type.icon)
                                            Text(type.rawValue)
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Treatment Type")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Theme.secondaryText.opacity(0.7))
                                            .fixedSize(horizontal: false, vertical: true)
                                        HStack(spacing: 8) {
                                            Image(systemName: treatmentType.icon)
                                                .font(.system(size: 13))
                                            Text(treatmentType.rawValue)
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundStyle(Theme.primaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.secondaryText)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Theme.cardBackground)
                                .clipShape(Theme.continuousRoundedRect(8))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Notes (full width)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.secondaryText.opacity(0.7))
                            TextEditor(text: $notes)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.primaryText)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Theme.cardBackground)
                        .clipShape(Theme.continuousRoundedRect(8))
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
                    .foregroundStyle(Theme.accentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        HapticManager.tap()
                        onSave()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accentColor)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(date: $date, title: "Select Treatment Date")
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
                    .foregroundStyle(isSelected ? Theme.accentColor : Theme.secondaryText)
                
                Text(type.rawValue)
                    .font(Theme.subheadline)
                    .foregroundStyle(isSelected ? Theme.primaryText : Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Theme.accentColor.opacity(0.15) : Theme.inputFieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Theme.accentColor : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Picker Sheet
// Debug: Clean date picker sheet for selecting dates in add muster/health record sheets
struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    let title: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(Theme.cardBackground)
                        .clipShape(Theme.continuousRoundedRect(16))
                        .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accentColor)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

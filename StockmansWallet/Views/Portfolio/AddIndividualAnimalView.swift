//
//  AddIndividualAnimalView.swift
//  StockmansWallet
//
//  Form for adding a single individual animal
//

import SwiftUI
import SwiftData

struct AddIndividualAnimalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]
    
    @State private var currentStep = 1
    @State private var isMovingForward = true
    @State private var animalName = ""
    @State private var paddockName = ""
    @State private var selectedSpecies = "Cattle"
    @State private var selectedBreed = ""
    @State private var selectedCategory = ""
    @State private var ageMonths = 12
    @State private var initialWeight: Double = 300
    @State private var dailyWeightGain: Double = 0.5
    @State private var isPregnant = false
    @State private var joinedDate = Date()
    @State private var calvingRate: Int = 85
    @State private var inCalf = true
    @State private var selectedSaleyard: String?
    @State private var tagNumber = ""
    @State private var birthDate: Date?
    @State private var hasBirthDate = false
    @State private var breedSearchText = ""
    @State private var categorySearchText = ""
    @State private var showingBreedPicker = false
    @State private var showingCategoryPicker = false
    
    private let speciesOptions = ["Cattle", "Sheep", "Pig"]
    
    // Debug: Get user preferences for filtered saleyards
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    private var isBreederCategory: Bool {
        let breederCategories = [
            "Breeding Cow", "Breeding Ewe", "Breeder Sow", "Breeding Doe",
            "Maiden Ewe (Joined)"
        ]
        return breederCategories.contains(selectedCategory)
    }
    
    private var totalSteps: Int {
        isBreederCategory ? 4 : 3 // Basic Info, Breeder (conditional), Physical Attributes, Additional Details
    }
    
    private var breedOptions: [String] {
        let breeds: [String]
        switch selectedSpecies {
        case "Cattle":
            breeds = ReferenceData.cattleBreeds
        case "Sheep":
            breeds = ReferenceData.sheepBreeds
        case "Pig":
            breeds = ReferenceData.pigBreeds
        default:
            breeds = []
        }
        if breedSearchText.isEmpty { return breeds }
        return breeds.filter { $0.localizedCaseInsensitiveContains(breedSearchText) }
    }
    
    private var categoryOptions: [String] {
        let categories: [String]
        switch selectedSpecies {
        case "Cattle":
            categories = ReferenceData.cattleCategories
        case "Sheep":
            categories = ReferenceData.sheepCategories
        case "Pig":
            categories = ReferenceData.pigCategories
        default:
            categories = []
        }
        if categorySearchText.isEmpty { return categories }
        return categories.filter { $0.localizedCaseInsensitiveContains(categorySearchText) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    // Debug: Back button meets iOS 26 HIG minimum touch target of 44x44pt
                    Button(action: {
                        HapticManager.tap()
                        if currentStep > 1 {
                            isMovingForward = false
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentStep -= 1
                            }
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.primaryText)
                            .frame(width: 44, height: 44) // iOS 26 HIG: Minimum 44x44pt
                            .background(Theme.inputFieldBackground)
                            .clipShape(Circle())
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .accessibilityLabel("Back")
                    
                    Spacer()
                    
                    Text("Add Individual Animal")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                
                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        if currentStep == 1 {
                            step1Content
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        } else if currentStep == 2 && isBreederCategory {
                            breedersContent
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        } else if (currentStep == 2 && !isBreederCategory) || (currentStep == 3 && isBreederCategory) {
                            step2Content
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        } else {
                            step3Content
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                
                // Bottom controls
                // Debug: No background on bottom controls for cleaner design (like AddHerdFlowView)
                VStack(spacing: 16) {
                    // Debug: Using Theme.PrimaryButtonStyle for iOS 26 HIG compliance (52pt height, proper styling)
                    Button(action: {
                        HapticManager.tap()
                        if currentStep < totalSteps {
                            isMovingForward = true
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentStep += 1
                            }
                        } else {
                            saveAnimal()
                        }
                    }) {
                        Text(currentStep < totalSteps ? "Next" : "Done")
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .disabled(!isStepValid)
                    .opacity(isStepValid ? 1.0 : 0.5)
                    .padding(.horizontal, 20)
                    .accessibilityLabel(currentStep < totalSteps ? "Next" : "Done")
                    
                    HStack(spacing: 8) {
                        ForEach(1...totalSteps, id: \.self) { step in
                            Circle()
                                .fill(step <= currentStep ? Theme.accent : Theme.primaryText.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingBreedPicker) {
                ScrollablePickerSheet(
                    title: "Select Breed",
                    options: breedOptions,
                    selectedValue: $selectedBreed,
                    searchText: $breedSearchText,
                    onSelect: { breed in
                        selectedBreed = breed
                    }
                )
                .presentationBackground(Theme.sheetBackground)
            }
            .sheet(isPresented: $showingCategoryPicker) {
                ScrollablePickerSheet(
                    title: "Select Category",
                    options: categoryOptions,
                    selectedValue: $selectedCategory,
                    searchText: $categorySearchText,
                    onSelect: { category in
                        selectedCategory = category
                    }
                )
                .presentationBackground(Theme.sheetBackground)
            }
            .background(Theme.sheetBackground.ignoresSafeArea())
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
        }
    }
    
    // MARK: - Step 1: Basic Information
    private var step1Content: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Animal Name/Tag")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                TextField("e.g., TAG-001 or Bessie", text: $animalName)
                    .textFieldStyle(AddHerdTextFieldStyle())
                    .accessibilityLabel("Animal name")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("Paddock Location")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text("Optional")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                TextField("e.g., North Paddock", text: $paddockName)
                    .textFieldStyle(AddHerdTextFieldStyle())
                    .accessibilityLabel("Paddock location")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Species")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Picker("Species", selection: $selectedSpecies) {
                    ForEach(speciesOptions, id: \.self) { species in
                        Text(species).tag(species)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedSpecies) { _, _ in
                    HapticManager.tap()
                    selectedBreed = ""
                    selectedCategory = ""
                    breedSearchText = ""
                    categorySearchText = ""
                }
                .accessibilityLabel("Species")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Breed")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                // Debug: Picker button meets iOS 26 HIG minimum touch target of 44pt height
                Button(action: {
                    HapticManager.tap()
                    showingBreedPicker = true
                }) {
                    HStack {
                        Text(selectedBreed.isEmpty ? "Select Breed" : selectedBreed)
                            .font(Theme.body)
                            .foregroundStyle(selectedBreed.isEmpty ? Theme.secondaryText : Theme.primaryText)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .padding()
                    .frame(minHeight: Theme.minimumTouchTarget) // iOS 26 HIG: Minimum 44pt
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonBorderShape(.roundedRectangle)
                .disabled(selectedSpecies.isEmpty)
                .opacity(selectedSpecies.isEmpty ? 0.5 : 1.0)
                .accessibilityLabel("Select breed")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                // Debug: Picker button meets iOS 26 HIG minimum touch target of 44pt height
                Button(action: {
                    HapticManager.tap()
                    showingCategoryPicker = true
                }) {
                    HStack {
                        Text(selectedCategory.isEmpty ? "Select Category" : selectedCategory)
                            .font(Theme.body)
                            .foregroundStyle(selectedCategory.isEmpty ? Theme.secondaryText : Theme.primaryText)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .padding()
                    .frame(minHeight: Theme.minimumTouchTarget) // iOS 26 HIG: Minimum 44pt
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonBorderShape(.roundedRectangle)
                .disabled(selectedSpecies.isEmpty)
                .opacity(selectedSpecies.isEmpty ? 0.5 : 1.0)
                .accessibilityLabel("Select category")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Breeders (Conditional)
    private var breedersContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header - center aligned and larger font
            Text("Breeders")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Debug: Calving rate title outside container matching other field labels
            VStack(alignment: .leading, spacing: 8) {
                Text("Calving Rate: \(calvingRate)%")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Slider(value: Binding(
                    get: { Double(calvingRate) },
                    set: { calvingRate = Int($0) }
                ), in: 50...100, step: 1)
                .padding()
                .background(Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityLabel("Calving rate")
            
            // Debug: Joined date full width
            VStack(alignment: .leading, spacing: 8) {
                Text("Joined Date")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                DatePicker("", selection: $joinedDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityLabel("Joined date")
            
            // Debug: In Calf full width
            VStack(alignment: .leading, spacing: 8) {
                Text("In Calf")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Toggle("", isOn: $inCalf)
                    .labelsHidden()
                    .tint(Theme.positiveChange)
                    .padding()
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Step 2/3: Physical Attributes
    private var step2Content: some View {
        VStack(alignment: .leading, spacing: 24) {
            Toggle(isOn: $hasBirthDate) {
                Text("Specify Birth Date")
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
            }
            .tint(Theme.accent)
            .padding()
            .background(Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            if hasBirthDate {
                DatePicker("Birth Date", selection: Binding(
                    get: { birthDate ?? Date() },
                    set: { birthDate = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)
                .foregroundStyle(Theme.primaryText)
                .padding()
                .background(Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                // Debug: Field label outside container, value inside with body font
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age (months)")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Stepper(value: $ageMonths, in: 1...120, step: 1) {
                        Text("\(ageMonths) months")
                            .font(Theme.body)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .padding()
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            
            // Debug: Field label outside container, value inside with body font
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Weight (kg)")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                HStack {
                    Slider(value: $initialWeight, in: 50...1000, step: 5)
                    Text("\(Int(initialWeight)) kg")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 80)
                }
                .padding()
                .background(Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            // Debug: Field label outside container, value inside with body font
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Weight Gain (kg/day)")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                HStack {
                    Slider(value: $dailyWeightGain, in: 0...2.0, step: 0.1)
                    Text(String(format: "%.2f kg/day", dailyWeightGain))
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 100)
                }
                .padding()
                .background(Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Step 3/4: Additional Details
    private var step3Content: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
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
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Validation
    private var isStepValid: Bool {
        switch currentStep {
        case 1:
            return !animalName.isEmpty && !selectedBreed.isEmpty && !selectedCategory.isEmpty
        case 2:
            if isBreederCategory {
                return true // Breeder step is always valid
            } else {
                return initialWeight > 0 // Physical attributes
            }
        case 3:
            if isBreederCategory {
                return initialWeight > 0 // Physical attributes
            } else {
                return true // Additional details always valid
            }
        case 4:
            return true // Additional details always valid
        default:
            return false
        }
    }
    
    private func saveAnimal() {
        let prefs = preferences.first ?? UserPreferences()
        
        var calculatedAgeMonths = ageMonths
        if hasBirthDate, let birthDate = birthDate {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.month], from: birthDate, to: Date())
            calculatedAgeMonths = ageComponents.month ?? ageMonths
        }
        
        // Determine sex from category
        let sex: String
        if selectedCategory.lowercased().contains("steer")
            || selectedCategory.lowercased().contains("bull")
            || selectedCategory.lowercased().contains("ram")
            || selectedCategory.lowercased().contains("buck")
            || selectedCategory.lowercased().contains("wether")
            || selectedCategory.lowercased().contains("barrow") {
            sex = "Male"
        } else if selectedCategory.lowercased().contains("heifer")
                    || selectedCategory.lowercased().contains("cow")
                    || selectedCategory.lowercased().contains("ewe")
                    || selectedCategory.lowercased().contains("sow")
                    || selectedCategory.lowercased().contains("doe")
                    || selectedCategory.lowercased().contains("gilt") {
            sex = "Female"
        } else {
            sex = "Mixed"
        }
        
        let herd = HerdGroup(
            name: animalName,
            species: selectedSpecies,
            breed: selectedBreed,
            sex: sex,
            category: selectedCategory,
            ageMonths: calculatedAgeMonths,
            headCount: 1,
            initialWeight: initialWeight,
            dailyWeightGain: dailyWeightGain,
            isBreeder: inCalf || selectedCategory.lowercased().contains("breeding"),
            selectedSaleyard: selectedSaleyard ?? prefs.defaultSaleyard
        )
        
        herd.paddockName = paddockName.isEmpty ? nil : paddockName
        herd.isPregnant = inCalf
        if herd.isPregnant {
            herd.joinedDate = joinedDate
            herd.calvingRate = Double(calvingRate) / 100.0
        }
        
        modelContext.insert(herd)
        
        do {
            try modelContext.save()
            HapticManager.success()
            dismiss()
        } catch {
            HapticManager.error()
            print("Error saving animal: \(error)")
        }
    }
}

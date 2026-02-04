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
    @State private var animalName = "" // Animal ID
    @State private var animalNickname = "" // Optional nickname
    @State private var paddockName = ""
    @State private var selectedSpecies = "Cattle"
    @State private var selectedBreed = ""
    @State private var selectedCategory = ""
    @State private var ageMonths = 12
    @State private var initialWeight: Double = 300
    @State private var dailyWeightGain: Double = 0.0 // Default: 0.0 kg/day (starting at zero)
    @State private var joinedDate = Date()
    // Debug: Breeding-specific state variables (removed inCalf and isPregnant, added breedingProgramType)
    @State private var calvingRate: Int = 50 // Default: 50% (halfway on 0-100% scale)
    @State private var breedingProgramType: BreedingProgramType? = nil // Debug: No default selection - user must choose
    @State private var joiningPeriodStart = Date()
    @State private var joiningPeriodEnd = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var selectedSaleyard: String?
    @State private var tagNumber = ""
    @State private var birthDate: Date?
    @State private var hasBirthDate = false
    @State private var breedSearchText = ""
    @State private var categorySearchText = ""
    @State private var showingBreedPicker = false
    @State private var showingCategoryPicker = false
    @State private var showingSaleyardPicker = false
    // Debug: Calves at foot state (not typically used for individual animals, but needed for component compatibility)
    @State private var calvesAtFootHeadCount: Int? = nil
    @State private var calvesAtFootAgeMonths: Int? = nil
    @State private var calvesAtFootAverageWeight: Int? = nil // Debug: Average weight of calves at foot in kg
    
    private let speciesOptions = ["Cattle", "Sheep", "Pigs", "Goats"]
    
    // Debug: Get user preferences for filtered saleyards
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    // Debug: Determines if category requires breeding-specific step
    private var isBreederCategory: Bool {
        let breederCategories = [
            "Breeder", "Breeder Doe", "Breeder Buck",
            "Maiden Ewe (Joined)", "Heifer (Joined)", "First Calf Heifer"
        ]
        return breederCategories.contains(selectedCategory)
    }
    
    private var totalSteps: Int {
        // Debug: Updated for 3-page split (Location, Species, Breed)
        // Non-breeders: 5 steps (Location, Species, Breed, Physical, Additional)
        // Breeders: 6 steps (Location, Species, Breed, Breeder, Physical, Additional)
        isBreederCategory ? 6 : 5
    }
    
    private var breedOptions: [String] {
        let breeds: [String]
        switch selectedSpecies {
        case "Cattle":
            breeds = ReferenceData.cattleBreeds
        case "Sheep":
            breeds = ReferenceData.sheepBreeds
        case "Pigs":
            breeds = ReferenceData.pigBreeds
        case "Goats":
            breeds = ReferenceData.goatBreeds
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
        case "Pigs":
            categories = ReferenceData.pigCategories
        case "Goats":
            categories = ReferenceData.goatCategories
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
                // Debug: Updated flow logic with 3-page split (Location, Species, Breed)
                ScrollView {
                    VStack(spacing: 0) {
                        if currentStep == 1 {
                            // Step 1: ID & Location (animal ID, optional nickname, location)
                            locationContent
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        } else if currentStep == 2 {
                            // Step 2: Species (species cards only)
                            speciesContent
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        } else if currentStep == 3 {
                            // Step 3: Breed (breed, category)
                            breedContent
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        } else if currentStep == 4 && isBreederCategory {
                            // Step 4: Breeder details (for breeder categories only)
                            breedersContent
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        } else if (currentStep == 4 && !isBreederCategory) || (currentStep == 5 && isBreederCategory) {
                            // Step 4/5: Physical attributes
                            step2Content
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        } else {
                            // Step 5/6: Additional details
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
                                .fill(step <= currentStep ? Theme.accentColor : Theme.primaryText.opacity(0.3))
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
            .sheet(isPresented: $showingSaleyardPicker) {
                SaleyardSelectionSheet(selectedSaleyard: $selectedSaleyard)
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
    
    // MARK: - Step 1: ID & Location
    // Debug: Animal ID, optional nickname, and paddock location
    private var locationContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header
            Text("ID & Location")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Animal ID")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                TextField("e.g. A001 etc", text: $animalName)
                    .textFieldStyle(AddHerdTextFieldStyle())
                    .accessibilityLabel("Animal ID")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("Animal Nickname")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text("Optional")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                TextField("e.g. Bessie", text: $animalNickname)
                    .textFieldStyle(AddHerdTextFieldStyle())
                    .accessibilityLabel("Animal nickname")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("Location")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text("Optional")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                TextField("e.g. North Paddock", text: $paddockName)
                    .textFieldStyle(AddHerdTextFieldStyle())
                    .accessibilityLabel("Location")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Step 2: Species
    // Debug: Species card selector only (gives cards room to breathe)
    private var speciesContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header
            Text("Species")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            
            // Debug: Grid of species cards with emoji icons (2x2 grid with more space)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                // Cattle - Available
                SpeciesCard(
                    emoji: "🐄",
                    name: "Cattle",
                    isAvailable: true,
                    isSelected: selectedSpecies == "Cattle"
                ) {
                    HapticManager.tap()
                    selectedSpecies = "Cattle"
                    selectedBreed = ""
                    selectedCategory = ""
                    breedSearchText = ""
                    categorySearchText = ""
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
            
            // Debug: Subtle info text for coming soon animals (matches onboarding style)
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Theme.secondaryText)
                    .font(.caption)
                Text("Support for Sheep, Pigs, and Goats coming soon!")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Step 3: Breed
    // Debug: Breed and category selection
    private var breedContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header
            Text("Breed")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            
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
    // Debug: Using shared BreedersFormSection component for consistency across flows
    private var breedersContent: some View {
        BreedersFormSection(
            calvingRate: $calvingRate,
            breedingProgramType: $breedingProgramType,
            joiningPeriodStart: $joiningPeriodStart,
            joiningPeriodEnd: $joiningPeriodEnd,
            calvesAtFootHeadCount: $calvesAtFootHeadCount,
            calvesAtFootAgeMonths: $calvesAtFootAgeMonths,
            calvesAtFootAverageWeight: $calvesAtFootAverageWeight
        )
    }
    
    // MARK: - Physical Attributes
    private var step2Content: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header
            Text("Physical")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            
            Toggle(isOn: $hasBirthDate) {
                Text("Specify Birth Date")
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
            }
            .tint(Theme.accentColor)
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
            
            // Debug: Daily weight gain slider (always visible, matches herd flow style)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Average Daily Weight Gain")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text(String(format: "%.1f kg/day", dailyWeightGain))
                        .font(Theme.body)
                        .foregroundStyle(Theme.accentColor)
                        .fontWeight(.semibold)
                }
                
                Slider(value: $dailyWeightGain, in: 0...2.0, step: 0.1)
                    .tint(Theme.accentColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Average daily weight gain")
                    .accessibilityValue(String(format: "%.1f kilograms per day", dailyWeightGain))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Saleyard
    private var step3Content: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header
            Text("Saleyard")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            
            // Debug: Saleyard picker button that opens searchable sheet (no redundant label)
            Button(action: {
                HapticManager.tap()
                showingSaleyardPicker = true
            }) {
                HStack {
                    Text(selectedSaleyard ?? "Use Default")
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
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
            .accessibilityLabel("Select saleyard")
            
            // Debug: Subtle info text (matches onboarding style)
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Theme.secondaryText)
                    .font(.caption)
                Text("Valuation engine currently derived from this saleyard. You can change it later in Settings.")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Validation
    // Debug: Updated validation for 3-page split (Location, Species, Breed)
    private var isStepValid: Bool {
        switch currentStep {
        case 1:
            // Step 1: ID & Location - only animal ID is required
            return !animalName.isEmpty
        case 2:
            // Step 2: Species - species selection required
            return !selectedSpecies.isEmpty
        case 3:
            // Step 3: Breed - breed and category required
            return !selectedBreed.isEmpty && !selectedCategory.isEmpty
        case 4:
            if isBreederCategory {
                // Step 4 (breeders): Breeder details - always valid
                return true
            } else {
                // Step 4 (non-breeders): Physical attributes
                return initialWeight > 0
            }
        case 5:
            if isBreederCategory {
                // Step 5 (breeders): Physical attributes
                return initialWeight > 0
            } else {
                // Step 5 (non-breeders): Additional details - always valid
                return true
            }
        case 6:
            // Step 6 (breeders): Additional details - always valid
            return true
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
        
        // Debug: Determine if this is a breeder category (removed inCalf dependency)
        let isBreeder = selectedCategory.lowercased().contains("breeding") || selectedCategory.lowercased().contains("breeder")
        
        let herd = HerdGroup(
            name: animalNickname, // Nickname (optional, can be empty)
            species: selectedSpecies,
            breed: selectedBreed,
            sex: sex,
            category: selectedCategory,
            ageMonths: calculatedAgeMonths,
            headCount: 1,
            initialWeight: initialWeight,
            dailyWeightGain: dailyWeightGain,
            isBreeder: isBreeder,
            selectedSaleyard: selectedSaleyard ?? prefs.defaultSaleyard,
            animalIdNumber: animalName.isEmpty ? nil : animalName // Animal ID
        )
        
        herd.paddockName = paddockName.isEmpty ? nil : paddockName
        
        // Debug: Set breeding-specific data for breeder categories
        if isBreederCategory {
            herd.isPregnant = true // Fix: Set isPregnant to true so calving accrual shows in Growth and mortality card
            
            // Debug: Calculate joinedDate based on breeding program type
            if let programType = breedingProgramType {
                switch programType {
                case .ai, .controlled:
                    // Debug: For AI and Controlled, use midpoint of period for accrual calculation
                    let startInterval = joiningPeriodStart.timeIntervalSince1970
                    let endInterval = joiningPeriodEnd.timeIntervalSince1970
                    let midpointInterval = (startInterval + endInterval) / 2.0
                    herd.joinedDate = Date(timeIntervalSince1970: midpointInterval)
                case .uncontrolled:
                    // Debug: For Uncontrolled, use start date for 12-month rolling accrual
                    herd.joinedDate = joiningPeriodStart
                }
            } else {
                // Fallback to default joinedDate if no breeding type specified
                herd.joinedDate = joinedDate
            }
            
            herd.calvingRate = Double(calvingRate) / 100.0
            
            // Debug: Store breeding program info in additionalInfo
            if let programType = breedingProgramType {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                
                switch programType {
                case .ai:
                    herd.additionalInfo = "Breeding: AI, Insemination Period: \(formatter.string(from: joiningPeriodStart)) - \(formatter.string(from: joiningPeriodEnd))"
                case .controlled:
                    herd.additionalInfo = "Breeding: Controlled, Joining Period: \(formatter.string(from: joiningPeriodStart)) - \(formatter.string(from: joiningPeriodEnd))"
                case .uncontrolled:
                    herd.additionalInfo = "Breeding: Uncontrolled (year-round)"
                }
            }
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

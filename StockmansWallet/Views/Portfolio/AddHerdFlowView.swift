//
//  AddHerdFlowView.swift
//  StockmansWallet
//
//  3-Step Add Herd Flow (Based on ADD HERD Flow PDF)
//

import SwiftUI
import SwiftData
import UIKit

struct AddHerdFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]
    
    @State private var currentStep = 1
    @State private var isMovingForward = true
    @State private var herdName = "" // Debug: Herd Name (required, simplified from previous Herd ID + Nickname)
    @State private var paddockLocation = ""
    @State private var selectedSpecies = "Cattle"
    @State private var selectedBreed = ""
    @State private var selectedCategory = ""
    // Debug: Optional numeric values for friction-free input (HIG: Forms & Data Entry - empty fields)
    @State private var headCount: Int? = nil
    @State private var averageAgeMonths: Int? = nil
    @State private var averageWeightKg: Int? = nil
    @State private var dailyGainGrams = 0 // Default: 0 kg/day (starting at zero)
    @State private var mortalityRate = 0 // Default: 0% (starting at zero)
    @State private var calvesAtFootHeadCount: Int? = nil
    @State private var calvesAtFootAgeMonths: Int? = nil
    @State private var calvesAtFootAverageWeight: Int? = nil // Debug: Average weight of calves at foot in kg
    @State private var selectedSaleyard: String? = nil
    @State private var additionalInfo = ""
    @State private var breedSearchText = ""
    @State private var categorySearchText = ""
    @State private var showingBreedPicker = false
    @State private var showingCategoryPicker = false
    @State private var showingSaleyardPicker = false
    
    // Debug: Breeding-specific state variables
    @State private var calvingRate = 50 // Default: 50% (halfway on 0-100% scale)
    @State private var joinedDate = Date()
    @State private var breedingProgramType: BreedingProgramType? = nil // Debug: No default selection - user must choose
    @State private var joiningPeriodStart = Date()
    @State private var joiningPeriodEnd = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    
    
    // Performance: Cache filtered options to prevent expensive recomputation on every view update
    // Old approach: computed properties ran switch + filter on EVERY keystroke
    // New approach: only update when dependencies (species, search text) actually change
    @State private var cachedBreedOptions: [String] = []
    @State private var cachedCategoryOptions: [String] = []
    
    private let speciesOptions = ["Cattle", "Sheep", "Pigs", "Goats"]
    
    // Performance: Now returns cached value instead of recomputing
    private var breedOptions: [String] {
        cachedBreedOptions
    }
    
    // Performance: Now returns cached value instead of recomputing
    private var categoryOptions: [String] {
        cachedCategoryOptions
    }
    
    // Debug: Helper to compute breed options (called only when dependencies change)
    private func computeBreedOptions() -> [String] {
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
    
    // Debug: Helper to compute category options (called only when dependencies change)
    private func computeCategoryOptions() -> [String] {
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
    
    
    // Debug: Determines if category requires breeding-specific step (calvingRate, joinedDate, breedingProgramType)
    private var isBreederCategory: Bool {
        let breederCategories = [
            "Breeder", "Breeder Doe", "Breeder Buck",
            "Maiden Ewe (Joined)", "Heifer (Joined)", "First Calf Heifer"
        ]
        return breederCategories.contains(selectedCategory)
    }
    
    // Debug: Determines if "Calves at Foot" section should be shown in Physical Attributes
    private var shouldShowCalvesAtFoot: Bool {
        let calvesAtFootCategories = [
            "Heifer (Joined)", "First Calf Heifer", "Breeder"
        ]
        return calvesAtFootCategories.contains(selectedCategory)
    }
    
    // Debug: Updated step count for 3-page split (Location, Species, Breed)
    // Non-breeders: 5 steps (Location, Species, Breed, Physical, Saleyard)
    // Breeders: 7 steps (Location, Species, Breed, Breeder Selection, Breeding Details, Physical, Saleyard)
    private var totalSteps: Int {
        isBreederCategory ? 7 : 5
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    // Debug: Close button (X) on step 1, back button (chevron) on other steps - meets iOS 26 HIG minimum touch target of 44x44pt
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
                        Image(systemName: currentStep == 1 ? "xmark" : "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.primaryText)
                            .frame(width: 44, height: 44) // iOS 26 HIG: Minimum 44x44pt
                            .background(Theme.inputFieldBackground)
                            .clipShape(Circle())
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .accessibilityLabel(currentStep == 1 ? "Close" : "Back")
                    
                    Spacer()
                    
                    Text("Add Herd")
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
                            // Step 1: ID & Location (herd ID, optional nickname, location)
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
                            // Step 4: Breeder selection (for breeder categories only)
                            breederSelectionContent
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        } else if currentStep == 5 && isBreederCategory {
                            // Step 5: Breeding details (for breeder categories only)
                            breedingDetailsContent
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        } else if (currentStep == 4 && !isBreederCategory) || (currentStep == 6 && isBreederCategory) {
                            // Step 4/6: Physical attributes
                            step2Content
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        } else {
                            // Step 5/7: Saleyard selection
                            step3Content
                                .transition(isMovingForward ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                
                // Bottom controls
                // Debug: No background on bottom controls for cleaner design (like onboarding pages)
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
                            saveHerd()
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
            // Performance: Initialize cached options on appear
            .onAppear {
                cachedBreedOptions = computeBreedOptions()
                cachedCategoryOptions = computeCategoryOptions()
                #if DEBUG
                print("📋 AddHerdFlowView: Initialized cached options (breeds: \(cachedBreedOptions.count), categories: \(cachedCategoryOptions.count))")
                #endif
            }
            // Performance: Update breed options only when dependencies change
            .onChange(of: selectedSpecies) { _, _ in
                cachedBreedOptions = computeBreedOptions()
                cachedCategoryOptions = computeCategoryOptions()
                // Reset breed and category when species changes
                selectedBreed = ""
                selectedCategory = ""
                #if DEBUG
                print("📋 Species changed to \(selectedSpecies), updated options")
                #endif
            }
            // Performance: Update breed options only when search text changes
            .onChange(of: breedSearchText) { _, _ in
                cachedBreedOptions = computeBreedOptions()
            }
            // Performance: Update category options only when search text changes
            .onChange(of: categorySearchText) { _, _ in
                cachedCategoryOptions = computeCategoryOptions()
            }
        }
    }
    
    // MARK: - Step 1: ID & Location
    // Debug: Herd Name (required) and optional paddock location
    private var locationContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header
            Text("ID & Location")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Herd Name")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                TextField("e.g. The Angus Herd", text: $herdName)
                    .textFieldStyle(AddHerdTextFieldStyle())
                    .accessibilityLabel("Herd Name")
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
                TextField("e.g. Swamp Paddock", text: $paddockLocation)
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
    
    // MARK: - Step 4: Breeder Selection (Breeders Only)
    // Debug: Breeder selection screen (AI/Controlled/Uncontrolled)
    private var breederSelectionContent: some View {
        BreederSelectionScreen(breedingProgramType: $breedingProgramType)
    }
    
    // MARK: - Step 5: Breeding Details (Breeders Only)
    // Debug: Breeding-specific inputs based on selected program type
    private var breedingDetailsContent: some View {
        BreedingDetailsScreen(
            breedingProgramType: breedingProgramType,
            calvingRate: $calvingRate,
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
            
            // Debug: HIG-compliant text fields with empty placeholders for friction-free input
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Head")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    TextField("", value: $headCount, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(AddHerdTextFieldStyle())
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("Head count")
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Average Age (mo)")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    TextField("", value: $averageAgeMonths, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(AddHerdTextFieldStyle())
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("Average age in months")
                }
                .frame(maxWidth: .infinity)
            }
            

            
            // Debug: Text field for weight with empty placeholder for friction-free input
            VStack(alignment: .leading, spacing: 8) {
                Text("Average Weight (kg)")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                TextField("", value: $averageWeightKg, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(AddHerdTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Average weight in kilograms")
            }
            
            // Debug: Daily weight gain slider (always visible)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Average Daily Weight Gain")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text(String(format: "%.1f kg/day", Double(dailyGainGrams) / 10.0))
                        .font(Theme.body)
                        .foregroundStyle(Theme.accentColor)
                        .fontWeight(.semibold)
                }
                
                Slider(value: Binding(
                    get: { Double(dailyGainGrams) },
                    set: { dailyGainGrams = Int($0) }
                ), in: 0...30, step: 1)
                    .tint(Theme.accentColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Average daily weight gain")
                    .accessibilityValue(String(format: "%.1f kilograms per day", Double(dailyGainGrams) / 10.0))
            }
            
            // Debug: Mortality rate slider (always visible)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Estimated Mortality")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text("\(mortalityRate)%")
                        .font(Theme.body)
                        .foregroundStyle(Theme.accentColor)
                        .fontWeight(.semibold)
                }
                
                Slider(value: Binding(
                    get: { Double(mortalityRate) },
                    set: { mortalityRate = Int($0) }
                ), in: 0...30, step: 1)
                    .tint(Theme.accentColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Estimated mortality rate")
                    .accessibilityValue("\(mortalityRate) percent")
            }
            
            // Debug: Calves at Foot removed from Physical Attributes (now in Breeding Details screen)
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
            // Step 1: ID & Location - only herd name is required
            return !herdName.isEmpty
        case 2:
            // Step 2: Species - species selection required
            return !selectedSpecies.isEmpty
        case 3:
            // Step 3: Breed - breed and category required
            return !selectedBreed.isEmpty && !selectedCategory.isEmpty
        case 4:
            if isBreederCategory {
                // Step 4 (breeders): Breeder selection - requires user to select an option
                return breedingProgramType != nil
            } else {
                // Step 4 (non-breeders): Physical attributes validation
                return (headCount ?? 0) > 0 && (averageWeightKg ?? 0) > 0
            }
        case 5:
            if isBreederCategory {
                // Step 5 (breeders): Breeding details - always valid (optional fields)
                return true
            } else {
                // Step 5 (non-breeders): Saleyard selection - always valid (has default)
                return true
            }
        case 6:
            // Step 6 (breeders): Physical attributes validation
            return (headCount ?? 0) > 0 && (averageWeightKg ?? 0) > 0
        case 7:
            // Step 7 (breeders): Saleyard selection - always valid (has default)
            return true
        default:
            return false
        }
    }
    
    // MARK: - Save Herd
    private func saveHerd() {
        print("💾 AddHerdFlowView: Starting saveHerd()")
        
        let prefs = preferences.first ?? UserPreferences()
        // Debug: dailyGainGrams is in tenths (0-30 slider where 10 = 1.0 kg/day), so divide by 10
        let dailyWeightGain = Double(dailyGainGrams) / 10.0
        print("💾 AddHerdFlowView: dailyGainGrams=\(dailyGainGrams), converted to dailyWeightGain=\(dailyWeightGain) kg/day")
        
        // Debug: Safely unwrap optional numeric values with sensible defaults
        let finalHeadCount = headCount ?? 1
        let finalAgeMonths = averageAgeMonths ?? 0
        let finalWeightKg = averageWeightKg ?? 300
        
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
        
        // Debug: Use selectedSaleyard if specified, otherwise fall back to default saleyard
        let effectiveSaleyard = selectedSaleyard ?? prefs.defaultSaleyard
        
        // Debug: Determine if this is a breeder category (removed inCalf dependency)
        let isBreeder = selectedCategory.lowercased().contains("breeding") || selectedCategory.lowercased().contains("breeder")
        
        // Debug: Create herd with simplified name field (no separate ID field anymore)
        let herd = HerdGroup(
            name: herdName, // Debug: Herd Name (required, simplified identifier)
            species: selectedSpecies,
            breed: selectedBreed,
            sex: sex,
            category: selectedCategory,
            ageMonths: finalAgeMonths,
            headCount: finalHeadCount,
            initialWeight: Double(finalWeightKg),
            dailyWeightGain: dailyWeightGain,
            isBreeder: isBreeder,
            selectedSaleyard: effectiveSaleyard,
            animalIdNumber: nil // Debug: No longer using separate ID field
        )
        
        print("💾 AddHerdFlowView: Created herd object with ID: \(herd.id)")
        print("   Name: \(herd.name), HeadCount: \(herd.headCount), Species: \(herd.species)")
        print("   InitialWeight: \(herd.initialWeight) kg, DailyWeightGain: \(herd.dailyWeightGain) kg/day")
        
        herd.paddockName = paddockLocation.isEmpty ? nil : paddockLocation
        herd.mortalityRate = Double(mortalityRate) / 100.0
        
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
        }
        
        // Debug: Additional info for calves at foot and breeding program
        var infoParts: [String] = []
        if !additionalInfo.isEmpty { infoParts.append(additionalInfo) }
        if let calvesCount = calvesAtFootHeadCount, let calvesAge = calvesAtFootAgeMonths, calvesCount > 0 {
            var calvesInfo = "Calves at Foot: \(calvesCount) head, \(calvesAge) months"
            // Debug: Add weight if provided
            if let calvesWeight = calvesAtFootAverageWeight, calvesWeight > 0 {
                calvesInfo += ", \(calvesWeight) kg"
            }
            infoParts.append(calvesInfo)
        }
        // Debug: Add breeding program information to additional info
        if isBreederCategory, let programType = breedingProgramType {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            
            switch programType {
            case .ai:
                infoParts.append("Breeding: AI, Insemination Period: \(formatter.string(from: joiningPeriodStart)) - \(formatter.string(from: joiningPeriodEnd))")
            case .controlled:
                infoParts.append("Breeding: Controlled, Joining Period: \(formatter.string(from: joiningPeriodStart)) - \(formatter.string(from: joiningPeriodEnd))")
            case .uncontrolled:
                infoParts.append("Breeding: Uncontrolled (year-round)")
            }
        }
        if !infoParts.isEmpty { herd.additionalInfo = infoParts.joined(separator: " | ") }
        
        // Debug: Insert into model context
        print("💾 AddHerdFlowView: Inserting herd into modelContext")
        modelContext.insert(herd)
        
        do {
            // Debug: Save and ensure the context is properly flushed
            print("💾 AddHerdFlowView: Attempting to save modelContext")
            try modelContext.save()
            print("✅ AddHerdFlowView: Successfully saved herd with ID: \(herd.id)")
            
            // Debug: Small delay to ensure SwiftData propagates the save
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                HapticManager.success()
                dismiss()
            }
        } catch {
            HapticManager.error()
            print("❌ AddHerdFlowView: Error saving herd: \(error)")
            print("   Error details: \(error.localizedDescription)")
        }
    }
}

// MARK: - Searchable Dropdown (kept as-is, with Theme colors)
struct SearchableDropdown: View {
    @Binding var selectedValue: String
    @Binding var searchText: String
    let options: [String]
    let placeholder: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Debug: Dropdown button meets iOS 26 HIG minimum touch target of 44pt height
            Button(action: {
                HapticManager.tap()
                isExpanded.toggle()
            }) {
                HStack {
                    Text(selectedValue.isEmpty ? placeholder : selectedValue)
                        .font(Theme.body)
                        .foregroundStyle(selectedValue.isEmpty ? Theme.secondaryText : Theme.primaryText)
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
            
            if isExpanded {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Theme.secondaryText)
                        TextField("Search...", text: $searchText)
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                    }
                    .padding()
                    .background(Theme.inputFieldBackground)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(options, id: \.self) { option in
                                Button(action: {
                                    HapticManager.tap()
                                    selectedValue = option
                                    searchText = ""
                                    isExpanded = false
                                }) {
                                    HStack {
                                        Text(option)
                                            .font(Theme.body)
                                            .foregroundStyle(Theme.primaryText)
                                        Spacer()
                                        if selectedValue == option {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Theme.accentColor)
                                        }
                                    }
                                    .padding()
                                    .background(Theme.cardBackground.opacity(0.7))
                                }
                                .buttonBorderShape(.roundedRectangle)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .background(Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.primaryText.opacity(0.2), lineWidth: 1)
                )
                .padding(.top, 4)
            }
        }
    }
}

extension Color {
    static let slideUpCardBackground = Theme.cardBackground
    static let fieldBackground = Theme.cardBackground
}

struct AddHerdTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(Theme.primaryText)
    }
}

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Theme.accentColor : Theme.primaryText.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
        }
    }
}

struct ScrollablePickerSheet: View {
    let title: String
    let options: [String]
    @Binding var selectedValue: String
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void
    
    @State private var localSearchText: String = ""
    
    init(title: String, options: [String], selectedValue: Binding<String>, searchText: Binding<String>? = nil, onSelect: @escaping (String) -> Void) {
        self.title = title
        self.options = options
        self._selectedValue = selectedValue
        self._searchText = searchText ?? Binding.constant("")
        self.onSelect = onSelect
    }
    
    private var filteredOptions: [String] {
        if localSearchText.isEmpty { return options }
        return options.filter { $0.localizedCaseInsensitiveContains(localSearchText) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.secondaryText)
                    TextField("Search...", text: $localSearchText)
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                }
                .padding()
                .background(Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredOptions, id: \.self) { option in
                            Button(action: {
                                HapticManager.tap()
                                searchText = localSearchText
                                onSelect(option)
                                dismiss()
                            }) {
                                HStack {
                                    Text(option)
                                        .font(Theme.body)
                                        .foregroundStyle(Theme.primaryText)
                                    Spacer()
                                    if selectedValue == option {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.accentColor)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonBorderShape(.roundedRectangle)
                            .background(Theme.background)
                            
                            Divider()
                                .background(Theme.cardBackground.opacity(0.3))
                                .padding(.leading, 20)
                        }
                    }
                }
                .background(Theme.background)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .foregroundStyle(Theme.accentColor)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            localSearchText = searchText
        }
    }
}

// MARK: - Species Card Component
// Debug: Card component for species selection with "Coming Soon" badge
struct SpeciesCard: View {
    let emoji: String
    let name: String
    let isAvailable: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isAvailable {
                action()
            }
        }) {
            VStack(spacing: 12) {
                // Debug: Emoji icon (will be replaced with custom images later)
                Text(emoji)
                    .font(.system(size: 44))
                
                // Debug: Species name
                Text(name)
                    .font(Theme.headline)
                    .foregroundStyle(isAvailable ? Theme.primaryText : Theme.secondaryText)
                
                // Debug: "Coming Soon" badge for unavailable species
                if !isAvailable {
                    Text("Coming Soon")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140) // Fixed height for consistency
            .padding()
            .background(
                // Debug: Show selected state with accent color border
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isAvailable ? Theme.inputFieldBackground : Theme.inputFieldBackground.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(isSelected ? Theme.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonBorderShape(.roundedRectangle)
        .disabled(!isAvailable)
        .accessibilityLabel(isAvailable ? name : "\(name) coming soon")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(!isAvailable ? "This animal type will be available in a future update" : "")
    }
}

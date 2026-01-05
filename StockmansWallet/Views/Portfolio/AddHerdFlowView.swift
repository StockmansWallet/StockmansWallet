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
    @State private var herdName = ""
    @State private var paddockLocation = ""
    @State private var selectedSpecies = "Cattle"
    @State private var selectedBreed = ""
    @State private var selectedCategory = ""
    @State private var headCount = 0
    @State private var averageAgeMonths = 0
    @State private var averageWeightKg = 300
    @State private var dailyGainGrams = 0
    @State private var mortalityRate = 0
    @State private var calvesAtFootHeadCount = 0
    @State private var calvesAtFootAgeMonths = 0
    @State private var selectedSaleyard: String? = nil
    @State private var inCalf = true
    @State private var additionalInfo = ""
    @State private var breedSearchText = ""
    @State private var categorySearchText = ""
    @State private var showingBreedPicker = false
    @State private var showingCategoryPicker = false
    @State private var showingSaleyardPicker = false
    
    @State private var calvingRate = 0
    @State private var joinedDate = Date()
    @State private var controlledBreedingProgram = false
    @State private var joiningPeriodStart = Date()
    @State private var joiningPeriodEnd = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    
    private let speciesOptions = ["Cattle", "Sheep", "Pigs", "Goats"]
    
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
    
    // Debug: Determines if category requires breeding-specific step (calvingRate, joinedDate, inCalf)
    private var isBreederCategory: Bool {
        let breederCategories = [
            "Breeding Cow", "Breeding Ewe", "Breeder Sow", "Breeding Doe",
            "Maiden Ewe (Joined)", "Heifer (Joined)", "First Calf Heifer"
        ]
        return breederCategories.contains(selectedCategory)
    }
    
    // Debug: Determines if "Calves at Foot" section should be shown in Physical Attributes
    private var shouldShowCalvesAtFoot: Bool {
        let calvesAtFootCategories = [
            "Heifer (Joined)", "First Calf Heifer", "Breeding Cow"
        ]
        return calvesAtFootCategories.contains(selectedCategory)
    }
    
    private var totalSteps: Int {
        isBreederCategory ? 4 : 3
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
            .sheet(isPresented: $showingSaleyardPicker) {
                AddHerdSaleyardSelectionSheet(selectedSaleyard: $selectedSaleyard)
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
    
    // MARK: - Step 1
    private var step1Content: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Herd Name")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                TextField("e.g. North Paddock Herd", text: $herdName)
                    .textFieldStyle(AddHerdTextFieldStyle())
                    .accessibilityLabel("Herd name")
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
                TextField("e.g. North Paddock", text: $paddockLocation)
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
                // Note: SwiftUI segmented controls don't reliably respect custom tint colors in dark mode
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
            
            // Debug: HIG-compliant slider for calving rate (estimated percentage)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Calving Rate")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text("\(calvingRate)%")
                        .font(Theme.body)
                        .foregroundStyle(Theme.accent)
                        .fontWeight(.semibold)
                }
                Slider(value: Binding(
                    get: { Double(calvingRate) },
                    set: { calvingRate = Int($0) }
                ), in: 50...100, step: 1)
                    .tint(Theme.accent)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Calving rate")
                    .accessibilityValue("\(calvingRate) percent")
            }
            
            // Debug: HIG-compliant toggle for In Calf status
            HStack {
                Text("In Calf")
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Toggle("", isOn: $inCalf)
                    .labelsHidden()
                    .tint(Theme.accent)
            }
            .padding()
            .background(Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityLabel("In calf status")
            
            // Debug: Breeding Program section - controls joining period
            VStack(alignment: .leading, spacing: 12) {
                Text("Breeding Program")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                // Debug: Toggle for controlled breeding program
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Controlled Program")
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                        Text(controlledBreedingProgram ? "Specific joining period" : "Accruing all year round")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                    Toggle("", isOn: $controlledBreedingProgram)
                        .labelsHidden()
                        .tint(Theme.accent)
                }
                .padding()
                .background(Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityLabel("Controlled breeding program")
                
                // Debug: Show joining period date range if controlled program is enabled
                if controlledBreedingProgram {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Joining Period")
                            .font(Theme.body)
                            .foregroundStyle(Theme.secondaryText)
                        
                        VStack(spacing: 12) {
                            // Start date
                            HStack {
                                Text("Start")
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.secondaryText)
                                    .frame(width: 60, alignment: .leading)
                                DatePicker("", selection: $joiningPeriodStart, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }
                            
                            Divider()
                                .background(Theme.primaryText.opacity(0.2))
                            
                            // End date
                            HStack {
                                Text("End")
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.secondaryText)
                                    .frame(width: 60, alignment: .leading)
                                DatePicker("", selection: $joiningPeriodEnd, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }
                        }
                        .padding()
                        .background(Theme.inputFieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .accessibilityLabel("Joining period date range")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Step 2
    private var step2Content: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header - center aligned and larger font
            Text("Physical Attributes")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Debug: HIG-compliant text fields for known numeric values (head count, age)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Head Count")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    TextField("0", value: $headCount, format: .number)
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
                    TextField("0", value: $averageAgeMonths, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(AddHerdTextFieldStyle())
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("Average age in months")
                }
                .frame(maxWidth: .infinity)
            }
            

            
            // Debug: Text field for weight (known measured value)
            VStack(alignment: .leading, spacing: 8) {
                Text("Average Weight (kg)")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                TextField("0", value: $averageWeightKg, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(AddHerdTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Average weight in kilograms")
            }
            
            // Debug: HIG-compliant slider for daily gain (estimated value, visual feedback useful)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily Weight Gain")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text(String(format: "%.1f kg/day", Double(dailyGainGrams) / 10.0))
                        .font(Theme.body)
                        .foregroundStyle(Theme.accent)
                        .fontWeight(.semibold)
                }
                Slider(value: Binding(
                    get: { Double(dailyGainGrams) },
                    set: { dailyGainGrams = Int($0) }
                ), in: 0...30, step: 1)
                    .tint(Theme.accent)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Daily weight gain")
                    .accessibilityValue(String(format: "%.1f kilograms per day", Double(dailyGainGrams) / 10.0))
            }
            

            
            // Debug: HIG-compliant slider for mortality rate (estimated percentage, slider is ideal)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Mortality Rate")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text("\(mortalityRate)%")
                        .font(Theme.body)
                        .foregroundStyle(Theme.accent)
                        .fontWeight(.semibold)
                }
                Slider(value: Binding(
                    get: { Double(mortalityRate) },
                    set: { mortalityRate = Int($0) }
                ), in: 0...30, step: 1)
                    .tint(Theme.accent)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Mortality rate")
                    .accessibilityValue("\(mortalityRate) percent")
            }
            
            // Debug: Only show "Calves at Foot" for breeder cattle categories
            if shouldShowCalvesAtFoot {
                Text("Calves at Foot")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                // Debug: Text fields for known calf counts and ages
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Head Count")
                            .font(Theme.body)
                            .foregroundStyle(Theme.secondaryText)
                        TextField("0", value: $calvesAtFootHeadCount, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(AddHerdTextFieldStyle())
                            .multilineTextAlignment(.center)
                            .accessibilityLabel("Calves head count")
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Average Age (mo)")
                            .font(Theme.body)
                            .foregroundStyle(Theme.secondaryText)
                        TextField("0", value: $calvesAtFootAgeMonths, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(AddHerdTextFieldStyle())
                            .multilineTextAlignment(.center)
                            .accessibilityLabel("Calves average age in months")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Step 3
    private var step3Content: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header - center aligned and larger font
            Text("Saleyard Selection")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Debug: Saleyard picker button that opens searchable sheet
            VStack(alignment: .leading, spacing: 8) {
                Text("Saleyard")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                // Debug: Picker button meets iOS 26 HIG minimum touch target of 44pt height
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
            }
            
            // Debug: Informative text about valuation engine - placed below picker
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Theme.accent)
                        .font(.system(size: 16))
                        .padding(.top, 2)
                    
                    Text("Valuation engine currently derived from this saleyard. You can change it later in Settings.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Theme.accent.opacity(0.1))
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
            return !herdName.isEmpty && !selectedBreed.isEmpty && !selectedCategory.isEmpty
        case 2:
            if isBreederCategory {
                return true
            } else {
                return headCount > 0 && averageWeightKg > 0
            }
        case 3:
            if isBreederCategory {
                return headCount > 0 && averageWeightKg > 0
            } else {
                return true
            }
        case 4:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Save Herd
    private func saveHerd() {
        let prefs = preferences.first ?? UserPreferences()
        let dailyWeightGain = Double(dailyGainGrams) / 1000.0
        
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
        
        let herd = HerdGroup(
            name: herdName,
            species: selectedSpecies,
            breed: selectedBreed,
            sex: sex,
            category: selectedCategory,
            ageMonths: averageAgeMonths,
            headCount: headCount,
            initialWeight: Double(averageWeightKg),
            dailyWeightGain: dailyWeightGain,
            isBreeder: inCalf || selectedCategory.lowercased().contains("breeding"),
            selectedSaleyard: effectiveSaleyard
        )
        
        herd.paddockName = paddockLocation.isEmpty ? nil : paddockLocation
        herd.isPregnant = inCalf
        herd.mortalityRate = Double(mortalityRate) / 100.0
        
        // Debug: Set breeding-specific data for breeder categories
        if isBreederCategory {
            herd.joinedDate = joinedDate
            herd.calvingRate = Double(calvingRate) / 100.0
        }
        
        // Debug: Additional info for calves at foot and breeding program
        var infoParts: [String] = []
        if !additionalInfo.isEmpty { infoParts.append(additionalInfo) }
        if calvesAtFootHeadCount > 0 {
            infoParts.append("Calves at Foot: \(calvesAtFootHeadCount) head, \(calvesAtFootAgeMonths) months")
        }
        if isBreederCategory {
            if controlledBreedingProgram {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                infoParts.append("Controlled Breeding: \(formatter.string(from: joiningPeriodStart)) - \(formatter.string(from: joiningPeriodEnd))")
            } else {
                infoParts.append("Breeding: All year round")
            }
        }
        if !infoParts.isEmpty { herd.additionalInfo = infoParts.joined(separator: " | ") }
        
        modelContext.insert(herd)
        
        do {
            try modelContext.save()
            HapticManager.success()
            dismiss()
        } catch {
            HapticManager.error()
            print("Error saving herd: \(error)")
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
                                                .foregroundStyle(Theme.accent)
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
                    .fill(step <= currentStep ? Theme.accent : Theme.primaryText.opacity(0.3))
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
                                            .foregroundStyle(Theme.accent)
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
                    .foregroundStyle(Theme.accent)
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

// MARK: - Add Herd Saleyard Selection Sheet
// Debug: HIG-compliant searchable sheet for selecting saleyard during Add Herd flow
struct AddHerdSaleyardSelectionSheet: View {
    @Binding var selectedSaleyard: String?
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]
    @State private var searchText = ""
    
    // Debug: Get user preferences for filtered saleyards
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    // Debug: Filter saleyards based on search text and user preferences
    private var filteredSaleyards: [String] {
        let enabledSaleyards = userPrefs.filteredSaleyards
        if searchText.isEmpty {
            return enabledSaleyards
        } else {
            return enabledSaleyards.filter { 
                $0.localizedCaseInsensitiveContains(searchText) 
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Debug: Default option section
                Section {
                    Button(action: {
                        HapticManager.tap()
                        selectedSaleyard = nil
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use Default")
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                
                                if let defaultSaleyard = userPrefs.defaultSaleyard {
                                    Text(defaultSaleyard)
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedSaleyard == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accent)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }
                
                // Debug: All saleyards section - filterable by search
                Section {
                    ForEach(filteredSaleyards, id: \.self) { saleyard in
                        Button(action: {
                            HapticManager.tap()
                            selectedSaleyard = saleyard
                            dismiss()
                        }) {
                            HStack {
                                Text(saleyard)
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                if selectedSaleyard == saleyard {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.accent)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("Select Specific Saleyard")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                
                // Debug: Show helpful message if no results
                if filteredSaleyards.isEmpty {
                    Section {
                        Text("No saleyards found")
                            .font(Theme.body)
                            .foregroundStyle(Theme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search saleyards")
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Select Saleyard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

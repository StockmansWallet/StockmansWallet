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
    @State private var priceSource = ""
    @State private var combinedAll = false
    @State private var inCalf = true
    @State private var additionalInfo = ""
    @State private var breedSearchText = ""
    @State private var categorySearchText = ""
    @State private var showingBreedPicker = false
    @State private var showingCategoryPicker = false
    @State private var showingPriceSourcePicker = false
    
    @State private var calvingRate = 0
    @State private var joinedDate = Date()
    
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
    
    private var isBreederCategory: Bool {
        let breederCategories = [
            "Breeding Cow", "Breeding Ewe", "Breeder Sow", "Breeding Doe",
            "Maiden Ewe (Joined)"
        ]
        return breederCategories.contains(selectedCategory)
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
                    
                    Text("Add Herd / Mob")
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
            .sheet(isPresented: $showingPriceSourcePicker) {
                ScrollablePickerSheet(
                    title: "Select Price Source",
                    options: ReferenceData.priceSources,
                    selectedValue: $priceSource,
                    onSelect: { source in
                        priceSource = source
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
    
    // MARK: - Step 2
    private var step2Content: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header - center aligned and larger font
            Text("Physical Attributes")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Head Count")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Picker("Head Count", selection: $headCount) {
                        ForEach(0...5000, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 80)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Average Age (mo)")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Picker("Average Age", selection: $averageAgeMonths) {
                        ForEach(0...180, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 80)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(maxWidth: .infinity)
            }
            
            Text("Weight")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
                .padding(.top, 4)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Average (kg)")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Picker("Average Weight", selection: $averageWeightKg) {
                        ForEach(weightRange, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 80)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Gain (kg)")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Picker("Daily Gain", selection: $dailyGainGrams) {
                        ForEach(0...30, id: \.self) { value in
                            Text(String(format: "%.1f", Double(value) / 10.0)).tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 80)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(maxWidth: .infinity)
            }
            
            Text("Health")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Mortality Rate")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                Picker("Mortality Rate", selection: $mortalityRate) {
                    ForEach(0...30, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 80)
                .background(Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            Text("Calves at Foot")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Head Count")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Picker("Calves Head Count", selection: $calvesAtFootHeadCount) {
                        ForEach(0...5000, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 80)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Average Age (mo)")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Picker("Calves Average Age", selection: $calvesAtFootAgeMonths) {
                        ForEach(0...24, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 80)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    private var weightRange: [Int] {
        switch selectedSpecies {
        case "Cattle":
            return Array(stride(from: 25, through: 1200, by: 5))
        case "Sheep":
            return Array(2...160)
        case "Goats":
            return Array(2...140)
        case "Pigs":
            return Array(1...350)
        default:
            return Array(stride(from: 1, through: 1200, by: 5))
        }
    }
    
    // MARK: - Step 3
    private var step3Content: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Price Source")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                // Debug: Picker button meets iOS 26 HIG minimum touch target of 44pt height
                Button(action: {
                    HapticManager.tap()
                    showingPriceSourcePicker = true
                }) {
                    HStack {
                        Text(priceSource.isEmpty ? "Select Source" : priceSource)
                            .font(Theme.body)
                            .foregroundStyle(priceSource.isEmpty ? Theme.secondaryText : Theme.primaryText)
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
                .accessibilityLabel("Select price source")
            }
            
            Toggle(isOn: $combinedAll) {
                Text("Combined (All)")
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
            }
            .tint(Theme.accent)
            .padding()
            .background(Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            selectedSaleyard: priceSource == "Saleyard" ? prefs.defaultSaleyard : nil
        )
        
        herd.paddockName = paddockLocation.isEmpty ? nil : paddockLocation
        herd.isPregnant = inCalf
        herd.mortalityRate = Double(mortalityRate) / 100.0
        
        var infoParts: [String] = []
        if !additionalInfo.isEmpty { infoParts.append(additionalInfo) }
        if calvesAtFootHeadCount > 0 {
            infoParts.append("Calves at Foot: \(calvesAtFootHeadCount) head, \(calvesAtFootAgeMonths) months")
        }
        if combinedAll { infoParts.append("Combined (All): Yes") }
        if priceSource != "Private Sales" { infoParts.append("Price Source: \(priceSource)") }
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

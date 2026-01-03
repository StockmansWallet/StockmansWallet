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
    
    @State private var animalName = ""
    @State private var selectedSpecies = "Cattle"
    @State private var selectedBreed = ""
    @State private var selectedCategory = ""
    @State private var sex = "Male"
    @State private var ageMonths = 12
    @State private var initialWeight: Double = 300
    @State private var dailyWeightGain: Double = 0.5
    @State private var isBreeder = false
    @State private var isPregnant = false
    @State private var joinedDate = Date()
    @State private var calvingRate: Double = 0.85
    @State private var selectedSaleyard: String?
    @State private var paddockName = ""
    @State private var tagNumber = ""
    @State private var birthDate: Date?
    @State private var hasBirthDate = false
    
    private let speciesOptions = ["Cattle", "Sheep", "Pig"]
    
    private var breedOptions: [String] {
        switch selectedSpecies {
        case "Cattle":
            return ReferenceData.cattleBreeds
        case "Sheep":
            return ["Merino", "Dorper", "Poll Dorset", "Suffolk", "Border Leicester", "Corriedale", "Romney", "Other"]
        case "Pig":
            return ["Large White", "Landrace", "Duroc", "Hampshire", "Pietrain", "Berkshire", "Other"]
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
        case "Pig":
            return ReferenceData.pigCategories
        default:
            return []
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    // Debug: Back button meets iOS 26 HIG minimum touch target of 44x44pt
                    Button(action: {
                        HapticManager.tap()
                        dismiss()
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
                    VStack(spacing: 24) {
                        // Basic Information (no card, no title)
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Animal Name/Tag")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                TextField("e.g., TAG-001 or Bessie", text: $animalName)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Theme.inputFieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
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
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
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
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
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
                        
                        // Physical Attributes (no section title)
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $hasBirthDate) {
                                    Text("Specify Birth Date")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                }
                                .tint(Theme.accent)
                                
                                if hasBirthDate {
                                    DatePicker("Birth Date", selection: Binding(
                                        get: { birthDate ?? Date() },
                                        set: { birthDate = $0 }
                                    ), displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
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
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Weight (kg)")
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
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
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
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        
                        // Additional Details (no section title)
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Paddock Name (Optional)")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                TextField("e.g., North Paddock", text: $paddockName)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Theme.inputFieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Saleyard (Optional)")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                Picker("Saleyard", selection: $selectedSaleyard) {
                                    Text("Use Default").tag(nil as String?)
                                    ForEach(ReferenceData.saleyards, id: \.self) { saleyard in
                                        Text(saleyard).tag(saleyard as String?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(Theme.inputFieldBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            Toggle(isOn: $isBreeder) {
                                Text("Breeding Stock")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                            }
                            .tint(Theme.accent)
                            .padding()
                            .background(Theme.inputFieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
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
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                }
                                .padding()
                                .background(Theme.cardBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                
                // Bottom controls (matching AddHerdFlowView)
                // Debug: No background on bottom controls for cleaner design
                VStack(spacing: 16) {
                    // Debug: Using Theme.PrimaryButtonStyle for iOS 26 HIG compliance (52pt height, proper styling)
                    Button(action: {
                        HapticManager.tap()
                        saveAnimal()
                    }) {
                        Text("Save")
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .disabled(!isValid)
                    .opacity(isValid ? 1.0 : 0.5)
                    .padding(.horizontal, 20)
                    .accessibilityLabel("Save animal")
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .background(Theme.sheetBackground.ignoresSafeArea())
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
        }
    }
    
    private var isValid: Bool {
        !animalName.isEmpty && !selectedBreed.isEmpty && !selectedCategory.isEmpty && initialWeight > 0
    }
    
    private func saveAnimal() {
        let prefs = preferences.first ?? UserPreferences()
        
        var calculatedAgeMonths = ageMonths
        if hasBirthDate, let birthDate = birthDate {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.month], from: birthDate, to: Date())
            calculatedAgeMonths = ageComponents.month ?? ageMonths
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
            isBreeder: isBreeder,
            selectedSaleyard: selectedSaleyard ?? prefs.defaultSaleyard
        )
        
        herd.paddockName = paddockName.isEmpty ? nil : paddockName
        herd.isPregnant = isBreeder && isPregnant
        if herd.isPregnant {
            herd.joinedDate = joinedDate
            herd.calvingRate = calvingRate
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

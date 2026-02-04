//
//  BreedersFormSection.swift
//  StockmansWallet
//
//  Shared reusable component for breeding-related fields in Add Herd and Add Individual flows
//  Debug: Single source of truth for breeder data entry
//  Rule: Simple solutions, HIG compliance
//

import SwiftUI

// MARK: - Breeding Program Type Enum
// Debug: Three breeding program options for breeder management
enum BreedingProgramType: String, CaseIterable {
    case ai = "Artificial Insemination"
    case controlled = "Controlled Breeding"
    case uncontrolled = "Uncontrolled Breeding"
    
    // Debug: Helper to get description for each breeding type
    var description: String {
        switch self {
        case .ai:
            return "Breeding is managed through planned insemination dates rather than running bulls."
        case .controlled:
            return "A defined joining period where bulls are added and removed at set dates."
        case .uncontrolled:
            return "Bulls run with breeders year-round with no defined joining period."
        }
    }
    
    // Debug: Helper to check if breeding type requires date picker
    var requiresDatePicker: Bool {
        switch self {
        case .ai, .controlled:
            return true
        case .uncontrolled:
            return false
        }
    }
    
    // Debug: Label for date picker based on breeding type
    var datePickerLabel: String {
        switch self {
        case .ai:
            return "Insemination Period"
        case .controlled:
            return "Joining Period"
        case .uncontrolled:
            return ""
        }
    }
    
    // Debug: Helper note about calving accrual timing
    var calvingNote: String {
        switch self {
        case .ai:
            return "Calving accrual commences at midpoint of insemination period, reaching 100% at calving (~9 months)"
        case .controlled:
            return "Calving accrual commences at midpoint of joining period, reaching 100% at calving (~9 months)"
        case .uncontrolled:
            return "Calving accrual progresses over 12 months based on your calving rate, reflecting year-round breeding"
        }
    }
}

// MARK: - Breeder Selection Screen
// Debug: Initial screen to select breeding program type (matches reference screenshot)
struct BreederSelectionScreen: View {
    @Binding var breedingProgramType: BreedingProgramType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header - center aligned title
            Text("Breeder")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Debug: Section description - left aligned
            Text("Select the breeding program that best suits your operation. This helps calculate calf accruals.")
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Debug: Breeding program options - three cards with radio button style
            VStack(spacing: 12) {
                ForEach(BreedingProgramType.allCases, id: \.self) { programType in
                    breedingOptionCard(for: programType)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Breeding Option Card
    // Debug: Individual selectable card for each breeding program type
    @ViewBuilder
    private func breedingOptionCard(for programType: BreedingProgramType) -> some View {
        Button {
            HapticManager.tap()
            withAnimation(.easeInOut(duration: 0.2)) {
                breedingProgramType = programType
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Debug: Radio button indicator (circle or checkmark)
                Image(systemName: breedingProgramType == programType ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(breedingProgramType == programType ? Theme.accentColor : Theme.secondaryText)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Debug: Show AI label inline with text instead of badge
                    Text(programType == .ai ? "\(programType.rawValue) (AI)" : programType.rawValue)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Text(programType.description)
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(breedingProgramType == programType ? Theme.accentColor.opacity(0.1) : Theme.inputFieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(breedingProgramType == programType ? Theme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(programType.rawValue)
        .accessibilityAddTraits(breedingProgramType == programType ? [.isSelected] : [])
    }
}

// MARK: - Breeding Details Screen
// Debug: Second screen showing breeding-specific inputs based on selected program type
struct BreedingDetailsScreen: View {
    let breedingProgramType: BreedingProgramType?
    @Binding var calvingRate: Int
    @Binding var joiningPeriodStart: Date
    @Binding var joiningPeriodEnd: Date
    @Binding var calvesAtFootHeadCount: Int?
    @Binding var calvesAtFootAgeMonths: Int?
    @Binding var calvesAtFootAverageWeight: Int? // Debug: Average weight of calves at foot in kg
    
    var body: some View {
        // Debug: Show selection screen if no program type selected, otherwise show details
        if let programType = breedingProgramType {
            VStack(alignment: .leading, spacing: 24) {
                // Debug: Section header - breeding type title
                Text(programType.rawValue)
                    .font(Theme.title)
                    .foregroundStyle(Theme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Debug: Section description
                Text(programType.description)
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Debug: Date picker section for AI and Controlled Breeding
                if programType.requiresDatePicker {
                VStack(alignment: .leading, spacing: 8) {
                    Text(programType.datePickerLabel)
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    
                    // Debug: Horizontal date pickers for Start and End dates
                    HStack(spacing: 12) {
                        // Start date picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            DatePicker("", selection: $joiningPeriodStart, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // End date picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("End")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            DatePicker("", selection: $joiningPeriodEnd, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .accessibilityLabel("\(programType.datePickerLabel) date range")
            }
            
            // Debug: Estimated Calving slider (0-100% range as shown in screenshots)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Estimated Calving")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text("\(calvingRate)%")
                        .font(Theme.body)
                        .foregroundStyle(Theme.accentColor)
                        .fontWeight(.semibold)
                }
                
                Slider(value: Binding(
                    get: { Double(calvingRate) },
                    set: { calvingRate = Int($0) }
                ), in: 0...100, step: 1)
                    .tint(Theme.accentColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(Theme.inputFieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Estimated calving rate")
                    .accessibilityValue("\(calvingRate) percent")
            }
            
            // Debug: Calves at Foot section (moved from Physical Attributes to match screenshots)
            VStack(alignment: .leading, spacing: 8) {
                Text("Calves at Foot")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                
                // Debug: Three text fields for Head, Average Age, and Average Weight
                VStack(spacing: 12) {
                    // Head and Age fields side by side
                    HStack(spacing: 12) {
                        // Head field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Head")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            TextField("", value: $calvesAtFootHeadCount, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(AddHerdTextFieldStyle())
                                .multilineTextAlignment(.center)
                                .accessibilityLabel("Calves head count")
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Average Age field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Average Age (Months)")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            TextField("", value: $calvesAtFootAgeMonths, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(AddHerdTextFieldStyle())
                                .multilineTextAlignment(.center)
                                .accessibilityLabel("Calves average age in months")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Average Weight field (full width)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Average Weight (kg)")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        TextField("", value: $calvesAtFootAverageWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(AddHerdTextFieldStyle())
                            .multilineTextAlignment(.center)
                            .accessibilityLabel("Calves average weight in kilograms")
                    }
                }
                .padding()
                .background(Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            // Debug: Info note about calving accrual timing for all breeding types
            if !programType.calvingNote.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Theme.secondaryText)
                        .font(.system(size: 14))
                    Text(programType.calvingNote)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.secondaryText.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Legacy Breeders Form Section (deprecated)
// Debug: Keep for backward compatibility but recommend using new screens above
struct BreedersFormSection: View {
    @Binding var calvingRate: Int
    @Binding var breedingProgramType: BreedingProgramType?
    @Binding var joiningPeriodStart: Date
    @Binding var joiningPeriodEnd: Date
    @Binding var calvesAtFootHeadCount: Int?
    @Binding var calvesAtFootAgeMonths: Int?
    @Binding var calvesAtFootAverageWeight: Int? // Debug: Average weight of calves at foot in kg
    
    var body: some View {
        // Debug: Show selection screen if no program type selected, otherwise show details
        if breedingProgramType == nil {
            BreederSelectionScreen(breedingProgramType: $breedingProgramType)
        } else {
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
    }
}




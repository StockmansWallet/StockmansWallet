//
//  BreedersFormSection.swift
//  StockmansWallet
//
//  Shared reusable component for breeding-related fields in Add Herd and Add Individual flows
//  Debug: Single source of truth for breeder data entry
//

import SwiftUI

// MARK: - Breeding Program Type Enum
// Debug: Three breeding program options for breeder management
enum BreedingProgramType: String, CaseIterable {
    case ai = "Artificial Insemination (AI)"
    case controlled = "Controlled Breeding"
    case uncontrolled = "Uncontrolled Breeding"
    
    // Debug: Helper to get description for each breeding type
    var description: String {
        switch self {
        case .ai:
            return "Breeding is managed through planned insemination dates rather than running bulls.\n*Calving accrual commences midpoint of the insemination period"
        case .controlled:
            return "A defined joining period where bulls are added and removed at set dates.\n*Calving accrual commences midpoint of the joining period"
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
}

// MARK: - Breeders Form Section
// Debug: HIG-compliant form section for breeder animals shared across add herd/individual flows
struct BreedersFormSection: View {
    @Binding var calvingRate: Int
    @Binding var breedingProgramType: BreedingProgramType
    @Binding var joiningPeriodStart: Date
    @Binding var joiningPeriodEnd: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Debug: Section header - center aligned and larger font
            Text("Breeders")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Debug: Section description
            Text("Select how you manage joining. This determines how calving value accrues in your herd.")
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Debug: Breeding program options
            VStack(spacing: 16) {
                ForEach(BreedingProgramType.allCases, id: \.self) { programType in
                    breedingProgramCard(for: programType)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    // MARK: - Breeding Program Card
    // Debug: Individual card for each breeding program option
    @ViewBuilder
    private func breedingProgramCard(for programType: BreedingProgramType) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Debug: Selection button with program title and description
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    breedingProgramType = programType
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    // Debug: Radio button indicator
                    Image(systemName: breedingProgramType == programType ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(breedingProgramType == programType ? Theme.accent : Theme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(programType.rawValue)
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                            .multilineTextAlignment(.leading)
                        
                        Text(programType.description)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(breedingProgramType == programType ? Theme.accent.opacity(0.1) : Theme.inputFieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(breedingProgramType == programType ? Theme.accent : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            
            // Debug: Show content if this program type is selected
            if breedingProgramType == programType {
                VStack(alignment: .leading, spacing: 16) {
                    // Debug: Date picker for AI and Controlled Breeding only (shown above slider)
                    if programType.requiresDatePicker {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(programType.datePickerLabel)
                                .font(Theme.body)
                                .foregroundStyle(Theme.secondaryText)
                            
                            // Debug: Horizontal layout for Start and End date pickers
                            HStack(spacing: 12) {
                                // Start date
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                    DatePicker("", selection: $joiningPeriodStart, displayedComponents: .date)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                }
                                .frame(maxWidth: .infinity)
                                
                                // End date
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("End")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                    DatePicker("", selection: $joiningPeriodEnd, displayedComponents: .date)
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(Theme.inputFieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .accessibilityLabel("\(programType.datePickerLabel) date range")
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Debug: Estimated Calving slider - shown below date pickers for all breeding types
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Estimated Calving")
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
                            .accessibilityLabel("Estimated calving rate")
                            .accessibilityValue("\(calvingRate) percent")
                    }
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}




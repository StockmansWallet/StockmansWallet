//
//  BreedersFormSection.swift
//  StockmansWallet
//
//  Shared reusable component for breeding-related fields in Add Herd and Add Individual flows
//  Debug: Single source of truth for breeder data entry
//

import SwiftUI

// MARK: - Breeders Form Section
// Debug: HIG-compliant form section for breeder animals shared across add herd/individual flows
struct BreedersFormSection: View {
    @Binding var calvingRate: Int
    @Binding var inCalf: Bool
    @Binding var controlledBreedingProgram: Bool
    @Binding var joiningPeriodStart: Date
    @Binding var joiningPeriodEnd: Date
    
    var body: some View {
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
}




//
//  ThemedSegmentedControl.swift
//  StockmansWallet
//
//  Flat themed segmented control that follows Apple HIG sizing and behavior.
//  Debug: Matches app theme while preserving segmented control semantics.
//

import SwiftUI

// Debug: Reusable segmented control with themed styling and smooth selection animation.
struct ThemedSegmentedControl<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String
    let accessibilityLabel: String
    
    @Namespace private var selectionNamespace
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                
                Button {
                    guard selection != option else { return }
                    HapticManager.selectionChanged()
                    // Debug: Respect reduce motion while keeping HIG-style motion.
                    if Theme.prefersReducedMotion {
                        selection = option
                    } else {
                        withAnimation(.easeInOut(duration: Theme.animationDuration(0.18))) {
                            selection = option
                        }
                    }
                } label: {
                    Text(label(option))
                        .font(Theme.headline)
                        .foregroundStyle(isSelected ? Theme.primaryText : Theme.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: Theme.minimumTouchTarget)
                        .padding(.vertical, 4)
                        .background {
                            if isSelected {
                                Theme.continuousRoundedRect(12)
                                    .fill(Theme.secondaryBackground)
                                    .matchedGeometryEffect(id: "themed-segment-selection", in: selectionNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label(option))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Theme.cardBackground)
        .overlay(
            Theme.continuousRoundedRect(14)
                .stroke(Theme.separator, lineWidth: 1)
        )
        .clipShape(Theme.continuousRoundedRect(14))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }
}


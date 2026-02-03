//
//  SaleyardSelector.swift
//  StockmansWallet
//
//  Saleyard selector button that opens sheet
//

import SwiftUI

struct SaleyardSelector: View {
    @Binding var selectedSaleyard: String?
    @State private var showingSaleyardSheet = false
    
    var body: some View {
        // Debug: Tappable card that opens searchable sheet (HIG pattern for long lists)
        Button(action: {
            HapticManager.tap()
            showingSaleyardSheet = true
        }) {
            HStack {
                // Debug: Icon background changed from rounded rectangle to circle shape
                ZStack {
                    Circle()
                        .fill(Theme.dashboardIconBackground)
                    Image(systemName: "dollarsign.bank.building")
                        .foregroundStyle(Theme.sectionHarvest)
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
                
                Text(selectedSaleyard ?? "Your Favourite Saleyards")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(16)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain) // Debug: Prevent button highlight, keep custom styling
        .sheet(isPresented: $showingSaleyardSheet) {
            SaleyardSelectionSheet(selectedSaleyard: $selectedSaleyard)
        }
        .accessibilityLabel("Select saleyard")
        .accessibilityValue(selectedSaleyard ?? "Your selected saleyards")
        .accessibilityHint("Opens sheet to filter portfolio valuations by saleyard prices")
    }
}

#Preview {
    SaleyardSelector(selectedSaleyard: .constant("Wagga Wagga"))
        .padding()
}


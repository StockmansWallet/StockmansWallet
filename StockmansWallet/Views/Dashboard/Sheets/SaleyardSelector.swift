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
                Image(systemName: "dollarsign.bank.building")
                    .foregroundStyle(Theme.accent)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saleyard")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText)
                    Text(selectedSaleyard ?? "Your Selected Saleyards")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
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


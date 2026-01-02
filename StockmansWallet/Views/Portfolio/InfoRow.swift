// InfoRow.swift
// StockmansWallet
//
// Reusable row for key/value display used in Herd details and reports.

import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
            
            Spacer(minLength: 12)
            
            Text(value)
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.trailing)
                .lineLimit(nil)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}


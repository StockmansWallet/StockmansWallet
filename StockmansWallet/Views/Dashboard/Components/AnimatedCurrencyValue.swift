//
//  AnimatedCurrencyValue.swift
//  StockmansWallet
//
//  Animated currency display with native iOS rolling number animation
//  Performance: Zero lag during scrubbing, beautiful .numericText() animation
//

import SwiftUI

struct AnimatedCurrencyValue: View {
    let value: Double
    let isScrubbing: Bool
    @State private var previousValue: Double = 0.0
    
    // Performance: Reuse formatter instead of creating new one on every render
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    // Determine if value is decreasing for reverse spin animation
    private var isDecreasing: Bool {
        return value < previousValue
    }
    
    private var formattedValue: (whole: String, decimal: String) {
        let whole = Self.numberFormatter.string(from: NSNumber(value: abs(value))) ?? "0"
        let decimal = String(format: "%02d", Int((abs(value) - floor(abs(value))) * 100))
        
        return (whole: whole, decimal: decimal)
    }
    
    var body: some View {
        // Debug: Responsive scaling - HStack scales down to fit available width
        // Debug: Dark brown text for light theme using Theme colors
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("$")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.primaryText)  // Dark brown from asset
                .tracking(-2)
                .padding(.trailing, 4)
                .accessibilityHidden(true)
            
            // Performance: While finger is down (isScrubbing) → instant updates, no animation
            // When finger lifts → beautiful .numericText() rolling animation
            // Debug: monospacedDigit() for proper alignment during number changes
            Text(formattedValue.whole)
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.primaryText)  // Dark brown from asset
                .tracking(-2)
                .contentTransition(isScrubbing ? .identity : .numericText(countsDown: isDecreasing))
                .animation(isScrubbing ? .none : .default, value: formattedValue.whole)
            
            Text(".")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.secondaryText)  // Medium brown from asset
                .tracking(-2)
                .accessibilityHidden(true)
            
            Text(formattedValue.decimal)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.secondaryText)  // Medium brown from asset
                .tracking(-1)
                .contentTransition(isScrubbing ? .identity : .numericText(countsDown: isDecreasing))
                .animation(isScrubbing ? .none : .default, value: formattedValue.decimal)
        }
        .frame(maxWidth: .infinity)
        .minimumScaleFactor(0.5) // Debug: Scale down to 50% if needed to fit screen width
        .lineLimit(1) // Debug: Keep on single line, scale instead of wrapping
        .padding(.vertical, 4)
        .padding(.horizontal, 16) // Debug: Horizontal padding for breathing room on smaller screens
        .onChange(of: value) { oldValue, newValue in
            previousValue = oldValue
        }
        .onAppear {
            previousValue = value
        }
        .accessibilityLabel("Portfolio value")
        .accessibilityValue(value.formatted(.currency(code: "AUD")))
    }
}

#Preview {
    ZStack {
        Color.black
        AnimatedCurrencyValue(value: 125750.45, isScrubbing: false)
    }
}


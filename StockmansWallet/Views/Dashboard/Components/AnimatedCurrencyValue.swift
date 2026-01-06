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
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("$")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
                .tracking(-2)
                .baselineOffset(4)
                .padding(.trailing, 8)
                .accessibilityHidden(true)
            
            // Performance: While finger is down (isScrubbing) → instant updates, no animation
            // When finger lifts → beautiful .numericText() rolling animation
            Text(formattedValue.whole)
                .font(.system(size: 50, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .tracking(-2)
                .fixedSize()
                .contentTransition(isScrubbing ? .identity : .numericText(countsDown: isDecreasing))
                .animation(isScrubbing ? .none : .default, value: formattedValue.whole)
            
            Text(".")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(-2)
                .accessibilityHidden(true)
            
            Text(formattedValue.decimal)
                .font(.system(size: 24, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.6))
                .tracking(-1)
                .fixedSize()
                .contentTransition(isScrubbing ? .identity : .numericText(countsDown: isDecreasing))
                .animation(isScrubbing ? .none : .default, value: formattedValue.decimal)
        }
        // Padding gives the digit rolling animation room to render without clipping
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
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


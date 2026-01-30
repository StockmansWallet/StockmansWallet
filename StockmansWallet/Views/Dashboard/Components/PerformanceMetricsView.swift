//
//  PerformanceMetricsView.swift
//  StockmansWallet
//
//  Portfolio performance metrics card
//

import SwiftUI

struct PerformanceMetricsView: View {
    let metrics: PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Theme.accentColor)
                    .accessibilityHidden(true)
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Change")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(metrics.totalChange, format: .currency(code: "AUD"))
                            .font(Theme.title3) // HIG: title3 (20pt) - primary emphasis without overwhelming
                            .foregroundStyle(metrics.totalChange >= 0 ? Theme.positiveChange : Theme.negativeChange)
                            .accessibilityLabel("Total change")
                            .accessibilityValue(metrics.totalChange.formatted(.currency(code: "AUD")))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Percent Change")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text("\(metrics.percentChange >= 0 ? "+" : "")\(metrics.percentChange, format: .number.precision(.fractionLength(1)))%")
                            .font(Theme.title3) // HIG: title3 (20pt) - primary emphasis without overwhelming
                            .foregroundStyle(metrics.percentChange >= 0 ? Theme.positiveChange : Theme.negativeChange)
                            .accessibilityLabel("Percent change")
                            .accessibilityValue("\(metrics.percentChange.formatted(.number.precision(.fractionLength(1)))) percent")
                    }
                }
                
                Divider()
                    .background(Theme.separator)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unrealized Gains")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(metrics.unrealizedGains, format: .currency(code: "AUD"))
                            .font(Theme.callout) // HIG: callout (16pt) for secondary metrics
                            .foregroundStyle(Theme.accentColor)
                            .accessibilityLabel("Unrealized gains")
                            .accessibilityValue(metrics.unrealizedGains.formatted(.currency(code: "AUD")))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Initial Value")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(metrics.initialValue, format: .currency(code: "AUD"))
                            .font(Theme.callout) // HIG: callout (16pt) for secondary metrics
                            .foregroundStyle(Theme.primaryText)
                            .accessibilityLabel("Initial value")
                            .accessibilityValue(metrics.initialValue.formatted(.currency(code: "AUD")))
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .cardStyle()
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PerformanceMetricsView(
        metrics: PerformanceMetrics(
            totalChange: 5240.20,
            percentChange: 4.35,
            unrealizedGains: 8500.00,
            initialValue: 120510.25
        )
    )
    .padding()
}


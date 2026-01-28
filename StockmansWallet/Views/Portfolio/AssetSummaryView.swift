import SwiftUI
import SwiftData

struct AssetSummaryView: View {
    let herds: [HerdGroup]
    let portfolioValue: Double
    let isLoading: Bool
    let modelContext: ModelContext
    let preferences: UserPreferences
    let valuationEngine: ValuationEngine
    
    private var activeHerds: [HerdGroup] {
        herds.filter { !$0.isSold }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Asset Summary")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundStyle(Theme.accent)
            }
            
            if isLoading {
                ProgressView()
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if activeHerds.isEmpty {
                Text("No active herds")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.primaryText.opacity(0.7))
            } else {
                HStack(spacing: 16) {
                    SummaryTile(title: "Active Herds", value: "\(activeHerds.count)", icon: "square.stack.3d.up.fill")
                    SummaryTile(title: "Head", value: "\(activeHerds.reduce(0) { $0 + $1.headCount })", icon: "person.3.fill")
                }
                
                HStack(spacing: 16) {
                    SummaryTile(title: "Portfolio Value", value: portfolioValue.formatted(.currency(code: "AUD")), icon: "chart.line.uptrend.xyaxis", highlight: true)
                }
            }
        }
        .padding(Theme.cardPadding)
        .cardStyle()
    }
}

private struct SummaryTile: View {
    let title: String
    let value: String
    let icon: String
    var highlight: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
            Text(value)
                .font(Theme.title)
                .foregroundStyle(highlight ? Theme.accent : Theme.primaryText)
            Text(title)
                .font(Theme.caption)
                .foregroundStyle(Theme.primaryText.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

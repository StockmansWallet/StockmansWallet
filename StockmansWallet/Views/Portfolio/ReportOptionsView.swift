import SwiftUI

struct ReportOptionsView: View {
    @Binding var showingAssetRegister: Bool
    @Binding var showingSalesSummary: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Report Options")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(Theme.accentColor)
            }
            
            VStack(spacing: 12) {
                Button {
                    HapticManager.tap()
                    showingAssetRegister = true
                } label: {
                    HStack {
                        Image(systemName: "doc.richtext.fill")
                            .foregroundStyle(Theme.accentColor)
                        Text("Asset Register (PDF)")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Theme.primaryText.opacity(0.6))
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                Button {
                    HapticManager.tap()
                    showingSalesSummary = true
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal.fill")
                            .foregroundStyle(Theme.accentColor)
                        Text("Sales Summary (PDF)")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Theme.primaryText.opacity(0.6))
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(Theme.cardPadding)
        .cardStyle()
    }
}

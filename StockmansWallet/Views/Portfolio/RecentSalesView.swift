import SwiftUI

struct RecentSalesView: View {
    let sales: [SalesRecord]
    
    private var sorted: [SalesRecord] {
        sales.sorted { $0.saleDate > $1.saleDate }.prefix(5).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Sales")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(Theme.accent)
            }
            
            if sorted.isEmpty {
                Text("No sales recorded")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.primaryText.opacity(0.7))
            } else {
                VStack(spacing: 12) {
                    ForEach(sorted, id: \.id) { sale in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sale.saleDate, format: .dateTime.day().month(.abbreviated).year())
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                Text("\(sale.headCount) head • \(Int(sale.averageWeight))kg • \(sale.pricePerKg, format: .number.precision(.fractionLength(2))) $/kg")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.primaryText.opacity(0.7))
                            }
                            Spacer()
                            Text(sale.netValue, format: .currency(code: "AUD"))
                                .font(Theme.headline)
                                .foregroundStyle(Theme.accent)
                        }
                        .padding(.vertical, 4)
                        
                        if sale.id != sorted.last?.id {
                            Divider().background(Theme.primaryText.opacity(0.15))
                        }
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
    }
}

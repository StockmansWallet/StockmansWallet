import SwiftUI

struct RecentSalesView: View {
    let sales: [SalesRecord]
    
    private var sortedSales: [SalesRecord] {
        Array(sales.sorted { $0.saleDate > $1.saleDate }.prefix(5))
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
            
            if sortedSales.isEmpty {
                Text("No sales recorded")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.primaryText.opacity(0.7))
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedSales, id: \.id) { sale in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sale.saleDate, format: .dateTime.day().month(.abbreviated).year())
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                
                                // Debug: Show pricing based on type
                                priceText(for: sale)
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.primaryText.opacity(0.7))
                                
                                // Debug: Show location if available
                                if let location = sale.saleLocation {
                                    Text(location)
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                            }
                            Spacer()
                            Text(sale.netValue, format: .currency(code: "AUD"))
                                .font(Theme.headline)
                                .foregroundStyle(Theme.accent)
                        }
                        .padding(.vertical, 4)
                        
                        if sale.id != sortedSales.last?.id {
                            Divider().background(Theme.primaryText.opacity(0.15))
                        }
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .cardStyle()
    }
    
    // Debug: Helper function to generate price text
    @ViewBuilder
    private func priceText(for sale: SalesRecord) -> some View {
        let pricingType = PricingType(rawValue: sale.pricingType) ?? .perKg
        if pricingType == .perKg {
            Text("\(sale.headCount) head • \(Int(sale.averageWeight))kg • \(sale.pricePerKg, format: .number.precision(.fractionLength(2))) $/kg")
        } else if let pricePerHead = sale.pricePerHead {
            Text("\(sale.headCount) head • \(Int(sale.averageWeight))kg • \(pricePerHead, format: .number.precision(.fractionLength(2))) $/head")
        } else {
            Text("\(sale.headCount) head • \(Int(sale.averageWeight))kg • N/A")
        }
    }
}

//
//  PhysicalSalesTableView.swift
//  StockmansWallet
//
//  Physical Sales Table - displays detailed cattle pricing by category
//  Debug: Shows Min/Max/Avg prices per kg and per head
//

import SwiftUI

struct PhysicalSalesTableView: View {
    let report: PhysicalSalesReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Table (no scroll, full width)
            VStack(spacing: 0) {
                // Table Header
                tableHeader
                
                // Table Rows
                ForEach(report.categories) { category in
                    categoryRow(category: category)
                }
            }
            .background(Theme.cardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Physical Sales Report")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            HStack {
                Text(report.saleyard)
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                
                Spacer()
                
                Text("\(report.totalYarding) head yarded")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.accent)
                
                Text(report.reportDate, style: .date)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
            }
        }
    }
    
    // MARK: - Table Header
    private var tableHeader: some View {
        HStack(spacing: 0) {
            // Category column (flexible)
            Text("Category")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .font(Theme.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
            
            Divider()
            
            // Avg Cents/kg column (fixed)
            VStack(spacing: 4) {
                Text("Avg")
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Text("¢/kg")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
            }
            .frame(width: 75)
            
            Divider()
            
            // Avg $/Head column (fixed)
            VStack(spacing: 4) {
                Text("Avg")
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Text("$/Head")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
            }
            .frame(width: 85)
        }
        .frame(height: 60)
        .background(Theme.cardBackground.opacity(0.5))
    }
    
    // MARK: - Category Row
    private func categoryRow(category: PhysicalSalesCategory) -> some View {
        HStack(spacing: 0) {
            // Category info (flexible)
            VStack(alignment: .leading, spacing: 4) {
                Text(category.categoryName)
                    .font(Theme.body.weight(.medium))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(category.weightRange + "kg")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                    
                    Text(category.salePrefix)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.accent.opacity(0.8))
                    
                    Text("\(category.headCount) hd")
                        .font(Theme.caption.weight(.medium))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            
            Divider()
            
            // Avg Cents/kg (fixed)
            priceCell(value: category.avgPriceCentsPerKg, format: .centsPerKg)
                .frame(width: 75)
            
            Divider()
            
            // Avg $/Head (fixed)
            priceCell(value: category.avgPriceDollarsPerHead, format: .dollarsPerHead)
                .frame(width: 85)
        }
        .frame(height: 70)
        .background(Theme.cardBackground)
    }
    
    // MARK: - Price Cell
    private func priceCell(value: Double?, format: PriceFormat) -> some View {
        Group {
            if let value = value {
                Text(format.formatted(value))
                    .font(Theme.body.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            } else {
                Text("–")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText.opacity(0.5))
            }
        }
    }
    
    // MARK: - Price Format
    enum PriceFormat {
        case centsPerKg
        case dollarsPerHead
        
        func formatted(_ value: Double) -> String {
            switch self {
            case .centsPerKg:
                return String(format: "%.0f¢", value)
            case .dollarsPerHead:
                return String(format: "$%.0f", value)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        PhysicalSalesTableView(
            report: PhysicalSalesReport(
                id: UUID().uuidString,
                saleyard: "Mount Barker",
                reportDate: Date(),
                totalYarding: 336,
                categories: [
                    PhysicalSalesCategory(
                        id: UUID().uuidString,
                        categoryName: "Yearling Steer",
                        weightRange: "400-500",
                        salePrefix: "Processor",
                        muscleScore: "C",
                        fatScore: 3,
                        headCount: 4,
                        minPriceCentsPerKg: 340.0,
                        maxPriceCentsPerKg: 340.0,
                        avgPriceCentsPerKg: 340.0,
                        minPriceDollarsPerHead: 1734.0,
                        maxPriceDollarsPerHead: 1734.0,
                        avgPriceDollarsPerHead: 1734.0
                    ),
                    PhysicalSalesCategory(
                        id: UUID().uuidString,
                        categoryName: "Yearling Heifer",
                        weightRange: "400-500",
                        salePrefix: "Feeder",
                        muscleScore: "C",
                        fatScore: 3,
                        headCount: 6,
                        minPriceCentsPerKg: 384.0,
                        maxPriceCentsPerKg: 384.0,
                        avgPriceCentsPerKg: 384.0,
                        minPriceDollarsPerHead: 1536.0,
                        maxPriceDollarsPerHead: 1536.0,
                        avgPriceDollarsPerHead: 1536.0
                    ),
                    PhysicalSalesCategory(
                        id: UUID().uuidString,
                        categoryName: "Grown Steer",
                        weightRange: "400-500",
                        salePrefix: "Feeder",
                        muscleScore: "C",
                        fatScore: 3,
                        headCount: 11,
                        minPriceCentsPerKg: 300.0,
                        maxPriceCentsPerKg: 370.0,
                        avgPriceCentsPerKg: 340.0,
                        minPriceDollarsPerHead: 1245.0,
                        maxPriceDollarsPerHead: 1586.0,
                        avgPriceDollarsPerHead: 1454.58
                    )
                ]
            )
        )
        .padding(.vertical)
    }
    .background(Theme.backgroundGradient)
}

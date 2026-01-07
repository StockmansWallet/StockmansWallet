//
//  ReportConfiguration.swift
//  StockmansWallet
//
//  Report configuration models for enhanced reporting system
//  Debug: Supports multiple report types with customizable options
//

import Foundation

// MARK: - Report Type Enum
// Debug: All available report types in the system
enum ReportType: String, CaseIterable, Identifiable {
    case assetRegister = "Asset Register"
    case salesSummary = "Sales Summary"
    case saleyardComparison = "Saleyard Comparison"
    case livestockValueVsLandArea = "Livestock Value vs Land Area"
    case farmComparison = "Farm vs Farm Comparison"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .assetRegister:
            return "doc.on.doc.fill"
        case .salesSummary:
            return "doc.richtext.fill"
        case .saleyardComparison:
            return "chart.bar.doc.horizontal.fill"
        case .livestockValueVsLandArea:
            return "chart.line.uptrend.xyaxis"
        case .farmComparison:
            return "building.2.crop.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .assetRegister:
            return "Complete listing of all livestock assets with valuations"
        case .salesSummary:
            return "Summary of all sales transactions and performance"
        case .saleyardComparison:
            return "Compare prices across different saleyards"
        case .livestockValueVsLandArea:
            return "Analyze livestock value density per acre"
        case .farmComparison:
            return "Compare performance across multiple properties"
        }
    }
}

// MARK: - Price Statistics Option
// Debug: Options for asset register price display
enum PriceStatisticsOption: String, CaseIterable, Identifiable {
    case current = "Current Price"
    case minimum = "Minimum Price"
    case maximum = "Maximum Price"
    case average = "Average Price"
    case all = "All Statistics"
    
    var id: String { rawValue }
}

// MARK: - Report Configuration
// Debug: Configuration options for generating reports
struct ReportConfiguration {
    var reportType: ReportType
    var startDate: Date
    var endDate: Date
    var includeFarmName: Bool
    var includePropertyDetails: Bool
    var priceStatistics: PriceStatisticsOption
    var selectedProperties: [UUID] // For farm comparison
    var selectedSaleyards: [String] // For saleyard comparison
    
    // Debug: Default configuration
    init(reportType: ReportType) {
        self.reportType = reportType
        self.endDate = Date()
        self.startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        self.includeFarmName = true
        self.includePropertyDetails = true
        self.priceStatistics = .current
        self.selectedProperties = []
        self.selectedSaleyards = []
    }
}

// MARK: - Report Output Format
// Debug: Available output formats for reports
enum ReportOutputFormat: String, CaseIterable {
    case pdf = "PDF"
    case print = "Print"
    case preview = "Preview"
}





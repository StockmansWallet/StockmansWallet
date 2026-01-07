//
//  EnhancedReportExportService.swift
//  StockmansWallet
//
//  Enhanced PDF generation service with better formatting
//  Debug: Structure provided - customize PDF layout as needed
//

import Foundation
import PDFKit
import SwiftUI
import SwiftData

// Debug: Enhanced service for generating professional PDFs
class EnhancedReportExportService {
    static let shared = EnhancedReportExportService()
    
    private init() {}
    
    // MARK: - Main PDF Generation
    
    /// Generate PDF for any report type with configuration
    func generatePDF(
        configuration: ReportConfiguration,
        herds: [HerdGroup],
        sales: [SalesRecord],
        preferences: UserPreferences,
        properties: [Property],
        modelContext: ModelContext,
        valuationEngine: ValuationEngine
    ) async -> URL? {
        
        // Generate report data
        let reportData = await ReportDataGenerator.generateReportData(
            configuration: configuration,
            herds: herds,
            sales: sales,
            preferences: preferences,
            properties: properties,
            modelContext: modelContext,
            valuationEngine: valuationEngine
        )
        
        // Generate PDF based on report type
        switch configuration.reportType {
        case .assetRegister:
            return generateAssetRegisterPDF(data: reportData, configuration: configuration)
        case .salesSummary:
            return generateSalesSummaryPDF(data: reportData, configuration: configuration)
        case .saleyardComparison:
            return generateSaleyardComparisonPDF(data: reportData, configuration: configuration)
        case .livestockValueVsLandArea:
            return generateLivestockValueVsLandAreaPDF(data: reportData, configuration: configuration)
        case .farmComparison:
            return generateFarmComparisonPDF(data: reportData, configuration: configuration)
        }
    }
    
    // MARK: - PDF Generation Methods
    
    // Debug: Generate Asset Register PDF with enhanced formatting
    private func generateAssetRegisterPDF(
        data: ReportData,
        configuration: ReportConfiguration
    ) -> URL? {
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Stockman's Wallet",
            kCGPDFContextAuthor: data.farmName ?? "User",
            kCGPDFContextTitle: "Asset Register"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 72.0 // 1 inch margins
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let fileName = "AssetRegister_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            var yPosition: CGFloat = margin
            
            // TODO: Customize header formatting
            yPosition = drawReportHeader(
                title: "Asset Register",
                farmName: data.farmName,
                configuration: configuration,
                context: context,
                yPosition: yPosition,
                pageWidth: pageWidth,
                margin: margin
            )
            
            // TODO: Add property details if configured
            if configuration.includePropertyDetails {
                // Draw property details section
                yPosition += 20
            }
            
            // Draw total value
            yPosition = drawSectionHeader("Portfolio Summary", yPosition: yPosition, margin: margin)
            yPosition = drawKeyValue(
                key: "Total Portfolio Value",
                value: formatCurrency(data.totalValue),
                yPosition: yPosition,
                margin: margin,
                isBold: true
            )
            yPosition += 30
            
            // Draw herds
            yPosition = drawSectionHeader("Livestock Assets", yPosition: yPosition, margin: margin)
            
            for herdData in data.herdData {
                // Check if we need a new page
                if yPosition > pageHeight - 200 {
                    context.beginPage()
                    yPosition = margin
                }
                
                yPosition = drawHerdData(
                    herdData: herdData,
                    configuration: configuration,
                    yPosition: yPosition,
                    margin: margin
                )
            }
            
            // TODO: Add footer with page numbers and generation date
            drawPageFooter(
                pageNumber: 1,
                totalPages: 1,
                yPosition: pageHeight - margin/2,
                pageWidth: pageWidth,
                margin: margin
            )
        }
        
        do {
            try pdfData.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
    
    // Debug: Generate Sales Summary PDF
    private func generateSalesSummaryPDF(
        data: ReportData,
        configuration: ReportConfiguration
    ) -> URL? {
        
        // TODO: Implement enhanced sales summary PDF generation
        // Similar structure to asset register but with sales data
        
        let fileName = "SalesSummary_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Use existing service as fallback for now
        // TODO: Replace with enhanced formatting
        return tempURL
    }
    
    // Debug: Generate Saleyard Comparison PDF
    private func generateSaleyardComparisonPDF(
        data: ReportData,
        configuration: ReportConfiguration
    ) -> URL? {
        
        // TODO: Implement saleyard comparison PDF with charts/tables
        let fileName = "SaleyardComparison_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        return tempURL
    }
    
    // Debug: Generate Livestock Value vs Land Area PDF
    private func generateLivestockValueVsLandAreaPDF(
        data: ReportData,
        configuration: ReportConfiguration
    ) -> URL? {
        
        // TODO: Implement land area analysis PDF with charts
        let fileName = "LivestockValueVsLandArea_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        return tempURL
    }
    
    // Debug: Generate Farm Comparison PDF
    private func generateFarmComparisonPDF(
        data: ReportData,
        configuration: ReportConfiguration
    ) -> URL? {
        
        // TODO: Implement farm comparison PDF with comparative tables
        let fileName = "FarmComparison_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        return tempURL
    }
    
    // MARK: - PDF Drawing Helper Methods
    
    /// Draw professional report header
    private func drawReportHeader(
        title: String,
        farmName: String?,
        configuration: ReportConfiguration,
        context: UIGraphicsPDFRendererContext,
        yPosition: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        
        var y = yPosition
        
        // TODO: Customize header styling
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 28),
            .foregroundColor: UIColor.black
        ]
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
        y += 40
        
        // Farm name if included
        if let farmName = farmName {
            let farmNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.darkGray
            ]
            farmName.draw(at: CGPoint(x: margin, y: y), withAttributes: farmNameAttributes)
            y += 30
        }
        
        // Date range and generation date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        
        let dateRangeText = "Period: \(dateFormatter.string(from: configuration.startDate)) - \(dateFormatter.string(from: configuration.endDate))"
        dateRangeText.draw(at: CGPoint(x: margin, y: y), withAttributes: dateAttributes)
        y += 18
        
        dateFormatter.dateStyle = .long
        let generatedText = "Generated: \(dateFormatter.string(from: Date()))"
        generatedText.draw(at: CGPoint(x: margin, y: y), withAttributes: dateAttributes)
        y += 30
        
        // Draw separator line
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: margin, y: y))
        linePath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        UIColor.lightGray.setStroke()
        linePath.lineWidth = 1
        linePath.stroke()
        y += 20
        
        return y
    }
    
    /// Draw section header
    private func drawSectionHeader(_ title: String, yPosition: CGFloat, margin: CGFloat) -> CGFloat {
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ]
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
        return yPosition + 30
    }
    
    /// Draw key-value pair
    private func drawKeyValue(
        key: String,
        value: String,
        yPosition: CGFloat,
        margin: CGFloat,
        isBold: Bool = false
    ) -> CGFloat {
        let keyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: isBold ? UIFont.boldSystemFont(ofSize: 14) : UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        key.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: keyAttributes)
        value.draw(at: CGPoint(x: margin + 200, y: yPosition), withAttributes: valueAttributes)
        
        return yPosition + 20
    }
    
    /// Draw herd data block
    private func drawHerdData(
        herdData: HerdReportData,
        configuration: ReportConfiguration,
        yPosition: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        
        var y = yPosition
        
        // Herd name (bold)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        herdData.name.draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttributes)
        y += 25
        
        // Details
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        var lines = [
            "Category: \(herdData.category)",
            "Head Count: \(herdData.headCount)",
            "Age: \(herdData.ageMonths) months",
            "Weight: \(Int(herdData.weight)) kg"
        ]
        
        // Add price statistics based on configuration
        switch configuration.priceStatistics {
        case .current:
            lines.append("Price: \(String(format: "%.2f", herdData.pricePerKg)) $/kg")
        case .minimum:
            lines.append("Min Price: \(String(format: "%.2f", herdData.minPrice)) $/kg")
        case .maximum:
            lines.append("Max Price: \(String(format: "%.2f", herdData.maxPrice)) $/kg")
        case .average:
            lines.append("Avg Price: \(String(format: "%.2f", herdData.avgPrice)) $/kg")
        case .all:
            lines.append(contentsOf: [
                "Current Price: \(String(format: "%.2f", herdData.pricePerKg)) $/kg",
                "Min Price: \(String(format: "%.2f", herdData.minPrice)) $/kg",
                "Max Price: \(String(format: "%.2f", herdData.maxPrice)) $/kg",
                "Avg Price: \(String(format: "%.2f", herdData.avgPrice)) $/kg"
            ])
        }
        
        lines.append("Net Value: \(formatCurrency(herdData.netValue))")
        
        for line in lines {
            line.draw(at: CGPoint(x: margin + 20, y: y), withAttributes: bodyAttributes)
            y += 18
        }
        
        y += 15 // Extra spacing between herds
        
        return y
    }
    
    /// Draw page footer
    private func drawPageFooter(
        pageNumber: Int,
        totalPages: Int,
        yPosition: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) {
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = "Page \(pageNumber) of \(totalPages) • Generated by Stockman's Wallet"
        let textSize = footerText.size(withAttributes: footerAttributes)
        let xPosition = (pageWidth - textSize.width) / 2
        
        footerText.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: footerAttributes)
    }
    
    // MARK: - Formatting Helpers
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "AUD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}





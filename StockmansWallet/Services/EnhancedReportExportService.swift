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
    
    // MARK: - Apple-Inspired Design Constants
    // Debug: Clean, modern styling inspired by Apple's design language
    
    // Colors - Subtle, refined palette
    private let primaryTextColor = UIColor.black
    private let secondaryTextColor = UIColor(white: 0.4, alpha: 1.0) // Subtle gray
    private let tertiaryTextColor = UIColor(white: 0.6, alpha: 1.0) // Lighter gray
    private let accentColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // SF Blue
    private let cardBackgroundColor = UIColor(white: 0.98, alpha: 1.0) // Very light gray
    private let dividerColor = UIColor(white: 0.9, alpha: 1.0) // Subtle divider
    
    // Typography - SF Pro inspired hierarchy (adjusted sizes)
    private let heroFont = UIFont.systemFont(ofSize: 36, weight: .bold) // Key numbers (reduced from 48)
    private let largeTitleFont = UIFont.systemFont(ofSize: 28, weight: .bold) // Page title (reduced from 32)
    private let titleFont = UIFont.systemFont(ofSize: 18, weight: .semibold) // Section titles (reduced from 20)
    private let headlineFont = UIFont.systemFont(ofSize: 15, weight: .semibold) // Card titles
    private let bodyFont = UIFont.systemFont(ofSize: 13, weight: .regular) // Body text
    private let captionFont = UIFont.systemFont(ofSize: 11, weight: .regular) // Small text
    private let labelFont = UIFont.systemFont(ofSize: 9, weight: .medium) // Tiny labels (reduced from 10)
    
    // Spacing - Optimized, consistent spacing
    private let sectionSpacing: CGFloat = 24 // Between major sections (reduced from 32)
    private let cardSpacing: CGFloat = 12 // Between cards (reduced from 16)
    private let lineSpacing: CGFloat = 8 // Between lines of text (increased from 6)
    private let cardPadding: CGFloat = 20 // Inside cards (increased from 16)
    private let cardCornerRadius: CGFloat = 12 // Rounded corners
    
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
        
        // Debug: Track pages for accurate page numbering
        var currentPage = 0
        var totalPages = 1 // Will be updated as we add pages
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            currentPage += 1
            var yPosition: CGFloat = margin
            
            // Draw header with logo and farmer details
            yPosition = drawReportHeader(
                title: "Asset Register",
                farmName: data.farmName,
                userDetails: data.userDetails,
                configuration: configuration,
                context: context,
                yPosition: yPosition,
                pageWidth: pageWidth,
                margin: margin
            )
            
            // Draw total portfolio value as hero card (no separate property details section)
            yPosition = drawHeroValueCard(
                label: "Total Portfolio Value",
                value: formatCurrency(data.totalValue),
                yPosition: yPosition,
                margin: margin,
                width: pageWidth - (margin * 2)
            )
            
            // Draw herds section
            yPosition = drawSectionHeader("Livestock Assets", yPosition: yPosition, margin: margin)
            
            for herdData in data.herdData {
                // Check if we need a new page
                if yPosition > pageHeight - 200 {
                    // Draw footer for current page
                    drawPageFooter(
                        pageNumber: currentPage,
                        totalPages: totalPages, // Will show current estimate
                        yPosition: pageHeight - margin/2,
                        pageWidth: pageWidth,
                        margin: margin
                    )
                    
                    context.beginPage()
                    currentPage += 1
                    totalPages = currentPage // Update total as we go
                    yPosition = margin + 20 // Small top margin on continuation pages
                }
                
                yPosition = drawHerdData(
                    herdData: herdData,
                    configuration: configuration,
                    yPosition: yPosition,
                    margin: margin,
                    pageWidth: pageWidth
                )
            }
            
            // Draw footer for last page
            totalPages = currentPage // Final total
            drawPageFooter(
                pageNumber: currentPage,
                totalPages: totalPages,
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
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Stockman's Wallet",
            kCGPDFContextAuthor: data.farmName ?? "User",
            kCGPDFContextTitle: "Sales Summary"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 72.0
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let fileName = "SalesSummary_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var currentPage = 0
        var totalPages = 1 // Will be updated as we add pages
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            currentPage += 1
            var yPosition: CGFloat = margin
            
            // Draw header with logo and user details
            yPosition = drawReportHeader(
                title: "Sales Summary",
                farmName: data.farmName,
                userDetails: data.userDetails,
                configuration: configuration,
                context: context,
                yPosition: yPosition,
                pageWidth: pageWidth,
                margin: margin
            )
            
            // Draw total sales value as hero card
            yPosition = drawHeroValueCard(
                label: "Total Sales Value",
                value: formatCurrency(data.totalSales),
                yPosition: yPosition,
                margin: margin,
                width: pageWidth - (margin * 2)
            )
            
            // Draw sales section
            yPosition = drawSectionHeader("Sales History", yPosition: yPosition, margin: margin)
            
            for saleData in data.salesData {
                // Check if we need a new page
                if yPosition > pageHeight - 200 {
                    drawPageFooter(
                        pageNumber: currentPage,
                        totalPages: totalPages,
                        yPosition: pageHeight - margin/2,
                        pageWidth: pageWidth,
                        margin: margin
                    )
                    
                    context.beginPage()
                    currentPage += 1
                    totalPages = currentPage // Update total as we go
                    yPosition = margin + 20
                }
                
                yPosition = drawSaleData(
                    saleData: saleData,
                    yPosition: yPosition,
                    margin: margin,
                    pageWidth: pageWidth
                )
            }
            
            // Draw footer for last page
            totalPages = currentPage // Final total
            drawPageFooter(
                pageNumber: currentPage,
                totalPages: totalPages,
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
    
    /// Draw sale data card
    private func drawSaleData(
        saleData: SaleReportData,
        yPosition: CGFloat,
        margin: CGFloat,
        pageWidth: CGFloat
    ) -> CGFloat {
        
        var y = yPosition
        let cardWidth = pageWidth - (margin * 2)
        let cardStartY = y
        let cardHeight: CGFloat = 120
        
        // Card background
        let cardRect = CGRect(x: margin, y: cardStartY, width: cardWidth, height: cardHeight)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cardCornerRadius)
        
        cardBackgroundColor.setFill()
        cardPath.fill()
        
        dividerColor.setStroke()
        cardPath.lineWidth = 0.5
        cardPath.stroke()
        
        // Content
        y += cardPadding
        let leftX = margin + cardPadding
        let rightX = margin + (cardWidth * 0.55)
        
        // Date + Net value
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: headlineFont,
            .foregroundColor: primaryTextColor
        ]
        dateFormatter.string(from: saleData.date).draw(at: CGPoint(x: leftX, y: y), withAttributes: nameAttributes)
        
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: primaryTextColor
        ]
        let valueText = formatCurrency(saleData.netValue)
        let valueSize = valueText.size(withAttributes: valueAttributes)
        valueText.draw(at: CGPoint(x: margin + cardWidth - cardPadding - valueSize.width, y: y), withAttributes: valueAttributes)
        
        y += 22
        
        // Pricing type subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryTextColor
        ]
        saleData.pricingType.rawValue.draw(at: CGPoint(x: leftX, y: y), withAttributes: subtitleAttributes)
        y += 18
        
        // Details with labels
        let dataAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: primaryTextColor
        ]
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: tertiaryTextColor,
            .kern: 0.3
        ]
        
        var leftY = y
        var rightY = y
        
        // Left column
        "HEAD COUNT".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: labelAttributes)
        leftY += 12
        "\(saleData.headCount) head".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: dataAttributes)
        leftY += 18
        
        "AVG WEIGHT".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: labelAttributes)
        leftY += 12
        "\(Int(saleData.avgWeight)) kg".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: dataAttributes)
        
        // Right column
        "PRICE".draw(at: CGPoint(x: rightX, y: rightY), withAttributes: labelAttributes)
        rightY += 12
        "$\(String(format: "%.2f", saleData.pricePerKg))/kg".draw(at: CGPoint(x: rightX, y: rightY), withAttributes: dataAttributes)
        
        return cardStartY + cardHeight + cardSpacing
    }
    
    /// Draw saleyard comparison data card
    private func drawSaleyardComparisonData(
        saleyardData: SaleyardComparisonData,
        yPosition: CGFloat,
        margin: CGFloat,
        pageWidth: CGFloat
    ) -> CGFloat {
        
        var y = yPosition
        let cardWidth = pageWidth - (margin * 2)
        let cardStartY = y
        let cardHeight: CGFloat = 120
        
        // Card background
        let cardRect = CGRect(x: margin, y: cardStartY, width: cardWidth, height: cardHeight)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cardCornerRadius)
        
        cardBackgroundColor.setFill()
        cardPath.fill()
        
        dividerColor.setStroke()
        cardPath.lineWidth = 0.5
        cardPath.stroke()
        
        // Content
        y += cardPadding
        let leftX = margin + cardPadding
        
        // Saleyard name header
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: headlineFont,
            .foregroundColor: primaryTextColor
        ]
        saleyardData.saleyardName.draw(at: CGPoint(x: leftX, y: y), withAttributes: nameAttributes)
        
        y += 22
        
        // Head count subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryTextColor
        ]
        "\(saleyardData.totalHeadCount) head sold".draw(at: CGPoint(x: leftX, y: y), withAttributes: subtitleAttributes)
        y += 18
        
        // Price details
        let dataAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: primaryTextColor
        ]
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: tertiaryTextColor,
            .kern: 0.3
        ]
        
        // Calculate column positions
        let contentWidth = cardWidth - (cardPadding * 2)
        let col1X = leftX
        let col2X = leftX + (contentWidth * 0.33)
        let col3X = leftX + (contentWidth * 0.66)
        
        // Labels
        "AVG PRICE".draw(at: CGPoint(x: col1X, y: y), withAttributes: labelAttributes)
        "MIN PRICE".draw(at: CGPoint(x: col2X, y: y), withAttributes: labelAttributes)
        "MAX PRICE".draw(at: CGPoint(x: col3X, y: y), withAttributes: labelAttributes)
        y += 14
        
        // Values
        "$\(String(format: "%.2f", saleyardData.avgPrice))/kg".draw(at: CGPoint(x: col1X, y: y), withAttributes: dataAttributes)
        "$\(String(format: "%.2f", saleyardData.minPrice))/kg".draw(at: CGPoint(x: col2X, y: y), withAttributes: dataAttributes)
        "$\(String(format: "%.2f", saleyardData.maxPrice))/kg".draw(at: CGPoint(x: col3X, y: y), withAttributes: dataAttributes)
        
        return cardStartY + cardHeight + cardSpacing
    }
    
    /// Draw land value analysis data card
    private func drawLandValueAnalysisData(
        landData: LandValueAnalysisData,
        yPosition: CGFloat,
        margin: CGFloat,
        pageWidth: CGFloat
    ) -> CGFloat {
        
        var y = yPosition
        let cardWidth = pageWidth - (margin * 2)
        let cardStartY = y
        let cardHeight: CGFloat = 120
        
        // Card background
        let cardRect = CGRect(x: margin, y: cardStartY, width: cardWidth, height: cardHeight)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cardCornerRadius)
        
        cardBackgroundColor.setFill()
        cardPath.fill()
        
        dividerColor.setStroke()
        cardPath.lineWidth = 0.5
        cardPath.stroke()
        
        // Content
        y += cardPadding
        let leftX = margin + cardPadding
        
        // Property name header
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: headlineFont,
            .foregroundColor: primaryTextColor
        ]
        landData.propertyName.draw(at: CGPoint(x: leftX, y: y), withAttributes: nameAttributes)
        
        // Livestock value on the right
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: primaryTextColor
        ]
        let valueText = formatCurrency(landData.livestockValue)
        let valueSize = valueText.size(withAttributes: valueAttributes)
        valueText.draw(at: CGPoint(x: margin + cardWidth - cardPadding - valueSize.width, y: y), withAttributes: valueAttributes)
        
        y += 22
        
        // Head count subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryTextColor
        ]
        "\(landData.totalHeadCount) head".draw(at: CGPoint(x: leftX, y: y), withAttributes: subtitleAttributes)
        y += 18
        
        // Property details
        let dataAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: primaryTextColor
        ]
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: tertiaryTextColor,
            .kern: 0.3
        ]
        
        // Calculate column positions
        let contentWidth = cardWidth - (cardPadding * 2)
        let col1X = leftX
        let col2X = leftX + (contentWidth * 0.5)
        
        // Labels
        "ACREAGE".draw(at: CGPoint(x: col1X, y: y), withAttributes: labelAttributes)
        "VALUE PER ACRE".draw(at: CGPoint(x: col2X, y: y), withAttributes: labelAttributes)
        y += 14
        
        // Values
        "\(String(format: "%.1f", landData.acreage)) acres".draw(at: CGPoint(x: col1X, y: y), withAttributes: dataAttributes)
        formatCurrency(landData.valuePerAcre).draw(at: CGPoint(x: col2X, y: y), withAttributes: dataAttributes)
        
        return cardStartY + cardHeight + cardSpacing
    }
    
    /// Draw farm comparison data card
    private func drawFarmComparisonData(
        farmData: FarmComparisonData,
        yPosition: CGFloat,
        margin: CGFloat,
        pageWidth: CGFloat
    ) -> CGFloat {
        
        var y = yPosition
        let cardWidth = pageWidth - (margin * 2)
        let cardStartY = y
        let cardHeight: CGFloat = 120
        
        // Card background
        let cardRect = CGRect(x: margin, y: cardStartY, width: cardWidth, height: cardHeight)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cardCornerRadius)
        
        cardBackgroundColor.setFill()
        cardPath.fill()
        
        dividerColor.setStroke()
        cardPath.lineWidth = 0.5
        cardPath.stroke()
        
        // Content
        y += cardPadding
        let leftX = margin + cardPadding
        
        // Property name header
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: headlineFont,
            .foregroundColor: primaryTextColor
        ]
        farmData.propertyName.draw(at: CGPoint(x: leftX, y: y), withAttributes: nameAttributes)
        
        // Total value on the right
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: primaryTextColor
        ]
        let valueText = formatCurrency(farmData.totalValue)
        let valueSize = valueText.size(withAttributes: valueAttributes)
        valueText.draw(at: CGPoint(x: margin + cardWidth - cardPadding - valueSize.width, y: y), withAttributes: valueAttributes)
        
        y += 22
        
        // Head count subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryTextColor
        ]
        "\(farmData.totalHeadCount) head".draw(at: CGPoint(x: leftX, y: y), withAttributes: subtitleAttributes)
        y += 18
        
        // Farm metrics
        let dataAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: primaryTextColor
        ]
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: tertiaryTextColor,
            .kern: 0.3
        ]
        
        // Calculate column positions
        let contentWidth = cardWidth - (cardPadding * 2)
        let col1X = leftX
        let col2X = leftX + (contentWidth * 0.5)
        
        // Labels
        "AVG PRICE/KG".draw(at: CGPoint(x: col1X, y: y), withAttributes: labelAttributes)
        "VALUE PER HEAD".draw(at: CGPoint(x: col2X, y: y), withAttributes: labelAttributes)
        y += 14
        
        // Values
        "$\(String(format: "%.2f", farmData.avgPricePerKg))/kg".draw(at: CGPoint(x: col1X, y: y), withAttributes: dataAttributes)
        formatCurrency(farmData.valuePerHead).draw(at: CGPoint(x: col2X, y: y), withAttributes: dataAttributes)
        
        return cardStartY + cardHeight + cardSpacing
    }
    
    // Debug: Generate Saleyard Comparison PDF
    private func generateSaleyardComparisonPDF(
        data: ReportData,
        configuration: ReportConfiguration
    ) -> URL? {
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Stockman's Wallet",
            kCGPDFContextAuthor: data.farmName ?? "User",
            kCGPDFContextTitle: "Saleyard Comparison"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 72.0
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let fileName = "SaleyardComparison_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var currentPage = 0
        var totalPages = 1
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            currentPage += 1
            var yPosition: CGFloat = margin
            
            // Draw header
            yPosition = drawReportHeader(
                title: "Saleyard Comparison",
                farmName: data.farmName,
                userDetails: data.userDetails,
                configuration: configuration,
                context: context,
                yPosition: yPosition,
                pageWidth: pageWidth,
                margin: margin
            )
            
            // Draw section header
            yPosition = drawSectionHeader("Saleyard Price Comparison", yPosition: yPosition, margin: margin)
            
            // Check if we have data
            if data.saleyardComparison.isEmpty {
                let messageAttributes: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: secondaryTextColor
                ]
                "No saleyard data available for the selected period.".draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: messageAttributes
                )
            } else {
                // Draw saleyard comparison cards
                for saleyardData in data.saleyardComparison {
                    // Check if we need a new page
                    if yPosition > pageHeight - 200 {
                        drawPageFooter(
                            pageNumber: currentPage,
                            totalPages: totalPages,
                            yPosition: pageHeight - margin/2,
                            pageWidth: pageWidth,
                            margin: margin
                        )
                        
                        context.beginPage()
                        currentPage += 1
                        totalPages = currentPage
                        yPosition = margin + 20
                    }
                    
                    yPosition = drawSaleyardComparisonData(
                        saleyardData: saleyardData,
                        yPosition: yPosition,
                        margin: margin,
                        pageWidth: pageWidth
                    )
                }
            }
            
            // Draw footer
            totalPages = currentPage
            drawPageFooter(
                pageNumber: currentPage,
                totalPages: totalPages,
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
    
    // Debug: Generate Livestock Value vs Land Area PDF
    private func generateLivestockValueVsLandAreaPDF(
        data: ReportData,
        configuration: ReportConfiguration
    ) -> URL? {
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Stockman's Wallet",
            kCGPDFContextAuthor: data.farmName ?? "User",
            kCGPDFContextTitle: "Value vs Land Area"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 72.0
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let fileName = "LivestockValueVsLandArea_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var currentPage = 0
        var totalPages = 1
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            currentPage += 1
            var yPosition: CGFloat = margin
            
            // Draw header
            yPosition = drawReportHeader(
                title: "Value vs Land Area",
                farmName: data.farmName,
                userDetails: data.userDetails,
                configuration: configuration,
                context: context,
                yPosition: yPosition,
                pageWidth: pageWidth,
                margin: margin
            )
            
            // Draw section header
            yPosition = drawSectionHeader("Land Area Analysis", yPosition: yPosition, margin: margin)
            
            // Check if we have data
            if data.landValueAnalysis.isEmpty {
                let messageAttributes: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: secondaryTextColor
                ]
                "No land area data available. Please add property acreage in settings.".draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: messageAttributes
                )
            } else {
                // Draw land value analysis cards
                for landData in data.landValueAnalysis {
                    // Check if we need a new page
                    if yPosition > pageHeight - 200 {
                        drawPageFooter(
                            pageNumber: currentPage,
                            totalPages: totalPages,
                            yPosition: pageHeight - margin/2,
                            pageWidth: pageWidth,
                            margin: margin
                        )
                        
                        context.beginPage()
                        currentPage += 1
                        totalPages = currentPage
                        yPosition = margin + 20
                    }
                    
                    yPosition = drawLandValueAnalysisData(
                        landData: landData,
                        yPosition: yPosition,
                        margin: margin,
                        pageWidth: pageWidth
                    )
                }
            }
            
            // Draw footer
            totalPages = currentPage
            drawPageFooter(
                pageNumber: currentPage,
                totalPages: totalPages,
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
    
    // Debug: Generate Farm Comparison PDF
    private func generateFarmComparisonPDF(
        data: ReportData,
        configuration: ReportConfiguration
    ) -> URL? {
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Stockman's Wallet",
            kCGPDFContextAuthor: data.farmName ?? "User",
            kCGPDFContextTitle: "Farm Comparison"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 72.0
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let fileName = "FarmComparison_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var currentPage = 0
        var totalPages = 1
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            currentPage += 1
            var yPosition: CGFloat = margin
            
            // Draw header
            yPosition = drawReportHeader(
                title: "Farm Comparison",
                farmName: data.farmName,
                userDetails: data.userDetails,
                configuration: configuration,
                context: context,
                yPosition: yPosition,
                pageWidth: pageWidth,
                margin: margin
            )
            
            // Draw section header
            yPosition = drawSectionHeader("Property Comparison", yPosition: yPosition, margin: margin)
            
            // Check if we have data
            if data.farmComparison.isEmpty {
                let messageAttributes: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: secondaryTextColor
                ]
                "No comparison data available. Add multiple properties to compare.".draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: messageAttributes
                )
            } else {
                // Draw farm comparison cards
                for farmData in data.farmComparison {
                    // Check if we need a new page
                    if yPosition > pageHeight - 200 {
                        drawPageFooter(
                            pageNumber: currentPage,
                            totalPages: totalPages,
                            yPosition: pageHeight - margin/2,
                            pageWidth: pageWidth,
                            margin: margin
                        )
                        
                        context.beginPage()
                        currentPage += 1
                        totalPages = currentPage
                        yPosition = margin + 20
                    }
                    
                    yPosition = drawFarmComparisonData(
                        farmData: farmData,
                        yPosition: yPosition,
                        margin: margin,
                        pageWidth: pageWidth
                    )
                }
            }
            
            // Draw footer
            totalPages = currentPage
            drawPageFooter(
                pageNumber: currentPage,
                totalPages: totalPages,
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
    
    // MARK: - PDF Drawing Helper Methods
    
    /// Draw Apple-inspired report header with clean hierarchy
    // Debug: Logo on RIGHT, title on LEFT, user details below
    private func drawReportHeader(
        title: String,
        farmName: String?,
        userDetails: UserDetails?,
        configuration: ReportConfiguration,
        context: UIGraphicsPDFRendererContext,
        yPosition: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        
        var y = yPosition
        let contentWidth = pageWidth - (margin * 2)
        
        // MARK: - Top Row: Title LEFT + Logo RIGHT
        let topBarY = y
        
        // Title on LEFT (large, bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: primaryTextColor
        ]
        title.draw(at: CGPoint(x: margin, y: topBarY), withAttributes: titleAttributes)
        
        // Logo on RIGHT (includes "REPORT POWERED BY" text)
        if let logoImage = UIImage(named: "stockmans_reportlogo") {
            let logoHeight: CGFloat = 70
            let logoAspect = logoImage.size.width / logoImage.size.height
            let logoWidth = logoHeight * logoAspect
            let logoX = pageWidth - margin - logoWidth
            let logoRect = CGRect(x: logoX, y: topBarY, width: logoWidth, height: logoHeight)
            logoImage.draw(in: logoRect)
        }
        
        y += 40 // Space after title
        
        // Period subtitle below title (LEFT aligned)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let periodAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: secondaryTextColor
        ]
        let periodText = "\(dateFormatter.string(from: configuration.startDate)) – \(dateFormatter.string(from: configuration.endDate))"
        periodText.draw(at: CGPoint(x: margin, y: y), withAttributes: periodAttributes)
        
        y += 52 // Increased space after period (more space above horizontal line)
        
        // Draw horizontal divider line before user details section
        drawDivider(at: y, margin: margin, width: contentWidth)
        
        y += 40 // Increased space after divider before user details
        
        // MARK: - User Details (Two-column grid)
        if let userDetails = userDetails {
            let labelAttr: [NSAttributedString.Key: Any] = [
                .font: labelFont,
                .foregroundColor: tertiaryTextColor,
                .kern: 0.5
            ]
            let valueAttr: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: primaryTextColor
            ]
            
            // Two-column layout
            let col1X = margin
            let col2X = margin + (contentWidth * 0.5)
            let labelOffset: CGFloat = 14
            
            var currentY = y
            
            // Row 1: PREPARED FOR | PROPERTY
            if let fullName = userDetails.fullName {
                "PREPARED FOR".draw(at: CGPoint(x: col1X, y: currentY), withAttributes: labelAttr)
                fullName.draw(at: CGPoint(x: col1X, y: currentY + labelOffset), withAttributes: valueAttr)
            }
            
            if let propertyName = userDetails.propertyName {
                "PROPERTY".draw(at: CGPoint(x: col2X, y: currentY), withAttributes: labelAttr)
                propertyName.draw(at: CGPoint(x: col2X, y: currentY + labelOffset), withAttributes: valueAttr)
            }
            currentY += 40
            
            // Row 2: PIC CODE | LOCATION
            if let pic = userDetails.propertyPIC {
                "PIC CODE".draw(at: CGPoint(x: col1X, y: currentY), withAttributes: labelAttr)
                pic.draw(at: CGPoint(x: col1X, y: currentY + labelOffset), withAttributes: valueAttr)
            }
            
            // Location (address or state)
            var locationText = ""
            if let address = userDetails.propertyAddress {
                locationText = address
            }
            if let state = userDetails.state {
                locationText += locationText.isEmpty ? state : ", \(state)"
            }
            if !locationText.isEmpty {
                "LOCATION".draw(at: CGPoint(x: col2X, y: currentY), withAttributes: labelAttr)
                locationText.draw(at: CGPoint(x: col2X, y: currentY + labelOffset), withAttributes: valueAttr)
            }
            currentY += 40
            
            y = currentY + 24 // Increased space before divider
            
            // Draw horizontal divider line
            drawDivider(at: y, margin: margin, width: contentWidth)
            
            y += 32 // Increased space after divider (more padding)
        } else {
            y += 24
        }
        
        return y
    }
    
    /// Draw subtle divider line (Apple style)
    private func drawDivider(at yPosition: CGFloat, margin: CGFloat, width: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: yPosition))
        path.addLine(to: CGPoint(x: margin + width, y: yPosition))
        dividerColor.setStroke()
        path.lineWidth = 0.5 // Very thin, subtle
        path.stroke()
    }
    
    /// Draw section header (Apple style - clean and prominent)
    private func drawSectionHeader(_ title: String, yPosition: CGFloat, margin: CGFloat) -> CGFloat {
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: primaryTextColor
        ]
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
        return yPosition + 36 // Increased from 24 for more spacing before cards
    }
    
    /// Draw hero value card (Apple style - prominent display for key metrics)
    // Debug: Large, visually striking display for important numbers like total portfolio value
    private func drawHeroValueCard(
        label: String,
        value: String,
        yPosition: CGFloat,
        margin: CGFloat,
        width: CGFloat
    ) -> CGFloat {
        var y = yPosition
        
        // Card background with subtle styling (optimized height)
        let cardHeight: CGFloat = 90
        let cardRect = CGRect(x: margin, y: y, width: width, height: cardHeight)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cardCornerRadius)
        
        // Subtle gradient-like effect with light background
        cardBackgroundColor.setFill()
        cardPath.fill()
        
        // Very subtle border
        dividerColor.setStroke()
        cardPath.lineWidth = 1
        cardPath.stroke()
        
        // Label (small, uppercase with normal letter spacing) - CENTERED
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: tertiaryTextColor,
            .kern: 0.5
        ]
        let labelText = label.uppercased()
        let labelSize = labelText.size(withAttributes: labelAttributes)
        let labelX = margin + (width - labelSize.width) / 2 // Center horizontally
        labelText.draw(at: CGPoint(x: labelX, y: y + cardPadding), withAttributes: labelAttributes)
        
        // Hero value (large, bold) - CENTERED - less space from label
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: heroFont,
            .foregroundColor: primaryTextColor
        ]
        let valueSize = value.size(withAttributes: valueAttributes)
        let valueX = margin + (width - valueSize.width) / 2 // Center horizontally
        value.draw(at: CGPoint(x: valueX, y: y + cardPadding + 20), withAttributes: valueAttributes)
        
        // Even more spacing after hero card value
        return y + cardHeight + 40 // Further increased for more padding below value
    }
    
    /// Draw compact key-value pair (inline style)
    private func drawKeyValue(
        key: String,
        value: String,
        yPosition: CGFloat,
        margin: CGFloat,
        isBold: Bool = false
    ) -> CGFloat {
        let keyAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: secondaryTextColor
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: isBold ? UIFont.systemFont(ofSize: 13, weight: .semibold) : bodyFont,
            .foregroundColor: primaryTextColor
        ]
        
        let keySize = key.size(withAttributes: keyAttributes)
        key.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: keyAttributes)
        value.draw(at: CGPoint(x: margin + keySize.width + 8, y: yPosition), withAttributes: valueAttributes)
        
        return yPosition + 18
    }
    
    /// Draw herd data card (Apple style - clean card with grid layout)
    // Debug: Modern card design with efficient two-column layout for data with labels
    private func drawHerdData(
        herdData: HerdReportData,
        configuration: ReportConfiguration,
        yPosition: CGFloat,
        margin: CGFloat,
        pageWidth: CGFloat
    ) -> CGFloat {
        
        var y = yPosition
        let cardWidth = pageWidth - (margin * 2)
        let cardStartY = y
        
        // Debug: Calculate card height based on whether we show breeding/risk data
        let showBreedingRiskData = herdData.breedingAccrual != nil || herdData.dailyWeightGain > 0 || herdData.mortalityRate > 0
        let estimatedHeight: CGFloat = showBreedingRiskData ? 170 : 130 // Taller for breeding/risk data
        
        // Card background
        let cardRect = CGRect(x: margin, y: cardStartY, width: cardWidth, height: estimatedHeight)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cardCornerRadius)
        
        cardBackgroundColor.setFill()
        cardPath.fill()
        
        dividerColor.setStroke()
        cardPath.lineWidth = 0.5
        cardPath.stroke()
        
        // Content starts with padding
        y += cardPadding
        let leftX = margin + cardPadding
        let rightX = margin + (cardWidth * 0.55) // Right column starts at 55%
        
        // MARK: - Card Header: Name + Value
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: headlineFont,
            .foregroundColor: primaryTextColor
        ]
        herdData.name.draw(at: CGPoint(x: leftX, y: y), withAttributes: nameAttributes)
        
        // Net value on the right (prominent)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: primaryTextColor
        ]
        let valueText = formatCurrency(herdData.netValue)
        let valueSize = valueText.size(withAttributes: valueAttributes)
        valueText.draw(at: CGPoint(x: margin + cardWidth - cardPadding - valueSize.width, y: y), withAttributes: valueAttributes)
        
        y += 22 // Reduced from 24
        
        // Category subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: secondaryTextColor
        ]
        herdData.category.draw(at: CGPoint(x: leftX, y: y), withAttributes: subtitleAttributes)
        y += 28 // Increased space after category (breed text)
        
        // MARK: - Horizontal grid layout (all four fields in one row)
        let dataAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: primaryTextColor
        ]
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: tertiaryTextColor,
            .kern: 0.3
        ]
        
        // Calculate column positions (4 columns evenly spaced)
        let contentWidth = cardWidth - (cardPadding * 2)
        let col1X = leftX
        let col2X = leftX + (contentWidth * 0.25)
        let col3X = leftX + (contentWidth * 0.50)
        let col4X = leftX + (contentWidth * 0.75)
        
        // Row 1: Labels
        "HEAD COUNT".draw(at: CGPoint(x: col1X, y: y), withAttributes: labelAttributes)
        "AGE".draw(at: CGPoint(x: col2X, y: y), withAttributes: labelAttributes)
        "WEIGHT".draw(at: CGPoint(x: col3X, y: y), withAttributes: labelAttributes)
        "PRICE".draw(at: CGPoint(x: col4X, y: y), withAttributes: labelAttributes)
        y += 14 // Space between label and value
        
        // Row 2: Values
        "\(herdData.headCount) head".draw(at: CGPoint(x: col1X, y: y), withAttributes: dataAttributes)
        "\(herdData.ageMonths) months".draw(at: CGPoint(x: col2X, y: y), withAttributes: dataAttributes)
        "\(Int(herdData.weight)) kg".draw(at: CGPoint(x: col3X, y: y), withAttributes: dataAttributes)
        
        let priceText: String
        switch configuration.priceStatistics {
        case .current:
            priceText = "$\(String(format: "%.2f", herdData.pricePerKg))/kg"
        case .minimum:
            priceText = "$\(String(format: "%.2f", herdData.minPrice))/kg (min)"
        case .maximum:
            priceText = "$\(String(format: "%.2f", herdData.maxPrice))/kg (max)"
        case .average:
            priceText = "$\(String(format: "%.2f", herdData.avgPrice))/kg (avg)"
        case .all:
            priceText = "$\(String(format: "%.2f", herdData.pricePerKg))/kg"
        }
        priceText.draw(at: CGPoint(x: col4X, y: y), withAttributes: dataAttributes)
        
        // MARK: - Breeding & Risk Allocations (for bank review)
        // Debug: Show calf accrual, DWG, and mortality provisions if relevant
        if showBreedingRiskData {
            y += 24 // Space before breeding/risk section
            
            // Section divider with lighter color
            let dividerY = y
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: leftX, y: dividerY))
            dividerPath.addLine(to: CGPoint(x: margin + cardWidth - cardPadding, y: dividerY))
            UIColor(white: 0.92, alpha: 1.0).setStroke()
            dividerPath.lineWidth = 0.5
            dividerPath.stroke()
            
            y += 12 // Space after divider
            
            // Calculate three-column layout for breeding/risk data
            let riskCol1X = leftX
            let riskCol2X = leftX + (contentWidth * 0.33)
            let riskCol3X = leftX + (contentWidth * 0.66)
            
            // Row: Labels (lighter, smaller text)
            if let breedingAccrual = herdData.breedingAccrual {
                "CALF ACCRUAL".draw(at: CGPoint(x: riskCol1X, y: y), withAttributes: labelAttributes)
            }
            if herdData.dailyWeightGain > 0 {
                let dwgX = herdData.breedingAccrual != nil ? riskCol2X : riskCol1X
                "DWG ALLOCATION".draw(at: CGPoint(x: dwgX, y: y), withAttributes: labelAttributes)
            }
            if herdData.mortalityRate > 0 {
                let mortX: CGFloat
                if herdData.breedingAccrual != nil && herdData.dailyWeightGain > 0 {
                    mortX = riskCol3X
                } else if herdData.breedingAccrual != nil || herdData.dailyWeightGain > 0 {
                    mortX = riskCol2X
                } else {
                    mortX = riskCol1X
                }
                "MORTALITY".draw(at: CGPoint(x: mortX, y: y), withAttributes: labelAttributes)
            }
            y += 12
            
            // Row: Values
            if let breedingAccrual = herdData.breedingAccrual {
                formatCurrency(breedingAccrual).draw(at: CGPoint(x: riskCol1X, y: y), withAttributes: dataAttributes)
            }
            if herdData.dailyWeightGain > 0 {
                let dwgX = herdData.breedingAccrual != nil ? riskCol2X : riskCol1X
                "\(String(format: "%.2f", herdData.dailyWeightGain)) kg/day".draw(at: CGPoint(x: dwgX, y: y), withAttributes: dataAttributes)
            }
            if herdData.mortalityRate > 0 {
                let mortX: CGFloat
                if herdData.breedingAccrual != nil && herdData.dailyWeightGain > 0 {
                    mortX = riskCol3X
                } else if herdData.breedingAccrual != nil || herdData.dailyWeightGain > 0 {
                    mortX = riskCol2X
                } else {
                    mortX = riskCol1X
                }
                "\(String(format: "%.1f", herdData.mortalityRate * 100))% p.a.".draw(at: CGPoint(x: mortX, y: y), withAttributes: dataAttributes)
            }
        }
        
        // Return position after card with spacing
        return cardStartY + estimatedHeight + cardSpacing
    }
    
    /// Draw minimal footer (Apple style - subtle and unobtrusive)
    // Debug: Clean footer with page number in "-- X of Y --" format, centered
    private func drawPageFooter(
        pageNumber: Int,
        totalPages: Int,
        yPosition: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) {
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: tertiaryTextColor
        ]
        
        // Page number in "-- X of Y --" format
        let footerText = "-- \(pageNumber) of \(totalPages) --"
        let textSize = footerText.size(withAttributes: footerAttributes)
        let xPosition = (pageWidth - textSize.width) / 2
        
        footerText.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: footerAttributes)
    }
    
    /// Draw property details card (Apple style - compact info card)
    // Debug: Clean card displaying additional property information
    private func drawPropertyDetails(
        propertyDetails: PropertyDetails,
        yPosition: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = yPosition
        let cardWidth = pageWidth - (margin * 2)
        
        y = drawSectionHeader("Property Details", yPosition: y, margin: margin)
        
        let cardStartY = y
        let cardHeight: CGFloat = 70
        
        // Card background
        let cardRect = CGRect(x: margin, y: cardStartY, width: cardWidth, height: cardHeight)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cardCornerRadius)
        
        cardBackgroundColor.setFill()
        cardPath.fill()
        
        dividerColor.setStroke()
        cardPath.lineWidth = 0.5
        cardPath.stroke()
        
        // Content in two columns
        y += cardPadding
        let leftX = margin + cardPadding
        let midX = margin + (cardWidth * 0.33)
        let rightX = margin + (cardWidth * 0.66)
        
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: tertiaryTextColor,
            .kern: 0.5
        ]
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: primaryTextColor
        ]
        
        var hasContent = false
        
        // Column 1: Acreage
        if let acreage = propertyDetails.acreage {
            "SIZE".draw(at: CGPoint(x: leftX, y: y), withAttributes: labelAttr)
            "\(String(format: "%.1f", acreage)) acres".draw(at: CGPoint(x: leftX, y: y + 14), withAttributes: valueAttr)
            hasContent = true
        }
        
        // Column 2: Property Type
        if let propertyType = propertyDetails.propertyType {
            "TYPE".draw(at: CGPoint(x: midX, y: y), withAttributes: labelAttr)
            propertyType.draw(at: CGPoint(x: midX, y: y + 14), withAttributes: valueAttr)
            hasContent = true
        }
        
        // Column 3: Default Saleyard
        if let saleyard = propertyDetails.defaultSaleyard {
            "SALEYARD".draw(at: CGPoint(x: rightX, y: y), withAttributes: labelAttr)
            saleyard.draw(at: CGPoint(x: rightX, y: y + 14), withAttributes: valueAttr)
            hasContent = true
        }
        
        return hasContent ? (cardStartY + cardHeight) : yPosition
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





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
            
            // Draw property details if configured
            if configuration.includePropertyDetails, let propertyDetails = data.propertyDetails {
                yPosition = drawPropertyDetails(
                    propertyDetails: propertyDetails,
                    yPosition: yPosition,
                    pageWidth: pageWidth,
                    margin: margin
                )
                yPosition += cardSpacing
            }
            
            // Draw total portfolio value as hero card
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
                        yPosition: pageHeight - margin/2,
                        pageWidth: pageWidth,
                        margin: margin
                    )
                    
                    context.beginPage()
                    currentPage += 1
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
            drawPageFooter(
                pageNumber: currentPage,
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
    
    /// Draw Apple-inspired report header with clean hierarchy
    // Debug: Modern, minimal header design with clear information architecture
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
        
        // MARK: - Top Bar: Logo + Generated Date (one line, subtle)
        let topBarY = y
        
        // Logo on left (increased size)
        if let logoImage = UIImage(named: "stockmanswallet_logo_bw") {
            let logoHeight: CGFloat = 40 // Increased from 28
            let logoAspect = logoImage.size.width / logoImage.size.height
            let logoWidth = logoHeight * logoAspect
            let logoRect = CGRect(x: margin, y: topBarY, width: logoWidth, height: logoHeight)
            logoImage.draw(in: logoRect)
        }
        
        // Generated date on right (subtle)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let generatedText = dateFormatter.string(from: Date())
        let generatedAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: tertiaryTextColor
        ]
        let generatedSize = generatedText.size(withAttributes: generatedAttributes)
        generatedText.draw(at: CGPoint(x: pageWidth - margin - generatedSize.width, y: topBarY + 8), withAttributes: generatedAttributes)
        
        y += 52 // Space after top bar (increased from 44)
        
        // MARK: - Hero Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: largeTitleFont,
            .foregroundColor: primaryTextColor
        ]
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
        y += 36 // Reduced from 42
        
        // Period subtitle (if applicable)
        let periodAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: secondaryTextColor
        ]
        let periodText = "\(dateFormatter.string(from: configuration.startDate)) – \(dateFormatter.string(from: configuration.endDate))"
        periodText.draw(at: CGPoint(x: margin, y: y), withAttributes: periodAttributes)
        y += 24 // Reduced from 28
        
        // MARK: - User Details (Clean grid layout)
        if let userDetails = userDetails {
            // Subtle divider line before details
            drawDivider(at: y, margin: margin, width: contentWidth)
            y += 20
            
            let labelAttr: [NSAttributedString.Key: Any] = [
                .font: labelFont,
                .foregroundColor: tertiaryTextColor,
                .kern: 0.5 // Letter spacing for labels
            ]
            let valueAttr: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: primaryTextColor
            ]
            
            // Two-column layout for efficient space use
            let col1X = margin
            let col2X = margin + (contentWidth * 0.5)
            let labelOffset: CGFloat = 14
            
            var currentY = y
            
            // Row 1: Name | Property
            if let fullName = userDetails.fullName {
                "PREPARED FOR".draw(at: CGPoint(x: col1X, y: currentY), withAttributes: labelAttr)
                fullName.draw(at: CGPoint(x: col1X, y: currentY + labelOffset), withAttributes: valueAttr)
            }
            
            if let propertyName = userDetails.propertyName {
                "PROPERTY".draw(at: CGPoint(x: col2X, y: currentY), withAttributes: labelAttr)
                propertyName.draw(at: CGPoint(x: col2X, y: currentY + labelOffset), withAttributes: valueAttr)
            }
            currentY += 36
            
            // Row 2: PIC | State & Address
            if let pic = userDetails.propertyPIC {
                "PIC CODE".draw(at: CGPoint(x: col1X, y: currentY), withAttributes: labelAttr)
                pic.draw(at: CGPoint(x: col1X, y: currentY + labelOffset), withAttributes: valueAttr)
            }
            
            // Combine state and address for compact display
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
            currentY += 36
            
            y = currentY + 8
            
            // Subtle divider line after details
            drawDivider(at: y, margin: margin, width: contentWidth)
            y += sectionSpacing
        } else {
            // If no user details, just add a divider
            drawDivider(at: y, margin: margin, width: contentWidth)
            y += sectionSpacing
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
        return yPosition + 24 // Tighter spacing, more modern
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
        let cardHeight: CGFloat = 90 // Reduced from 100
        let cardRect = CGRect(x: margin, y: y, width: width, height: cardHeight)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cardCornerRadius)
        
        // Subtle gradient-like effect with light background
        cardBackgroundColor.setFill()
        cardPath.fill()
        
        // Very subtle border
        dividerColor.setStroke()
        cardPath.lineWidth = 1
        cardPath.stroke()
        
        // Label (small, uppercase)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: tertiaryTextColor,
            .kern: 1.0 // Wide letter spacing for labels
        ]
        label.uppercased().draw(at: CGPoint(x: margin + cardPadding, y: y + cardPadding), withAttributes: labelAttributes)
        
        // Hero value (large, bold) - adjusted positioning
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: heroFont,
            .foregroundColor: primaryTextColor
        ]
        value.draw(at: CGPoint(x: margin + cardPadding, y: y + cardPadding + 24), withAttributes: valueAttributes)
        
        return y + cardHeight + cardSpacing
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
        
        // Estimate card height based on content
        let estimatedHeight: CGFloat = 120 // Increased from 110 to accommodate labels
        
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
        y += 18 // Reduced from 20
        
        // MARK: - Two-column data grid WITH LABELS
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
        
        // Left column with labels
        "HEAD COUNT".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: labelAttributes)
        leftY += 12
        "\(herdData.headCount) head".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: dataAttributes)
        leftY += 18
        
        "AGE".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: labelAttributes)
        leftY += 12
        "\(herdData.ageMonths) months".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: dataAttributes)
        
        // Right column with labels - Weight and Price
        "WEIGHT".draw(at: CGPoint(x: rightX, y: rightY), withAttributes: labelAttributes)
        rightY += 12
        "\(Int(herdData.weight)) kg".draw(at: CGPoint(x: rightX, y: rightY), withAttributes: dataAttributes)
        rightY += 18
        
        "PRICE".draw(at: CGPoint(x: rightX, y: rightY), withAttributes: labelAttributes)
        rightY += 12
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
        priceText.draw(at: CGPoint(x: rightX, y: rightY), withAttributes: dataAttributes)
        
        // Return position after card with spacing
        return cardStartY + estimatedHeight + cardSpacing
    }
    
    /// Draw minimal footer (Apple style - subtle and unobtrusive)
    // Debug: Clean footer with page number, centered
    private func drawPageFooter(
        pageNumber: Int,
        yPosition: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) {
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: tertiaryTextColor
        ]
        
        // Simple page number
        let footerText = "\(pageNumber)"
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





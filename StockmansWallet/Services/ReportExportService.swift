//
//  ReportExportService.swift
//  StockmansWallet
//
//  Service for exporting reports to PDF and CSV formats
//

import Foundation
import PDFKit
import SwiftUI
import SwiftData

class ReportExportService {
    static let shared = ReportExportService()
    
    private init() {}
    
    // MARK: - PDF Export
    
    /// Generates a PDF from a SwiftUI view
    func generatePDF(from view: some View, size: CGSize = CGSize(width: 595, height: 842)) -> URL? {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(origin: .zero, size: size)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            hostingController.view.layer.render(in: context.cgContext)
        }
        
        // Convert image to PDF
        let pdfData = NSMutableData()
        let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!
        var mediaBox = CGRect(origin: .zero, size: size)
        let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil)!
        
        pdfContext.beginPage(mediaBox: &mediaBox)
        pdfContext.draw(image.cgImage!, in: mediaBox)
        pdfContext.endPage()
        pdfContext.closePDF()
        
        // Save to temporary file
        let fileName = "Report_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
    
    /// Generates Asset Register PDF
    func generateAssetRegisterPDF(
        herds: [HerdGroup],
        valuations: [UUID: HerdValuation],
        totalValue: Double,
        preferences: UserPreferences
    ) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Stockman's Wallet",
            kCGPDFContextAuthor: "Stockman's Wallet",
            kCGPDFContextTitle: "Asset Register"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 72.0
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let fileName = "AssetRegister_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Debug: Track page numbers
        var currentPage = 0
        
        let data = renderer.pdfData { context in
            context.beginPage()
            currentPage += 1
            
            var yPosition: CGFloat = margin
            
            // MARK: - Apple-inspired Header Design (matching refined layout)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            // Top row: Title LEFT + Logo RIGHT
            let topBarY = yPosition
            
            // Title on LEFT (large, bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            "Asset Register".draw(at: CGPoint(x: margin, y: topBarY), withAttributes: titleAttributes)
            
            // Logo on RIGHT (includes "REPORT POWERED BY")
            if let logoImage = UIImage(named: "stockmans_reportlogo") {
                let logoHeight: CGFloat = 70
                let logoAspect = logoImage.size.width / logoImage.size.height
                let logoWidth = logoHeight * logoAspect
                let logoX = pageWidth - margin - logoWidth
                let logoRect = CGRect(x: logoX, y: topBarY, width: logoWidth, height: logoHeight)
                logoImage.draw(in: logoRect)
            }
            
            yPosition += 40 // Space after title
            
            // Date range below title (LEFT aligned)
            let periodAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor(white: 0.5, alpha: 1.0)
            ]
            let periodText = "\(dateFormatter.string(from: Date())) – \(dateFormatter.string(from: Date()))"
            periodText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: periodAttributes)
            
            yPosition += 32 // Space after date
            
            // User details in two-column grid
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: UIColor(white: 0.6, alpha: 1.0),
                .kern: 0.5
            ]
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.black
            ]
            
            let col1X = margin
            let col2X = margin + ((pageWidth - margin * 2) * 0.5)
            
            // Row 1: PREPARED FOR | PROPERTY
            if let firstName = preferences.firstName, let lastName = preferences.lastName {
                "PREPARED FOR".draw(at: CGPoint(x: col1X, y: yPosition), withAttributes: labelAttributes)
                "\(firstName) \(lastName)".draw(at: CGPoint(x: col1X, y: yPosition + 14), withAttributes: valueAttributes)
            }
            
            if let propertyName = preferences.propertyName {
                "PROPERTY".draw(at: CGPoint(x: col2X, y: yPosition), withAttributes: labelAttributes)
                propertyName.draw(at: CGPoint(x: col2X, y: yPosition + 14), withAttributes: valueAttributes)
            }
            yPosition += 40
            
            // Row 2: PIC CODE | LOCATION
            if let pic = preferences.propertyPIC {
                "PIC CODE".draw(at: CGPoint(x: col1X, y: yPosition), withAttributes: labelAttributes)
                pic.draw(at: CGPoint(x: col1X, y: yPosition + 14), withAttributes: valueAttributes)
            }
            
            let state = preferences.defaultState
            if !state.isEmpty {
                "LOCATION".draw(at: CGPoint(x: col2X, y: yPosition), withAttributes: labelAttributes)
                state.draw(at: CGPoint(x: col2X, y: yPosition + 14), withAttributes: valueAttributes)
            }
            yPosition += 64 // Increased space before divider
            
            // Draw horizontal divider line
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: yPosition))
            dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            UIColor(white: 0.9, alpha: 1.0).setStroke()
            dividerPath.lineWidth = 0.5
            dividerPath.stroke()
            yPosition += 32 // Increased space after divider
            
            // Total Portfolio Value - Hero Card (optimized)
            let cardWidth = pageWidth - (margin * 2)
            let heroCardHeight: CGFloat = 90 // Reduced from 100
            let cardRect = CGRect(x: margin, y: yPosition, width: cardWidth, height: heroCardHeight)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 12)
            
            UIColor(white: 0.98, alpha: 1.0).setFill()
            cardPath.fill()
            
            UIColor(white: 0.9, alpha: 1.0).setStroke()
            cardPath.lineWidth = 1
            cardPath.stroke()
            
            // Label - CENTERED
            let heroLabelAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: UIColor(white: 0.6, alpha: 1.0),
                .kern: 0.5
            ]
            let labelText = "TOTAL PORTFOLIO VALUE"
            let labelSize = labelText.size(withAttributes: heroLabelAttr)
            let labelX = margin + (cardWidth - labelSize.width) / 2
            labelText.draw(at: CGPoint(x: labelX, y: yPosition + 20), withAttributes: heroLabelAttr)
            
            // Value - CENTERED
            let heroValueAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let valueText = formatCurrency(totalValue)
            let valueSize = valueText.size(withAttributes: heroValueAttr)
            let valueX = margin + (cardWidth - valueSize.width) / 2
            valueText.draw(at: CGPoint(x: valueX, y: yPosition + 40), withAttributes: heroValueAttr)
            
            yPosition += heroCardHeight + 40 // Further increased spacing for more padding
            
            // Section Header
            let sectionHeaderAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
            "Livestock Assets".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionHeaderAttr)
            yPosition += 36 // Increased for more spacing before cards
            
            // Herds as cards
            let activeHerds = herds.filter { !$0.isSold }
            for herd in activeHerds {
                if yPosition > pageHeight - 200 {
                    // Draw footer for current page
                    let footerText = "\(currentPage)"
                    let footerAttr: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: UIColor(white: 0.6, alpha: 1.0)
                    ]
                    let textSize = footerText.size(withAttributes: footerAttr)
                    let xPosition = (pageWidth - textSize.width) / 2
                    footerText.draw(at: CGPoint(x: xPosition, y: pageHeight - margin/2), withAttributes: footerAttr)
                    
                    context.beginPage()
                    currentPage += 1
                    yPosition = margin + 20
                }
                
                // Herd Card (with labels, increased bottom padding)
                let herdCardHeight: CGFloat = 130 // Increased from 120 for more bottom padding
                let herdCardRect = CGRect(x: margin, y: yPosition, width: cardWidth, height: herdCardHeight)
                let herdCardPath = UIBezierPath(roundedRect: herdCardRect, cornerRadius: 12)
                
                UIColor(white: 0.98, alpha: 1.0).setFill()
                herdCardPath.fill()
                
                UIColor(white: 0.9, alpha: 1.0).setStroke()
                herdCardPath.lineWidth = 0.5
                herdCardPath.stroke()
                
                let cardPadding: CGFloat = 20 // Increased from 16
                var cardY = yPosition + cardPadding
                let leftX = margin + cardPadding
                let rightCol = margin + (cardWidth * 0.55)
                
                // Herd name + value
                let nameAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
                herd.name.draw(at: CGPoint(x: leftX, y: cardY), withAttributes: nameAttr)
                
                if let valuation = valuations[herd.id] {
                    let valueAttr: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 16, weight: .semibold), // Reduced from 17
                        .foregroundColor: UIColor.black
                    ]
                    let valueText = formatCurrency(valuation.netRealizableValue)
                    let valueSize = valueText.size(withAttributes: valueAttr)
                    valueText.draw(at: CGPoint(x: margin + cardWidth - cardPadding - valueSize.width, y: cardY), withAttributes: valueAttr)
                }
                
                cardY += 22
                
                // Category subtitle
                let subtitleAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor(white: 0.4, alpha: 1.0)
                ]
                "\(herd.breed) \(herd.category)".draw(at: CGPoint(x: leftX, y: cardY), withAttributes: subtitleAttr)
                cardY += 18
                
                // Details in grid WITH LABELS
                let detailAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13),
                    .foregroundColor: UIColor.black
                ]
                let labelAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                    .foregroundColor: UIColor(white: 0.6, alpha: 1.0),
                    .kern: 0.3
                ]
                
                var leftY = cardY
                var rightY = cardY
                
                // Left column with labels
                "HEAD COUNT".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: labelAttr)
                leftY += 12
                "\(herd.headCount) head".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: detailAttr)
                leftY += 18
                
                "AGE".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: labelAttr)
                leftY += 12
                "\(herd.ageMonths) months".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: detailAttr)
                
                // Right column with labels
                if let valuation = valuations[herd.id] {
                    "WEIGHT".draw(at: CGPoint(x: rightCol, y: rightY), withAttributes: labelAttr)
                    rightY += 12
                    let weightText = "\(Int(valuation.projectedWeight)) kg"
                    weightText.draw(at: CGPoint(x: rightCol, y: rightY), withAttributes: detailAttr)
                    rightY += 18
                    
                    "PRICE".draw(at: CGPoint(x: rightCol, y: rightY), withAttributes: labelAttr)
                    rightY += 12
                    let priceText = "$\(String(format: "%.2f", valuation.pricePerKg))/kg"
                    priceText.draw(at: CGPoint(x: rightCol, y: rightY), withAttributes: detailAttr)
                }
                
                yPosition += herdCardHeight + 12 // Card height + reduced spacing
            }
            
            // Draw footer for last page (Asset Register)
            let footerText = "\(currentPage)"
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor(white: 0.6, alpha: 1.0)
            ]
            let textSize = footerText.size(withAttributes: footerAttr)
            let xPosition = (pageWidth - textSize.width) / 2
            footerText.draw(at: CGPoint(x: xPosition, y: pageHeight - margin/2), withAttributes: footerAttr)
        }
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
    
    /// Generates Sales Summary PDF
    func generateSalesSummaryPDF(sales: [SalesRecord], preferences: UserPreferences? = nil) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Stockman's Wallet",
            kCGPDFContextAuthor: "Stockman's Wallet",
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
        
        let sortedSales = sales.sorted { $0.saleDate > $1.saleDate }
        let totalSales = sales.reduce(0) { $0 + $1.netValue }
        let totalGross = sales.reduce(0) { $0 + $1.totalGrossValue }
        let totalFreight = sales.reduce(0) { $0 + $1.freightCost }
        
        // Debug: Track page numbers
        var currentPage = 0
        
        let data = renderer.pdfData { context in
            context.beginPage()
            currentPage += 1
            
            var yPosition: CGFloat = margin
            let cardWidth = pageWidth - (margin * 2)
            
            // MARK: - Apple-inspired Header (Sales Summary)
            
            // Top bar: Logo on left, date on right
            let topBarY = yPosition
            if let logoImage = UIImage(named: "stockmanswallet_logo_bw") {
                let logoHeight: CGFloat = 55 // Increased from 50 for better visibility
                let logoAspect = logoImage.size.width / logoImage.size.height
                let logoWidth = logoHeight * logoAspect
                let logoRect = CGRect(x: margin, y: topBarY, width: logoWidth, height: logoHeight)
                logoImage.draw(in: logoRect)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let generatedText = dateFormatter.string(from: Date())
            let captionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor(white: 0.6, alpha: 1.0)
            ]
            let generatedSize = generatedText.size(withAttributes: captionAttributes)
            generatedText.draw(at: CGPoint(x: pageWidth - margin - generatedSize.width, y: topBarY + 12), withAttributes: captionAttributes)
            
            yPosition += 67
            
            // Large title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold), // Reduced from 32
                .foregroundColor: UIColor.black
            ]
            "Sales Summary".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 38
            
            // Subtle divider
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: yPosition))
            dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            UIColor(white: 0.9, alpha: 1.0).setStroke()
            dividerPath.lineWidth = 0.5
            dividerPath.stroke()
            yPosition += 20
            
            // User details in two-column grid (if available)
            if let prefs = preferences {
                let labelAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                    .foregroundColor: UIColor(white: 0.6, alpha: 1.0),
                    .kern: 0.5
                ]
                let valueAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13),
                    .foregroundColor: UIColor.black
                ]
                
                let col1X = margin
                let col2X = margin + (cardWidth * 0.5)
                
                if let firstName = prefs.firstName, let lastName = prefs.lastName {
                    "PREPARED FOR".draw(at: CGPoint(x: col1X, y: yPosition), withAttributes: labelAttributes)
                    "\(firstName) \(lastName)".draw(at: CGPoint(x: col1X, y: yPosition + 14), withAttributes: valueAttributes)
                }
                
                if let propertyName = prefs.propertyName {
                    "PROPERTY".draw(at: CGPoint(x: col2X, y: yPosition), withAttributes: labelAttributes)
                    propertyName.draw(at: CGPoint(x: col2X, y: yPosition + 14), withAttributes: valueAttributes)
                }
                yPosition += 40
                
                let divider2 = UIBezierPath()
                divider2.move(to: CGPoint(x: margin, y: yPosition))
                divider2.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
                UIColor(white: 0.9, alpha: 1.0).setStroke()
                divider2.lineWidth = 0.5
                divider2.stroke()
                yPosition += 28
            }
            
            // Summary Hero Card (optimized)
            let summaryCardHeight: CGFloat = 90 // Reduced from 100
            let summaryCardRect = CGRect(x: margin, y: yPosition, width: cardWidth, height: summaryCardHeight)
            let summaryCardPath = UIBezierPath(roundedRect: summaryCardRect, cornerRadius: 12)
            
            UIColor(white: 0.98, alpha: 1.0).setFill()
            summaryCardPath.fill()
            
            UIColor(white: 0.9, alpha: 1.0).setStroke()
            summaryCardPath.lineWidth = 1
            summaryCardPath.stroke()
            
            let heroLabelAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .medium), // Reduced from 10
                .foregroundColor: UIColor(white: 0.6, alpha: 1.0),
                .kern: 1.0
            ]
            "TOTAL SALES VALUE".draw(at: CGPoint(x: margin + 20, y: yPosition + 20), withAttributes: heroLabelAttr)
            
            let heroValueAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold), // Reduced from 44
                .foregroundColor: UIColor.black
            ]
            formatCurrency(totalSales).draw(at: CGPoint(x: margin + 20, y: yPosition + 42), withAttributes: heroValueAttr)
            
            yPosition += summaryCardHeight + 24 // Increased spacing (was 12)
            
            // Additional summary stats (compact, inline)
            let detailAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor(white: 0.4, alpha: 1.0)
            ]
            "Gross: \(formatCurrency(totalGross))".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: detailAttr)
            if totalFreight > 0 {
                let grossSize = "Gross: \(formatCurrency(totalGross))  ".size(withAttributes: detailAttr)
                "Freight: \(formatCurrency(totalFreight))".draw(at: CGPoint(x: margin + grossSize.width, y: yPosition), withAttributes: detailAttr)
            }
            yPosition += 32
            
            // Section header
            let sectionHeaderAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold), // Reduced from 20
                .foregroundColor: UIColor.black
            ]
            "Sales History".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionHeaderAttr)
            yPosition += 24 // Reduced from 32
            
            // Sales as cards
            for sale in sortedSales {
                if yPosition > pageHeight - 150 {
                    // Draw footer for current page
                    let footerText = "\(currentPage)"
                    let footerAttr: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: UIColor(white: 0.6, alpha: 1.0)
                    ]
                    let textSize = footerText.size(withAttributes: footerAttr)
                    let xPosition = (pageWidth - textSize.width) / 2
                    footerText.draw(at: CGPoint(x: xPosition, y: pageHeight - margin/2), withAttributes: footerAttr)
                    
                    context.beginPage()
                    currentPage += 1
                    yPosition = margin + 20
                }
                
                // Sale Card (with labels, optimized with better bottom padding)
                let saleCardHeight: CGFloat = 120 // Increased from 110 for more bottom padding
                let saleCardRect = CGRect(x: margin, y: yPosition, width: cardWidth, height: saleCardHeight)
                let saleCardPath = UIBezierPath(roundedRect: saleCardRect, cornerRadius: 12)
                
                UIColor(white: 0.98, alpha: 1.0).setFill()
                saleCardPath.fill()
                
                UIColor(white: 0.9, alpha: 1.0).setStroke()
                saleCardPath.lineWidth = 0.5
                saleCardPath.stroke()
                
                let cardPadding: CGFloat = 20 // Increased from 16
                var cardY = yPosition + cardPadding
                let leftX = margin + cardPadding
                let rightCol = margin + (cardWidth * 0.55)
                
                // Date + Net value
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                
                let dateAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
                dateFormatter.string(from: sale.saleDate).draw(at: CGPoint(x: leftX, y: cardY), withAttributes: dateAttr)
                
                let valueAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold), // Reduced from 17
                    .foregroundColor: UIColor.black
                ]
                let valueText = formatCurrency(sale.netValue)
                let valueSize = valueText.size(withAttributes: valueAttr)
                valueText.draw(at: CGPoint(x: margin + cardWidth - cardPadding - valueSize.width, y: cardY), withAttributes: valueAttr)
                
                cardY += 22
                
                // Details in two columns WITH LABELS
                let detailAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13),
                    .foregroundColor: UIColor.black
                ]
                let labelAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                    .foregroundColor: UIColor(white: 0.6, alpha: 1.0),
                    .kern: 0.3
                ]
                
                var leftY = cardY
                var rightY = cardY
                
                // Left column with labels
                "HEAD COUNT".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: labelAttr)
                leftY += 12
                "\(sale.headCount) head".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: detailAttr)
                leftY += 18
                
                "AVG WEIGHT".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: labelAttr)
                leftY += 12
                "\(Int(sale.averageWeight)) kg".draw(at: CGPoint(x: leftX, y: leftY), withAttributes: detailAttr)
                
                // Right column with labels
                "PRICE".draw(at: CGPoint(x: rightCol, y: rightY), withAttributes: labelAttr)
                rightY += 12
                "$\(String(format: "%.2f", sale.pricePerKg))/kg".draw(at: CGPoint(x: rightCol, y: rightY), withAttributes: detailAttr)
                rightY += 18
                
                "GROSS VALUE".draw(at: CGPoint(x: rightCol, y: rightY), withAttributes: labelAttr)
                rightY += 12
                formatCurrency(sale.totalGrossValue).draw(at: CGPoint(x: rightCol, y: rightY), withAttributes: detailAttr)
                
                yPosition += saleCardHeight + 12 // Card height + spacing
            }
            
            // Draw footer for last page (Sales Summary)
            let footerText = "\(currentPage)"
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor(white: 0.6, alpha: 1.0)
            ]
            let textSize = footerText.size(withAttributes: footerAttr)
            let xPosition = (pageWidth - textSize.width) / 2
            footerText.draw(at: CGPoint(x: xPosition, y: pageHeight - margin/2), withAttributes: footerAttr)
        }
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - CSV Export
    
    /// Generates Asset Register CSV
    func generateAssetRegisterCSV(
        herds: [HerdGroup],
        valuations: [UUID: HerdValuation]
    ) -> URL? {
        let activeHerds = herds.filter { !$0.isSold }
        
        var csv = "Herd Name,Category,Breed,Species,Head Count,Age (months),Initial Weight (kg),Projected Weight (kg),Price per kg,Price Source,Physical Value,Breeding Accrual,Gross Value,Mortality Deduction,Cost to Carry,Net Realizable Value,Paddock,Saleyard,Last Updated,Last Mustered\n"
        
        // Debug: Date formatter for CSV export
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for herd in activeHerds {
            let valuation = valuations[herd.id]
            let projectedWeight = valuation?.projectedWeight ?? herd.initialWeight
            let pricePerKg = valuation?.pricePerKg ?? 0.0
            let priceSource = valuation?.priceSource ?? "N/A"
            let physicalValue = valuation?.physicalValue ?? 0.0
            let breedingAccrual = valuation?.breedingAccrual ?? 0.0
            let grossValue = valuation?.grossValue ?? 0.0
            let mortalityDeduction = valuation?.mortalityDeduction ?? 0.0
            let costToCarry = valuation?.costToCarry ?? 0.0
            let netValue = valuation?.netRealizableValue ?? 0.0
            
            // Debug: Format dates for CSV
            let lastUpdated = dateFormatter.string(from: herd.updatedAt)
            let lastMustered = herd.lastMusterDate != nil ? dateFormatter.string(from: herd.lastMusterDate!) : ""
            
            let row = [
                escapeCSV(herd.name),
                escapeCSV(herd.category),
                escapeCSV(herd.breed),
                escapeCSV(herd.species),
                "\(herd.headCount)",
                "\(herd.ageMonths)",
                String(format: "%.2f", herd.initialWeight),
                String(format: "%.2f", projectedWeight),
                String(format: "%.2f", pricePerKg),
                escapeCSV(priceSource),
                String(format: "%.2f", physicalValue),
                String(format: "%.2f", breedingAccrual),
                String(format: "%.2f", grossValue),
                String(format: "%.2f", mortalityDeduction),
                String(format: "%.2f", costToCarry),
                String(format: "%.2f", netValue),
                escapeCSV(herd.paddockName ?? ""),
                escapeCSV(herd.selectedSaleyard ?? ""),
                lastUpdated,
                lastMustered
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        let fileName = "AssetRegister_\(Date().timeIntervalSince1970).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to save CSV: \(error)")
            return nil
        }
    }
    
    /// Generates Sales Summary CSV
    // Debug: Enhanced with new fields for better API data
    func generateSalesSummaryCSV(sales: [SalesRecord]) -> URL? {
        let sortedSales = sales.sorted { $0.saleDate > $1.saleDate }
        
        var csv = "Sale Date,Head Count,Average Weight (kg),Pricing Type,Price per kg,Price per head,Gross Value,Freight Cost,Freight Distance (km),Net Value,Sale Type,Sale Location\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for sale in sortedSales {
            let row = [
                dateFormatter.string(from: sale.saleDate),
                "\(sale.headCount)",
                String(format: "%.2f", sale.averageWeight),
                sale.pricingTypeEnum.rawValue, // Debug: Pricing type
                String(format: "%.2f", sale.pricePerKg),
                sale.pricePerHead != nil ? String(format: "%.2f", sale.pricePerHead!) : "", // Debug: Price per head if available
                String(format: "%.2f", sale.totalGrossValue),
                String(format: "%.2f", sale.freightCost),
                String(format: "%.2f", sale.freightDistance),
                String(format: "%.2f", sale.netValue),
                sale.saleType ?? "", // Debug: Sale type
                sale.saleLocation ?? "" // Debug: Sale location
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        let fileName = "SalesSummary_\(Date().timeIntervalSince1970).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to save CSV: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "AUD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"" + string.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return string
    }
}


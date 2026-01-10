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
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let fileName = "AssetRegister_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 72
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            "Asset Register".draw(at: CGPoint(x: 72, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .none
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]
            "Generated: \(dateFormatter.string(from: Date()))".draw(at: CGPoint(x: 72, y: yPosition), withAttributes: dateAttributes)
            yPosition += 30
            
            // Total Value
            let totalAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            "Total Portfolio Value: \(formatCurrency(totalValue))".draw(at: CGPoint(x: 72, y: yPosition), withAttributes: totalAttributes)
            yPosition += 50
            
            // Herds
            let activeHerds = herds.filter { !$0.isSold }
            for herd in activeHerds {
                if yPosition > pageHeight - 200 {
                    context.beginPage()
                    yPosition = 72
                }
                
                let herdAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.black
                ]
                herd.name.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: herdAttributes)
                yPosition += 25
                
                let bodyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ]
                
                var lines = [
                    "Category: \(herd.breed) \(herd.category)",
                    "Head Count: \(herd.headCount)",
                    "Species: \(herd.species)",
                    "Age: \(herd.ageMonths) months"
                ]
                
                if let valuation = valuations[herd.id] {
                    lines.append(contentsOf: [
                        "Projected Weight: \(Int(valuation.projectedWeight)) kg",
                        "Price per kg: \(String(format: "%.2f", valuation.pricePerKg)) $/kg",
                        "Net Value: \(formatCurrency(valuation.netRealizableValue))"
                    ])
                }
                
                for line in lines {
                    line.draw(at: CGPoint(x: 90, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 20
                }
                
                yPosition += 20
            }
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
    func generateSalesSummaryPDF(sales: [SalesRecord]) -> URL? {
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
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let fileName = "SalesSummary_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let sortedSales = sales.sorted { $0.saleDate > $1.saleDate }
        let totalSales = sales.reduce(0) { $0 + $1.netValue }
        let totalGross = sales.reduce(0) { $0 + $1.totalGrossValue }
        let totalFreight = sales.reduce(0) { $0 + $1.freightCost }
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 72
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            "Sales Summary".draw(at: CGPoint(x: 72, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .none
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]
            "Generated: \(dateFormatter.string(from: Date()))".draw(at: CGPoint(x: 72, y: yPosition), withAttributes: dateAttributes)
            yPosition += 40
            
            // Summary
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            
            "Total Sales Value: \(formatCurrency(totalSales))".draw(at: CGPoint(x: 72, y: yPosition), withAttributes: summaryAttributes)
            yPosition += 25
            "Total Gross Value: \(formatCurrency(totalGross))".draw(at: CGPoint(x: 72, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20
            if totalFreight > 0 {
                "Total Freight Costs: \(formatCurrency(totalFreight))".draw(at: CGPoint(x: 72, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 20
            }
            yPosition += 20
            
            // Sales List
            for sale in sortedSales {
                if yPosition > pageHeight - 150 {
                    context.beginPage()
                    yPosition = 72
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                
                let saleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ]
                dateFormatter.string(from: sale.saleDate).draw(at: CGPoint(x: 72, y: yPosition), withAttributes: saleAttributes)
                yPosition += 25
                
                let lines = [
                    "Head Count: \(sale.headCount)",
                    "Average Weight: \(Int(sale.averageWeight)) kg",
                    "Price per kg: \(String(format: "%.2f", sale.pricePerKg)) $/kg",
                    "Gross Value: \(formatCurrency(sale.totalGrossValue))",
                    "Net Value: \(formatCurrency(sale.netValue))"
                ]
                
                for line in lines {
                    line.draw(at: CGPoint(x: 90, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 20
                }
                
                yPosition += 20
            }
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
        
        var csv = "Herd Name,Category,Breed,Species,Head Count,Age (months),Initial Weight (kg),Projected Weight (kg),Price per kg,Price Source,Physical Value,Breeding Accrual,Gross Value,Mortality Deduction,Cost to Carry,Net Realizable Value,Paddock,Saleyard\n"
        
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
                escapeCSV(herd.selectedSaleyard ?? "")
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


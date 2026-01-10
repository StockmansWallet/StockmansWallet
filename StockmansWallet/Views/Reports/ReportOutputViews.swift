//
//  ReportOutputViews.swift
//  StockmansWallet
//
//  Views for previewing, exporting, and printing reports
//  Debug: Handles all report output formats
//

import SwiftUI
import SwiftData
import PDFKit

// MARK: - Report Preview View
// Debug: Preview report on screen before generating PDF
struct ReportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let configuration: ReportConfiguration
    let herds: [HerdGroup]
    let sales: [SalesRecord]
    let preferences: UserPreferences
    let properties: [Property]
    let modelContext: ModelContext
    let valuationEngine: ValuationEngine
    
    @State private var isLoading = true
    @State private var reportData: ReportData?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Loading report data...")
                        .tint(Theme.accent)
                        .padding()
                } else if let data = reportData {
                    reportContentView(data: data)
                        .padding()
                } else {
                    Text("Failed to load report data")
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadReportData()
            }
        }
    }
    
    // Debug: Generate report content view based on type
    @ViewBuilder
    private func reportContentView(data: ReportData) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            reportHeader(data: data)
            
            Divider()
            
            // Content based on report type
            switch configuration.reportType {
            case .assetRegister:
                assetRegisterContent(data: data)
            case .salesSummary:
                salesSummaryContent(data: data)
            case .saleyardComparison:
                saleyardComparisonContent(data: data)
            case .livestockValueVsLandArea:
                livestockValueVsLandAreaContent(data: data)
            case .farmComparison:
                farmComparisonContent(data: data)
            }
        }
        .padding()
        .stitchedCard()
    }
    
    // Debug: Report header with title and metadata
    private func reportHeader(data: ReportData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(configuration.reportType.rawValue)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Theme.primaryText)
            
            if configuration.includeFarmName, let farmName = data.farmName {
                Text(farmName)
                    .font(Theme.headline)
                    .foregroundStyle(Theme.secondaryText)
            }
            
            HStack {
                Text("Generated: \(Date(), format: .dateTime.day().month().year())")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                
                Spacer()
                
                Text("\(configuration.startDate, format: .dateTime.day().month().year()) - \(configuration.endDate, format: .dateTime.day().month().year())")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
    
    // Debug: Asset register content
    @ViewBuilder
    private func assetRegisterContent(data: ReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total Portfolio Value: \(data.totalValue, format: .currency(code: "AUD"))")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            ForEach(data.herdData) { herdData in
                VStack(alignment: .leading, spacing: 8) {
                    Text(herdData.name)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Group {
                        Text("Category: \(herdData.category)")
                        Text("Head Count: \(herdData.headCount)")
                        Text("Age: \(herdData.ageMonths) months")
                        Text("Weight: \(herdData.weight, format: .number.precision(.fractionLength(0))) kg")
                        
                        // Price statistics based on configuration
                        priceStatisticsView(herdData: herdData)
                        
                        Text("Net Value: \(herdData.netValue, format: .currency(code: "AUD"))")
                            .fontWeight(.semibold)
                    }
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                }
                .padding()
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // Debug: Price statistics based on configuration
    @ViewBuilder
    private func priceStatisticsView(herdData: HerdReportData) -> some View {
        switch configuration.priceStatistics {
        case .current:
            Text("Price: \(herdData.pricePerKg, format: .number.precision(.fractionLength(2))) $/kg")
        case .minimum:
            Text("Min Price: \(herdData.minPrice, format: .number.precision(.fractionLength(2))) $/kg")
        case .maximum:
            Text("Max Price: \(herdData.maxPrice, format: .number.precision(.fractionLength(2))) $/kg")
        case .average:
            Text("Avg Price: \(herdData.avgPrice, format: .number.precision(.fractionLength(2))) $/kg")
        case .all:
            VStack(alignment: .leading, spacing: 4) {
                Text("Current: \(herdData.pricePerKg, format: .number.precision(.fractionLength(2))) $/kg")
                Text("Min: \(herdData.minPrice, format: .number.precision(.fractionLength(2))) $/kg")
                Text("Max: \(herdData.maxPrice, format: .number.precision(.fractionLength(2))) $/kg")
                Text("Avg: \(herdData.avgPrice, format: .number.precision(.fractionLength(2))) $/kg")
            }
        }
    }
    
    // Debug: Sales summary content
    @ViewBuilder
    private func salesSummaryContent(data: ReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total Sales: \(data.totalSales, format: .currency(code: "AUD"))")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            ForEach(data.salesData) { saleData in
                VStack(alignment: .leading, spacing: 8) {
                    Text(saleData.date, format: .dateTime.day().month().year())
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Group {
                        Text("Head Count: \(saleData.headCount)")
                        Text("Average Weight: \(saleData.avgWeight, format: .number.precision(.fractionLength(0))) kg")
                        
                        // Debug: Show pricing based on type
                        if saleData.pricingType == .perKg {
                            Text("Price per kg: \(saleData.pricePerKg, format: .number.precision(.fractionLength(2))) $/kg")
                        } else if let pricePerHead = saleData.pricePerHead {
                            Text("Price per head: \(pricePerHead, format: .number.precision(.fractionLength(2))) $/head")
                            Text("(Equivalent: \(saleData.pricePerKg, format: .number.precision(.fractionLength(2))) $/kg)")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText.opacity(0.7))
                        }
                        
                        // Debug: Show sale type and location if available
                        if let saleType = saleData.saleType {
                            Text("Sale Type: \(saleType)")
                        }
                        if let location = saleData.saleLocation {
                            Text("Location: \(location)")
                        }
                        
                        Text("Net Value: \(saleData.netValue, format: .currency(code: "AUD"))")
                            .fontWeight(.semibold)
                    }
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                }
                .padding()
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // Debug: Saleyard comparison content
    @ViewBuilder
    private func saleyardComparisonContent(data: ReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Saleyard Price Comparison")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            ForEach(data.saleyardComparison) { comparison in
                VStack(alignment: .leading, spacing: 8) {
                    Text(comparison.saleyardName)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Group {
                        Text("Average Price: \(comparison.avgPrice, format: .number.precision(.fractionLength(2))) $/kg")
                        Text("Total Volume: \(comparison.totalHeadCount) head")
                        Text("Price Range: \(comparison.minPrice, format: .number.precision(.fractionLength(2))) - \(comparison.maxPrice, format: .number.precision(.fractionLength(2))) $/kg")
                    }
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                }
                .padding()
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // Debug: Livestock value vs land area content
    @ViewBuilder
    private func livestockValueVsLandAreaContent(data: ReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Livestock Value Density Analysis")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            ForEach(data.landValueAnalysis) { analysis in
                VStack(alignment: .leading, spacing: 8) {
                    Text(analysis.propertyName)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Group {
                        Text("Total Land Area: \(analysis.acreage, format: .number.precision(.fractionLength(0))) acres")
                        Text("Livestock Value: \(analysis.livestockValue, format: .currency(code: "AUD"))")
                        Text("Value per Acre: \(analysis.valuePerAcre, format: .currency(code: "AUD"))")
                            .fontWeight(.semibold)
                        Text("Head Count: \(analysis.totalHeadCount)")
                    }
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                }
                .padding()
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // Debug: Farm comparison content
    @ViewBuilder
    private func farmComparisonContent(data: ReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Farm Performance Comparison")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            ForEach(data.farmComparison) { comparison in
                VStack(alignment: .leading, spacing: 8) {
                    Text(comparison.propertyName)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Group {
                        Text("Total Value: \(comparison.totalValue, format: .currency(code: "AUD"))")
                        Text("Total Head Count: \(comparison.totalHeadCount)")
                        Text("Average Price: \(comparison.avgPricePerKg, format: .number.precision(.fractionLength(2))) $/kg")
                        Text("Value per Head: \(comparison.valuePerHead, format: .currency(code: "AUD"))")
                    }
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                }
                .padding()
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // Debug: Load report data asynchronously
    @MainActor
    private func loadReportData() async {
        isLoading = true
        
        // Generate report data based on type
        let data = await ReportDataGenerator.generateReportData(
            configuration: configuration,
            herds: herds,
            sales: sales,
            preferences: preferences,
            properties: properties,
            modelContext: modelContext,
            valuationEngine: valuationEngine
        )
        
        reportData = data
        isLoading = false
    }
}

// MARK: - Report PDF Export View
// Debug: Generate and export PDF
struct ReportPDFExportView: View {
    @Environment(\.dismiss) private var dismiss
    
    let configuration: ReportConfiguration
    let herds: [HerdGroup]
    let sales: [SalesRecord]
    let preferences: UserPreferences
    let properties: [Property]
    let modelContext: ModelContext
    let valuationEngine: ValuationEngine
    
    @State private var pdfURL: URL?
    @State private var isGenerating = true
    @State private var showShare = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.sheetBackground.ignoresSafeArea()
                
                Group {
                    if isGenerating {
                        ProgressView("Generating PDF...")
                            .tint(Theme.accent)
                            .foregroundStyle(Theme.primaryText)
                    } else if let url = pdfURL {
                        PDFKitRepresentedView(url: url)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding()
                    } else {
                        Text("Failed to generate PDF.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(configuration.reportType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if pdfURL != nil {
                        Button {
                            HapticManager.tap()
                            showShare = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
            }
            .task {
                await generatePDF()
            }
            .sheet(isPresented: $showShare) {
                if let url = pdfURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    @MainActor
    private func generatePDF() async {
        isGenerating = true
        
        // Generate PDF using enhanced service
        let url = await EnhancedReportExportService.shared.generatePDF(
            configuration: configuration,
            herds: herds,
            sales: sales,
            preferences: preferences,
            properties: properties,
            modelContext: modelContext,
            valuationEngine: valuationEngine
        )
        
        pdfURL = url
        isGenerating = false
    }
}

// MARK: - Report Print View
// Debug: Native print functionality
struct ReportPrintView: View {
    @Environment(\.dismiss) private var dismiss
    
    let configuration: ReportConfiguration
    let herds: [HerdGroup]
    let sales: [SalesRecord]
    let preferences: UserPreferences
    let properties: [Property]
    let modelContext: ModelContext
    let valuationEngine: ValuationEngine
    
    @State private var isGenerating = true
    @State private var showPrintDialog = false
    @State private var pdfURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.sheetBackground.ignoresSafeArea()
                
                if isGenerating {
                    ProgressView("Preparing for print...")
                        .tint(Theme.accent)
                        .foregroundStyle(Theme.primaryText)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "printer.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.accent)
                        
                        Text("Ready to Print")
                            .font(Theme.title)
                            .foregroundStyle(Theme.primaryText)
                        
                        Text("Your report is ready. Tap the button below to open the print dialog.")
                            .font(Theme.body)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button {
                            HapticManager.tap()
                            showPrintDialog = true
                        } label: {
                            HStack {
                                Image(systemName: "printer")
                                Text("Print")
                            }
                            .font(Theme.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 40)
                    }
                }
            }
            .navigationTitle("Print Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await preparePrint()
            }
            .sheet(isPresented: $showPrintDialog) {
                if let url = pdfURL {
                    PrintController(url: url)
                }
            }
        }
    }
    
    @MainActor
    private func preparePrint() async {
        isGenerating = true
        
        // Generate PDF for printing
        let url = await EnhancedReportExportService.shared.generatePDF(
            configuration: configuration,
            herds: herds,
            sales: sales,
            preferences: preferences,
            properties: properties,
            modelContext: modelContext,
            valuationEngine: valuationEngine
        )
        
        pdfURL = url
        isGenerating = false
    }
}

// MARK: - Helper Views

// PDFKit wrapper
private struct PDFKitRepresentedView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.clear
        if let doc = PDFDocument(url: url) {
            pdfView.document = doc
        }
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let doc = PDFDocument(url: url) {
            pdfView.document = doc
        }
    }
}

// Share sheet
private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Print controller
private struct PrintController: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = url.lastPathComponent
        printInfo.outputType = .general
        printController.printInfo = printInfo
        printController.printingItem = url
        
        let viewController = UIViewController()
        printController.present(animated: true) { _, _, _ in }
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}





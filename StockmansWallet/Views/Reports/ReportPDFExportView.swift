//
//  ReportPDFExportView.swift
//  StockmansWallet
//
//  View for generating and exporting PDF reports
//  Debug: Handles PDF generation, viewing, and sharing
//

import SwiftUI
import SwiftData
import PDFKit

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
                            .tint(Theme.accentColor)
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
                    Button {
                        HapticManager.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if pdfURL != nil {
                        Button {
                            HapticManager.tap()
                            showShare = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Theme.accentColor)
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
        
        // Small delay to prevent blank screen on first load (real device issue)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
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

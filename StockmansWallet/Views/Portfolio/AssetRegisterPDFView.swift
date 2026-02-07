import SwiftUI
import PDFKit
import SwiftData
import Foundation

struct AssetRegisterPDFView: View {
    let herds: [HerdGroup]
    let preferences: UserPreferences
    let modelContext: ModelContext
    let valuationEngine: ValuationEngine
    
    @State private var pdfURL: URL?
    @State private var isGenerating = true
    @State private var showShare = false
    
    var body: some View {
        ZStack {
            // Debug: Background for push navigation (not sheet)
            Theme.backgroundGradient.ignoresSafeArea()
            
            Group {
                if isGenerating {
                    ProgressView("Generating PDF…")
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
        .navigationTitle("Asset Register")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if pdfURL != nil {
                    Button {
                        HapticManager.tap()
                        showShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Theme.accentColor)
                    }
                    .buttonBorderShape(.roundedRectangle)
                }
            }
        }
        .task {
            await generate()
        }
        .sheet(isPresented: $showShare) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    @MainActor
    private func generate() async {
        // Ensure isGenerating starts as true
        isGenerating = true
        
        // Small delay to ensure UI updates before heavy work
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Fetch properties from modelContext
        let properties = (try? modelContext.fetch(FetchDescriptor<Property>())) ?? []
        
        // Create configuration
        var configuration = ReportConfiguration(reportType: .assetRegister)
        configuration.includePropertyDetails = true
        
        // Use EnhancedReportExportService for Apple-inspired design
        let url = await EnhancedReportExportService.shared.generatePDF(
            configuration: configuration,
            herds: herds,
            sales: [],
            preferences: preferences,
            properties: properties,
            modelContext: modelContext,
            valuationEngine: valuationEngine
        )
        
        // Ensure state update happens on main actor
        await MainActor.run {
            self.pdfURL = url
            self.isGenerating = false
        }
    }
}

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

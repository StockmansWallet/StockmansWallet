import SwiftUI
import PDFKit
import SwiftData

struct SalesSummaryPDFView: View {
    let sales: [SalesRecord]
    
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
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
        .navigationTitle("Sales Summary")
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
        
        // Get user preferences and properties
        guard let userPrefs = preferences.first else {
            await MainActor.run {
                self.pdfURL = nil
                self.isGenerating = false
            }
            return
        }
        
        // Fetch properties from modelContext
        let properties = (try? modelContext.fetch(FetchDescriptor<Property>())) ?? []
        
        // Create configuration
        var configuration = ReportConfiguration(reportType: .salesSummary)
        configuration.includePropertyDetails = true
        
        // Convert SalesRecord to data needed for report
        // Use EnhancedReportExportService for Apple-inspired design
        let url = await EnhancedReportExportService.shared.generatePDF(
            configuration: configuration,
            herds: [],
            sales: sales,
            preferences: userPrefs,
            properties: properties,
            modelContext: modelContext,
            valuationEngine: ValuationEngine.shared
        )
        
        // Ensure state update happens on main actor
        await MainActor.run {
            self.pdfURL = url
            self.isGenerating = false
        }
    }
}

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

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

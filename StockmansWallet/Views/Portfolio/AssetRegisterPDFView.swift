import SwiftUI
import PDFKit
import SwiftData

struct AssetRegisterPDFView: View {
    let herds: [HerdGroup]
    let preferences: UserPreferences
    let modelContext: ModelContext
    let valuationEngine: ValuationEngine
    
    @State private var pdfURL: URL?
    @State private var isGenerating = true
    @State private var showShare = false
    @State private var valuations: [UUID: HerdValuation] = [:]
    @State private var totalValue: Double = 0.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Debug: Solid sheet background for modal presentation
                Theme.sheetBackground.ignoresSafeArea()
                
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
    }
    
    @MainActor
    private func generate() async {
        isGenerating = true
        
        // Compute valuations for active herds
        let active = herds.filter { !$0.isSold }
        var map: [UUID: HerdValuation] = [:]
        var total: Double = 0.0
        for herd in active {
            let v = await valuationEngine.calculateHerdValue(
                herd: herd,
                preferences: preferences,
                modelContext: modelContext
            )
            map[herd.id] = v
            total += v.netRealizableValue
        }
        valuations = map
        totalValue = total
        
        if let url = ReportExportService.shared.generateAssetRegisterPDF(
            herds: herds,
            valuations: valuations,
            totalValue: totalValue,
            preferences: preferences
        ) {
            pdfURL = url
        } else {
            pdfURL = nil
        }
        isGenerating = false
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

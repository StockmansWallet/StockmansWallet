import SwiftUI
import PDFKit

struct SalesSummaryPDFView: View {
    let sales: [SalesRecord]
    
    @State private var pdfURL: URL?
    @State private var isGenerating = true
    @State private var showShare = false
    
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
                generate()
            }
            .sheet(isPresented: $showShare) {
                if let url = pdfURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func generate() {
        isGenerating = true
        pdfURL = ReportExportService.shared.generateSalesSummaryPDF(sales: sales)
        isGenerating = false
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

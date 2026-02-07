//
//  ReportPrintView.swift
//  StockmansWallet
//
//  View for printing reports
//  Debug: Handles print preparation and native print dialog
//

import SwiftUI
import SwiftData

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
                        .tint(Theme.accentColor)
                        .foregroundStyle(Theme.primaryText)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "printer.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.accentColor)
                        
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
                            .background(Theme.accentColor)
                            .clipShape(Theme.continuousRoundedRect(12))
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

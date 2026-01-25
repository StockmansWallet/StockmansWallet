//
//  PhysicalSalesTableView.swift
//  StockmansWallet
//
//  Physical Sales Table - displays detailed cattle pricing by category
//  Debug: Shows Min/Max/Avg prices per kg and per head with filtering
//

import SwiftUI
import AVFoundation

struct PhysicalSalesTableView: View {
    let report: PhysicalSalesReport
    let selectedCategory: String
    let selectedSalePrefix: String
    
    // Debug: Text-to-speech coordinator
    @State private var speechCoordinator = SpeechCoordinator()
    
    // Debug: Summary expansion state
    @State private var isSummaryExpanded = false
    
    // Debug: Computed property for filtered categories
    private var filteredCategories: [PhysicalSalesCategory] {
        report.categories.filter { category in
            let categoryMatch = selectedCategory == "All" || category.categoryName.contains(selectedCategory)
            let prefixMatch = selectedSalePrefix == "All" || category.salePrefix == selectedSalePrefix
            return categoryMatch && prefixMatch
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Summary text if available
            if let summary = report.summary {
                summarySection(text: summary)
            }
            
            // Table (no scroll, full width)
            VStack(spacing: 0) {
                // Table Header
                tableHeader
                
                // Table Rows
                if filteredCategories.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredCategories) { category in
                        categoryRow(category: category)
                    }
                }
            }
            .background(Theme.cardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .onDisappear {
            // Debug: Stop speech when view disappears
            speechCoordinator.stopSpeech()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Saleyard name heading (same size as National Indicators - 18pt semibold)
            Text(report.saleyard)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
            
            // Date and yardings info row
            HStack(alignment: .firstTextBaseline) {
                // Report date on left
                Text(report.reportDate, format: .dateTime.day().month().year())
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.secondaryText)
                
                Spacer()
                
                // Head yarded on right
                Text("\(report.totalYarding) Head Yarded")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.secondaryText)
            }
            
            // Comparison date
            if let comparisonDate = report.comparisonDate {
                Text("Comparison: \(comparisonDate, format: .dateTime.day().month().year())")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
            }
        }
    }
    
    
    // MARK: - Summary Section
    // Debug: Display text summary if available with text-to-speech and collapsible content
    private func summarySection(text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - tappable to expand/collapse
            Button(action: {
                HapticManager.tap()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSummaryExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Text("Market Summary")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                    
                    Spacer()
                    
                    // Expansion chevron
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .rotationEffect(.degrees(isSummaryExpanded ? 180 : 0))
                    
                    // Circular audio button with text-to-speech
                    Button {
                        HapticManager.tap()
                        speechCoordinator.toggleSpeech(text: text)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Theme.accent.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: speechCoordinator.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .accessibilityLabel(speechCoordinator.isSpeaking ? "Stop reading" : "Read market summary aloud")
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            
            // Collapsible content
            if isSummaryExpanded {
                // Parse summary text into bullet points
                let lines = text.components(separatedBy: ". ")
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Text("•")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.primaryText)
                                Text(line.trimmingCharacters(in: .whitespacesAndNewlines))
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Empty State
    // Debug: Show when no categories match filters
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 32))
                .foregroundStyle(Theme.secondaryText.opacity(0.5))
            Text("No Results")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
            Text("No sales match your selected filters")
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Table Header
    private var tableHeader: some View {
        HStack(spacing: 0) {
            // Category column (flexible)
            Text("Category")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .font(Theme.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
            
            Divider()
            
            // Avg Cents/kg column (fixed)
            VStack(spacing: 4) {
                Text("Avg")
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Text("¢/kg")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
            }
            .frame(width: 75)
            
            Divider()
            
            // Avg $/Head column (fixed)
            VStack(spacing: 4) {
                Text("Avg")
                    .font(Theme.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Text("$/Head")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
            }
            .frame(width: 85)
        }
        .frame(height: 60)
        .background(Theme.cardBackground.opacity(0.5))
    }
    
    // MARK: - Category Row
    private func categoryRow(category: PhysicalSalesCategory) -> some View {
        HStack(spacing: 0) {
            // Category info (flexible)
            VStack(alignment: .leading, spacing: 4) {
                Text(category.categoryName)
                    .font(Theme.body.weight(.medium))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(category.weightRange + "kg")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                    
                    Text(category.salePrefix)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.accent.opacity(0.8))
                    
                    Text("\(category.headCount) hd")
                        .font(Theme.caption.weight(.medium))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            
            Divider()
            
            // Avg Cents/kg (fixed)
            priceCell(value: category.avgPriceCentsPerKg, format: .centsPerKg)
                .frame(width: 75)
            
            Divider()
            
            // Avg $/Head (fixed)
            priceCell(value: category.avgPriceDollarsPerHead, format: .dollarsPerHead)
                .frame(width: 85)
        }
        .frame(height: 70)
        .background(Theme.cardBackground)
    }
    
    // MARK: - Price Cell
    private func priceCell(value: Double?, format: PriceFormat) -> some View {
        Group {
            if let value = value {
                Text(format.formatted(value))
                    .font(Theme.body.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            } else {
                Text("–")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText.opacity(0.5))
            }
        }
    }
    
    // MARK: - Price Format
    enum PriceFormat {
        case centsPerKg
        case dollarsPerHead
        
        func formatted(_ value: Double) -> String {
            switch self {
            case .centsPerKg:
                return String(format: "%.0f¢", value)
            case .dollarsPerHead:
                return String(format: "$%.0f", value)
            }
        }
    }
}

// MARK: - Speech Coordinator
// Debug: Manages text-to-speech playback with proper state management
// Debug: @MainActor ensures thread-safety since AVSpeechSynthesizer must run on main thread
@MainActor
@Observable
class SpeechCoordinator: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    var isSpeaking = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // Debug: Toggle speech on/off
    func toggleSpeech(text: String) {
        if isSpeaking {
            stopSpeech()
        } else {
            startSpeech(text: text)
        }
    }
    
    // Debug: Start speaking the text
    private func startSpeech(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-AU") // Australian English
        utterance.rate = 0.5 // Slightly slower for clarity
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    // Debug: Stop speaking
    func stopSpeech() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    // Debug: Called when speech finishes
    // Debug: nonisolated allows delegate to be called from any thread, then we update state on main
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
    
    // Debug: Called when speech is cancelled
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        PhysicalSalesTableView(
            report: PhysicalSalesReport(
                id: UUID().uuidString,
                saleyard: "Mount Barker",
                reportDate: Date(),
                comparisonDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                totalYarding: 336,
                categories: [
                    PhysicalSalesCategory(
                        id: UUID().uuidString,
                        categoryName: "Yearling Steer",
                        weightRange: "400-500",
                        salePrefix: "Processor",
                        muscleScore: "C",
                        fatScore: 3,
                        headCount: 4,
                        minPriceCentsPerKg: 340.0,
                        maxPriceCentsPerKg: 340.0,
                        avgPriceCentsPerKg: 340.0,
                        minPriceDollarsPerHead: 1734.0,
                        maxPriceDollarsPerHead: 1734.0,
                        avgPriceDollarsPerHead: 1734.0,
                        priceChangePerKg: nil,
                        priceChangePerHead: nil
                    ),
                    PhysicalSalesCategory(
                        id: UUID().uuidString,
                        categoryName: "Yearling Heifer",
                        weightRange: "400-500",
                        salePrefix: "Feeder",
                        muscleScore: "C",
                        fatScore: 3,
                        headCount: 6,
                        minPriceCentsPerKg: 384.0,
                        maxPriceCentsPerKg: 384.0,
                        avgPriceCentsPerKg: 384.0,
                        minPriceDollarsPerHead: 1536.0,
                        maxPriceDollarsPerHead: 1536.0,
                        avgPriceDollarsPerHead: 1536.0,
                        priceChangePerKg: nil,
                        priceChangePerHead: nil
                    ),
                    PhysicalSalesCategory(
                        id: UUID().uuidString,
                        categoryName: "Grown Steer",
                        weightRange: "400-500",
                        salePrefix: "Feeder",
                        muscleScore: "C",
                        fatScore: 3,
                        headCount: 11,
                        minPriceCentsPerKg: 300.0,
                        maxPriceCentsPerKg: 370.0,
                        avgPriceCentsPerKg: 340.0,
                        minPriceDollarsPerHead: 1245.0,
                        maxPriceDollarsPerHead: 1586.0,
                        avgPriceDollarsPerHead: 1454.58,
                        priceChangePerKg: -3.0,
                        priceChangePerHead: -15.0
                    ),
                    PhysicalSalesCategory(
                        id: UUID().uuidString,
                        categoryName: "Bulls",
                        weightRange: "600+",
                        salePrefix: "Processor",
                        muscleScore: "C",
                        fatScore: 4,
                        headCount: 5,
                        minPriceCentsPerKg: 366.0,
                        maxPriceCentsPerKg: 372.0,
                        avgPriceCentsPerKg: 369.0,
                        minPriceDollarsPerHead: 2340.0,
                        maxPriceDollarsPerHead: 2480.0,
                        avgPriceDollarsPerHead: 2410.0,
                        priceChangePerKg: 10.0,
                        priceChangePerHead: 65.0
                    ),
                    PhysicalSalesCategory(
                        id: UUID().uuidString,
                        categoryName: "Cows",
                        weightRange: "450-550",
                        salePrefix: "PTIC",
                        muscleScore: nil,
                        fatScore: nil,
                        headCount: 12,
                        minPriceCentsPerKg: 310.0,
                        maxPriceCentsPerKg: 320.0,
                        avgPriceCentsPerKg: 315.0,
                        minPriceDollarsPerHead: 1550.0,
                        maxPriceDollarsPerHead: 1760.0,
                        avgPriceDollarsPerHead: 1655.0,
                        priceChangePerKg: nil,
                        priceChangePerHead: nil
                    )
                ],
                state: "WA",
                summary: "Numbers were down for total small yarding of 336 head with the total fire ban yesterday disrupting transport. Trade weight cattle and cows dominated the yarding with processors keeping prices mainly firm.",
                audioURL: nil
            ),
            selectedCategory: "All",
            selectedSalePrefix: "All"
        )
        .padding(.vertical)
    }
    .background(Theme.backgroundGradient)
}

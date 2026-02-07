//
//  ReportConfigurationView.swift
//  StockmansWallet
//
//  Configuration view for report generation with preview and print options
//  Debug: Allows customisation before generating reports
//

import SwiftUI
import SwiftData

// MARK: - Date Range Preset
enum DateRangePreset: String, CaseIterable, Identifiable {
    case oneMonth = "1 Month"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case oneYear = "1 Year"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var shortLabel: String {
        switch self {
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .oneYear: return "1Y"
        case .custom: return "Custom"
        }
    }
    
    func dateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = Date()
        let start: Date
        
        switch self {
        case .oneMonth:
            start = calendar.date(byAdding: .month, value: -1, to: end) ?? end
        case .threeMonths:
            start = calendar.date(byAdding: .month, value: -3, to: end) ?? end
        case .sixMonths:
            start = calendar.date(byAdding: .month, value: -6, to: end) ?? end
        case .oneYear:
            start = calendar.date(byAdding: .year, value: -1, to: end) ?? end
        case .custom:
            // Default to 12 months for custom
            start = calendar.date(byAdding: .year, value: -1, to: end) ?? end
        }
        
        return (start, end)
    }
}

// Debug: Configuration sheet for customising report parameters
struct ReportConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var configuration: ReportConfiguration
    let herds: [HerdGroup]
    let sales: [SalesRecord]
    let preferences: UserPreferences
    let properties: [Property]
    let modelContext: ModelContext
    let valuationEngine: ValuationEngine
    
    @State private var showingPreview = false
    @State private var showingPDFExport = false
    @State private var showingPrint = false
    @State private var selectedPreset: DateRangePreset = .oneYear
    @State private var showCustomDates = false
    @State private var showingSaleyardSelection = false
    @State private var showingPropertySelection = false
    
    var body: some View {
        Form {
            // MARK: - Date Range Section
            Section {
                // Preset picker using native iOS style
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(Theme.accentColor)
                        .frame(width: 24)
                    
                    Picker("Time Period", selection: $selectedPreset) {
                        ForEach(DateRangePreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundStyle(Theme.primaryText)
                }
                .onChange(of: selectedPreset) { oldValue, newValue in
                    HapticManager.tap()
                    if newValue == .custom {
                        showCustomDates = true
                    } else {
                        showCustomDates = false
                        let range = newValue.dateRange()
                        configuration.startDate = range.start
                        configuration.endDate = range.end
                    }
                }
                
                // Show custom date pickers if Custom is selected
                if showCustomDates {
                    DatePicker("Start Date", selection: $configuration.startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $configuration.endDate, displayedComponents: .date)
                }
            } footer: {
                HStack(alignment: .center, spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    
                    if showCustomDates {
                        Text("Select a custom date range for this report")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    } else {
                        Text("Report will include data from the last \(selectedPreset.rawValue.lowercased())")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .listRowBackground(Theme.cardBackground)
            
            // MARK: - Type-Specific Options
            typeSpecificOptions
            
            // MARK: - Actions Section
            Section {
                // Generate PDF Button
                Button {
                    HapticManager.tap()
                    showingPDFExport = true
                } label: {
                    Label("Generate PDF", systemImage: "doc.fill")
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle(configuration.reportType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingPDFExport) {
                ReportPDFExportView(
                    configuration: configuration,
                    herds: herds,
                    sales: sales,
                    preferences: preferences,
                    properties: properties,
                    modelContext: modelContext,
                    valuationEngine: valuationEngine
                )
        }
        .sheet(isPresented: $showingPrint) {
                ReportPrintView(
                    configuration: configuration,
                    herds: herds,
                    sales: sales,
                    preferences: preferences,
                    properties: properties,
                    modelContext: modelContext,
                    valuationEngine: valuationEngine
                )
        }
        .sheet(isPresented: $showingSaleyardSelection) {
            SaleyardSelectionView(selectedSaleyards: $configuration.selectedSaleyards)
        }
        .sheet(isPresented: $showingPropertySelection) {
            PropertySelectionView(selectedProperties: $configuration.selectedProperties, properties: properties)
        }
        .onAppear {
            // Initialise date range on first appearance
            let range = selectedPreset.dateRange()
            configuration.startDate = range.start
            configuration.endDate = range.end
        }
    }
    
    // MARK: - Type-Specific Options
    @ViewBuilder
    private var typeSpecificOptions: some View {
        switch configuration.reportType {
        case .assetRegister:
            assetRegisterOptions
        case .saleyardComparison:
            saleyardComparisonOptions
        case .livestockValueVsLandArea:
            livestockValueVsLandAreaOptions
        case .farmComparison:
            farmComparisonOptions
        case .salesSummary:
            EmptyView()
        }
    }
    
    // MARK: - Asset Register Options
    private var assetRegisterOptions: some View {
        EmptyView()
    }
    
    // MARK: - Saleyard Comparison Options
    private var saleyardComparisonOptions: some View {
        Section {
            Button {
                HapticManager.tap()
                showingSaleyardSelection = true
            } label: {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .foregroundStyle(Theme.accentColor)
                        .frame(width: 24)
                    
                    Text("Select Saleyards")
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text("\(configuration.selectedSaleyards.count) selected")
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        } footer: {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                
                Text("Select saleyards to compare prices")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .listRowBackground(Theme.cardBackground)
    }
    
    // MARK: - Livestock Value vs Land Area Options
    private var livestockValueVsLandAreaOptions: some View {
        EmptyView()
    }
    
    // MARK: - Farm Comparison Options
    private var farmComparisonOptions: some View {
        Section {
            Button {
                HapticManager.tap()
                showingPropertySelection = true
            } label: {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(Theme.accentColor)
                        .frame(width: 24)
                    
                    Text("Select Properties")
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text("\(configuration.selectedProperties.count) selected")
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        } footer: {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                
                Text("Select properties to compare performance")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .listRowBackground(Theme.cardBackground)
    }
}

// MARK: - Saleyard Selection View
// Debug: Multi-select view for choosing saleyards
struct SaleyardSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSaleyards: [String]
    @State private var searchText = ""
    
    private var filteredSaleyards: [String] {
        if searchText.isEmpty {
            return ReferenceData.saleyards
        }
        return ReferenceData.saleyards.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filteredSaleyards, id: \.self) { saleyard in
                        Button {
                            HapticManager.tap()
                            if selectedSaleyards.contains(saleyard) {
                                selectedSaleyards.removeAll { $0 == saleyard }
                            } else {
                                selectedSaleyards.append(saleyard)
                            }
                        } label: {
                            HStack {
                                // Checkbox
                                Image(systemName: selectedSaleyards.contains(saleyard) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(selectedSaleyards.contains(saleyard) ? Theme.accentColor : Theme.secondaryText)
                                    .font(.system(size: 22))
                                
                                Text(saleyard)
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search saleyards"
            )
            .navigationTitle("Select Saleyards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accentColor)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.tertiaryBackground)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.tertiaryBackground)
    }
}

// MARK: - Property Selection View
// Debug: Multi-select view for choosing properties
struct PropertySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedProperties: [UUID]
    let properties: [Property]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(properties) { property in
                        Button {
                            HapticManager.tap()
                            if selectedProperties.contains(property.id) {
                                selectedProperties.removeAll { $0 == property.id }
                            } else {
                                selectedProperties.append(property.id)
                            }
                        } label: {
                            HStack {
                                // Checkbox
                                Image(systemName: selectedProperties.contains(property.id) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(selectedProperties.contains(property.id) ? Theme.accentColor : Theme.secondaryText)
                                    .font(.system(size: 22))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(property.propertyName)
                                        .font(Theme.body)
                                        .foregroundStyle(Theme.primaryText)
                                    if let pic = property.propertyPIC {
                                        Text("PIC: \(pic)")
                                            .font(Theme.caption)
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Select Properties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accentColor)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.tertiaryBackground)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.tertiaryBackground)
    }
}





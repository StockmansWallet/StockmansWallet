//
//  ReportConfigurationView.swift
//  StockmansWallet
//
//  Configuration view for report generation with preview and print options
//  Debug: Allows customization before generating reports
//

import SwiftUI
import SwiftData

// Debug: Configuration sheet for customizing report parameters
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
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Date Range Section
                Section {
                    DatePicker("Start Date", selection: $configuration.startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $configuration.endDate, displayedComponents: .date)
                } header: {
                    Label("Date Range", systemImage: "calendar")
                } footer: {
                    Text("Select the date range for this report")
                }
                .listRowBackground(Theme.cardBackground)
                
                // MARK: - Report Details Section
                Section {
                    Toggle("Include Farm Name", isOn: $configuration.includeFarmName)
                    Toggle("Include Property Details", isOn: $configuration.includePropertyDetails)
                } header: {
                    Label("Report Details", systemImage: "doc.text")
                }
                .listRowBackground(Theme.cardBackground)
                
                // MARK: - Type-Specific Options
                typeSpecificOptions
                
                // MARK: - Actions Section
                Section {
                    // Preview Button
                    Button {
                        HapticManager.tap()
                        showingPreview = true
                    } label: {
                        HStack {
                            Image(systemName: "eye.fill")
                                .foregroundStyle(Theme.accentColor)
                                .frame(width: 24)
                            Text("Preview Report")
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    
                    // Generate PDF Button
                    Button {
                        HapticManager.tap()
                        showingPDFExport = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(Theme.accentColor)
                                .frame(width: 24)
                            Text("Generate PDF")
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    
                    // Print Button
                    Button {
                        HapticManager.tap()
                        showingPrint = true
                    } label: {
                        HStack {
                            Image(systemName: "printer.fill")
                                .foregroundStyle(Theme.accentColor)
                                .frame(width: 24)
                            Text("Print Report")
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                } header: {
                    Label("Actions", systemImage: "bolt.fill")
                }
                .listRowBackground(Theme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient)
            .navigationTitle(configuration.reportType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                ReportPreviewView(
                    configuration: configuration,
                    herds: herds,
                    sales: sales,
                    preferences: preferences,
                    properties: properties,
                    modelContext: modelContext,
                    valuationEngine: valuationEngine
                )
            }
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
        Section {
            Picker("Price Statistics", selection: $configuration.priceStatistics) {
                ForEach(PriceStatisticsOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } header: {
            Label("Asset Register Options", systemImage: "chart.bar.fill")
        } footer: {
            Text("Choose which price statistics to include in the report")
        }
        .listRowBackground(Theme.cardBackground)
    }
    
    // MARK: - Saleyard Comparison Options
    private var saleyardComparisonOptions: some View {
        Section {
            NavigationLink {
                SaleyardSelectionView(selectedSaleyards: $configuration.selectedSaleyards)
            } label: {
                HStack {
                    Text("Select Saleyards")
                    Spacer()
                    Text("\(configuration.selectedSaleyards.count) selected")
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        } header: {
            Label("Saleyard Comparison Options", systemImage: "building.columns.fill")
        } footer: {
            Text("Select saleyards to compare prices")
        }
        .listRowBackground(Theme.cardBackground)
    }
    
    // MARK: - Livestock Value vs Land Area Options
    private var livestockValueVsLandAreaOptions: some View {
        Section {
            Text("This report analyzes livestock value density per acre across your properties")
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
        } header: {
            Label("Analysis Options", systemImage: "chart.xyaxis.line")
        }
        .listRowBackground(Theme.cardBackground)
    }
    
    // MARK: - Farm Comparison Options
    private var farmComparisonOptions: some View {
        Section {
            NavigationLink {
                PropertySelectionView(
                    selectedProperties: $configuration.selectedProperties,
                    properties: properties
                )
            } label: {
                HStack {
                    Text("Select Properties")
                    Spacer()
                    Text("\(configuration.selectedProperties.count) selected")
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        } header: {
            Label("Farm Comparison Options", systemImage: "building.2.fill")
        } footer: {
            Text("Select properties to compare performance")
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
                            Text(saleyard)
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            if selectedSaleyards.contains(saleyard) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accentColor)
                            }
                        }
                    }
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .searchable(text: $searchText, prompt: "Search saleyards")
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Select Saleyards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Property Selection View
// Debug: Multi-select view for choosing properties
struct PropertySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedProperties: [UUID]
    let properties: [Property]
    
    var body: some View {
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text(property.propertyName)
                                    .foregroundStyle(Theme.primaryText)
                                if let pic = property.propertyPIC {
                                    Text("PIC: \(pic)")
                                        .font(Theme.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                            }
                            Spacer()
                            if selectedProperties.contains(property.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accentColor)
                            }
                        }
                    }
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Select Properties")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}





//
//  CSVImportView.swift
//  StockmansWallet
//
//  Bulk import animals from CSV file
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]
    
    @State private var importStatus: ImportStatus = .ready
    @State private var importedCount = 0
    @State private var errorCount = 0
    @State private var errors: [String] = []
    @State private var showingFilePicker = false
    
    enum ImportStatus {
        case ready
        case importing
        case success
        case error
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Debug: Solid sheet background for modal presentation
                Theme.sheetBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.sectionSpacing) {
                        // Instructions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CSV Import")
                                .font(Theme.title)
                                .foregroundStyle(Theme.primaryText)
                            
                            Text("Import multiple animals from a CSV file. Your CSV should include the following columns:")
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText.opacity(0.7))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Required columns:")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                
                                Text("• name, species, breed, category, sex, ageMonths, headCount, initialWeight")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(Theme.primaryText.opacity(0.7))
                                
                                Text("Optional columns:")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                    .padding(.top, 8)
                                
                                Text("• dailyWeightGain, paddockName, selectedSaleyard, isBreeder, isPregnant, joinedDate, calvingRate")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(Theme.primaryText.opacity(0.7))
                            }
                        }
                        .padding(Theme.cardPadding)
                        .cardStyle()
                        
                        // Import Status
                        if importStatus != .ready {
                            VStack(spacing: 16) {
                                if importStatus == .importing {
                                    ProgressView()
                                        .tint(Theme.accentColor)
                                    Text("Importing...")
                                        .font(Theme.body)
                                        .foregroundStyle(Theme.primaryText.opacity(0.7))
                                } else if importStatus == .success {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundStyle(Theme.positiveChange)
                                    Text("Successfully imported \(importedCount) animal\(importedCount == 1 ? "" : "s")")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                    
                                    if errorCount > 0 {
                                        Text("\(errorCount) error\(errorCount == 1 ? "" : "s") encountered")
                                            .font(Theme.caption)
                                            .foregroundStyle(.orange)
                                    }
                                } else if importStatus == .error {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.red)
                                    Text("Import failed")
                                        .font(Theme.headline)
                                        .foregroundStyle(Theme.primaryText)
                                    
                                    if !errors.isEmpty {
                                        ScrollView {
                                            VStack(alignment: .leading, spacing: 4) {
                                                ForEach(errors, id: \.self) { error in
                                                    Text(error)
                                                        .font(Theme.caption)
                                                        .foregroundStyle(.red)
                                                }
                                            }
                                        }
                                        .frame(maxHeight: 200)
                                    }
                                }
                            }
                            .padding(Theme.cardPadding)
                            .cardStyle() // Standard card styling
                        }
                        
                        // Import Button - Debug: Using Theme.PrimaryButtonStyle for iOS 26 HIG compliance
                        Button(action: {
                            HapticManager.tap()
                            showingFilePicker = true
                        }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Select CSV File")
                            }
                        }
                        .buttonStyle(Theme.PrimaryButtonStyle())
                        .padding(.horizontal)
                        .disabled(importStatus == .importing)
                        
                        // Example CSV
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Example CSV Format")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            Text("""
name,species,breed,category,sex,ageMonths,headCount,initialWeight,dailyWeightGain,paddockName
North Herd,Cattle,Angus,Weaner Steer,Male,8,50,280,0.6,North Paddock
Bessie,Cattle,Hereford,Breeding Cow,Female,36,1,550,0.3,South Paddock
""")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Theme.primaryText.opacity(0.7))
                            .padding()
                            .background(Theme.inputFieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding(Theme.cardPadding)
                        .cardStyle() // Standard card styling
                    }
                    .padding()
                }
            }
            .navigationTitle("CSV Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accentColor)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .text],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importCSV(from: url)
                    }
                case .failure(let error):
                    importStatus = .error
                    errors = ["Failed to select file: \(error.localizedDescription)"]
                }
            }
        }
    }
    
    private func importCSV(from url: URL) {
        importStatus = .importing
        importedCount = 0
        errorCount = 0
        errors = []
        
        Task {
            do {
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                
                let data = try Data(contentsOf: url)
                guard let csvString = String(data: data, encoding: .utf8) else {
                    await MainActor.run {
                        importStatus = .error
                        errors = ["Failed to read CSV file. Please ensure it's UTF-8 encoded."]
                    }
                    return
                }
                
                let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }
                guard lines.count > 1 else {
                    await MainActor.run {
                        importStatus = .error
                        errors = ["CSV file must contain at least a header row and one data row."]
                    }
                    return
                }
                
                let header = lines[0].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                
                let prefs = preferences.first ?? UserPreferences()
                var newErrors: [String] = []
                
                for (index, line) in lines.dropFirst().enumerated() {
                    let values = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    
                    guard values.count == header.count else {
                        newErrors.append("Row \(index + 2): Column count mismatch")
                        errorCount += 1
                        continue
                    }
                    
                    let rowDict = Dictionary(uniqueKeysWithValues: zip(header, values))
                    
                    guard let name = rowDict["name"], !name.isEmpty,
                          let species = rowDict["species"], !species.isEmpty,
                          let breed = rowDict["breed"], !breed.isEmpty,
                          let category = rowDict["category"], !category.isEmpty,
                          let sex = rowDict["sex"], !sex.isEmpty,
                          let ageMonthsStr = rowDict["ageMonths"], let ageMonths = Int(ageMonthsStr),
                          let headCountStr = rowDict["headCount"], let headCount = Int(headCountStr),
                          let initialWeightStr = rowDict["initialWeight"], let initialWeight = Double(initialWeightStr) else {
                        newErrors.append("Row \(index + 2): Missing required fields")
                        errorCount += 1
                        continue
                    }
                    
                    let dailyWeightGain = Double(rowDict["dailyWeightGain"] ?? "0.5") ?? 0.5
                    let paddockName = rowDict["paddockName"]
                    let selectedSaleyard = rowDict["selectedSaleyard"] ?? prefs.defaultSaleyard
                    let isBreeder = (rowDict["isBreeder"]?.lowercased() == "true") || (rowDict["isBreeder"] == "1")
                    let isPregnant = (rowDict["isPregnant"]?.lowercased() == "true") || (rowDict["isPregnant"] == "1")
                    let calvingRate = Double(rowDict["calvingRate"] ?? "0.85") ?? 0.85
                    
                    var joinedDate: Date?
                    if let joinedDateStr = rowDict["joinedDate"], !joinedDateStr.isEmpty {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        joinedDate = formatter.date(from: joinedDateStr)
                    }
                    
                    let herd = HerdGroup(
                        name: name,
                        species: species,
                        breed: breed,
                        sex: sex,
                        category: category,
                        ageMonths: ageMonths,
                        headCount: headCount,
                        initialWeight: initialWeight,
                        dailyWeightGain: dailyWeightGain,
                        isBreeder: isBreeder,
                        selectedSaleyard: selectedSaleyard
                    )
                    
                    herd.paddockName = paddockName
                    herd.isPregnant = isBreeder && isPregnant
                    if herd.isPregnant, let joinedDate = joinedDate {
                        herd.joinedDate = joinedDate
                        herd.calvingRate = calvingRate
                    }
                    
                    await MainActor.run {
                        modelContext.insert(herd)
                        importedCount += 1
                    }
                }
                
                try? await MainActor.run {
                    try modelContext.save()
                }
                
                await MainActor.run {
                    if errorCount == 0 && newErrors.isEmpty {
                        importStatus = .success
                        HapticManager.success()
                    } else {
                        importStatus = .success
                        errors = newErrors
                        HapticManager.tap()
                    }
                }
                
            } catch {
                await MainActor.run {
                    importStatus = .error
                    errors = ["Failed to import CSV: \(error.localizedDescription)"]
                    HapticManager.error()
                }
            }
        }
    }
}

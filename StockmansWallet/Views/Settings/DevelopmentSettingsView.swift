//
//  DevelopmentSettingsView.swift
//  StockmansWallet
//
//  Development and Testing Options
//

import SwiftUI
import SwiftData

struct DevelopmentSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    @State private var isGeneratingData = false
    @State private var generationStatus = ""
    @State private var showAlert = false
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var body: some View {
        List {
            Section {
                // Debug: Keep reset onboarding for testing purposes
                Button(action: {
                    HapticManager.tap()
                    resetOnboarding()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(.red)
                            .frame(width: 24)
                        
                        Text("Reset Onboarding (Testing)")
                            .font(Theme.body)
                            .foregroundStyle(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.cardBackground)
                
                // Debug: Generate sample data on Supabase (run once)
                Button(action: {
                    HapticManager.tap()
                    generateSupabaseSampleData()
                }) {
                    HStack {
                        if isGeneratingData {
                            ProgressView()
                                .frame(width: 24)
                        } else {
                            Image(systemName: "cloud.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Generate Sample Data on Server")
                                .font(Theme.body)
                                .foregroundStyle(isGeneratingData ? .secondary : .primary)
                            
                            if !generationStatus.isEmpty {
                                Text(generationStatus)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(isGeneratingData)
                .listRowBackground(Theme.cardBackground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Development")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Sample Data Generation", isPresented: $showAlert) {
            Button("OK") {
                showAlert = false
            }
        } message: {
            Text(generationStatus)
        }
    }
    
    // Debug: Reset onboarding for testing purposes
    @MainActor
    private func resetOnboarding() {
        if let prefs = preferences.first {
            prefs.hasCompletedOnboarding = false
            try? modelContext.save()
        }
    }
    
    // Debug: Generate sample data on Supabase (run once)
    @MainActor
    private func generateSupabaseSampleData() {
        isGeneratingData = true
        generationStatus = "Starting generation..."
        
        Task {
            do {
                try await SupabaseSampleDataGenerator.shared.generateAndUploadSampleData()
                generationStatus = "✅ Successfully generated and uploaded sample data to Supabase!"
                showAlert = true
                HapticManager.success()
            } catch {
                generationStatus = "❌ Error: \(error.localizedDescription)"
                showAlert = true
                HapticManager.error()
            }
            isGeneratingData = false
        }
    }
}


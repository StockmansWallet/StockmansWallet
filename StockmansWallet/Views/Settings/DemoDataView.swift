//
//  DemoDataView.swift
//  StockmansWallet
//
//  Demo Data Management for Testing and Visualization
//  Debug: Allows users to add and remove realistic mock herds
//

import SwiftUI
import SwiftData

struct DemoDataView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Debug: Track selected duration for mock data generation
    @State private var selectedDuration: MockDataDuration = .threeMonths
    
    // Debug: Track operation states
    @State private var isGenerating = false
    @State private var isRemoving = false
    @State private var isResettingAll = false
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Debug: Check if data exists
    @State private var hasMockData = false
    @State private var hasUserData = false
    
    // Debug: Confirmation dialogs
    @State private var showRemoveMockConfirmation = false
    @State private var showResetAllConfirmation = false
    
    var body: some View {
        List {
            // MARK: - Info Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Demo Data")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.primaryText)
                            
                            Text("Test charts and visualizations")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    
                    Text("Generate realistic mock herds spread over time to see how your charts work with real-world farming patterns. Data includes purchases, sales, weight changes, and head count adjustments for realistic chart fluctuations.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
                .listRowBackground(Theme.cardBackground)
            }
            .listSectionSeparator(.hidden)
            
            // MARK: - Duration Selection
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time Period")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.secondaryText)
                    
                    // Debug: Custom selection cards for duration
                    ForEach(MockDataDuration.allCases, id: \.self) { duration in
                        DurationSelectionCard(
                            duration: duration,
                            isSelected: selectedDuration == duration,
                            onTap: {
                                HapticManager.tap()
                                selectedDuration = duration
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Theme.cardBackground)
            } header: {
                Text("Select how much demo data to generate")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
            }
            .listSectionSeparator(.hidden)
            
            // MARK: - Actions Section
            Section {
                VStack(spacing: 12) {
                    // Debug: Generate button
                    Button(action: generateMockData) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                            }
                            
                            Text(isGenerating ? "Generating..." : "Add Mock Data")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isGenerating || isRemoving || isResettingAll)
                    .opacity((isGenerating || isRemoving || isResettingAll) ? 0.6 : 1.0)
                    
                    // Debug: Remove mock data button (only show if mock data exists)
                    if hasMockData {
                        Button(action: {
                            HapticManager.tap()
                            showRemoveMockConfirmation = true
                        }) {
                            HStack {
                                if isRemoving {
                                    ProgressView()
                                        .tint(Theme.accentColor)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.system(size: 16))
                                }
                                
                                Text(isRemoving ? "Removing..." : "Remove Mock Data")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(Theme.accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isGenerating || isRemoving || isResettingAll)
                        .opacity((isGenerating || isRemoving || isResettingAll) ? 0.6 : 1.0)
                    }
                    
                    // Debug: Reset all data button (only show if any user data exists)
                    if hasUserData {
                        Button(action: {
                            HapticManager.tap()
                            showResetAllConfirmation = true
                        }) {
                            HStack {
                                if isResettingAll {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 16))
                                }
                                
                                Text(isResettingAll ? "Resetting..." : "Reset All Data")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isGenerating || isRemoving || isResettingAll)
                        .opacity((isGenerating || isRemoving || isResettingAll) ? 0.6 : 1.0)
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Theme.cardBackground)
            } header: {
                Text("Mock data is separate from your real herds")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.secondaryText.opacity(0.7))
            }
            .listSectionSeparator(.hidden)
            
            // MARK: - Success/Error Messages
            if showSuccessMessage {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.green)
                        
                        Text(successMessage)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.primaryText)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Theme.cardBackground.opacity(0.5))
                }
                .listSectionSeparator(.hidden)
            }
            
            if showError {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.red)
                        
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.primaryText)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Theme.cardBackground.opacity(0.5))
                }
                .listSectionSeparator(.hidden)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .listSectionSeparator(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Demo Data")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .task {
            // Debug: Check if data exists when view appears
            checkForExistingData()
        }
        // Debug: Confirmation dialog for removing mock data
        .alert("Remove Mock Data?", isPresented: $showRemoveMockConfirmation) {
            Button("Cancel", role: .cancel) {
                HapticManager.tap()
            }
            Button("Remove", role: .destructive) {
                removeMockData()
            }
        } message: {
            Text("This will delete all mock/demo herds. Your real herds will not be affected.")
        }
        // Debug: Confirmation dialog for resetting all data
        .alert("Reset All Data?", isPresented: $showResetAllConfirmation) {
            Button("Cancel", role: .cancel) {
                HapticManager.tap()
            }
            Button("Reset Everything", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete ALL data including herds, properties, sales records, and settings. This action cannot be undone. The app will return to a fresh state.")
        }
    }
    
    // MARK: - Actions
    
    /// Generate mock data for the selected duration
    /// Debug: Creates realistic herds spread over time
    @MainActor
    private func generateMockData() {
        guard !isGenerating else { return }
        
        isGenerating = true
        showSuccessMessage = false
        showError = false
        
        HapticManager.tap()
        
        Task {
            do {
                // Debug: Generate mock data using the service
                try await MockDataGenerator.shared.generateMockData(
                    for: selectedDuration,
                    in: modelContext
                )
                
                // Debug: Success feedback
                HapticManager.success()
                successMessage = "Generated \(selectedDuration.herdCount) mock herds over \(selectedDuration.rawValue.lowercased())"
                showSuccessMessage = true
                hasMockData = true
                
                // Debug: Hide success message after 3 seconds
                try? await Task.sleep(for: .seconds(3))
                showSuccessMessage = false
                
            } catch {
                // Debug: Error feedback
                HapticManager.error()
                errorMessage = "Failed to generate mock data: \(error.localizedDescription)"
                showError = true
                
                #if DEBUG
                print("❌ Error generating mock data: \(error)")
                #endif
            }
            
            isGenerating = false
        }
    }
    
    /// Remove all mock data
    /// Debug: Safely removes only herds marked as mock data
    @MainActor
    private func removeMockData() {
        guard !isRemoving else { return }
        
        isRemoving = true
        showSuccessMessage = false
        showError = false
        
        HapticManager.tap()
        
        Task {
            do {
                // Debug: Remove mock data using the service
                try MockDataGenerator.shared.removeMockData(from: modelContext)
                
                // Debug: Success feedback
                HapticManager.success()
                successMessage = "All mock data removed successfully"
                showSuccessMessage = true
                hasMockData = false
                
                // Debug: Hide success message after 3 seconds
                try? await Task.sleep(for: .seconds(3))
                showSuccessMessage = false
                
            } catch {
                // Debug: Error feedback
                HapticManager.error()
                errorMessage = "Failed to remove mock data: \(error.localizedDescription)"
                showError = true
                
                #if DEBUG
                print("❌ Error removing mock data: \(error)")
                #endif
            }
            
            isRemoving = false
        }
    }
    
    /// Reset all data (delete everything)
    /// Debug: Removes ALL user-generated data to return app to fresh state
    @MainActor
    private func resetAllData() {
        guard !isResettingAll else { return }
        
        isResettingAll = true
        showSuccessMessage = false
        showError = false
        
        HapticManager.tap()
        
        Task {
            do {
                // Debug: Delete all data using the service
                try MockDataGenerator.shared.resetAllData(from: modelContext)
                
                // Debug: Success feedback
                HapticManager.success()
                successMessage = "All data has been reset successfully"
                showSuccessMessage = true
                hasMockData = false
                hasUserData = false
                
                // Debug: Post notification that data was cleared (for other views to refresh)
                NotificationCenter.default.post(name: .dataCleared, object: nil)
                
                // Debug: Hide success message after 3 seconds
                try? await Task.sleep(for: .seconds(3))
                showSuccessMessage = false
                
            } catch {
                // Debug: Error feedback
                HapticManager.error()
                errorMessage = "Failed to reset data: \(error.localizedDescription)"
                showError = true
                
                #if DEBUG
                print("❌ Error resetting all data: \(error)")
                #endif
            }
            
            isResettingAll = false
        }
    }
    
    /// Check if mock data and user data exist
    /// Debug: Updates UI to show/hide remove/reset buttons
    @MainActor
    private func checkForExistingData() {
        hasMockData = MockDataGenerator.shared.hasMockData(in: modelContext)
        hasUserData = MockDataGenerator.shared.hasUserData(in: modelContext)
    }
}

// MARK: - Duration Selection Card

/// Debug: Custom selection card for duration options
private struct DurationSelectionCard: View {
    let duration: MockDataDuration
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Debug: Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Theme.accentColor : Theme.secondaryText.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Theme.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(duration.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.primaryText)
                    
                    Text("\(duration.herdCount) herds")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Theme.accentColor.opacity(0.1) : Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Theme.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        DemoDataView()
    }
}

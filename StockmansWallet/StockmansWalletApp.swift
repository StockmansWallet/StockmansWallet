//
//  StockmansWalletApp.swift
//  StockmansWallet
//
//  Created by Leon Ernst on 29/12/2025.
//

import SwiftUI
import SwiftData

@main
struct StockmansWalletApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            HerdGroup.self,
            UserPreferences.self,
            MarketPrice.self,
            SalesRecord.self,
        ])
        
        // Use a specific URL for the store to allow for easier migration/deletion if needed
        let storeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("StockmansWallet.sqlite")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, try to delete the old store and create a new one
            print("ModelContainer creation failed: \(error)")
            print("Attempting to reset database...")
            
            // Delete the existing store files
            let fileManager = FileManager.default
            let shmURL = storeURL.appendingPathExtension("sqlite-shm")
            let walURL = storeURL.appendingPathExtension("sqlite-wal")
            
            try? fileManager.removeItem(at: storeURL)
            try? fileManager.removeItem(at: shmURL)
            try? fileManager.removeItem(at: walURL)
            
            // Try creating again
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark) // Always dark mode
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Root View (Handles Onboarding)
struct RootView: View {
    @Query private var preferences: [UserPreferences]
    
    var body: some View {
        Group {
            if preferences.first?.hasCompletedOnboarding == true {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

//
//  SupabaseClient.swift
//  StockmansWallet
//
//  Singleton Supabase client for backend connection
//  Debug: Manages connection to Supabase backend for market data and caching
//

import Foundation
import Supabase

// MARK: - Supabase Client Singleton
// Debug: Central client for all Supabase operations
class SupabaseClientManager {
    static let shared = SupabaseClientManager()
    
    let client: SupabaseClient
    
    // Debug: Initialize with credentials from Config
    private init() {
        guard let url = URL(string: Config.supabaseURL) else {
            fatalError("Invalid Supabase URL in Config.swift. Please check your configuration.")
        }
        
        // Debug: Create Supabase client with URL and anon key
        // Note: The warning about emitLocalSessionAsInitialSession is a deprecation notice
        // for future versions. Since the configuration API structure varies by SDK version,
        // we use the simple initialization. The app works correctly with anonymous access
        // for market data without requiring auth session management.
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Config.supabaseAnonKey
        )
        
        print("🔵 Debug: SupabaseClient initialized with URL: \(url)")
    }
    
    // MARK: - Health Check
    // Debug: Verify connection to Supabase
    func testConnection() async -> Bool {
        do {
            // Try a simple query to verify connection
            let _: [TestConnection] = try await client
                .from("mla_national_indicators")
                .select()
                .limit(1)
                .execute()
                .value
            
            print("✅ Debug: Supabase connection successful")
            return true
        } catch {
            print("❌ Debug: Supabase connection failed: \(error)")
            return false
        }
    }
}

// MARK: - Helper Models
// Debug: Minimal model for connection testing
private struct TestConnection: Codable {
    let id: String?
}

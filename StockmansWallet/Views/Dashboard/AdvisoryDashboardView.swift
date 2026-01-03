//
//  AdvisoryDashboardView.swift
//  StockmansWallet
//
//  Dashboard for Advisory Users
//  Debug: Placeholder view - will show different metrics than farmer dashboard
//

import SwiftUI
import SwiftData

struct AdvisoryDashboardView: View {
    @Query private var preferences: [UserPreferences]
    
    // Debug: Get user's name for personalized greeting
    private var userName: String {
        guard let userPrefs = preferences.first,
              let firstName = userPrefs.firstName else {
            return "there"
        }
        return firstName
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Debug: Background with parallax effect (like iOS home screen wallpapers)
                ParallaxImageView(
                    imageName: "FarmBG_01",
                    intensity: 25,
                    opacity: 0.08,
                    scale: 0.5,              // Image takes 50% of screen height
                    verticalOffset: 0        // Position at top
                )
                
                // Background gradient overlay
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Icon
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 80))
                        .foregroundStyle(Theme.accent.opacity(0.6))
                    
                    // Welcome message
                    VStack(spacing: 16) {
                        Text("Welcome, \(userName)!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Theme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Advisory Dashboard")
                            .font(Theme.title)
                            .foregroundStyle(Theme.secondaryText)
                        
                        Text("Coming Soon")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                                    .fill(Theme.accent.opacity(0.15))
                            )
                            .padding(.top, 8)
                    }
                    
                    // Description
                    VStack(spacing: 12) {
                        Text("Your dashboard will feature:")
                            .font(Theme.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DashboardFeatureItem(text: "Client portfolio overview")
                            DashboardFeatureItem(text: "Recent activity feed")
                            DashboardFeatureItem(text: "Pending tasks and alerts")
                            DashboardFeatureItem(text: "Key performance metrics")
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

// MARK: - Dashboard Feature Item
struct DashboardFeatureItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(Theme.accent)
            
            Text(text)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText)
            
            Spacer()
        }
    }
}


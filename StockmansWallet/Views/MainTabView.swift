//
//  MainTabView.swift
//  StockmansWallet
//
//  Main Navigation Structure
//  Debug: Uses pure SwiftUI for tab bar styling (HIG compliant, no UIKit in init)
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var herds: [HerdGroup]
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject (modern pattern)
    let valuationEngine = ValuationEngine.shared
    
    // Debug: State for managing tab bar appearance
    @State private var tabBarAppearanceConfigured = false
    
    var body: some View {
        ZStack {
            // Debug: Gradient background behind everything for depth and visual hierarchy
            Theme.backgroundGradient.ignoresSafeArea()
            
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    // Debug: Accessibility - clear labels for VoiceOver
                    .accessibilityLabel("Dashboard tab")
                
                PortfolioView()
                    .tabItem {
                        Label("Portfolio", systemImage: "wallet.bifold")
                    }
                    .accessibilityLabel("Portfolio tab")
                
                MarketView()
                    .tabItem {
                        Label("Market", systemImage: "chart.bar.fill")
                    }
                    .accessibilityLabel("Market tab")
                
                ReportsView()
                    .tabItem {
                        Label("Reports", systemImage: "doc.text.fill")
                    }
                    .accessibilityLabel("Reports tab")
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings tab")
            }
            // Debug: Pure SwiftUI approach for tab bar styling
            .toolbarBackground(.clear, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .tint(Theme.accent)
            .onAppear {
                // Debug: Only configure appearance once (HIG: avoid repeated UIKit access)
                if !tabBarAppearanceConfigured {
                    configureTabBarAppearance()
                    tabBarAppearanceConfigured = true
                }
            }
        }
    }
    
    // Debug: Extract UIKit appearance setup to separate method (called once on appear)
    // This is acceptable as a last resort when pure SwiftUI modifiers are insufficient
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
    }
}

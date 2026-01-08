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
    // Performance: Don't query herds here - child views will query only what they need
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject (modern pattern)
    let valuationEngine = ValuationEngine.shared
    
    // Debug: State for managing tab bar appearance
    @State private var tabBarAppearanceConfigured = false
    
    // Debug: Determine if user is a farmer or advisory user
    private var isFarmer: Bool {
        guard let userPrefs = preferences.first else { return true }
        return userPrefs.userRole == .farmerGrazier
    }
    
    var body: some View {
        ZStack {
            // Debug: Gradient background behind everything for depth and visual hierarchy
            Theme.backgroundGradient.ignoresSafeArea()
            
            // Debug: Conditional tab view based on user role
            if isFarmer {
                farmerTabView
            } else {
                advisoryTabView
            }
        }
    }
    
    // MARK: - Farmer Tab View (Original)
    // Debug: Dashboard, Portfolio, Market, Tools, Settings
    private var farmerTabView: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.text.clipboard.fill")
                }
                .accessibilityLabel("Dashboard tab")
            
            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "wallet.bifold")
                }
                .accessibilityLabel("Portfolio tab")
            
            MarketView()
                .tabItem {
                    Label("Market", systemImage: "chart.bar.xaxis.ascending")
                }
                .accessibilityLabel("Market tab")
            
            ToolsView()
                .tabItem {
                    Label {
                        Text("Tools")
                    } icon: {
                        Image("tools_icon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .padding(2)
                    }
                }
                .accessibilityLabel("Tools tab")
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .accessibilityLabel("Settings tab")
        }
        .toolbarBackground(.clear, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(Theme.accent)
        .onAppear {
            if !tabBarAppearanceConfigured {
                configureTabBarAppearance()
                tabBarAppearanceConfigured = true
            }
        }
    }
    
    // MARK: - Advisory Tab View
    // Debug: Dashboard, Clients, Tools, Settings
    private var advisoryTabView: some View {
        TabView {
            AdvisoryDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.text.clipboard.fill")
                }
                .accessibilityLabel("Dashboard tab")
            
            ClientsView()
                .tabItem {
                    Label("Clients", systemImage: "person.3.fill")
                }
                .accessibilityLabel("Clients tab")
            
            ToolsView()
                .tabItem {
                    Label {
                        Text("Tools")
                    } icon: {
                        Image("tools_icon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .padding(2)
                    }
                }
                .accessibilityLabel("Tools tab")
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .accessibilityLabel("Settings tab")
        }
        .toolbarBackground(.clear, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(Theme.accent)
        .onAppear {
            if !tabBarAppearanceConfigured {
                configureTabBarAppearance()
                tabBarAppearanceConfigured = true
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


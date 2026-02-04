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
                    Label("Markets", systemImage: "chart.bar.xaxis.ascending")
                }
                .accessibilityLabel("Markets tab")
            
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
        // Debug: iOS 26+ uses glass effect, iOS 17-25 needs visible background
        .toolbarBackground(toolbarBackgroundVisibility, for: .tabBar)
        .tint(Theme.accentColor)
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
        // Debug: iOS 26+ uses glass effect, iOS 17-25 needs visible background
        .toolbarBackground(toolbarBackgroundVisibility, for: .tabBar)
        .tint(Theme.accentColor)
        .onAppear {
            if !tabBarAppearanceConfigured {
                configureTabBarAppearance()
                tabBarAppearanceConfigured = true
            }
        }
    }
    
    // Debug: Computed property for toolbar background visibility based on iOS version
    private var toolbarBackgroundVisibility: Visibility {
        // Always visible to prevent flickering
        return .visible
    }
    
    // Debug: Extract UIKit appearance setup to separate method (called once on appear)
    // This is acceptable as a last resort when pure SwiftUI modifiers are insufficient
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        // Background color for tab bar (Theme.Background.primary: #211A12)
        let bgColor = UIColor(red: 33/255, green: 26/255, blue: 18/255, alpha: 1.0)
        
        // Configure opaque background
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = bgColor
        appearance.shadowColor = .clear
        
        // Set unselected item color (Theme.Label.tertiary: #5E5142 - muted brown, clearly visible but not bright)
        // Debug: Darker than white/light beige, maintains visual hierarchy with orange active state
        let normalColor = UIColor(red: 94/255, green: 81/255, blue: 66/255, alpha: 1.0)
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        
        // Set selected item color (Theme.Accent.primary: #D07321)
        let selectedColor = UIColor(red: 208/255, green: 115/255, blue: 33/255, alpha: 1.0)
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}


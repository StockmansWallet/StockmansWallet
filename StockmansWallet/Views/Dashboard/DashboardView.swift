//
//  DashboardView.swift
//  StockmansWallet
//
//  Main Dashboard with Portfolio Value and Interactive Chart
//  Debug: Uses @Observable pattern, proper error handling, and comprehensive accessibility
//

import SwiftUI
import SwiftData
import Charts
import Foundation

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var herds: [HerdGroup]
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject (modern pattern)
    let valuationEngine = ValuationEngine.shared
    
    // Debug: State management for dashboard data
    @State private var portfolioValue: Double = 0.0
    @State private var portfolioChange: Double = 0.0
    @State private var baseValue: Double = 0.0
    @State private var dayAgoValue: Double = 0.0
    @State private var valuationHistory: [ValuationDataPoint] = []
    @State private var selectedDate: Date?
    @State private var selectedValue: Double?
    @State private var isScrubbing: Bool = false
    @State private var isLoading = true
    @State private var loadError: String? = nil
    @State private var timeRange: TimeRange = .all
    @State private var customStartDate: Date?
    @State private var customEndDate: Date?
    @State private var capitalConcentration: [CapitalConcentrationBreakdown] = []
    @State private var unrealizedGains: Double = 0.0
    @State private var totalCostToCarry: Double = 0.0
    @State private var performanceMetrics: PerformanceMetrics?
    
    // Debug: Crypto-style value reveal - show last known value briefly before updating
    @State private var displayValue: Double = 0.0
    @State private var isUpdatingValue: Bool = false
    // Debug: Dynamic change values for each time range (like CoinSpot)
    @State private var timeRangeChange: Double = 0.0
    
    // Debug: Saleyard override for dashboard-level pricing comparison
    // nil = default, uses each herd's configured saleyard (normal operation)
    // non-nil = overrides all herds to use specified saleyard (comparison mode)
    @State private var selectedSaleyard: String? = nil
    
    @State private var showingAddAssetMenu = false
    @State private var showingCustomDatePicker = false
    @State private var backgroundImageTrigger = false // Debug: Trigger to force view refresh on background change
    
    // Debug: State for clearing mock data (temporary dev feature)
    @State private var isClearingMockData = false
    
    // Debug: Smart refresh tracking (Coinbase-style)
    // Only reload when necessary, not on every view appearance
    @State private var hasLoadedData = false // Track if we've loaded data this session
    @State private var lastRefreshDate: Date? = nil // Track when data was last refreshed
    private let refreshThreshold: TimeInterval = 300 // 5 minutes - only refresh if older
    
    
    // Performance: Race condition prevention - ensures only one data load at a time
    private let loadCoordinator = LoadCoordinator()
    
    var body: some View {
        NavigationStack {
            mainContentWithModifiers
        }
    }
    
    // Debug: Separate view with all modifiers to reduce complexity
    @ViewBuilder
    private var mainContentWithModifiers: some View {
        let contentWithNav = mainContent
            .navigationBarTitleDisplayMode(.inline)
            
        
        contentWithNav
            .task {
                // Performance: .task automatically cancels when view disappears
                // Debug: Smart loading - like Coinbase/production apps
                // Only load if: first time, or data is stale (>5 min old)
                await loadDataIfNeeded(force: false)
            }
            .onDisappear {
                // Performance: .task's automatic cancellation will stop ongoing work
                // LoadCoordinator prevents race conditions if multiple loads overlap
                #if DEBUG
                print("📊 DashboardView disappeared - task will auto-cancel")
                #endif
            }
            .refreshable {
                // Debug: Explicit user pull-to-refresh always forces reload
                // LoadCoordinator automatically cancels previous load before starting new one
                await loadDataIfNeeded(force: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DataCleared"))) { _ in
                Task {
                    await MainActor.run {
                        self.valuationHistory = []
                        self.portfolioValue = 0.0
                        self.baseValue = 0.0
                        self.hasLoadedData = false // Force reload after clearing data
                    }
                    await loadDataIfNeeded(force: true)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BackgroundImageChanged"))) { _ in
                // Debug: Toggle state to force view refresh when background image changes
                Task { @MainActor in
                    #if DEBUG
                    print("🖼️ DashboardView: Background image changed notification received")
                    #endif
                    backgroundImageTrigger.toggle()
                    #if DEBUG
                    print("🖼️ DashboardView: backgroundImageTrigger is now \(backgroundImageTrigger)")
                    #endif
                }
            }
            .onChange(of: herds.count) { _, _ in
                // Debug: Herd count changed - force reload
                Task {
                    await loadDataIfNeeded(force: true)
                }
            }
            .onChange(of: timeRange) { _, _ in
                // Debug: Update change value when time range changes (like CoinSpot)
                updateTimeRangeChange()
            }
            .onChange(of: valuationHistory.count) { _, _ in
                // Debug: Update change value when history data changes
                updateTimeRangeChange()
            }
            .onChange(of: selectedSaleyard) { _, _ in
                // Debug: Saleyard changed - force reload for new prices
                // This allows comparing portfolio value across different saleyards
                Task {
                    await loadDataIfNeeded(force: true)
                }
            }
            .sheet(isPresented: $showingAddAssetMenu) {
                AddAssetMenuView(isPresented: $showingAddAssetMenu)
                    .transition(.move(edge: .trailing))
                    .presentationBackground(Theme.sheetBackground)
            }
            .sheet(isPresented: $showingCustomDatePicker) {
                CustomDateRangeSheet(
                    startDate: $customStartDate,
                    endDate: $customEndDate,
                    timeRange: $timeRange
                )
            }
            .background(Theme.backgroundColor.ignoresSafeArea())
    }
    
    // Debug: Extract main content to reduce body complexity
    @ViewBuilder
    private var mainContent: some View {
        Group {
            let activeHerds = herds.filter { !$0.isSold }
            
            // Debug: Handle empty, error, and loaded states
            if activeHerds.isEmpty {
                EmptyDashboardView(showingAddAssetMenu: $showingAddAssetMenu)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Empty dashboard")
                    .accessibilityHint("Add your first herd to get started.")
            } else if let error = loadError {
                // Debug: Error state with retry option
                ErrorStateView(errorMessage: error) {
                    Task {
                        await loadValuations()
                    }
                }
                .accessibilityLabel("Error loading dashboard")
                .accessibilityHint(error)
            } else {
                dashboardContentView
            }
        }
    }
    
    // Debug: Dashboard content with parallax background and fixed header
    @ViewBuilder
    private var dashboardContentView: some View {
        let userPrefs = preferences.first ?? UserPreferences()
        let backgroundImageName = userPrefs.backgroundImageName
        // Debug: Force view update when backgroundImageTrigger changes
        let _ = backgroundImageTrigger
        
        ZStack(alignment: .top) {
            // Debug: Background image with parallax effect (like iOS home screen wallpapers)
            // Uses user's selected background from preferences (built-in or custom)
            // Only show background if backgroundImageName is not nil
            if let imageName = backgroundImageName {
                if userPrefs.isCustomBackground {
                    // Debug: Load custom background from document directory
                    CustomParallaxImageView(
                        imageName: imageName,
                        intensity: 25,           // Movement amount (20-40)
                        opacity: 0.5,            // Background opacity
                        scale: 0.5,              // Image takes 50% of screen height
                        verticalOffset: -60,     // Move image up to show more middle/lower area
                        blur: 0                  // BG Image Blur radius
                    )
                    .id("custom_\(imageName)_\(backgroundImageTrigger)") // Debug: Force view recreation on background change
                } else {
                    // Debug: Load built-in background from Assets
                    ParallaxImageView(
                        imageName: imageName,
                        intensity: 25,           // Movement amount (20-40)
                        opacity: 0.5,            // Background opacity
                        scale: 0.5,              // Image takes 50% of screen height
                        verticalOffset: -60,     // Move image up to show more middle/lower area
                        blur: 0                  // BG Image Blur radius
                    )
                    .id("builtin_\(imageName)_\(backgroundImageTrigger)") // Debug: Force view recreation on background change
                }
            } else {
                // Debug: Subtle orange radial glow from top when no background is selected
                // Adds visual interest and warmth to the "none" background option
                RadialGradient(
                    colors: [
                        Theme.accent.opacity(0.12),  // Subtle orange glow at top
                        Theme.accent.opacity(0.04),  // Fade to very subtle
                        Color.clear                   // Fade to transparent
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
                .id("glow_\(backgroundImageTrigger)") // Debug: Force view recreation on background change
            }
            
            // Debug: Fixed portfolio value - stays in place while content scrolls over it
            VStack {
                PortfolioValueCard(
                    value: selectedValue ?? displayValue,
                    change: isScrubbing ? (selectedValue ?? displayValue) - baseValue : timeRangeChange,
                    baseValue: baseValue, // Debug: Pass baseValue for percentage calculation
                    isLoading: isLoading,
                    isScrubbing: isScrubbing,
                    isUpdating: isUpdatingValue
                )
                .padding(.horizontal, Theme.cardPadding)
                .padding(.top, 30) 
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total portfolio value")
                .accessibilityValue("\(portfolioValue.formatted(.currency(code: "AUD")))")
                
                
                Spacer()
            }
            
            // Debug: Scrollable content panel - starts lower to show more background
            ScrollView {
                VStack(spacing: 0) {
                    // Debug: Top spacing to position content panel lower and clear the fixed header
                    Color.clear
                        .frame(height: 230) // Adjust this to control how much background shows
                    
                    contentPanel
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    // Debug: Rounded panel with all dashboard content
    @ViewBuilder
    private var contentPanel: some View {
        VStack(spacing: Theme.sectionSpacing) {
            // Debug: Show placeholder when insufficient data (< 2 points), otherwise show chart
            if filteredHistory.count < 2 {
                // Debug: Empty state for new portfolios - matches InteractiveChartView structure exactly
                VStack(spacing: 0) {
                    // Debug: Space for date hover pill (matches InteractiveChartView)
                    Color.clear
                        .frame(height: 32)
                    
                    // Debug: Main chart area placeholder
                    VStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.accent.opacity(0.6))
                        
                        Text("New Portfolio")
                            .font(Theme.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.primaryText)
                        
                        Text("Your portfolio is brand new! As time passes and your herd data accumulates, this chart will automatically populate with historical valuation data.")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .lineLimit(4)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.01))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                            .strokeBorder(
                                Color.white.opacity(0.1),
                                style: StrokeStyle(
                                    lineWidth: 1,
                                    lineCap: .round
                                )
                            )
                    )
                    
                    // Debug: Space for chart date labels (matches InteractiveChartView)
                    Color.clear
                        .frame(height: 32)
                        .padding(.top, 10)
                }
                .padding(.horizontal, Theme.cardPadding)
                .accessibilityLabel("Chart placeholder")
                .accessibilityHint("This chart will populate as your portfolio data accumulates over time.")
            } else {
                InteractiveChartView(
                    data: filteredHistory,
                    selectedDate: $selectedDate,
                    selectedValue: $selectedValue,
                    isScrubbing: $isScrubbing,
                    timeRange: $timeRange,
                    baseValue: baseValue,
                    onValueChange: { newValue, change in
                        portfolioChange = change
                    }
                )
                .padding(.horizontal, Theme.cardPadding)
                .accessibilityHint("Drag your finger across the chart to explore values over time.")
            }
            
            TimeRangeSelector(
                timeRange: $timeRange,
                customStartDate: $customStartDate,
                customEndDate: $customEndDate,
                showingCustomDatePicker: $showingCustomDatePicker
            )
                .padding(.horizontal, Theme.cardPadding)
                .padding(.top, -Theme.sectionSpacing)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Time range selector")
            
            // Debug: Saleyard selector - updates valuations based on selected saleyard prices
            SaleyardSelector(selectedSaleyard: $selectedSaleyard)
                .padding(.horizontal, Theme.cardPadding)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Saleyard selector")
            
            MarketPulseView()
                .padding(.horizontal, Theme.cardPadding)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Herd performance")
            
            HerdDynamicsView(herds: herds.filter { !$0.isSold })
                .padding(.horizontal, Theme.cardPadding)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Growth and mortality")
            
            if !capitalConcentration.isEmpty {
                CapitalConcentrationView(breakdown: capitalConcentration, totalValue: portfolioValue)
                    .padding(.horizontal, Theme.cardPadding)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Herd composition")
            }
            
            #if DEBUG
            // Debug: Temporary Clear Mock Data button for development
            // TODO: Remove this button before production release
            Button(action: {
                HapticManager.tap()
                clearMockData()
            }) {
                HStack(spacing: 8) {
                    if isClearingMockData {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    Text(isClearingMockData ? "Clearing..." : "Clear Mock Data")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(Theme.DestructiveButtonStyle())
            .disabled(isClearingMockData)
            .padding(.horizontal, Theme.cardPadding)
            .padding(.top, Theme.sectionSpacing)
            .accessibilityLabel("Clear mock data")
            .accessibilityHint("Removes all mock data from the dashboard")
            #endif
        }
        .padding(.top, -12)
        .padding(.bottom, 100)
        .background(
            // Debug: iOS 26 HIG - Panel background using native UnevenRoundedRectangle
            // Uses sheetCornerRadius (32pt) for large panel surfaces, matching iOS sheet standards
            // Dark panel with gradient and drop shadow for depth and hierarchy
            ZStack {
                // Base background layer
                UnevenRoundedRectangle(
                    topLeadingRadius: Theme.sheetCornerRadius,
                    topTrailingRadius: Theme.sheetCornerRadius,
                    style: .continuous
                )
                .fill(Theme.backgroundColor)
                .ignoresSafeArea()
                
                // Gradient overlay for visual interest
                UnevenRoundedRectangle(
                    topLeadingRadius: Theme.sheetCornerRadius,
                    topTrailingRadius: Theme.sheetCornerRadius,
                    style: .continuous
                )
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FFA042").opacity(0.15),  // Orange accent from top
                            Color(hex: "1E1815").opacity(0)      // Fade to transparent
                        ],
                        center: .top,
                        startRadius: 0,
                        endRadius: 500
                    )
                )
                .ignoresSafeArea()
            }
            .shadow(color: .black.opacity(0.8), radius: 30, y: -8)
        )
    }
    
    private var filteredHistory: [ValuationDataPoint] {
        guard !valuationHistory.isEmpty else { return [] }
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .custom:
            // Debug: Filter by custom date range if set
            guard let startDate = customStartDate, let endDate = customEndDate else {
                return valuationHistory
            }
            return valuationHistory.filter { $0.date >= startDate && $0.date <= endDate }
        case .week:
            let cutoffDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return valuationHistory.filter { $0.date >= cutoffDate }
        case .month:
            let cutoffDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return valuationHistory.filter { $0.date >= cutoffDate }
        case .year:
            let cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return valuationHistory.filter { $0.date >= cutoffDate }
        case .all:
            return valuationHistory
        }
    }
    
    // Debug: Calculate change based on selected time range (like CoinSpot)
    // Updates dynamically when user changes time range filter
    private func updateTimeRangeChange() {
        guard !valuationHistory.isEmpty else {
            timeRangeChange = 0.0
            return
        }
        
        let filtered = filteredHistory
        guard let firstValue = filtered.first?.value else {
            timeRangeChange = 0.0
            return
        }
        
        // Debug: Calculate change from first point in range to current value
        timeRangeChange = portfolioValue - firstValue
    }
    
    // Debug: Value reveal - show last value, hold with pulse, then transition to new value
    // NOTE: Caller should check if value changed before calling this function
    // Uses simple SwiftUI numeric text animation (same as chart scrubbing)
    private func updateDisplayValueWithDelay(newValue: Double, lastValue: Double) async {
        #if DEBUG
        print("💰 Step 1: Showing last value \(lastValue)")
        #endif
        // Debug: Show last known value first
        await MainActor.run {
            displayValue = lastValue
        }
        
        // Debug: Small delay to ensure the UI renders with the old value
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #if DEBUG
        print("💰 Step 2: Starting pulse/glow and holding for 1.5 seconds...")
        #endif
        // Debug: Enable glow while holding at old value
        await MainActor.run {
            isUpdatingValue = true
        }
        
        // Debug: Hold at old value for 1.5 seconds with pulse/glow (reduced from 2s for faster UX)
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        #if DEBUG
        print("💰 Step 3: Stopping pulse before value changes")
        #endif
        // Debug: Turn off pulsing BEFORE the number changes (per user requirement)
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.3)) {
                isUpdatingValue = false
            }
        }
        
        // Debug: Brief delay to let the glow fade out
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        #if DEBUG
        print("💰 Step 4: Transitioning from \(lastValue) to \(newValue) using native SwiftUI animation")
        #endif
        // Debug: Simple value transition - SwiftUI's numericText animation handles the smooth transition
        await MainActor.run {
            displayValue = newValue
        }
        
        #if DEBUG
        print("💰 Animation complete!")
        #endif
    }
    
    // Debug: Async data loading with proper error handling
    // Debug: Smart data loading - Coinbase/production app pattern
    // Only loads when necessary: first time, stale data, or forced refresh
    // Performance: Uses LoadCoordinator to prevent race conditions from concurrent triggers
    private func loadDataIfNeeded(force: Bool) async {
        // Performance: Wrap in coordinator to prevent concurrent loads
        do {
            try await loadCoordinator.execute {
                // Debug: Check if we need to load data
                let (needsRefresh, isFirstLoad) = await MainActor.run {
                    let isFirst = !self.hasLoadedData
                    
                    // Force refresh (user pull-to-refresh, data changed)
                    if force {
                        #if DEBUG
                        print("📊 Force refresh requested")
                        #endif
                        return (true, isFirst)
                    }
                    
                    // First time loading
                    if isFirst {
                        #if DEBUG
                        print("📊 First time loading - will load cache then refresh if stale")
                        #endif
                        return (true, isFirst)
                    }
                    
                    // Check if data is stale (>5 minutes old)
                    if let lastRefresh = self.lastRefreshDate {
                        let timeSinceRefresh = Date().timeIntervalSince(lastRefresh)
                        if timeSinceRefresh > self.refreshThreshold {
                            #if DEBUG
                            print("📊 Data is stale (\(Int(timeSinceRefresh))s old), refreshing...")
                            #endif
                            return (true, isFirst)
                        } else {
                            #if DEBUG
                            print("📊 Data is fresh (\(Int(timeSinceRefresh))s old), skipping reload")
                            #endif
                            return (false, isFirst)
                        }
                    }
                    
                    // No last refresh date, needs refresh
                    return (true, isFirst)
                }
                
                guard needsRefresh else {
                    #if DEBUG
                    print("📊 Skipping reload - data is fresh")
                    #endif
                    return
                }
                
                // Debug: First time only - load cached data immediately
                if isFirstLoad {
                    await MainActor.run {
                        let prefs = self.preferences.first ?? UserPreferences()
                        self.displayValue = prefs.lastPortfolioValue
                        #if DEBUG
                        print("💰 Initial displayValue set to: \(self.displayValue)")
                        #endif
                        
                        // Load cached chart data immediately for instant display
                        self.loadCachedChartData()
                    }
                }
                
                // Debug: Now load fresh data
                await self.loadValuations()
                
                // Debug: Mark as loaded and update timestamp
                await MainActor.run {
                    self.hasLoadedData = true
                    self.lastRefreshDate = Date()
                }
            }
        } catch {
            // Race condition resolved by coordinator - previous load was cancelled
            #if DEBUG
            print("📊 Load operation error (expected if cancelled): \(error)")
            #endif
        }
    }
    
    private func loadValuations() async {
        #if DEBUG
        print("💰 loadValuations() called")
        #endif
        await MainActor.run {
            self.isLoading = true
            self.loadError = nil
            // Debug: Don't clear valuationHistory - keep showing cached data while refreshing
        }
        
        // Debug: Fetch preferences and active herds
        let prefs = preferences.first ?? UserPreferences()
        let currentHerds = herds
        let activeHerds = currentHerds.filter { !$0.isSold }
        
        // Debug: Early return if no active herds
        guard !activeHerds.isEmpty else {
            await MainActor.run {
                self.portfolioValue = 0.0
                self.displayValue = 0.0 // Debug: No delay for empty state
                self.baseValue = 0.0
                self.valuationHistory = []
                self.capitalConcentration = []
                self.unrealizedGains = 0.0
                self.totalCostToCarry = 0.0
                self.performanceMetrics = nil
                self.timeRangeChange = 0.0
                self.isLoading = false
            }
            return
        }
        
        // Debug: Wrap in do-catch for proper error handling
        do {
            try await performValuationCalculations(activeHerds: activeHerds, prefs: prefs)
        } catch {
            await MainActor.run {
                self.loadError = "Failed to load valuations: \(error.localizedDescription)"
                self.isLoading = false
            }
            HapticManager.error()
        }
    }
    
    // Debug: Extracted calculation logic for better organization
    private func performValuationCalculations(activeHerds: [HerdGroup], prefs: UserPreferences) async throws {
        // Debug: Parallel calculation of herd valuations using task groups
        let results = await withTaskGroup(of: (netValue: Double, category: String, cost: Double, breeding: Double, initial: Double).self) { group in
            var results: [(netValue: Double, category: String, cost: Double, breeding: Double, initial: Double)] = []
            for herd in activeHerds {
                group.addTask { @MainActor [modelContext] in
                    // Debug: Pass selectedSaleyard override for comparison mode
                    // When nil (default), uses each herd's configured saleyard
                    // When set, overrides all herds to use that specific saleyard
                    let valuation = await self.valuationEngine.calculateHerdValue(
                        herd: herd,
                        preferences: prefs,
                        modelContext: modelContext,
                        saleyardOverride: self.selectedSaleyard
                    )
                    
                    let initialValuation = await self.valuationEngine.calculateHerdValue(
                        herd: herd,
                        preferences: prefs,
                        modelContext: modelContext,
                        asOfDate: herd.createdAt,
                        saleyardOverride: self.selectedSaleyard
                    )
                    
                    return (
                        netValue: valuation.netRealizableValue,
                        category: herd.category,
                        cost: valuation.costToCarry,
                        breeding: valuation.breedingAccrual,
                        initial: initialValuation.netRealizableValue
                    )
                }
            }
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        var valuations: Double = 0.0
        var categoryTotals: [String: Double] = [:]
        var totalCost: Double = 0.0
        var totalBreedingAccrual: Double = 0.0
        var initialValue: Double = 0.0
        
        for result in results {
            valuations += result.netValue
            categoryTotals[result.category, default: 0.0] += result.netValue
            totalCost += result.cost
            totalBreedingAccrual += result.breeding
            initialValue += result.initial
        }
        
        // Guard against division by zero when computing percentages
        let concentration: [CapitalConcentrationBreakdown]
        if valuations > 0 {
            concentration = categoryTotals.map { category, value in
                CapitalConcentrationBreakdown(category: category, value: value, percentage: (value / valuations) * 100)
            }
            .sorted { $0.value > $1.value }
        } else {
            concentration = categoryTotals.map { category, value in
                CapitalConcentrationBreakdown(category: category, value: value, percentage: 0.0)
            }
            .sorted { $0.value > $1.value }
        }
        
        let totalChange = valuations - initialValue
        let percentChange = initialValue > 0 ? (totalChange / initialValue) * 100 : 0.0
        
        // Debug: Get last known portfolio value for crypto-style reveal
        let lastKnownValue = prefs.lastPortfolioValue
        
        // Debug: Update UI state on main actor
        await MainActor.run {
            self.portfolioValue = valuations
            self.baseValue = initialValue
            self.portfolioChange = totalChange
            self.capitalConcentration = concentration
            self.unrealizedGains = totalBreedingAccrual
            self.totalCostToCarry = totalCost
            self.performanceMetrics = PerformanceMetrics(
                totalChange: totalChange,
                percentChange: percentChange,
                unrealizedGains: totalBreedingAccrual,
                initialValue: initialValue
            )
            self.isLoading = false
        }
        
        HapticManager.tap()
        
        // Debug: Crypto-style value reveal - but only if value actually changed significantly
        // Check difference before starting animation to avoid unnecessary delays
        let valueDifference = abs(valuations - lastKnownValue)
        #if DEBUG
        print("💰 Value difference: $\(valueDifference) (lastKnown: $\(lastKnownValue), new: $\(valuations))")
        #endif
        
        if valueDifference > 1.0 {
            // Debug: Run animation (blocks chart loading intentionally for better UX)
            #if DEBUG
            print("💰 Running value animation (significant change detected)")
            #endif
            await updateDisplayValueWithDelay(newValue: valuations, lastValue: lastKnownValue)
        } else {
            // Debug: No significant change, update immediately
            #if DEBUG
            print("💰 Updating value immediately (no significant change)")
            #endif
            await MainActor.run {
                self.displayValue = valuations
            }
        }
        
        // Debug: Save new portfolio value to preferences after value update
        await MainActor.run {
            prefs.lastPortfolioValue = valuations
            prefs.lastPortfolioUpdateDate = Date()
            #if DEBUG
            print("💰 Saved new portfolio value to preferences: \(valuations)")
            #endif
        }
        
        // Debug: Progressive chart loading for faster perceived performance
        // Phase 1: Show current value immediately (instant chart appearance)
        await loadHistoricalDataProgressively(activeHerds: activeHerds, prefs: prefs, portfolioValue: valuations)
    }
    
    // Debug: Load cached chart data from last session for instant display
    @MainActor
    private func loadCachedChartData() {
        guard let prefs = preferences.first,
              let cachedData = prefs.lastChartData,
              let decoded = try? JSONDecoder().decode([ValuationDataPoint].self, from: cachedData),
              !decoded.isEmpty else {
            #if DEBUG
            print("📊 No cached chart data available")
            #endif
            return
        }
        
        // Debug: Show last known chart data immediately
        self.valuationHistory = decoded
        #if DEBUG
        print("📊 Loaded cached chart data: \(decoded.count) points from \(prefs.lastPortfolioUpdateDate?.formatted() ?? "unknown")")
        #endif
    }
    
    // Debug: Cache chart data for instant display on next launch
    @MainActor
    private func cacheChartData(_ data: [ValuationDataPoint]) {
        guard let prefs = preferences.first,
              let encoded = try? JSONEncoder().encode(data) else {
            return
        }
        
        prefs.lastChartData = encoded
        #if DEBUG
        print("📊 Cached chart data: \(data.count) points for next session")
        #endif
    }
    
    // Debug: Progressive historical data loading for faster chart appearance
    // Phase 1: Current value only (instant) - only if no cached data
    // Phase 2: Full history (background - complete picture)
    private func loadHistoricalDataProgressively(activeHerds: [HerdGroup], prefs: UserPreferences, portfolioValue: Double) async {
        // Debug: If no chart data visible, add today's point immediately for instant feedback
        let hasVisibleData = await MainActor.run { !self.valuationHistory.isEmpty }
        
        if !hasVisibleData {
            #if DEBUG
            print("📊 No visible data - adding current value immediately")
            #endif
            // Debug: Add today's value immediately so chart appears instantly
            await MainActor.run {
                self.valuationHistory = [ValuationDataPoint(
                    date: Date(),
                    value: portfolioValue,
                    physicalValue: portfolioValue,
                    breedingAccrual: self.unrealizedGains
                )]
            }
        }
        
        // Debug: Now load full history (will replace the single point or cached data)
        #if DEBUG
        print("📊 Loading full historical data...")
        #endif
        await loadFullHistory(activeHerds: activeHerds, prefs: prefs, endDate: Date())
    }
    
    // Debug: Load complete historical data (up to 3 years)
    // Performance: Now cancellable to prevent wasted CPU when user navigates away
    private func loadFullHistory(activeHerds: [HerdGroup], prefs: UserPreferences, endDate: Date) async {
        let calendar = Calendar.current
        let startDate = Date(timeIntervalSince1970: 1672531200) // Jan 1, 2023
        let earliestHerdDate = activeHerds.map { $0.createdAt }.min() ?? startDate
        let historyStartDate = min(startDate, earliestHerdDate)
        
        let daysFromStart = calendar.dateComponents([.day], from: historyStartDate, to: endDate).day ?? 0
        let totalDays = min(daysFromStart + 1, 1095) // Max 3 years
        
        var history: [ValuationDataPoint] = []
        
        // Debug: Load all historical data with appropriate granularity
        // Daily for last 7 days, weekly for older data
        for dayOffset in (0..<totalDays).reversed() {
            // Performance: Check if task was cancelled (user navigated away, new data load started, etc.)
            // This prevents wasting CPU on calculations that won't be displayed
            do {
                try Task.checkCancellation()
            } catch {
                #if DEBUG
                print("📊 Historical data load cancelled at day \(dayOffset)/\(totalDays)")
                #endif
                return
            }
            
            // Debug: Skip non-week days for data older than 7 days (optimization)
            if dayOffset > 7 && dayOffset % 7 != 0 {
                continue
            }
            
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { continue }
            guard date >= historyStartDate else { continue }
            
            let activeHerdsForDate = activeHerds.filter { $0.createdAt <= date }
            guard !activeHerdsForDate.isEmpty else { continue }
            
            // Debug: Parallel valuation calculation for all herds at this date
            let dayValuations = await withTaskGroup(of: (physical: Double, breeding: Double, total: Double).self, returning: (physical: Double, breeding: Double, total: Double).self) { group in
                var totals = (physical: 0.0, breeding: 0.0, total: 0.0)
                for herd in activeHerdsForDate {
                    group.addTask { @MainActor [modelContext] in
                        let valuation = await self.valuationEngine.calculateHerdValue(
                            herd: herd,
                            preferences: prefs,
                            modelContext: modelContext,
                            asOfDate: date,
                            saleyardOverride: self.selectedSaleyard
                        )
                        return (valuation.physicalValue, valuation.breedingAccrual, valuation.netRealizableValue)
                    }
                }
                for await values in group {
                    totals.physical += values.physical
                    totals.breeding += values.breeding
                    totals.total += values.total
                }
                return totals
            }
            
            history.append(ValuationDataPoint(
                date: date,
                value: dayValuations.total,
                physicalValue: dayValuations.physical,
                breedingAccrual: dayValuations.breeding
            ))
        }
        
        // Debug: Calculate day-ago value for 24h change display
        let dayAgo = calendar.date(byAdding: .hour, value: -24, to: endDate) ?? endDate
        let dayAgoDataPoint = history.last { $0.date <= dayAgo } ?? history.first
        
        let currentPortfolioValue = self.portfolioValue
        
        await MainActor.run {
            // Debug: Update chart with fresh data
            self.valuationHistory = history
            self.dayAgoValue = dayAgoDataPoint?.value ?? currentPortfolioValue
            self.updateTimeRangeChange()
            
            // Debug: Cache for instant display on next launch
            self.cacheChartData(history)
            
            HapticManager.success()
            
            #if DEBUG
            print("📊 Full history loaded: \(history.count) data points")
            #endif
        }
    }
    
    // Debug: Clear all mock data (temporary dev feature)
    // TODO: Remove this function before production release
    @MainActor
    private func clearMockData() {
        isClearingMockData = true
        Task { @MainActor in
            await HistoricalMockDataService.shared.clearAllData(modelContext: modelContext)
            // Debug: Notify dashboard to refresh after data is cleared
            NotificationCenter.default.post(name: NSNotification.Name("DataCleared"), object: nil)
            isClearingMockData = false
            HapticManager.success()
        }
    }
}

// MARK: - Portfolio Value Card
// MARK: - Extracted Components
// Components:
//   - AnimatedCurrencyValue → Components/AnimatedCurrencyValue.swift
//   - PortfolioValueCard → Components/PortfolioValueCard.swift
//   - CapitalConcentrationView → Components/CapitalConcentrationView.swift
//   - PerformanceMetricsView → Components/PerformanceMetricsView.swift
//   - InteractiveChartView → InteractiveChartView.swift (already extracted)
// States:
//   - EmptyDashboardView → States/EmptyDashboardView.swift
//   - ErrorStateView → States/ErrorStateView.swift
// Models:
//   - DashboardModels → Models/DashboardModels.swift

// MARK: - Herd Composition View (Category Breakdown with Pie Chart)
// Debug: Shows category distribution with pie chart and detailed breakdown list
// Debug: HIG-compliant searchable sheet for saleyard selection (31+ items)
// Default (nil) uses each herd's configured saleyard, otherwise overrides all herds

// MARK: - Sheet Views (Extracted)
// SaleyardSelector → Sheets/SaleyardSelector.swift
// SaleyardSelectionSheet → Sheets/SaleyardSelectionSheet.swift
// CustomDateRangeSheet → Sheets/CustomDateRangeSheet.swift

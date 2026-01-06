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
    @State private var displayValue: Double = 0.0 {
        didSet {
            #if DEBUG
            print("💰 displayValue changed: \(oldValue) → \(displayValue)")
            #endif
        }
    }
    @State private var isUpdatingValue: Bool = false {
        didSet {
            #if DEBUG
            print("💰 isUpdatingValue changed: \(oldValue) → \(isUpdatingValue)")
            #endif
        }
    }
    
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
        let _ = print("🖼️ DashboardView: Rendering with background=\(backgroundImageName ?? "none"), isCustom=\(userPrefs.isCustomBackground), trigger=\(backgroundImageTrigger)")
        
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
    // Only triggers when value has changed (new herd, sold animal, app launch, etc.)
    // Uses simple SwiftUI numeric text animation (same as chart scrubbing)
    private func updateDisplayValueWithDelay(newValue: Double, lastValue: Double) async {
        #if DEBUG
        print("💰 updateDisplayValueWithDelay: lastValue=\(lastValue), newValue=\(newValue), diff=\(abs(newValue - lastValue))")
        #endif
        
        // Debug: Check if value has actually changed (threshold of $1 to avoid floating point issues)
        guard abs(newValue - lastValue) > 1.0 else {
            #if DEBUG
            print("💰 No significant change, updating immediately")
            #endif
            // No significant change, update immediately
            await MainActor.run {
                displayValue = newValue
            }
            return
        }
        
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
        print("💰 Step 2: Starting pulse/glow and holding for 2 seconds...")
        #endif
        // Debug: Enable glow while holding at old value
        await MainActor.run {
            isUpdatingValue = true
        }
        
        // Debug: Hold at old value for 2 seconds with pulse/glow
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
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
                let needsRefresh = await MainActor.run {
                    // Force refresh (user pull-to-refresh, data changed)
                    if force {
                        #if DEBUG
                        print("📊 Force refresh requested")
                        #endif
                        return true
                    }
                    
                    // First time loading
                    if !self.hasLoadedData {
                        #if DEBUG
                        print("📊 First time loading - will load cache then refresh if stale")
                        #endif
                        return true
                    }
                    
                    // Check if data is stale (>5 minutes old)
                    if let lastRefresh = self.lastRefreshDate {
                        let timeSinceRefresh = Date().timeIntervalSince(lastRefresh)
                        if timeSinceRefresh > self.refreshThreshold {
                            #if DEBUG
                            print("📊 Data is stale (\(Int(timeSinceRefresh))s old), refreshing...")
                            #endif
                            return true
                        } else {
                            #if DEBUG
                            print("📊 Data is fresh (\(Int(timeSinceRefresh))s old), skipping reload")
                            #endif
                            return false
                        }
                    }
                    
                    // No last refresh date, needs refresh
                    return true
                }
                
                guard needsRefresh else {
                    #if DEBUG
                    print("📊 Skipping reload - data is fresh")
                    #endif
                    return
                }
                
                // Debug: First time only - load cached data immediately
                if !self.hasLoadedData {
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
            self.valuationHistory = []
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
        
        // Debug: Crypto-style value reveal - run in parallel so it doesn't block chart loading
        #if DEBUG
        print("💰 Starting value animation in parallel with chart loading")
        #endif
        Task {
            await updateDisplayValueWithDelay(newValue: valuations, lastValue: lastKnownValue)
            
            // Debug: Save new portfolio value to preferences AFTER animation completes
            await MainActor.run {
                prefs.lastPortfolioValue = valuations
                prefs.lastPortfolioUpdateDate = Date()
                #if DEBUG
                print("💰 Saved new portfolio value to preferences: \(valuations)")
                #endif
            }
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
    // Phase 1: Current value only (instant)
    // Phase 2: Last 30 days (fast - most relevant data)
    // Phase 3: Full history (background - complete picture)
    private func loadHistoricalDataProgressively(activeHerds: [HerdGroup], prefs: UserPreferences, portfolioValue: Double) async {
        // Debug: Simplified - just load full history directly
        // Cached data is already showing, we're just refreshing in background
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
struct PortfolioValueCard: View {
    let value: Double
    let change: Double
    let baseValue: Double // Debug: Base value for calculating percentage change
    let isLoading: Bool
    let isScrubbing: Bool
    let isUpdating: Bool // Debug: Pulse/glow state during value transition
    
    // Debug: Calculate percentage change from base value
    private var percentageChange: Double {
        guard baseValue > 0 else { return 0 }
        return (change / baseValue) * 100
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Total Portfolio Value")
                .font(Theme.caption)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
            
            // Debug: Always show the number - never hide it with ProgressView
            // Use pulsing effect (isUpdating) to indicate loading instead
            AnimatedCurrencyValue(
                value: value,
                isScrubbing: isScrubbing
            )
                .padding(.bottom, 8)
                // Debug: Pulse/glow effect during value update (crypto-style)
                .shadow(
                    color: isUpdating ? Theme.accent.opacity(0.6) : .clear,
                    radius: isUpdating ? 20 : 0
                )
                .shadow(
                    color: isUpdating ? Theme.accent.opacity(0.4) : .clear,
                    radius: isUpdating ? 40 : 0
                )
                .animation(.easeInOut(duration: 0.8).repeatCount(3, autoreverses: true), value: isUpdating)
            
            // Debug: Change pill with both dollar amount and percentage
            HStack(spacing: 6) {
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(change >= 0 ? Theme.positiveChange : Theme.negativeChange)
                    .accessibilityHidden(true)
                
                // Dollar change
                Text(change, format: .currency(code: "AUD"))
                    .font(.system(size: 11, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(change >= 0 ? Theme.positiveChange : Theme.negativeChange)
                
                // Debug: Separator dot between dollar and percentage
                Text("•")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle((change >= 0 ? Theme.positiveChange : Theme.negativeChange).opacity(0.5))
                    .accessibilityHidden(true)
                
                // Percentage change
                Text("\(percentageChange >= 0 ? "+" : "")\(percentageChange, specifier: "%.2f")%")
                    .font(.system(size: 11, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(change >= 0 ? Theme.positiveChange : Theme.negativeChange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular.interactive().tint((change >= 0 ? Theme.positiveChange : Theme.negativeChange).opacity(0.1)), in: Capsule())
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            .animation(UIAccessibility.isReduceMotionEnabled ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: change)
            .accessibilityLabel("Change for selected time range")
            .accessibilityValue("\(change.formatted(.currency(code: "AUD"))), \(percentageChange, specifier: "%.2f") percent")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.cardPadding)
    }
}

// MARK: - Animated Currency Value with Native iOS Animation
// Performance: Zero lag during scrubbing, beautiful .numericText() animation on release
struct AnimatedCurrencyValue: View {
    let value: Double
    let isScrubbing: Bool
    @State private var previousValue: Double = 0.0
    
    // Performance: Reuse formatter instead of creating new one on every render
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    // Determine if value is decreasing for reverse spin animation
    private var isDecreasing: Bool {
        return value < previousValue
    }
    
    private var formattedValue: (whole: String, decimal: String) {
        let whole = Self.numberFormatter.string(from: NSNumber(value: abs(value))) ?? "0"
        let decimal = String(format: "%02d", Int((abs(value) - floor(abs(value))) * 100))
        
        return (whole: whole, decimal: decimal)
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("$")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
                .tracking(-2)
                .baselineOffset(4)
                .padding(.trailing, 8)
                .accessibilityHidden(true)
            
            // Performance: While finger is down (isScrubbing) → instant updates, no animation
            // When finger lifts → beautiful .numericText() rolling animation
            Text(formattedValue.whole)
                .font(.system(size: 50, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .tracking(-2)
                .fixedSize()
                .contentTransition(isScrubbing ? .identity : .numericText(countsDown: isDecreasing))
                .animation(isScrubbing ? .none : .default, value: formattedValue.whole)
            
            Text(".")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(-2)
                .accessibilityHidden(true)
            
            Text(formattedValue.decimal)
                .font(.system(size: 24, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.6))
                .tracking(-1)
                .fixedSize()
                .contentTransition(isScrubbing ? .identity : .numericText(countsDown: isDecreasing))
                .animation(isScrubbing ? .none : .default, value: formattedValue.decimal)
        }
        // Padding gives the digit rolling animation room to render without clipping
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
        .onChange(of: value) { oldValue, newValue in
            previousValue = oldValue
        }
        .onAppear {
            previousValue = value
        }
        .accessibilityLabel("Portfolio value")
        .accessibilityValue(value.formatted(.currency(code: "AUD")))
    }
}

// MARK: - InteractiveChartView is now in separate file
// See: InteractiveChartView.swift (~400 lines extracted for better maintainability)

// MARK: - Data Models
struct CapitalConcentrationBreakdown: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    let percentage: Double
}

struct PerformanceMetrics {
    let totalChange: Double
    let percentChange: Double
    let unrealizedGains: Double
    let initialValue: Double
}

// MARK: - Herd Composition View (Category Breakdown with Pie Chart)
// Debug: Shows category distribution with pie chart and detailed breakdown list
struct CapitalConcentrationView: View {
    let breakdown: [CapitalConcentrationBreakdown]
    let totalValue: Double
    
    // Debug: Color palette for pie chart segments (darker earthy, muted tones)
    private let chartColors: [Color] = [
        Color(red: 0.70, green: 0.45, blue: 0.30), // Dark terracotta
        Color(red: 0.45, green: 0.55, blue: 0.65), // Muted blue
        Color(red: 0.50, green: 0.60, blue: 0.45), // Dark sage
        Color(red: 0.75, green: 0.63, blue: 0.40), // Dark sand
        Color(red: 0.60, green: 0.50, blue: 0.63), // Deep lavender
        Color(red: 0.70, green: 0.50, blue: 0.45), // Brick rose
        Color(red: 0.45, green: 0.63, blue: 0.63), // Deep teal
        Color(red: 0.67, green: 0.57, blue: 0.43)  // Dark tan
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Herd Composition")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            // Debug: Pie chart showing category distribution
            if !breakdown.isEmpty {
                Chart {
                    ForEach(Array(breakdown.enumerated()), id: \.element.id) { index, item in
                        SectorMark(
                            angle: .value("Value", item.value),
                            innerRadius: .ratio(0.618), // Golden ratio for elegant donut
                            angularInset: 2.0 // Small gap between segments
                        )
                        .foregroundStyle(chartColors[index % chartColors.count])
                        .cornerRadius(4)
                        .accessibilityLabel("\(item.category)")
                        .accessibilityValue("\(item.percentage.formatted(.number.precision(.fractionLength(1)))) percent")
                    }
                }
                .frame(height: 200)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Category distribution chart")
            }
            
            // Debug: Category list with bars (existing design)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(breakdown.enumerated()), id: \.element.id) { index, item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            // Debug: Color indicator matching pie chart
                            RoundedRectangle(cornerRadius: 3)
                                .fill(chartColors[index % chartColors.count])
                                .frame(width: 12, height: 12)
                                .accessibilityHidden(true)
                            
                            Text(item.category)
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            Text(item.value, format: .currency(code: "AUD"))
                                .font(Theme.callout) // HIG: callout (16pt) for list values with many digits
                                .foregroundStyle(Theme.primaryText)
                                .accessibilityLabel("\(item.category) value")
                                .accessibilityValue(item.value.formatted(.currency(code: "AUD")))
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.primaryText.opacity(0.1))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(chartColors[index % chartColors.count])
                                    .frame(width: geometry.size.width * CGFloat(item.percentage / 100), height: 8)
                                    .accessibilityLabel("\(item.category) percentage")
                                    .accessibilityValue("\(item.percentage.formatted(.number.precision(.fractionLength(1)))) percent")
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(item.percentage, format: .number.precision(.fractionLength(1)))%")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Performance Metrics View
struct PerformanceMetricsView: View {
    let metrics: PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Change")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(metrics.totalChange, format: .currency(code: "AUD"))
                            .font(Theme.title3) // HIG: title3 (20pt) - primary emphasis without overwhelming
                            .foregroundStyle(metrics.totalChange >= 0 ? Theme.positiveChange : Theme.negativeChange)
                            .accessibilityLabel("Total change")
                            .accessibilityValue(metrics.totalChange.formatted(.currency(code: "AUD")))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Percent Change")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text("\(metrics.percentChange >= 0 ? "+" : "")\(metrics.percentChange, format: .number.precision(.fractionLength(1)))%")
                            .font(Theme.title3) // HIG: title3 (20pt) - primary emphasis without overwhelming
                            .foregroundStyle(metrics.percentChange >= 0 ? Theme.positiveChange : Theme.negativeChange)
                            .accessibilityLabel("Percent change")
                            .accessibilityValue("\(metrics.percentChange.formatted(.number.precision(.fractionLength(1)))) percent")
                    }
                }
                
                Divider()
                    .background(Theme.separator)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unrealized Gains")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(metrics.unrealizedGains, format: .currency(code: "AUD"))
                            .font(Theme.callout) // HIG: callout (16pt) for secondary metrics
                            .foregroundStyle(Theme.accent)
                            .accessibilityLabel("Unrealized gains")
                            .accessibilityValue(metrics.unrealizedGains.formatted(.currency(code: "AUD")))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Initial Value")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(metrics.initialValue, format: .currency(code: "AUD"))
                            .font(Theme.callout) // HIG: callout (16pt) for secondary metrics
                            .foregroundStyle(Theme.primaryText)
                            .accessibilityLabel("Initial value")
                            .accessibilityValue(metrics.initialValue.formatted(.currency(code: "AUD")))
                    }
                }
            }
        }
        .padding(Theme.cardPadding)
        .stitchedCard()
        .accessibilityElement(children: .contain)
    }
}


// MARK: - Empty Dashboard View
struct EmptyDashboardView: View {
    @Binding var showingAddAssetMenu: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: State for loading indicator during mock data generation
    @State private var isGeneratingData = false
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 80))
                    .foregroundStyle(Theme.accent.opacity(0.5))
                    .accessibilityHidden(true)
                
                Text("Add your first herd or individual animals to start tracking your livestock portfolio value in real-time")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                HapticManager.tap()
                showingAddAssetMenu = true
            }) {
                Text("Add Your First Herd")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(Theme.PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .accessibilityLabel("Add your first herd")
            .accessibilityHint("Opens the asset menu to add a herd.")
            
            // Debug: Temporary Add Mock Data button for easier development
            // TODO: Remove this button before production release
            Button(action: {
                HapticManager.tap()
                addMockData()
            }) {
                HStack(spacing: 8) {
                    if isGeneratingData {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chart.bar.fill")
                    }
                    Text(isGeneratingData ? "Generating..." : "Add Mock Data")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(Theme.SecondaryButtonStyle())
            .disabled(isGeneratingData)
            .padding(.horizontal, 40)
            .accessibilityLabel("Add mock demo data")
            .accessibilityHint("Generates 3 years of historical mock data for testing")
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea())
    }
    
    // Debug: Add 3-year historical mock data
    @MainActor
    private func addMockData() {
        isGeneratingData = true
        Task { @MainActor in
            await HistoricalMockDataService.shared.generate3YearHistoricalData(
                modelContext: modelContext,
                preferences: userPrefs
            )
            // Debug: Notify dashboard to refresh after data is added
            NotificationCenter.default.post(name: NSNotification.Name("DataCleared"), object: nil)
            isGeneratingData = false
            HapticManager.success()
        }
    }
}

// MARK: - Error State View
// Debug: Reusable error state component with retry action
struct ErrorStateView: View {
    let errorMessage: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red.opacity(0.7))
                .accessibilityHidden(true)
            
            Text("Something went wrong")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
            
            Text(errorMessage)
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                HapticManager.tap()
                retryAction()
            }) {
                Text("Try Again")
                    .font(Theme.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            }
            .buttonBorderShape(.roundedRectangle)
            .accessibilityLabel("Try again")
            .accessibilityHint("Retry loading the dashboard data")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Saleyard Selector
// Debug: HIG-compliant searchable sheet for saleyard selection (31+ items)
// Default (nil) uses each herd's configured saleyard, otherwise overrides all herds
struct SaleyardSelector: View {
    @Binding var selectedSaleyard: String?
    @State private var showingSaleyardSheet = false
    
    var body: some View {
        // Debug: Tappable card that opens searchable sheet (HIG pattern for long lists)
        Button(action: {
            HapticManager.tap()
            showingSaleyardSheet = true
        }) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Theme.accent)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saleyard")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText)
                    Text(selectedSaleyard ?? "Your Selected Saleyards")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(16)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain) // Debug: Prevent button highlight, keep custom styling
        .sheet(isPresented: $showingSaleyardSheet) {
            SaleyardSelectionSheet(selectedSaleyard: $selectedSaleyard)
        }
        .accessibilityLabel("Select saleyard")
        .accessibilityValue(selectedSaleyard ?? "Your selected saleyards")
        .accessibilityHint("Opens sheet to filter portfolio valuations by saleyard prices")
    }
}

// MARK: - Saleyard Selection Sheet
// Debug: HIG-compliant searchable sheet for selecting from 31+ saleyards
// Follows iOS patterns: search bar, grouped list, clear selection action
struct SaleyardSelectionSheet: View {
    @Binding var selectedSaleyard: String?
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]
    @State private var searchText = ""
    
    // Debug: Get user preferences for filtered saleyards
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    // Debug: Filter saleyards based on search text and user preferences
    private var filteredSaleyards: [String] {
        let enabledSaleyards = userPrefs.filteredSaleyards
        if searchText.isEmpty {
            return enabledSaleyards
        } else {
            return enabledSaleyards.filter { 
                $0.localizedCaseInsensitiveContains(searchText) 
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Debug: Default option section - always visible at top
                Section {
                    Button(action: {
                        HapticManager.tap()
                        selectedSaleyard = nil
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Selected Saleyards")
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                Text("Uses each herd's configured saleyard")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            
                            Spacer()
                            
                            if selectedSaleyard == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accent)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear) // Debug: Remove default list row background
                } header: {
                    Text("Default")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                
                // Debug: All saleyards section - filterable by search
                Section {
                    ForEach(filteredSaleyards, id: \.self) { saleyard in
                        Button(action: {
                            HapticManager.tap()
                            selectedSaleyard = saleyard
                            dismiss()
                        }) {
                            HStack {
                                Text(saleyard)
                                    .font(Theme.body)
                                    .foregroundStyle(Theme.primaryText)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                if selectedSaleyard == saleyard {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.accent)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear) // Debug: Remove default list row background
                    }
                } header: {
                    Text("Compare with Specific Saleyard")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                
                // Debug: Show helpful message if no results
                if filteredSaleyards.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.secondaryText.opacity(0.5))
                            
                            Text("No saleyards found")
                                .font(Theme.body)
                                .foregroundStyle(Theme.secondaryText)
                            
                            Text("Try a different search term")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear) // Debug: Remove default list row background
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search saleyards"
            )
            .navigationTitle("Select Saleyard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundColor)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Custom Date Range Sheet
// Debug: HIG-compliant sheet for selecting custom date range with graphical date pickers
struct CustomDateRangeSheet: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Binding var timeRange: TimeRange
    @Environment(\.dismiss) private var dismiss
    
    // Debug: Local state for date pickers, initialized with existing values or defaults
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    
    init(startDate: Binding<Date?>, endDate: Binding<Date?>, timeRange: Binding<TimeRange>) {
        self._startDate = startDate
        self._endDate = endDate
        self._timeRange = timeRange
        
        // Debug: Initialize with existing dates or reasonable defaults
        let calendar = Calendar.current
        let now = Date()
        let defaultStart = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        _tempStartDate = State(initialValue: startDate.wrappedValue ?? defaultStart)
        _tempEndDate = State(initialValue: endDate.wrappedValue ?? now)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Start Date",
                        selection: $tempStartDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                } header: {
                    Text("From")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Section {
                    DatePicker(
                        "End Date",
                        selection: $tempEndDate,
                        in: tempStartDate...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                } header: {
                    Text("To")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Section {
                    // Debug: Show date range summary
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Range")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                            Text(dateRangeSummary)
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .foregroundStyle(Theme.secondaryText)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        HapticManager.tap()
                        // Debug: Apply selected dates and set time range to custom
                        startDate = tempStartDate
                        endDate = tempEndDate
                        timeRange = .custom
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                    .fontWeight(.semibold)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundColor)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // Debug: Format date range as readable string
    private var dateRangeSummary: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let days = Calendar.current.dateComponents([.day], from: tempStartDate, to: tempEndDate).day ?? 0
        
        return "\(formatter.string(from: tempStartDate)) - \(formatter.string(from: tempEndDate)) (\(days + 1) days)"
    }
}



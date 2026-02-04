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
import UniformTypeIdentifiers

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    // Performance: Only query herds (headCount > 1), not individual animals
    @Query(filter: #Predicate<HerdGroup> { $0.headCount > 1 }) private var herds: [HerdGroup]
    @Query private var preferences: [UserPreferences]
    
    // Debug: Use 'let' with @Observable instead of @StateObject (modern pattern)
    // ValuationEngine also holds session state that persists across view recreations
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
    @State private var isReorderMode = false // Debug: Long-press to enable card reordering
    @State private var draggedCardId: String? = nil // Debug: Track currently dragged card
    
    // Debug: Smart refresh tracking - optimized for daily MLA price updates
    // MLA updates once daily at 1:30am, so no time-based polling needed
    // Only fetch when: first load (cache stale check), user adds/edits herd, manual refresh
    // Note: Session state tracking moved to SessionState.shared (persists across view recreations)
    
    // Debug: Track herd changes to prevent false onChange triggers on view rebuild
    @State private var trackedHerdCount: Int = -1 // -1 = uninitialized
    @State private var trackedHerdUpdateTime: Date? = nil
    
    // Debug: Track if we need to show animation on next load (dopamine hit)
    @State private var shouldAnimateValue = false
    
    
    // Performance: Race condition prevention - ensures only one data load at a time
    private let loadCoordinator = LoadCoordinator()
    
    // Debug: Bottom fade overlay to blend image into base background color
    private var backgroundImageBottomFadeOverlay: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "1B150E"), location: 0.0),
                .init(color: Color(hex: "1B150E"), location: 0.45),
                .init(color: Color(hex: "1B150E").opacity(0.0), location: 1.0)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    // Debug: Render background image with bottom fade aligned to image edge
    // Apple-style: compute fade using the same image geometry (scale + offset)
    @ViewBuilder
    private func backgroundImageWithBottomFade<Content: View>(
        scale: CGFloat,
        intensity: CGFloat,
        verticalOffset: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: .topLeading) {
            content()
            
            GeometryReader { geometry in
                // Debug: Match UIKit image layout math so fade starts at image bottom edge
                let imageHeight = (geometry.size.height * scale) + (intensity * 2)
                let imageBottom = verticalOffset + imageHeight
                let fadeHeight = imageHeight * 0.4
                
                backgroundImageBottomFadeOverlay
                    .frame(height: fadeHeight)
                    .frame(maxWidth: .infinity)
                    .position(
                        x: geometry.size.width / 2,
                        y: imageBottom - (fadeHeight / 2) + 1
                    )
                    .allowsHitTesting(false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            mainContentWithModifiers
                .onAppear {
                    print("🚀🚀🚀 DASHBOARD VIEW APPEARED - NEW CODE IS RUNNING 🚀🚀🚀")
                    print("🚀 dashboardHasLoadedThisSession = \(valuationEngine.dashboardHasLoadedThisSession)")
                    print("🚀 trackedHerdCount = \(trackedHerdCount)")
                    print("🚀 herds.count = \(herds.count)")
                }
        }
    }
    
    // Debug: Separate view with all modifiers to reduce complexity
    @ViewBuilder
    private var mainContentWithModifiers: some View {
        let contentWithNav = mainContent
            .navigationBarTitleDisplayMode(.inline)
            
        
        contentWithNav
            .task(id: valuationEngine.dashboardHasLoadedThisSession) {
                // Performance: .task with ID only runs when dashboardHasLoadedThisSession changes
                // ValuationEngine persists across view recreations (tab switches, navigation)
                // This prevents reloading when: preferences change, tab switches, view rebuilds
                // Task runs when: app first launches (dashboardHasLoadedThisSession = false)
                // Task skips when: returning from settings, switching tabs (dashboardHasLoadedThisSession = true)
                
                // Debug: Initialize tracked values on first appearance to prevent false onChange triggers
                if trackedHerdCount == -1 {
                    trackedHerdCount = herds.count
                    trackedHerdUpdateTime = herds.map(\.updatedAt).max()
                    #if DEBUG
                    print("📊 Initialized tracked values: count=\(trackedHerdCount), updateTime=\(trackedHerdUpdateTime?.formatted() ?? "nil")")
                    #endif
                }
                
                // Debug: User is viewing dashboard - prepare for dopamine hit animation
                shouldAnimateValue = true
                
                await loadDataIfNeeded(force: false)
            }
            .onDisappear {
                // Performance: .task's automatic cancellation will stop ongoing work
                // LoadCoordinator prevents race conditions if multiple loads overlap
                #if DEBUG
                print("📊 DashboardView disappeared - task will auto-cancel")
                #endif
                
                // Debug: Save current portfolio value when leaving dashboard
                // This ensures next visit shows old value → new value animation for dopamine hit
                let prefs = preferences.first ?? UserPreferences()
                prefs.lastPortfolioValue = portfolioValue
                prefs.lastPortfolioUpdateDate = Date()
                #if DEBUG
                print("💰 Saved portfolio value on disappear: \(portfolioValue)")
                #endif
            }
            .refreshable {
                // Debug: Explicit user pull-to-refresh always forces reload
                // LoadCoordinator automatically cancels previous load before starting new one
                // Don't animate on pull-to-refresh - user is just refreshing, not expecting dopamine hit
                shouldAnimateValue = false
                await loadDataIfNeeded(force: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DataCleared"))) { _ in
                Task {
                    await MainActor.run {
                        self.valuationHistory = []
                        self.portfolioValue = 0.0
                        self.baseValue = 0.0
                        self.valuationEngine.dashboardHasLoadedThisSession = false // Force reload after clearing data
                        #if DEBUG
                        print("🔵 Dashboard state reset after data clear")
                        #endif
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
            .onChange(of: herds.count) { oldCount, newCount in
                // Debug: Track herd count changes to detect add/remove operations
                // Only trigger if count actually changed from last tracked value
                guard newCount != trackedHerdCount else { return }
                
                trackedHerdCount = newCount
                
                // Debug: Herd count changed - user added/removed herd, show dopamine hit animation
                Task {
                    await MainActor.run {
                        // Debug: Reset display value to last saved before recalculating
                        let prefs = self.preferences.first ?? UserPreferences()
                        self.displayValue = prefs.lastPortfolioValue
                        self.shouldAnimateValue = true
                        #if DEBUG
                        print("💰 Herd count changed (\(oldCount) → \(newCount)) - reset display to \(self.displayValue), animation enabled")
                        #endif
                    }
                    await loadDataIfNeeded(force: true)
                }
            }
            .onChange(of: herds.map(\.updatedAt).max()) { oldValue, newValue in
                // Debug: Track herd update times to detect edit operations
                // Only trigger if update time actually changed from last tracked value
                guard newValue != trackedHerdUpdateTime else {
                    #if DEBUG
                    print("💰 Dashboard: Herd update time unchanged (view rebuild), skipping reload")
                    #endif
                    return
                }
                guard herds.count > 0 else { return }
                
                trackedHerdUpdateTime = newValue
                
                // Debug: Herd was edited (breed, saleyard, weight, etc.) - recalculate with cached prices
                #if DEBUG
                print("💰 Dashboard: Herd edited (breed/saleyard/weight), recalculating with cached prices...")
                #endif
                
                Task {
                    // Don't animate - user is editing, not adding assets
                    shouldAnimateValue = false
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
                // Don't animate - user is comparing prices, not adding assets
                Task {
                    shouldAnimateValue = false
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
            .background(Theme.background.ignoresSafeArea())
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
            // Debug: Base background color behind dashboard image for flatter look
            Color(hex: "1B150E")
                .ignoresSafeArea()
            
            // Debug: Background image with parallax effect (like iOS home screen wallpapers)
            // Uses user's selected background from preferences (built-in or custom)
            // Only show background if backgroundImageName is not nil
            if let imageName = backgroundImageName {
                // Debug: Slightly reduce background image opacity for flatter look
                let backgroundImageOpacity = Theme.backgroundImageOpacity * 0.6
                if userPrefs.isCustomBackground {
                    // Debug: Load custom background from document directory
                    backgroundImageWithBottomFade(
                        scale: 0.5,
                        intensity: 25,
                        verticalOffset: -60
                    ) {
                        CustomParallaxImageView(
                            imageName: imageName,
                            intensity: 25,                          // Movement amount (20-40)
                            opacity: backgroundImageOpacity,        // Background opacity (10% reduced)
                            scale: 0.5,                             // Image takes 50% of screen height
                            verticalOffset: -60,                    // Move image up to show more middle/lower area
                            blur: 0                                 // BG Image Blur radius
                        )
                    }
                    .id("custom_\(imageName)_\(backgroundImageTrigger)") // Debug: Force view recreation on background change
                    .onAppear {
                        #if DEBUG
                        print("🖼️ DashboardView: Applied bottom fade (shared container) to custom background")
                        #endif
                    }
                } else {
                    // Debug: Load built-in background from Assets
                    backgroundImageWithBottomFade(
                        scale: 0.5,
                        intensity: 25,
                        verticalOffset: -60
                    ) {
                        ParallaxImageView(
                            imageName: imageName,
                            intensity: 25,                          // Movement amount (20-40)
                            opacity: backgroundImageOpacity,        // Background opacity (10% reduced)
                            scale: 0.5,                             // Image takes 50% of screen height
                            verticalOffset: -60,                    // Move image up to show more middle/lower area
                            blur: 0                                 // BG Image Blur radius
                        )
                    }
                    .id("builtin_\(imageName)_\(backgroundImageTrigger)") // Debug: Force view recreation on background change
                    .onAppear {
                        #if DEBUG
                        print("🖼️ DashboardView: Applied bottom fade (shared container) to built-in background")
                        #endif
                    }
                }
            } else {
                // Debug: Solid dark brown background when no image is selected.
                Color(hex: "1B150E")
                    .ignoresSafeArea()
                    .id("glow_\(backgroundImageTrigger)") // Debug: Force view recreation on background change
            }
            
            // Debug: Fixed portfolio value header - stays in place while content scrolls beneath
            VStack(spacing: 0) {
                // Debug: Offline indicator pill above the value card
                if valuationEngine.isOffline {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Offline - Showing cached prices")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(.top, 10) // Debug: Space from top safe area
                    .transition(.opacity.animation(.easeInOut)) // Debug: Smooth fade in/out
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                PortfolioValueCard(
                    value: selectedValue ?? displayValue,
                    change: isScrubbing ? (selectedValue ?? displayValue) - baseValue : (portfolioValue - baseValue),
                    baseValue: baseValue,
                    isLoading: isLoading,
                    isScrubbing: isScrubbing,
                    isUpdating: isUpdatingValue
                )
                .padding(.horizontal, Theme.cardPadding)
                .padding(.top, 54) // Debug: Increased to align with Portfolio page value positioning
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total portfolio value")
                .accessibilityValue("\(portfolioValue.formatted(.currency(code: "AUD")))")
                
                Spacer()
            }
            
            // Debug: iOS 26 page structure - single-axis vertical scroll only (Apple HIG: no horizontal drag)
            // Fixed header above; scroll content below with no 2D dragging of the card
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Debug: Top spacing to position content panel lower and clear the fixed header
                    Color.clear
                        .frame(height: 230)
                    
                    contentPanel
                }
                .frame(minWidth: 0, maxWidth: .infinity) // HIG: content width constrained so no horizontal scroll
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .vertical) // iOS 16.4+: no bounce when content is shorter than screen
        }
    }
    
    // Debug: Rounded panel with all dashboard content (displayed in user's custom order)
    @ViewBuilder
    private var contentPanel: some View {
        let userPrefs = preferences.first ?? UserPreferences()
        
        VStack(spacing: 20) { // Apple HIG: 20pt spacing between sections
            // Debug: Show skeleton loaders during initial load
            if isLoading {
                // Chart skeleton
                DashboardChartSkeleton()
                    .padding(.horizontal, Theme.cardPadding)
                
                // Dashboard card skeletons
                ForEach(0..<3, id: \.self) { _ in
                    DashboardCardSkeleton()
                        .padding(.horizontal, Theme.cardPadding)
                }
            } else {
                // Debug: Display cards in user's custom order from preferences
                ForEach(userPrefs.dashboardCardOrder, id: \.self) { cardId in
                    // Debug: Render each card type inline to maintain access to @State bindings
                    if userPrefs.isCardVisible(cardId) {
                        switch cardId {
                        case "performanceChart":
                            dashboardCardWrapper(cardId: cardId, isReorderable: false) {
                                performanceChartCard
                            }
                        case "quickActions":
                            dashboardCardWrapper(cardId: cardId, isReorderable: true) {
                                saleyardSelectorCard
                            }
                        // Debug: Removed herd performance card - chart at top shows performance over time
                        // case "marketSummary":
                        //     dashboardCardWrapper(cardId: cardId, isReorderable: true) {
                        //         marketPulseCard
                        //     }
                        case "recentActivity":
                            dashboardCardWrapper(cardId: cardId, isReorderable: true) {
                                herdDynamicsCard
                            }
                        case "herdComposition":
                            if !capitalConcentration.isEmpty {
                                dashboardCardWrapper(cardId: cardId, isReorderable: true) {
                                    capitalConcentrationCard
                                }
                            }
                        default:
                            EmptyView()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20) // Apple HIG: Consistent 20pt padding
        .padding(.bottom, 100)
        .background(
            // Debug: iOS 26 HIG - Panel background using native UnevenRoundedRectangle
            // Uses sheetCornerRadius (32pt) for large panel surfaces, matching iOS sheet standards
            UnevenRoundedRectangle(
                topLeadingRadius: Theme.sheetCornerRadius,
                topTrailingRadius: Theme.sheetCornerRadius,
                style: .continuous
            )
            .fill(Theme.background)

        )
    }
    
    // MARK: - Individual Card Views
    // Debug: Separate computed properties for each dashboard card to maintain access to @State bindings
    
    @ViewBuilder
    private var performanceChartCard: some View {
        // Debug: Unified card background for chart + range selector
        VStack(spacing: 0) {
            // Debug: Range selector pill only (no title bar heading).
            HStack {
                Spacer()
                DashboardTimeRangePill(label: dashboardTimeRangeLabel) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button {
                            HapticManager.tap()
                            if range == .custom {
                                showingCustomDatePicker = true
                            } else {
                                timeRange = range
                            }
                        } label: {
                            HStack {
                                Text(range.rawValue)
                                if timeRange == range {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.clear)
            
            // Debug: Always show chart, even for new portfolios
            // Chart automatically handles showing growth from zero to current value
            InteractiveChartView(
                data: filteredHistory,
                selectedDate: $selectedDate,
                selectedValue: $selectedValue,
                isScrubbing: $isScrubbing,
                timeRange: $timeRange,
                // Debug: Provide custom range dates so labels match date picker selection
                customStartDate: customStartDate,
                customEndDate: customEndDate,
                baseValue: baseValue,
                onValueChange: { newValue, change in
                    portfolioChange = change
                }
            )
            .clipped() // Debug: Clip chart content to prevent overflow beyond bounds
            .padding(.top, -32) // Debug: Compensate for internal date hover pill spacer
            .padding(.horizontal, 0) // Debug: Chart line should reach card edges
            .accessibilityHint("Drag your finger across the chart to explore values over time.")
            
            // Debug: Keep time range selector visible when overall history exists
            // This prevents the selector from disappearing when a custom range is empty
//            if valuationHistory.count >= 2 {
//                TimeRangeSelector(
//                    timeRange: $timeRange,
//                    customStartDate: $customStartDate,
//                    customEndDate: $customEndDate,
//                    showingCustomDatePicker: $showingCustomDatePicker
//                )
//                .padding(.horizontal, Theme.dashboardCardPadding)
//                .padding(.top, 6) // Debug: Keep selector below date labels
//                .padding(.bottom, 12) // Debug: Breathing room above rounded corners
//                .accessibilityElement(children: .contain)
//                .accessibilityLabel("Time range selector")
//            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.secondaryBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .padding(.horizontal, Theme.cardPadding)
    }
    
    @ViewBuilder
    private var saleyardSelectorCard: some View {
        // Debug: Saleyard selector without card wrapper - Apple HIG pattern
        VStack(spacing: 16) {
            SaleyardSelector(selectedSaleyard: $selectedSaleyard)
                .padding(.horizontal, Theme.cardPadding)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Saleyard selector")
            
            // Debug: Info note - Apple HIG pattern for supplementary info
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText.opacity(0.5))
                Text("Market prices are based on available saleyard benchmark data. Additional sale channels will be progressively integrated to improve pricing accuracy.")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.cardPadding)
            .padding(.horizontal, 8)
        }
    }
    
    // Debug: Removed herd performance card - chart at top shows performance over time
    // @ViewBuilder
    // private var marketPulseCard: some View {
    //     MarketPulseView(showsDashboardHeader: true)
    //         .cardStyle()
    //         .padding(.horizontal, Theme.cardPadding)
    //         .accessibilityElement(children: .contain)
    //         .accessibilityLabel("Herd performance")
    // }
    
    @ViewBuilder
    private var herdDynamicsCard: some View {
        HerdDynamicsView(
            showsDashboardHeader: true,
            herds: herds.filter { !$0.isSold }
        )
            .cardStyle()
            .padding(.horizontal, Theme.cardPadding)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Growth and mortality")
    }
    
    @ViewBuilder
    private var capitalConcentrationCard: some View {
        CapitalConcentrationView(
            showsDashboardHeader: true,
            breakdown: capitalConcentration,
            totalValue: portfolioValue
        )
            .cardStyle()
            .padding(.horizontal, Theme.cardPadding)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Herd composition")
    }

    // MARK: - Dashboard Card Reordering
    @ViewBuilder
    private func dashboardCardWrapper<Content: View>(
        cardId: String,
        isReorderable: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .onTapGesture {
                // Debug: Tap to exit reorder mode without dragging.
                if isReorderMode {
                    isReorderMode = false
                }
            }
            .onDrag {
                // Debug: Drag starts with long-press gesture (system default).
                guard isReorderable else { return NSItemProvider() }
                isReorderMode = true
                draggedCardId = cardId
                return NSItemProvider(object: cardId as NSString)
            }
            .onDrop(
                of: [.text],
                delegate: CardReorderDropDelegate(
                    itemId: cardId,
                    draggedCardId: $draggedCardId,
                    isReorderMode: $isReorderMode,
                    onMove: moveDashboardCard
                )
            )
    }

    // Debug: Move cards within user preferences order.
    private func moveDashboardCard(from sourceId: String, to destinationId: String) {
        guard let prefs = preferences.first else { return }
        var order = prefs.dashboardCardOrder
        guard let fromIndex = order.firstIndex(of: sourceId),
              let toIndex = order.firstIndex(of: destinationId),
              fromIndex != toIndex else { return }
        
        // Debug: Animate card reordering for smooth iOS HIG-style shuffle.
        withAnimation(.snappy(duration: 0.22)) {
            order.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
            prefs.dashboardCardOrder = order
        }
    }

    // Debug: Time range label for the dashboard title bar pill.
    private var dashboardTimeRangeLabel: String {
        switch timeRange {
        case .custom:
            guard let start = customStartDate, let end = customEndDate else { return "Custom" }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        case .day:
            return "1d"
        case .week:
            return "7d"
        case .month:
            return "1m"
        case .year:
            return "1y"
        case .all:
            return "All"
        }
    }
    
    private var filteredHistory: [ValuationDataPoint] {
        guard !valuationHistory.isEmpty else { return [] }
        let calendar = Calendar.current
        let now = Date()
        
        // Debug: Helper function to ensure we always have at least 2 points for line drawing
        // Includes the last point before cutoff so chart shows continuous line
        func filterWithAnchor(cutoffDate: Date) -> [ValuationDataPoint] {
            let filtered = valuationHistory.filter { $0.date >= cutoffDate }
            
            // If we have filtered points, also include the last point before cutoff
            // This ensures the line extends to show the value at the start of the range
            if !filtered.isEmpty {
                // Find the last point before the cutoff date
                if let anchorPoint = valuationHistory.last(where: { $0.date < cutoffDate }) {
                    // Only add if not already included
                    if !filtered.contains(where: { $0.date == anchorPoint.date }) {
                        #if DEBUG
                        print("📊 Added anchor point: \(anchorPoint.date.formatted()) ($\(anchorPoint.value))")
                        #endif
                        return [anchorPoint] + filtered
                    }
                }
            }
            
            #if DEBUG
            print("📊 Filtered to \(filtered.count) points (cutoff: \(cutoffDate.formatted()))")
            if let first = filtered.first, let last = filtered.last {
                print("📊 Showing: \(first.date.formatted()) ($\(first.value)) to \(last.date.formatted()) ($\(last.value))")
            }
            #endif
            
            return filtered
        }
        
        switch timeRange {
        case .custom:
            // Debug: Filter by custom date range if set
            guard let startDate = customStartDate, let _ = customEndDate else {
                return valuationHistory
            }
            return filterWithAnchor(cutoffDate: startDate)
        case .day:
            // Debug: Show last 24 hours of data with anchor point
            let cutoffDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            return filterWithAnchor(cutoffDate: cutoffDate)
        case .week:
            let cutoffDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return filterWithAnchor(cutoffDate: cutoffDate)
        case .month:
            let cutoffDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return filterWithAnchor(cutoffDate: cutoffDate)
        case .year:
            let cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return filterWithAnchor(cutoffDate: cutoffDate)
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
                // Debug: Simplified load logic - no time-based polling needed
                // MLA updates daily at 1:30am, ValuationEngine checks cache freshness
                let (needsRefresh, isFirstLoad) = await MainActor.run {
                    let isFirst = !self.valuationEngine.dashboardHasLoadedThisSession
                    
                    // Force refresh (user pull-to-refresh, herd added/edited)
                    if force {
                        #if DEBUG
                        print("📊 Force refresh requested (user action)")
                        #endif
                        return (true, isFirst)
                    }
                    
                    // First time loading this session
                    // ValuationEngine will check if cache is from before 1:30am MLA update
                    if isFirst {
                        #if DEBUG
                        print("📊 First load - ValuationEngine will check if prices are from before 1:30am update")
                        #endif
                        return (true, isFirst)
                    }
                    
                    // Already loaded data this session - skip reload
                    // User actions (add/edit herd) will trigger force=true refresh
                    #if DEBUG
                    print("📊 Already loaded this session - skipping reload (no time-based polling)")
                    #endif
                    return (false, isFirst)
                }
                
                guard needsRefresh else {
                    #if DEBUG
                    print("📊 Skipping reload - data is fresh")
                    #endif
                    return
                }
                
                // Debug: Mark as loading IMMEDIATELY to prevent duplicate loads from view recreations
                // This must happen before any async work that could be cancelled
                if isFirstLoad {
                    await MainActor.run {
                        self.valuationEngine.dashboardHasLoadedThisSession = true
                        #if DEBUG
                        print("✅ Dashboard marked as loaded IMMEDIATELY (prevents duplicate loads)")
                        #endif
                    }
                }
                
                // Debug: STEP 1 - Check for calving events and auto-generate calves
                // This must happen BEFORE calculating portfolio value so new calves are included
                await CalvingManager.shared.processCalvingEvents(herds: Array(herds), modelContext: modelContext)
                
                // Debug: STEP 2 - Convert manual "calves at foot" text entries to real HerdGroup entities
                // This ensures all calves (auto and manual) are tracked with proper DWG (0.9 kg/day for cattle)
                await CalvingManager.shared.processManualCalvesAtFoot(herds: Array(herds), modelContext: modelContext)
                
                // Debug: Prepare for animation - always show cached value first when animation flag is set
                await MainActor.run {
                    let prefs = self.preferences.first ?? UserPreferences()
                    
                    // Only reset displayValue if we haven't already (onChange might have done it)
                    if self.shouldAnimateValue && self.displayValue != prefs.lastPortfolioValue {
                        self.displayValue = prefs.lastPortfolioValue
                        #if DEBUG
                        print("💰 Animation mode: displayValue set to cached \(self.displayValue)")
                        #endif
                    } else if isFirstLoad {
                        self.displayValue = prefs.lastPortfolioValue
                        #if DEBUG
                        print("💰 First load: displayValue set to cached \(self.displayValue)")
                        #endif
                    }
                    
                    // Load cached chart data immediately for instant display
                    self.loadCachedChartData()
                }
                
                // Debug: Now load fresh data
                await self.loadValuations()
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
        // Debug: BATCH PREFETCH - Fetch ALL prices in ONE API call before calculations
        // This reduces hundreds of individual API calls to just ONE
        await valuationEngine.prefetchPricesForHerds(activeHerds)
        
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
        
        // Debug: Dopamine hit animation - run in PARALLEL so chart loads instantly
        let valueDifference = abs(valuations - lastKnownValue)
        let shouldAnimate = await MainActor.run { self.shouldAnimateValue }
        
        #if DEBUG
        print("💰 Value difference: $\(valueDifference) (lastKnown: $\(lastKnownValue), new: $\(valuations)), shouldAnimate: \(shouldAnimate)")
        #endif
        
        if shouldAnimate && valueDifference > 1.0 {
            // Debug: Run dopamine hit animation in parallel - doesn't block chart loading
            #if DEBUG
            print("💰 Starting dopamine hit animation in parallel: $\(lastKnownValue) → $\(valuations)")
            #endif
            Task {
                await updateDisplayValueWithDelay(newValue: valuations, lastValue: lastKnownValue)
                
                // Debug: Animation complete - disable flag until next view appearance
                await MainActor.run {
                    self.shouldAnimateValue = false
                }
            }
        } else {
            // Debug: No animation needed - update immediately
            #if DEBUG
            if !shouldAnimate {
                print("💰 Updating immediately (animation disabled)")
            } else {
                print("💰 Updating immediately (no significant change)")
            }
            #endif
            await MainActor.run {
                self.displayValue = valuations
                self.shouldAnimateValue = false
            }
        }
        
        // Debug: DON'T save portfolio value here - only save when user leaves dashboard (onDisappear)
        // This ensures every return to dashboard shows old → new value animation for dopamine hit
        
        // Debug: Chart loading runs immediately in parallel with value animation
        // Chart shows instantly while the big number animates independently
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
        // Debug: If no chart data visible, add starting point + today's value immediately
        let hasVisibleData = await MainActor.run { !self.valuationHistory.isEmpty }
        
        if !hasVisibleData {
            #if DEBUG
            print("📊 No visible data - adding starting point and current value for chart")
            #endif
            // Debug: Find the earliest herd creation date
            let earliestHerdDate = activeHerds.map { $0.createdAt }.min() ?? Date()
            
            // Debug: Add starting point at herd creation (value = 0) + current value
            // This ensures chart shows growth from zero to current value for new portfolios
            await MainActor.run {
                self.valuationHistory = [
                    ValuationDataPoint(
                        date: earliestHerdDate,
                        value: 0,
                        physicalValue: 0,
                        breedingAccrual: 0
                    ),
                    ValuationDataPoint(
                        date: Date(),
                        value: portfolioValue,
                        physicalValue: portfolioValue,
                        breedingAccrual: self.unrealizedGains
                    )
                ]
            }
        }
        
        // Debug: Now load full history (will replace the two points or cached data)
        #if DEBUG
        print("📊 Loading full historical data...")
        #endif
        await loadFullHistory(activeHerds: activeHerds, prefs: prefs, endDate: Date())
    }
    
    // Debug: Load complete historical data (up to 3 years)
    // Performance: Now cancellable to prevent wasted CPU when user navigates away
    private func loadFullHistory(activeHerds: [HerdGroup], prefs: UserPreferences, endDate: Date) async {
        let calendar = Calendar.current
        
        // Debug: Get ALL herds (including sold ones) for historical calculations
        let allHerds = herds
        
        // Debug: Get earliest herd creation date and normalize to start of day
        guard let earliestHerdDate = allHerds.map({ $0.createdAt }).min() else {
            #if DEBUG
            print("📊 No herds found, skipping history load")
            #endif
            return
        }
        
        // Debug: Normalize dates to start of day to avoid time-based issues
        let startOfEarliestDay = calendar.startOfDay(for: earliestHerdDate)
        let startOfToday = calendar.startOfDay(for: endDate)
        
        // Debug: Calculate days since earliest herd was created
        let daysFromStart = calendar.dateComponents([.day], from: startOfEarliestDay, to: startOfToday).day ?? 0
        let totalDays = min(daysFromStart + 1, 365) // Max 1 year of history
        
        var history: [ValuationDataPoint] = []
        
        #if DEBUG
        print("📊 Loading history: \(totalDays) days from \(startOfEarliestDay.formatted(.dateTime.month().day().year())) to \(startOfToday.formatted(.dateTime.month().day().year()))")
        #endif
        
        // Debug: Load all historical data with granular daily data
        // Daily for last 30 days, weekly for older data (up to 1 year)
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
            
            // Debug: Daily for last 30 days, weekly for older dates
            let shouldInclude = dayOffset <= 30 || dayOffset % 7 == 0
            if !shouldInclude {
                continue
            }
            
            // Debug: Calculate date at end of day (11:59 PM) for accurate "as of date" valuation
            guard let dateAtStartOfDay = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday) else { continue }
            guard let dateAtEndOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: dateAtStartOfDay) else { continue }
            
            // Debug: Filter herds that were active on this specific date
            // Include herds that:
            // 1. Were created on or before this date
            // 2. Were NOT sold, OR were sold AFTER this date
            let activeHerdsForDate = allHerds.filter { herd in
                let herdStartDay = calendar.startOfDay(for: herd.createdAt)
                let wasCreatedByThisDate = herdStartDay <= dateAtStartOfDay
                
                // Debug: Check if herd was sold after this date (or not sold at all)
                let wasActiveOnThisDate: Bool
                if let soldDate = herd.soldDate {
                    let soldDay = calendar.startOfDay(for: soldDate)
                    wasActiveOnThisDate = soldDay > dateAtStartOfDay
                } else {
                    wasActiveOnThisDate = true // Not sold, so still active
                }
                
                return wasCreatedByThisDate && wasActiveOnThisDate
            }
            
            // Debug: Track herds and calculate even if empty (will show $0 or previous value)
            #if DEBUG
            if dayOffset <= 7 {
                let soldToday = allHerds.filter { herd in
                    if let soldDate = herd.soldDate {
                        let soldDay = calendar.startOfDay(for: soldDate)
                        return soldDay == dateAtStartOfDay
                    }
                    return false
                }
                if !soldToday.isEmpty {
                    print("📊 Day \(dayOffset): \(dateAtStartOfDay.formatted(.dateTime.month().day())) - \(soldToday.count) herd(s) sold today! Portfolio will dip.")
                }
            }
            #endif
            
            guard !activeHerdsForDate.isEmpty else {
                #if DEBUG
                if dayOffset <= 7 {
                    print("📊 Day \(dayOffset): \(dateAtStartOfDay.formatted(.dateTime.month().day())) = $0 (0 herds active)")
                }
                #endif
                continue
            }
            
            // Debug: Parallel valuation calculation for all herds at this date
            let dayValuations = await withTaskGroup(of: (physical: Double, breeding: Double, total: Double).self, returning: (physical: Double, breeding: Double, total: Double).self) { group in
                var totals = (physical: 0.0, breeding: 0.0, total: 0.0)
                for herd in activeHerdsForDate {
                    group.addTask { @MainActor [modelContext] in
                        let valuation = await self.valuationEngine.calculateHerdValue(
                            herd: herd,
                            preferences: prefs,
                            modelContext: modelContext,
                            asOfDate: dateAtEndOfDay,
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
                date: dateAtEndOfDay,
                value: dayValuations.total,
                physicalValue: dayValuations.physical,
                breedingAccrual: dayValuations.breeding
            ))
            
            #if DEBUG
            if dayOffset <= 7 || dayOffset % 7 == 0 {
                print("📊 Day \(dayOffset): \(dateAtStartOfDay.formatted(.dateTime.month().day())) = $\(String(format: "%.0f", dayValuations.total)) (\(activeHerdsForDate.count) herds)")
            }
            #endif
        }
        
        // Debug: Ensure chart has at least 2 points to display a line
        // If we only have 1 point (brand new portfolio), add a starting point at $0
        if history.count == 1, let firstPoint = history.first {
            let startPoint = ValuationDataPoint(
                date: startOfEarliestDay,
                value: 0,
                physicalValue: 0,
                breedingAccrual: 0
            )
            // Insert at beginning if different from first point
            if startPoint.date < firstPoint.date {
                history.insert(startPoint, at: 0)
                #if DEBUG
                print("📊 Added starting point at $0 for chart display")
                #endif
            }
        }
        
        // Debug: Calculate day-ago value for 24h change display
        let dayAgo = calendar.date(byAdding: .hour, value: -24, to: startOfToday) ?? startOfToday
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
            print("📊 ============================================")
            print("📊 Full history loaded: \(history.count) data points")
            if let first = history.first, let last = history.last {
                print("📊 Date range: \(first.date.formatted(.dateTime.month().day())) ($\(String(format: "%.0f", first.value))) to \(last.date.formatted(.dateTime.month().day())) ($\(String(format: "%.0f", last.value)))")
                let totalChange = last.value - first.value
                let percentChange = first.value > 0 ? (totalChange / first.value * 100) : 0
                print("📊 Total change: $\(String(format: "%.0f", totalChange)) (\(String(format: "%.1f", percentChange))%)")
            }
            print("📊 Today's value: $\(String(format: "%.0f", currentPortfolioValue))")
            print("📊 ============================================")
            #endif
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

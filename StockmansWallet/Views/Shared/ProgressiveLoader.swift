//
//  ProgressiveLoader.swift
//  StockmansWallet
//
//  Progressive loading indicators for smooth data loading UX
//  Debug: Provides shimmer effect and skeleton loaders for cards and content
//

import SwiftUI

// MARK: - Shimmer Effect Modifier
/// Debug: Animated shimmer effect that moves across content during loading
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 1.5
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Theme.primaryText.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(
                        .linear(duration: duration)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 400
                    }
                }
            )
            .clipped()
    }
}

extension View {
    /// Applies shimmer effect to any view
    func shimmer(duration: Double = 1.5) -> some View {
        modifier(ShimmerEffect(duration: duration))
    }
}

// MARK: - Portfolio Card Skeleton Loader
/// Debug: Skeleton loader that matches portfolio card structure
struct PortfolioCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Debug: Header skeleton
            HStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 120, height: 16)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 20, height: 16)
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.tertiaryBackground)
            
            // Debug: Content rows skeleton
            VStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 60, height: 14)
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 140, height: 14)
                    }
                }
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .cardStyle()
        .shimmer()
    }
}

// MARK: - Stats Card Skeleton Loader
/// Debug: Skeleton loader for portfolio stats cards
struct StatsCardSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            // Debug: Large value skeleton
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 180, height: 40)
                
                // Change pill skeleton
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 120, height: 24)
            }
            .padding(.vertical, Theme.cardPadding)
            
            // Debug: Stats row skeleton
            HStack(spacing: 16) {
                ForEach(0..<2, id: \.self) { _ in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 60, height: 24)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 40, height: 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .shimmer()
    }
}

// MARK: - Market Price Row Skeleton
/// Debug: Skeleton loader for market price rows
struct MarketPriceRowSkeleton: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 100, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 80, height: 16)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 60, height: 12)
            }
        }
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, 12)
        .shimmer()
    }
}

// MARK: - Dashboard Chart Skeleton
/// Debug: Skeleton loader for dashboard performance chart
struct DashboardChartSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            // Debug: Time range selector skeleton
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 80, height: 32)
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 10)
            
            // Debug: Chart area skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.tertiaryBackground)
                .frame(height: 200)
                .padding(.horizontal, Theme.dashboardCardPadding)
                .padding(.bottom, Theme.dashboardCardPadding)
        }
        .cardStyle()
        .shimmer()
    }
}

// MARK: - Dashboard Card Skeleton
/// Debug: Generic skeleton for dashboard cards with header
struct DashboardCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Debug: Header with icon and title
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 28, height: 28)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 120, height: 16)
                
                Spacer()
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 10)
            .background(Theme.tertiaryBackground)
            
            // Debug: Content area with rows
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 100, height: 14)
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 60, height: 14)
                    }
                }
            }
            .padding(Theme.dashboardCardPadding)
        }
        .cardStyle()
        .shimmer()
    }
}

// MARK: - Physical Sales Table Skeleton
/// Debug: Skeleton loader for physical sales report table
struct PhysicalSalesTableSkeleton: View {
    var body: some View {
        VStack(spacing: 8) {
            // Debug: Table header row
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.tertiaryBackground)
                        .frame(height: 12)
                }
            }
            .padding(.bottom, 4)
            
            // Debug: Table data rows
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { col in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(height: col == 0 ? 14 : 12)
                    }
                }
            }
        }
        .padding()
        .shimmer()
    }
}

// MARK: - Herd Value Card Skeleton
/// Debug: Skeleton loader for herd/animal total value display at top of detail page
struct HerdValueCardSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            // Debug: Herd name skeleton
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.tertiaryBackground)
                .frame(width: 150, height: 18)
            
            // Debug: Large value skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.tertiaryBackground)
                .frame(width: 200, height: 44)
            
            // Debug: Change indicator skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.tertiaryBackground)
                .frame(width: 120, height: 28)
        }
        .padding(.vertical, Theme.cardPadding * 1.5)
        .frame(maxWidth: .infinity)
        .shimmer()
    }
}

// MARK: - Herd Detail Card Skeleton
/// Debug: Skeleton loader for detail cards with header and content rows
struct HerdDetailCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Debug: Header
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 120, height: 16)
                Spacer()
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 12)
            .background(Theme.tertiaryBackground)
            
            // Debug: Content rows
            VStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 80, height: 14)
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 100, height: 14)
                    }
                }
            }
            .padding(Theme.dashboardCardPadding)
        }
        .cardStyle()
        .shimmer()
    }
}

// MARK: - Report List Skeleton
/// Debug: Skeleton loader for report preview lists
struct ReportListSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            // Debug: Portfolio value row
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 120, height: 16)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.tertiaryBackground)
                    .frame(width: 100, height: 18)
            }
            
            Divider().background(Theme.separator)
            
            // Debug: Herd rows
            ForEach(0..<3, id: \.self) { _ in
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 140, height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 100, height: 12)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .shimmer()
    }
}

// MARK: - Summary Tiles Skeleton
/// Debug: Skeleton loader for asset summary tiles
struct SummaryTilesSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ForEach(0..<2, id: \.self) { _ in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 40, height: 40)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 60, height: 20)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.tertiaryBackground)
                            .frame(width: 50, height: 12)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.tertiaryBackground)
                        .frame(width: 40, height: 40)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.tertiaryBackground)
                        .frame(width: 100, height: 20)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.tertiaryBackground)
                        .frame(width: 80, height: 12)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .shimmer()
    }
}

// MARK: - Progressive Loading Container
/// Debug: Container view that shows skeleton loaders while content is loading
struct ProgressiveLoadingContainer<Content: View>: View {
    let isLoading: Bool
    let skeletonCount: Int
    let skeletonType: SkeletonType
    @ViewBuilder let content: () -> Content
    
    enum SkeletonType {
        case portfolioCard
        case statsCard
        case marketRow
        case dashboardChart
        case dashboardCard
        case physicalSalesTable
        case herdValueCard
        case herdDetailCard
        case reportList
        case summaryTiles
    }
    
    init(
        isLoading: Bool,
        skeletonCount: Int = 3,
        skeletonType: SkeletonType = .portfolioCard,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLoading = isLoading
        self.skeletonCount = skeletonCount
        self.skeletonType = skeletonType
        self.content = content
    }
    
    var body: some View {
        if isLoading {
            skeletonView
        } else {
            content()
        }
    }
    
    @ViewBuilder
    private var skeletonView: some View {
        switch skeletonType {
        case .portfolioCard:
            ForEach(0..<skeletonCount, id: \.self) { _ in
                PortfolioCardSkeleton()
                    .padding(.horizontal, Theme.cardPadding)
            }
        case .statsCard:
            StatsCardSkeleton()
                .padding(.horizontal, Theme.cardPadding)
        case .marketRow:
            ForEach(0..<skeletonCount, id: \.self) { _ in
                MarketPriceRowSkeleton()
            }
        case .dashboardChart:
            DashboardChartSkeleton()
                .padding(.horizontal, Theme.cardPadding)
        case .dashboardCard:
            ForEach(0..<skeletonCount, id: \.self) { _ in
                DashboardCardSkeleton()
                    .padding(.horizontal, Theme.cardPadding)
            }
        case .physicalSalesTable:
            PhysicalSalesTableSkeleton()
        case .herdValueCard:
            HerdValueCardSkeleton()
        case .herdDetailCard:
            ForEach(0..<skeletonCount, id: \.self) { _ in
                HerdDetailCardSkeleton()
                    .padding(.horizontal, Theme.cardPadding)
            }
        case .reportList:
            ReportListSkeleton()
        case .summaryTiles:
            SummaryTilesSkeleton()
        }
    }
}

// MARK: - Simple Loader with Message
/// Debug: Simple centered loader with optional message
struct SimpleLoader: View {
    let message: String?
    
    init(_ message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Theme.accentColor)
                .scaleEffect(1.2)
            
            if let message = message {
                Text(message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview
#Preview("Portfolio Card Skeleton") {
    VStack(spacing: 16) {
        PortfolioCardSkeleton()
        PortfolioCardSkeleton()
    }
    .padding()
    .background(Theme.background)
}

#Preview("Stats Card Skeleton") {
    StatsCardSkeleton()
        .padding()
        .background(Theme.background)
}

#Preview("Market Row Skeleton") {
    VStack(spacing: 0) {
        ForEach(0..<5, id: \.self) { _ in
            MarketPriceRowSkeleton()
        }
    }
    .cardStyle()
    .padding()
    .background(Theme.background)
}

#Preview("Progressive Container") {
    ScrollView {
        VStack(spacing: 16) {
            ProgressiveLoadingContainer(
                isLoading: true,
                skeletonCount: 3,
                skeletonType: .portfolioCard
            ) {
                Text("Content Here")
            }
        }
        .padding()
    }
    .background(Theme.background)
}

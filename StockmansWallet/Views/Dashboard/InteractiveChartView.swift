//
//  InteractiveChartView.swift
//  StockmansWallet
//
//  Interactive chart with scrubbing for portfolio valuations
//  Performance: Optimized for 60fps scrubbing with binary search and cached formatters
//

import SwiftUI
import Charts

// MARK: - Time Range Enum
enum TimeRange: String, CaseIterable {
    case custom = "Custom"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case all = "All"
}

// MARK: - Interactive Chart View
struct InteractiveChartView: View {
    let data: [ValuationDataPoint]
    @Binding var selectedDate: Date?
    @Binding var selectedValue: Double?
    @Binding var isScrubbing: Bool
    @Binding var timeRange: TimeRange
    let baseValue: Double
    let onValueChange: (Double, Double) -> Void
    
    @State private var scrubberX: CGFloat?
    @State private var chartOpacity: Double = 0.0
    
    // Performance optimization: Cache sorted data to avoid sorting on every drag event (60fps)
    // This dramatically improves scrubbing performance by sorting once instead of 60 times/second
    @State private var sortedData: [ValuationDataPoint] = []
    
    // Performance: Cache scrubber position to avoid recalculating on every render
    @State private var scrubberPosition: ScrubberPosition?
    
    // Performance: Debounce mechanism to prevent excessive updates during fast scrubbing
    // Batches rapid finger movements into fewer state updates for smoother 60fps performance
    @State private var debounceWorkItem: DispatchWorkItem?
    
    // Debug: Struct to batch scrubber state updates (reduces view updates from 3 to 1)
    private struct ScrubberPosition {
        let date: Date
        let value: Double
        let xPosition: CGFloat
    }
    
    // Performance: Binary search for fast data point lookup during scrubbing (O(log n) vs O(n))
    private func findSurroundingPoints(for date: Date, in sorted: [ValuationDataPoint]) -> (before: ValuationDataPoint?, after: ValuationDataPoint?) {
        guard !sorted.isEmpty else { return (nil, nil) }
        
        // Binary search to find insertion point
        var left = 0
        var right = sorted.count - 1
        
        while left <= right {
            let mid = (left + right) / 2
            let midDate = sorted[mid].date
            
            if midDate < date {
                left = mid + 1
            } else if midDate > date {
                right = mid - 1
            } else {
                // Exact match
                return (sorted[mid], mid + 1 < sorted.count ? sorted[mid + 1] : nil)
            }
        }
        
        // left is now the insertion point
        let before = right >= 0 ? sorted[right] : nil
        let after = left < sorted.count ? sorted[left] : nil
        
        return (before, after)
    }
    
    
    // Performance: Single gradient definition - no dynamic changes during scrubbing
    private var fullOpacityGradient: LinearGradient {
        LinearGradient(
            colors: [Theme.accent.opacity(0.3), Theme.accent.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func edgeExtendedData(for data: [ValuationDataPoint], in range: TimeRange) -> [ValuationDataPoint] {
        guard !data.isEmpty else { return data }
        // Debug: Sort data chronologically (oldest to newest)
        let sorted = data.sorted { $0.date < $1.date }
        let first = sorted[0]
        
        let epsilon: TimeInterval
        switch range {
        case .custom:
            // Debug: No edge extension for custom range - show exact selected dates
            return sorted
        case .week, .month:
            epsilon = 60 * 60 * 12
        case .year:
            epsilon = 60 * 60 * 24
        case .all:
            // Debug: Return sorted data to ensure chronological order
            return sorted
        }
        
        // Debug: Create leading edge point before the first data point
        // This extends the chart line to the left edge for better visual appearance
        let leading = ValuationDataPoint(
            date: first.date.addingTimeInterval(-epsilon),
            value: first.value,
            physicalValue: first.physicalValue,
            breedingAccrual: first.breedingAccrual
        )
        
        // Debug: Use sorted data (not original unsorted data) to prevent line jumping
        // This ensures the chart draws lines in chronological order
        var out = sorted
        out.insert(leading, at: 0)
        return out
    }
    
    // Debug: Grid removed per user request - clean minimal chart appearance
    private var chartGrid: some View {
        Color.clear
    }
    
    // Performance: Chart content without dimming effect to prevent redraw on every drag event
    // Apple HIG: Charts should respond immediately without lag - dimming causes full chart redraw at 60fps
    private func chartContent() -> some View {
        let renderData = edgeExtendedData(for: data, in: timeRange)
        let yRange = valueRange(data: data)
        let xRange = dataRange(data: renderData)
        
        return Chart {
            // Debug: Removed opacity changes that triggered chart redraw on every drag event
            // This is the #1 performance issue - changing opacity forces full chart re-render
            ForEach(renderData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Theme.accent)
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .butt, lineJoin: .round))
            }
            
            ForEach(renderData) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Value", yRange.lowerBound),
                    yEnd: .value("Value", point.value)
                )
                .foregroundStyle(fullOpacityGradient)
                .interpolationMethod(.monotone)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXScale(domain: xRange, range: .plotDimension(padding: 0))
        .chartYScale(domain: yRange, range: .plotDimension(padding: 0))
        .chartPlotStyle { plotArea in
            plotArea
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Portfolio value chart")
    }
    
    // Performance: Simplified date pill without scale/opacity animations during scrubbing
    // Apple HIG: Avoid animating elements during continuous gestures for 60fps
    private var dateHoverPill: some View {
        Group {
            if isScrubbing, let position = scrubberPosition {
                GeometryReader { geometry in
                    // Debug: Date pill with fully rounded capsule shape and subtle orange tint
                    // Performance: No scale/opacity animations - just fade in/out on start/end
                    Text(position.date, format: .dateTime.day(.twoDigits).month(.abbreviated).year())
                        .font(.system(size: 11, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        // Debug: Solid accent background (no glass effect)
                        .background(
                            Capsule()
                                .fill(Theme.accent)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                        .offset(x: {
                            // Performance: Calculate offset once per position update
                            let pillWidth: CGFloat = 100
                            let pillOffset = position.xPosition - (pillWidth / 2)
                            return max(0, min(pillOffset, geometry.size.width - pillWidth))
                        }())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Selected date")
                        .accessibilityValue(position.date.formatted(date: .abbreviated, time: .omitted))
                        // Performance: No animations during scrubbing - instant updates for 60fps
                        .animation(.none, value: position.date)
                        .animation(.none, value: position.xPosition)
                }
                .frame(height: 32)
                // Performance: Fade in pill when scrubbing starts
                .transition(.opacity)
            } else {
                // Performance: Keep space reserved to prevent layout shifts
                Color.clear
                    .frame(height: 32)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            dateHoverPill
                .padding(.bottom, 0)
            
            GeometryReader { geometry in
                ZStack {
                    chartGrid
                    
                    chartContent()
                        // Debug: Simple fade-in animation (no rendering artifacts like mask had)
                        // Smooth opacity transition prevents jarring "pop" on load
                        .opacity(chartOpacity)
                        .chartOverlay { proxy in
                            GeometryReader { geo in
                                Rectangle()
                                    .fill(.clear)
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                // Performance: Early exit if no data
                                                guard !data.isEmpty else { return }
                                                
                                                // Performance: Set scrubbing state once at start of gesture
                                                if !isScrubbing {
                                                    isScrubbing = true
                                                }
                                                
                                                let location = value.location
                                                
                                                // Performance: Get date from chart position
                                                guard let date: Date = proxy.value(atX: location.x),
                                                      let plotFrameAnchor = proxy.plotFrame else {
                                                    return
                                                }
                                                
                                                let plotFrame = geo[plotFrameAnchor]
                                                let sorted = sortedData
                                                
                                                // Performance: Calculate scrubber position once, then batch update
                                                let position: ScrubberPosition
                                                
                                                // Handle edge cases: before first or after last data point
                                                if let first = sorted.first, date <= first.date {
                                                    let xPlot = proxy.position(forX: first.date) ?? location.x
                                                    position = ScrubberPosition(
                                                        date: first.date,
                                                        value: first.value,
                                                        xPosition: plotFrame.origin.x + xPlot
                                                    )
                                                } else if let last = sorted.last, date >= last.date {
                                                    let xPlot = proxy.position(forX: last.date) ?? location.x
                                                    position = ScrubberPosition(
                                                        date: last.date,
                                                        value: last.value,
                                                        xPosition: plotFrame.origin.x + xPlot
                                                    )
                                                } else {
                                                    // Performance: Binary search for surrounding points (O(log n))
                                                    let (before, after) = findSurroundingPoints(for: date, in: sorted)
                                                    
                                                    if let b = before, let a = after {
                                                        // Linear interpolation between data points
                                                        let timeDiff = a.date.timeIntervalSince(b.date)
                                                        let timeFromB = date.timeIntervalSince(b.date)
                                                        let t = timeDiff > 0 ? timeFromB / timeDiff : 0.0
                                                        let interpolatedValue = b.value + (a.value - b.value) * t
                                                        
                                                        // Calculate x position
                                                        let xPos: CGFloat
                                                        if let xPlot = proxy.position(forX: date) {
                                                            xPos = plotFrame.origin.x + xPlot
                                                        } else if let xB = proxy.position(forX: b.date),
                                                                  let xA = proxy.position(forX: a.date) {
                                                            let xInterp = xB + (xA - xB) * CGFloat(t)
                                                            xPos = plotFrame.origin.x + xInterp
                                                        } else {
                                                            xPos = location.x
                                                        }
                                                        
                                                        position = ScrubberPosition(
                                                            date: date,
                                                            value: interpolatedValue,
                                                            xPosition: xPos
                                                        )
                                                    } else {
                                                        // Fallback: shouldn't happen with binary search
                                                        return
                                                    }
                                                }
                                                
                                                // Performance: Update visual scrubber immediately for responsiveness
                                                withAnimation(.none) {
                                                    scrubberPosition = position
                                                    scrubberX = position.xPosition
                                                }
                                                
                                                // Performance: Debounce the expensive state updates and callbacks
                                                // Cancel previous pending update
                                                debounceWorkItem?.cancel()
                                                
                                                // For VoiceOver, update immediately without debounce
                                                if UIAccessibility.isVoiceOverRunning {
                                                    selectedDate = position.date
                                                    selectedValue = position.value
                                                    onValueChange(position.value, position.value - baseValue)
                                                } else {
                                                    // Schedule debounced update after 16ms (one frame at 60fps)
                                                    let workItem = DispatchWorkItem {
                                                        Task { @MainActor in
                                                            selectedDate = position.date
                                                            selectedValue = position.value
                                                            onValueChange(position.value, position.value - baseValue)
                                                        }
                                                    }
                                                    debounceWorkItem = workItem
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.016, execute: workItem)
                                                }
                                            }
                                            .onEnded { _ in
                                                // Performance: Execute any pending debounced update immediately
                                                debounceWorkItem?.cancel()
                                                debounceWorkItem = nil
                                                
                                                // Performance: Batch state reset with animation
                                                withAnimation(.easeOut(duration: 0.2)) {
                                                    isScrubbing = false
                                                    scrubberPosition = nil
                                                }
                                                // Performance: Separate state updates that don't need animation
                                                selectedDate = nil
                                                selectedValue = nil
                                                scrubberX = nil
                                                onValueChange(baseValue, 0)
                                            }
                                    )
                                
                                // Performance: Only render scrubber when actively scrubbing
                                // Use cached position to avoid recalculating on every render
                                if isScrubbing,
                                   let position = scrubberPosition,
                                   let xInPlot = proxy.position(forX: position.date),
                                   let yInPlot = proxy.position(forY: position.value),
                                   let plotFrameAnchor = proxy.plotFrame {
                                    
                                    let plotFrame = geo[plotFrameAnchor]
                                    let x = plotFrame.origin.x + xInPlot
                                    let y = plotFrame.origin.y + yInPlot
                                    
                                    // Performance: Use Group with .drawingGroup() to batch GPU operations
                                    // Apple HIG: Minimize render passes for smooth 60fps interaction
                                    Group {
                                        // Vertical scrubber line
                                        Path { p in
                                            p.move(to: CGPoint(x: x, y: plotFrame.minY))
                                            p.addLine(to: CGPoint(x: x, y: plotFrame.maxY))
                                        }
                                        .stroke(.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                        
                                        // Scrubber dot at data point
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 12, height: 12)
                                            .shadow(color: Theme.accent.opacity(1), radius: 6)
                                            .shadow(color: Theme.accent.opacity(0.4), radius: 12)
                                            .position(x: x, y: y)
                                            .accessibilityHidden(true)
                                    }
                                    // Performance: drawingGroup() renders all elements as single texture
                                    // Critical for 60fps scrubbing performance
                                    .drawingGroup()
                                }
                            }
                        }
                }
            }
            .frame(height: 200)
            .clipped()
            // Debug: Clean minimal chart styling with subtle stroke matching other cards
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
            .accessibilityLabel("Portfolio value chart")
            
            ChartDateLabelsView(
                data: data,
                timeRange: timeRange
            )
            .padding(.horizontal, Theme.cardPadding)
            .padding(.top, 10)
            .padding(.bottom, 4)
        }
        .onAppear {
            // Performance: Initialize sorted data cache for smooth scrubbing
            sortedData = data.sorted { $0.date < $1.date }
            
            // Debug: Fade in chart smoothly (respects reduce motion accessibility setting)
            if UIAccessibility.isReduceMotionEnabled {
                chartOpacity = 1.0
            } else {
                withAnimation(.easeIn(duration: 0.6)) {
                    chartOpacity = 1.0
                }
            }
        }
        .onChange(of: data.count) { _, _ in
            // Performance: Update sorted data cache when data changes
            sortedData = data.sorted { $0.date < $1.date }
            
            // Debug: Fade in chart when data updates
            chartOpacity = 0.0
            if UIAccessibility.isReduceMotionEnabled {
                chartOpacity = 1.0
            } else {
                withAnimation(.easeIn(duration: 0.6)) {
                    chartOpacity = 1.0
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Calculate value range for Y-axis with 10% padding
    private func valueRange(data: [ValuationDataPoint]) -> ClosedRange<Double> {
        guard !data.isEmpty else { return 0...100 }
        
        let values = data.map { $0.value }
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...100
        }
        
        // Add 10% padding on top and bottom for visual breathing room
        let padding = (maxValue - minValue) * 0.1
        let paddedMin = max(0, minValue - padding)
        let paddedMax = maxValue + padding
        
        return paddedMin...paddedMax
    }
    
    /// Calculate date range for X-axis
    private func dataRange(data: [ValuationDataPoint]) -> ClosedRange<Date> {
        guard !data.isEmpty else {
            let now = Date()
            return now...now
        }
        
        let dates = data.map { $0.date }
        guard let min = dates.min(), let max = dates.max() else {
            let now = Date()
            return now...now
        }
        
        return min...max
    }
}

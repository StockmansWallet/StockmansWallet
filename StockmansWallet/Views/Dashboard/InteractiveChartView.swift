//
//  InteractiveChartView.swift
//  StockmansWallet
//
//  Interactive chart with scrubbing for portfolio valuations.
//  Uses Swift Charts ChartProxy (chartOverlay) only; prioritised for iOS 26, fallback for 18 and 17.
//  Performance: Optimized for 60fps scrubbing with binary search and cached formatters.
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
    // Debug: Pass custom range dates for accurate label display
    let customStartDate: Date?
    let customEndDate: Date?
    let baseValue: Double
    let onValueChange: (Double, Double) -> Void
    
    @State private var scrubberX: CGFloat?
    
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

    // Debug: Clamp scrubber to chart bounds so it never renders off-screen
    private func clampedX(_ x: CGFloat, in plotFrame: CGRect) -> CGFloat {
        let dotRadius: CGFloat = 6
        return min(max(x, plotFrame.minX + dotRadius), plotFrame.maxX - dotRadius)
    }

    // Debug: Clamp scrubber to chart bounds so it never renders off-screen
    private func clampedY(_ y: CGFloat, in plotFrame: CGRect) -> CGFloat {
        let dotRadius: CGFloat = 6
        return min(max(y, plotFrame.minY + dotRadius), plotFrame.maxY - dotRadius)
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
    
    
    // Debug: Chart area fill fades from accent to transparent
    private var chartAreaFill: LinearGradient {
        LinearGradient(
            colors: [
                Theme.accentColor.opacity(0.35),
                Theme.accentColor.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func edgeExtendedData(for data: [ValuationDataPoint], in range: TimeRange) -> [ValuationDataPoint] {
        // Debug: No edge extension to prevent chart line from overflowing container bounds
        // Return chronologically sorted data without adding leading edge points
        return data.sorted { $0.date < $1.date }
    }
    
    // Debug: Grid removed per user request - clean minimal chart appearance
    private var chartGrid: some View {
        Color.clear
    }
    
    // HIG: Chart content following Apple's Charts framework best practices
    // Charts handle their own smooth transitions when data or scales change
    private func chartContent() -> some View {
        let renderData = edgeExtendedData(for: data, in: timeRange)
        let yRange = valueRange(data: data)
        let xRange = dataRange(data: renderData)
        
        return Chart {
            ForEach(renderData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Theme.accentColor)
                // Debug: Smooth line without overshoot to keep within chart bounds
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)) // Debug: Thicker line for visibility; round lineCap to prevent extension
            }
            
            ForEach(renderData) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Value", yRange.lowerBound),
                    yEnd: .value("Value", point.value)
                )
                .foregroundStyle(chartAreaFill)
                // Debug: Match line interpolation for consistent fill
                .interpolationMethod(.monotone)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXScale(domain: xRange)
        .chartYScale(domain: yRange)
        .chartPlotStyle { plotArea in
            plotArea
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(Rectangle()) // Debug: Clip chart to prevent line from extending beyond bounds
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
                        .foregroundStyle(Theme.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        // Debug: Solid dark background with rounded rectangle (no glass effect)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(hex: "552F0D"))
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
                        // Swift Charts: ChartProxy (chartOverlay) is the official API for custom scrubbing.
                        // Prioritised for iOS 26; same implementation runs on iOS 18 and 17 (no @available needed).
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
                                                
                                                // Apple HIG: Only scrub when drag is primarily horizontal so vertical drags scroll the page
                                                // Prevents dashboard card feeling draggable in 2D; chart scrub = horizontal, page scroll = vertical
                                                let t = value.translation
                                                if abs(t.height) > abs(t.width) { return }
                                                
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
                                                    let rawX = plotFrame.origin.x + xPlot
                                                    position = ScrubberPosition(
                                                        date: first.date,
                                                        value: first.value,
                                                        xPosition: clampedX(rawX, in: plotFrame)
                                                    )
                                                } else if let last = sorted.last, date >= last.date {
                                                    let xPlot = proxy.position(forX: last.date) ?? location.x
                                                    let rawX = plotFrame.origin.x + xPlot
                                                    position = ScrubberPosition(
                                                        date: last.date,
                                                        value: last.value,
                                                        xPosition: clampedX(rawX, in: plotFrame)
                                                    )
                                                } else {
                                                    // Performance: Binary search for surrounding points (O(log n))
                                                    let (before, after) = findSurroundingPoints(for: date, in: sorted)
                                                    
                                                    if let b = before, let a = after {
                                                        // Swift Charts: Use linear interpolation so the scrubber moves smoothly (good UX).
                                                        // ChartProxy.value(atX:) gives us the date; we derive value from data so dot position matches chart scale.
                                                        // Dot may sit slightly off the monotone curve between points but moves continuously (iOS 26 / 18 / 17).
                                                        let timeDiff = a.date.timeIntervalSince(b.date)
                                                        let timeFromB = date.timeIntervalSince(b.date)
                                                        let t = timeDiff > 0 ? timeFromB / timeDiff : 0.0
                                                        let interpolatedValue = b.value + (a.value - b.value) * t
                                                        
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
                                                        
                                                        let clampedXPos = clampedX(xPos, in: plotFrame)
                                                        position = ScrubberPosition(
                                                            date: date,
                                                            value: interpolatedValue,
                                                            xPosition: clampedXPos
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
                                                
                                                // Debug: Remove animation to prevent glitch on release
                                                // Instant state reset prevents visual artifacts from partial render frames
                                                isScrubbing = false
                                                scrubberPosition = nil
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
                                    let rawX = plotFrame.origin.x + xInPlot
                                    let rawY = plotFrame.origin.y + yInPlot
                                    let x = clampedX(rawX, in: plotFrame)
                                    let y = clampedY(rawY, in: plotFrame)
                                    
                                    // Performance: Use Group with .drawingGroup() to batch GPU operations
                                    // Apple HIG: Minimize render passes for smooth 60fps interaction
                                    Group {
                                        // Vertical scrubber line
                                        Path { p in
                                            p.move(to: CGPoint(x: x, y: plotFrame.minY))
                                            p.addLine(to: CGPoint(x: x, y: plotFrame.maxY))
                                        }
                                        // Debug: Solid, thin scrubber line with brand color
                                        .stroke(Color(hex: "F3B887").opacity(0.3), style: StrokeStyle(lineWidth: 1))
                                        
                                        // Scrubber dot at data point
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 10, height: 10)
                                            .overlay(
                                                // Debug: Brand-color stroke for scrubber dot
                                                Circle()
                                                    .stroke(Theme.accentColor, lineWidth: 1)
                                            )
                                       
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
            // Debug: Slightly taller chart for better readability
            .frame(height: 180)
            .accessibilityLabel("Portfolio value chart")
            
            ChartDateLabelsView(
                data: data,
                timeRange: timeRange,
                customStartDate: customStartDate,
                customEndDate: customEndDate
            )
            .padding(.horizontal, Theme.cardPadding)
            .padding(.top, 10)
            .padding(.bottom, 4)
        }
        .onAppear {
            // Performance: Initialize sorted data cache for smooth scrubbing
            sortedData = data.sorted { $0.date < $1.date }
        }
        .onChange(of: data.count) { _, _ in
            // Performance: Update sorted data cache when data changes
            sortedData = data.sorted { $0.date < $1.date }
        }
        .onChange(of: timeRange) { _, _ in
            // HIG: Reset scrubbing state when time range changes
            // Ensures clean slate for new time range without visual artifacts
            isScrubbing = false
            scrubberPosition = nil
            selectedDate = nil
            selectedValue = nil
            scrubberX = nil
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

//
//  DashboardModels.swift
//  StockmansWallet
//
//  Data models for Dashboard views
//

import Foundation

// MARK: - Capital Concentration Breakdown
/// Represents the breakdown of capital by livestock category
struct CapitalConcentrationBreakdown: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    let percentage: Double
}

// MARK: - Performance Metrics
/// Portfolio performance metrics for display
struct PerformanceMetrics {
    let totalChange: Double
    let percentChange: Double
    let unrealizedGains: Double
    let initialValue: Double
}


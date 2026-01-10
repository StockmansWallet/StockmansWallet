//
//  ReportDataGenerator.swift
//  StockmansWallet
//
//  Generates report data from herds, sales, and properties
//  Debug: Structure provided - customize data aggregation logic as needed
//

import Foundation
import SwiftData

// Debug: Main report data generator
class ReportDataGenerator {
    
    // MARK: - Main Generation Method
    // Debug: Entry point for generating report data
    static func generateReportData(
        configuration: ReportConfiguration,
        herds: [HerdGroup],
        sales: [SalesRecord],
        preferences: UserPreferences,
        properties: [Property],
        modelContext: ModelContext,
        valuationEngine: ValuationEngine
    ) async -> ReportData {
        
        // Filter data by date range
        let filteredHerds = filterHerdsByDateRange(herds, configuration: configuration)
        let filteredSales = filterSalesByDateRange(sales, configuration: configuration)
        
        // Generate data based on report type
        switch configuration.reportType {
        case .assetRegister:
            return await generateAssetRegisterData(
                herds: filteredHerds,
                configuration: configuration,
                preferences: preferences,
                modelContext: modelContext,
                valuationEngine: valuationEngine
            )
            
        case .salesSummary:
            return generateSalesSummaryData(
                sales: filteredSales,
                configuration: configuration,
                preferences: preferences
            )
            
        case .saleyardComparison:
            return await generateSaleyardComparisonData(
                herds: filteredHerds,
                sales: filteredSales,
                configuration: configuration,
                preferences: preferences,
                modelContext: modelContext,
                valuationEngine: valuationEngine
            )
            
        case .livestockValueVsLandArea:
            return await generateLivestockValueVsLandAreaData(
                herds: filteredHerds,
                properties: properties,
                configuration: configuration,
                preferences: preferences,
                modelContext: modelContext,
                valuationEngine: valuationEngine
            )
            
        case .farmComparison:
            return await generateFarmComparisonData(
                herds: filteredHerds,
                properties: properties,
                configuration: configuration,
                preferences: preferences,
                modelContext: modelContext,
                valuationEngine: valuationEngine
            )
        }
    }
    
    // MARK: - Date Range Filtering
    
    private static func filterHerdsByDateRange(_ herds: [HerdGroup], configuration: ReportConfiguration) -> [HerdGroup] {
        // TODO: Implement date range filtering for herds
        // Filter by herd.createdAt or other date field
        // For now, return active herds
        return herds.filter { !$0.isSold }
    }
    
    private static func filterSalesByDateRange(_ sales: [SalesRecord], configuration: ReportConfiguration) -> [SalesRecord] {
        // TODO: Implement date range filtering for sales
        return sales.filter { sale in
            sale.saleDate >= configuration.startDate && sale.saleDate <= configuration.endDate
        }
    }
    
    // MARK: - Asset Register Data Generation
    
    private static func generateAssetRegisterData(
        herds: [HerdGroup],
        configuration: ReportConfiguration,
        preferences: UserPreferences,
        modelContext: ModelContext,
        valuationEngine: ValuationEngine
    ) async -> ReportData {
        
        var herdDataArray: [HerdReportData] = []
        var totalValue: Double = 0.0
        
        // TODO: Calculate valuations for each herd
        for herd in herds {
            // Calculate valuation
            let valuation = await valuationEngine.calculateHerdValue(
                herd: herd,
                preferences: preferences,
                modelContext: modelContext
            )
            
            // TODO: Calculate price statistics (min/max/avg) based on historical data
            // For now, use current price as placeholder
            let currentPrice = valuation.pricePerKg
            let minPrice = currentPrice * 0.9 // TODO: Get actual min from historical data
            let maxPrice = currentPrice * 1.1 // TODO: Get actual max from historical data
            let avgPrice = currentPrice // TODO: Calculate actual average
            
            let herdData = HerdReportData(
                id: herd.id,
                name: herd.name,
                category: "\(herd.breed) \(herd.category)",
                headCount: herd.headCount,
                ageMonths: herd.ageMonths,
                weight: valuation.projectedWeight,
                pricePerKg: currentPrice,
                minPrice: minPrice,
                maxPrice: maxPrice,
                avgPrice: avgPrice,
                netValue: valuation.netRealizableValue
            )
            
            herdDataArray.append(herdData)
            totalValue += valuation.netRealizableValue
        }
        
        // Get farm name if configured
        let farmName = configuration.includeFarmName ? (preferences.propertyName ?? "My Farm") : nil
        
        return ReportData(
            farmName: farmName,
            totalValue: totalValue,
            totalSales: 0,
            herdData: herdDataArray,
            salesData: [],
            saleyardComparison: [],
            landValueAnalysis: [],
            farmComparison: []
        )
    }
    
    // MARK: - Sales Summary Data Generation
    
    private static func generateSalesSummaryData(
        sales: [SalesRecord],
        configuration: ReportConfiguration,
        preferences: UserPreferences
    ) -> ReportData {
        
        var salesDataArray: [SaleReportData] = []
        var totalSales: Double = 0.0
        
        // Debug: Aggregate sales data with new fields
        for sale in sales {
            let saleData = SaleReportData(
                id: sale.id,
                date: sale.saleDate,
                headCount: sale.headCount,
                avgWeight: sale.averageWeight,
                pricePerKg: sale.pricePerKg,
                pricePerHead: sale.pricePerHead,
                pricingType: sale.pricingTypeEnum,
                saleType: sale.saleType,
                saleLocation: sale.saleLocation,
                netValue: sale.netValue
            )
            
            salesDataArray.append(saleData)
            totalSales += sale.netValue
        }
        
        let farmName = configuration.includeFarmName ? (preferences.propertyName ?? "My Farm") : nil
        
        return ReportData(
            farmName: farmName,
            totalValue: 0,
            totalSales: totalSales,
            herdData: [],
            salesData: salesDataArray,
            saleyardComparison: [],
            landValueAnalysis: [],
            farmComparison: []
        )
    }
    
    // MARK: - Saleyard Comparison Data Generation
    
    private static func generateSaleyardComparisonData(
        herds: [HerdGroup],
        sales: [SalesRecord],
        configuration: ReportConfiguration,
        preferences: UserPreferences,
        modelContext: ModelContext,
        valuationEngine: ValuationEngine
    ) async -> ReportData {
        
        var comparisonData: [SaleyardComparisonData] = []
        
        // TODO: Group herds/sales by saleyard and calculate statistics
        let selectedSaleyards = configuration.selectedSaleyards.isEmpty ? ReferenceData.saleyards : configuration.selectedSaleyards
        
        for saleyard in selectedSaleyards {
            // Filter herds by saleyard
            let saleyardHerds = herds.filter { $0.selectedSaleyard == saleyard }
            
            // TODO: Filter sales by matching herdGroupId to herds with this saleyard
            let saleyardHerdIds = Set(saleyardHerds.map { $0.id })
            let saleyardSales = sales.filter { saleyardHerdIds.contains($0.herdGroupId) }
            
            // TODO: Calculate price statistics for this saleyard
            var prices: [Double] = []
            var totalHeadCount = 0
            
            // Get prices from sales
            for sale in saleyardSales {
                prices.append(sale.pricePerKg)
                totalHeadCount += sale.headCount
            }
            
            // Get prices from herds
            for herd in saleyardHerds {
                let valuation = await valuationEngine.calculateHerdValue(
                    herd: herd,
                    preferences: preferences,
                    modelContext: modelContext
                )
                prices.append(valuation.pricePerKg)
                totalHeadCount += herd.headCount
            }
            
            // Calculate statistics
            let avgPrice = prices.isEmpty ? 0 : prices.reduce(0, +) / Double(prices.count)
            let minPrice = prices.min() ?? 0
            let maxPrice = prices.max() ?? 0
            
            let comparison = SaleyardComparisonData(
                saleyardName: saleyard,
                avgPrice: avgPrice,
                minPrice: minPrice,
                maxPrice: maxPrice,
                totalHeadCount: totalHeadCount
            )
            
            comparisonData.append(comparison)
        }
        
        let farmName = configuration.includeFarmName ? (preferences.propertyName ?? "My Farm") : nil
        
        return ReportData(
            farmName: farmName,
            totalValue: 0,
            totalSales: 0,
            herdData: [],
            salesData: [],
            saleyardComparison: comparisonData,
            landValueAnalysis: [],
            farmComparison: []
        )
    }
    
    // MARK: - Livestock Value vs Land Area Data Generation
    
    private static func generateLivestockValueVsLandAreaData(
        herds: [HerdGroup],
        properties: [Property],
        configuration: ReportConfiguration,
        preferences: UserPreferences,
        modelContext: ModelContext,
        valuationEngine: ValuationEngine
    ) async -> ReportData {
        
        var analysisData: [LandValueAnalysisData] = []
        
        // TODO: Group herds by property and calculate value per acre
        // For now, use default property
        for property in properties where property.acreage != nil && property.acreage! > 0 {
            // TODO: Filter herds by property (need to add property relationship to HerdGroup)
            // For now, calculate for all herds
            
            var propertyValue: Double = 0.0
            var propertyHeadCount = 0
            
            for herd in herds {
                let valuation = await valuationEngine.calculateHerdValue(
                    herd: herd,
                    preferences: preferences,
                    modelContext: modelContext
                )
                propertyValue += valuation.netRealizableValue
                propertyHeadCount += herd.headCount
            }
            
            let valuePerAcre = propertyValue / (property.acreage ?? 1.0)
            
            let analysis = LandValueAnalysisData(
                propertyName: property.propertyName,
                acreage: property.acreage ?? 0,
                livestockValue: propertyValue,
                valuePerAcre: valuePerAcre,
                totalHeadCount: propertyHeadCount
            )
            
            analysisData.append(analysis)
        }
        
        let farmName = configuration.includeFarmName ? (preferences.propertyName ?? "My Farm") : nil
        
        return ReportData(
            farmName: farmName,
            totalValue: 0,
            totalSales: 0,
            herdData: [],
            salesData: [],
            saleyardComparison: [],
            landValueAnalysis: analysisData,
            farmComparison: []
        )
    }
    
    // MARK: - Farm Comparison Data Generation
    
    private static func generateFarmComparisonData(
        herds: [HerdGroup],
        properties: [Property],
        configuration: ReportConfiguration,
        preferences: UserPreferences,
        modelContext: ModelContext,
        valuationEngine: ValuationEngine
    ) async -> ReportData {
        
        var comparisonData: [FarmComparisonData] = []
        
        // TODO: Group herds by property and calculate performance metrics
        let selectedPropertyIDs = configuration.selectedProperties.isEmpty ? properties.map { $0.id } : configuration.selectedProperties
        let selectedProperties = properties.filter { selectedPropertyIDs.contains($0.id) }
        
        for property in selectedProperties {
            // TODO: Filter herds by property (need to add property relationship to HerdGroup)
            // For now, use all herds as placeholder
            
            var propertyValue: Double = 0.0
            var propertyHeadCount = 0
            var totalWeight: Double = 0.0
            var prices: [Double] = []
            
            for herd in herds {
                let valuation = await valuationEngine.calculateHerdValue(
                    herd: herd,
                    preferences: preferences,
                    modelContext: modelContext
                )
                
                propertyValue += valuation.netRealizableValue
                propertyHeadCount += herd.headCount
                totalWeight += valuation.projectedWeight * Double(herd.headCount)
                prices.append(valuation.pricePerKg)
            }
            
            let avgPrice = prices.isEmpty ? 0 : prices.reduce(0, +) / Double(prices.count)
            let valuePerHead = propertyHeadCount > 0 ? propertyValue / Double(propertyHeadCount) : 0
            
            let comparison = FarmComparisonData(
                propertyName: property.propertyName,
                totalValue: propertyValue,
                totalHeadCount: propertyHeadCount,
                avgPricePerKg: avgPrice,
                valuePerHead: valuePerHead
            )
            
            comparisonData.append(comparison)
        }
        
        let farmName = configuration.includeFarmName ? (preferences.propertyName ?? "My Farm") : nil
        
        return ReportData(
            farmName: farmName,
            totalValue: 0,
            totalSales: 0,
            herdData: [],
            salesData: [],
            saleyardComparison: [],
            landValueAnalysis: [],
            farmComparison: comparisonData
        )
    }
}


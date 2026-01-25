//
//  MLAAPIService.swift
//  StockmansWallet
//
//  Service for fetching live data from MLA NLRS API
//  Debug: Connects to public MLA API (no authentication required)
//

import Foundation

// MARK: - MLA API Service
// Debug: Fetches real-time market data from MLA's public API
class MLAAPIService {
    static let shared = MLAAPIService()
    
    private let baseURL = "https://api-mlastatistics.mla.com.au"
    
    private init() {}
    
    // MARK: - Fetch National Indicators
    // Debug: Fetches cattle indicators (EYCI, WYCI) from MLA API
    func fetchNationalIndicators() async throws -> [NationalIndicator] {
        print("🔵 Debug: Starting fetchNationalIndicators from MLA API")
        
        // Indicator IDs for cattle
        let cattleIndicatorIDs = [
            0,  // EYCI - Eastern Young Cattle Indicator
            1   // WYCI - Western Young Cattle Indicator
        ]
        
        var indicators: [NationalIndicator] = []
        
        // Fetch each indicator
        for indicatorID in cattleIndicatorIDs {
            print("🔵 Debug: Fetching indicator ID: \(indicatorID)")
            do {
                let indicator = try await fetchIndicator(id: indicatorID)
                print("✅ Debug: Successfully fetched \(indicator.abbreviation): \(indicator.value)")
                indicators.append(indicator)
            } catch {
                print("❌ Debug: Error fetching indicator \(indicatorID): \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                // Continue with other indicators even if one fails
            }
        }
        
        print("🔵 Debug: Total indicators fetched: \(indicators.count)")
        return indicators
    }
    
    // MARK: - Fetch Single Indicator
    // Debug: Fetches a specific indicator by ID
    private func fetchIndicator(id: Int) async throws -> NationalIndicator {
        // Build URL
        let urlString = "\(baseURL)/report/5?indicatorID=\(id)"
        print("🌐 Debug: API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Debug: Invalid URL")
            throw MLAAPIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("🌐 Debug: Making network request...")
        
        // Fetch data
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("🌐 Debug: Received response")
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Debug: Not an HTTP response")
            throw MLAAPIError.badResponse
        }
        
        print("🌐 Debug: HTTP Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Debug: Bad status code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Debug: Response body: \(responseString)")
            }
            throw MLAAPIError.badResponse
        }
        
        // Decode response
        let decoder = JSONDecoder()
        
        do {
            let apiResponse = try decoder.decode(MLAIndicatorResponse.self, from: data)
            print("✅ Debug: Successfully decoded response, rows: \(apiResponse.total_number_rows)")
            
            // Get the most recent data point
            guard let latestData = apiResponse.data.first else {
                print("❌ Debug: No data in response")
                throw MLAAPIError.noData
            }
            
            // Convert to app model
            let indicator = latestData.toNationalIndicator()
            print("✅ Debug: Converted to indicator: \(indicator.abbreviation) = \(indicator.value)")
            return indicator
            
        } catch {
            print("❌ Debug: Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Debug: Response JSON: \(responseString.prefix(500))")
            }
            throw MLAAPIError.decodingError
        }
    }
    
    // MARK: - Fetch All Available Indicators (for future use)
    // Debug: Gets list of all available indicators from MLA
    func fetchAvailableIndicators() async throws -> [MLAIndicatorInfo] {
        let urlString = "\(baseURL)/indicator"
        guard let url = URL(string: urlString) else {
            throw MLAAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MLAAPIError.badResponse
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(MLAIndicatorListResponse.self, from: data)
        
        return apiResponse.data
    }
    
    // MARK: - Fetch Physical Sales Report
    // Debug: Fetches physical sales data from MLA API
    func fetchPhysicalSalesReport(saleyard: String? = nil, date: Date = Date()) async throws -> PhysicalSalesReport {
        print("🔵 Debug: Starting fetchPhysicalSalesReport from MLA API")
        print("🔵 Debug: Saleyard: \(saleyard ?? "All"), Date: \(date)")
        
        // Note: After extensive testing, the MLA Statistics API (report/4 and report/10)
        // consistently returns empty data for physical sales queries.
        // Physical sales data from https://www.mla.com.au/prices-markets/cattlephysicalreport/
        // may come from a different API or require web scraping.
        
        print("💡 Debug: MLA Statistics API does not appear to provide physical sales data")
        print("💡 Debug: Recommended approach:")
        print("   1. Use Supabase Edge Function to scrape MLA website daily")
        print("   2. Cache the data in Supabase database")
        print("   3. Serve cached data to app")
        print("💡 Debug: Using mock data for MVP demonstration")
        
        throw MLAAPIError.noData
    }
    
    // MARK: - Fetch from Specific Report Endpoint
    // Debug: Internal method to fetch from a specific report endpoint
    private func fetchPhysicalSalesFromReport(reportID: Int, saleyard: String?, date: Date) async throws -> PhysicalSalesReport {
        // Build URL with proper parameters for each report type
        var urlString = "\(baseURL)/report/\(reportID)"
        
        // Format date as YYYY-MM-DD
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var queryItems: [String] = []
        
        // Different reports need different parameters
        switch reportID {
        case 4:
            // Report 4 needs: fromDate, toDate, category, optional saleyardID
            // Use date range 8-14 days ago (MLA needs historical data)
            let endDate = Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
            
            let fromDateString = dateFormatter.string(from: startDate)
            let toDateString = dateFormatter.string(from: endDate)
            
            queryItems.append("fromDate=\(fromDateString)")
            queryItems.append("toDate=\(toDateString)")
            
            // Try different common categories - MLA might use different naming
            // Common options: "Vealer", "Yearling", "Steer", etc.
            queryItems.append("category=Vealer")
            
            if let saleyard = saleyard {
                queryItems.append("saleyardID=\(saleyard)")
            }
            
        case 10:
            // Report 10 needs: fromDate, toDate AT LEAST 7 days before today, species
            // Use date range 8-14 days ago
            let endDate = Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
            
            let fromDateString = dateFormatter.string(from: startDate)
            let toDateString = dateFormatter.string(from: endDate)
            
            queryItems.append("fromDate=\(fromDateString)")
            queryItems.append("toDate=\(toDateString)")
            queryItems.append("species=Cattle") // Focus on cattle for MVP
            
            // Try without stateID to get all states
            
        default:
            break
        }
        
        if !queryItems.isEmpty {
            urlString += "?" + queryItems.joined(separator: "&")
        }
        
        print("🌐 Debug: Physical Sales API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Debug: Invalid URL")
            throw MLAAPIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("🌐 Debug: Making network request for physical sales...")
        
        // Fetch data
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("🌐 Debug: Received physical sales response")
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Debug: Not an HTTP response")
            throw MLAAPIError.badResponse
        }
        
        print("🌐 Debug: HTTP Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Debug: Bad status code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Debug: Response body: \(responseString.prefix(500))")
            }
            throw MLAAPIError.badResponse
        }
        
        // First, let's see what the raw JSON looks like
        if let responseString = String(data: data, encoding: .utf8) {
            print("📊 Debug: Physical Sales Raw JSON (first 2000 chars): \(responseString.prefix(2000))")
        }
        
        // For now, return a placeholder until we see the actual response structure
        // We'll update this once we see what the API returns
        print("⚠️ Debug: Physical sales endpoint returned data, but we need to decode it")
        print("⚠️ Debug: Please check console output above to see JSON structure")
        
        throw MLAAPIError.decodingError // Temporary - will be replaced once we see the response
    }
}

// MARK: - MLA API Models
// Debug: Models matching MLA API response structure

struct MLAIndicatorResponse: Codable {
    let message: String
    let total_number_rows: Int
    let data: [MLAIndicatorData]
    
    // Debug: Custom decoding to handle MLA API's "total number rows" with space instead of underscore
    enum CodingKeys: String, CodingKey {
        case message
        case total_number_rows = "total number rows"
        case data
    }
}

struct MLAIndicatorData: Codable {
    let calendar_date: String
    let species_id: String
    let indicator_id: Int  // Changed from String to Int - API returns number
    let indicator_name: String  // Changed from indicator_desc
    let indicator_units: String
    let head_count: Double  // Changed from String to Double
    let indicator_value: Double  // Changed from String to Double
    
    // Debug: Custom coding keys to handle MLA API naming
    enum CodingKeys: String, CodingKey {
        case calendar_date
        case species_id
        case indicator_id
        case indicator_name = "indicator_desc"  // API uses "indicator_desc" not "indicator_name"
        case indicator_units
        case head_count
        case indicator_value
    }
    
    // Convert to app's NationalIndicator model
    func toNationalIndicator() -> NationalIndicator {
        // Parse value - already a Double
        let value = indicator_value
        
        // For MVP, we don't have previous day's data to calculate change
        // This will be implemented when we cache data in Supabase
        let change = 0.0
        let trend: PriceTrend = .neutral
        
        // Parse abbreviation from indicator name
        let abbreviation: String
        if indicator_name.contains("Eastern Young Cattle") {
            abbreviation = "EYCI"
        } else if indicator_name.contains("Western Young Cattle") {
            abbreviation = "WYCI"
        } else {
            // Extract first letters of each word
            let words = indicator_name.components(separatedBy: " ")
            abbreviation = words.compactMap { $0.first }.map(String.init).joined()
        }
        
        return NationalIndicator(
            name: indicator_name,
            abbreviation: abbreviation,
            value: value,
            change: change,
            trend: trend,
            unit: indicator_units,
            changeDuration: "24h" // Debug: Daily change from MLA API
        )
    }
}

struct MLAIndicatorListResponse: Codable {
    let message: String
    let data: [MLAIndicatorInfo]
}

struct MLAIndicatorInfo: Codable {
    let indicator_id: Int
    let indicator_desc: String
    let species_id: String
    let indicator_units: String
}

// MARK: - Error Types
enum MLAAPIError: Error {
    case invalidURL
    case badResponse
    case noData
    case decodingError
    
    var description: String {
        switch self {
        case .invalidURL:
            return "Invalid MLA API URL"
        case .badResponse:
            return "Bad response from MLA API"
        case .noData:
            return "No data returned from MLA API"
        case .decodingError:
            return "Failed to decode MLA API response"
        }
    }
}

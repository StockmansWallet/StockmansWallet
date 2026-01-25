# Markets Page - Complete Redesign

**Date**: January 24, 2026  
**Status**: ✅ Complete

---

## 🎯 Overview

Complete redesign of the Markets page with tabbed navigation (similar to Portfolio page) featuring personalized market data, national indicators, saleyard reports, and AI-powered market intelligence.

---

## 📁 File Structure

```
StockmansWallet/
├── Services/
│   └── MarketDataService.swift          # UPDATED - Added new data models and methods
├── Views/Market/
│   ├── MarketView.swift                 # COMPLETELY REBUILT - New tabbed design
│   ├── MarketViewModel.swift            # UPDATED - New state and methods
│   └── PriceDetailSheet.swift           # UNCHANGED - Still compatible
└── Docs/
    └── MARKETS-PAGE-REDESIGN.md         # NEW - This documentation
```

---

## 🏗️ Architecture

### Navigation Structure

**4 Tabs (Segmented Control):**
1. **Overview** - Landing page with Top Insight + quick access cards
2. **My Markets** - Prices for user's actual livestock categories
3. **Market Pulse** - National indicators + saleyard reports
4. **Intelligence** - AI predictions with confidence levels

### State Management
- **Pattern**: MVVM with @Observable macro
- **ViewModel**: `MarketViewModel` manages all state and business logic
- **Service**: `MarketDataService` provides mock data (ready for MLA API integration)

### Data Flow
```
User opens Markets
    ↓
Load all data in parallel:
    - Top Insight (daily takeaway)
    - National Indicators (EYCI, WYCI, NSI, NHLI)
    - Saleyard Reports (filtered by state)
    - Market Intelligence (AI predictions)
    ↓
User switches to "My Markets" tab
    ↓
Load prices filtered by user's HerdGroup categories
    (only shows categories they actually have livestock in)
    ↓
User taps price card
    ↓
Load historical & regional data for that category
    ↓
Show detailed price sheet with charts
```

---

## 🎨 Features by Tab

### 1. Overview Tab

**TOP INSIGHT Banner**
- Single sentence daily market takeaway
- Displayed as prominent banner (not full card)
- Mock example: *"Market conditions for weaners in your region are improving as tightening supply supports prices"*
- Source: MLA data/API (mock for now)

**Quick Access Cards**
- Navigate to other tabs
- Show count badges (e.g., "8 prices available")
- Clean, tappable design

**Last Updated Timestamp**
- Relative time display (e.g., "5 minutes ago")

---

### 2. My Markets Tab

**Personalized Pricing**
- Shows ONLY categories the user has in their portfolio
- Filters based on `HerdGroup.category` from user's actual livestock
- Empty state if user has no livestock yet
- Example: If user has "Weaner Steer" and "Breeding Cow", only those prices show

**Price Cards**
- 2-column grid layout
- Shows: Category, Weight Range, Price, Change indicator with 24h duration
- Tappable to see historical charts and regional comparison

**Data Filtering**
- Automatically filtered by user's herd categories
- Updates when user adds/removes livestock

---

### 3. Market Pulse Tab

**National Indicators**
- Large, prominent cards for EYCI, WYCI, NSI, NHLI
- Shows: Value, Change with 24h duration, Trend (up/down/steady)
- 2-column grid layout
- Color-coded trends (green=up, red=down, gray=steady)

**Physical Sales Report** *(MLA-style interface)*

**Filter Layout:**
- **Row 1:** Report Date | State (Optional)
- **Row 2:** Category | Sale Prefix
- **Row 3:** Saleyard (Full-width sheet selector)

**Filter Controls:**
1. **Report Date Selection**: Dropdown to select report dates (last 7 days)
2. **State Filter** *(optional)*: Filter by state or show all
3. **Category Filter**: All, Bulls, Cows, Grown Heifer, Grown Steer, Yearling Heifer, Yearling Steer
4. **Sale Prefix Filter**: All, Feeder, Processor, PTIC, Restocker
5. **Saleyard Selection**: Sheet-based selector (like dashboard)
   - Searchable list of 24 saleyards with physical reports
   - Full-screen sheet for easy browsing
   - Checkmark indicates current selection

**Report Display:**
- **Market Summary**: Text summary with bullet points
- **Audio Icon**: Play market commentary (when available)
- **Detailed Table**: Shows pricing by category with:
  - Category name, weight range, sale prefix
  - Muscle score and fat score (when applicable)
  - Head count
  - Average price (¢/kg)
  - Average price ($/head)
  - Price changes from comparison date

**Directional Movements**
- Visual indicators on all cards
- Arrow icons for trends
- Percentage changes displayed

---

### 4. Intelligence Tab

**AI Predictive Insights**
- Forward-looking predictions (30-60+ day horizon)
- Confidence indicator: High / Medium / Low
  - High: Green with checkmark seal icon
  - Medium: Orange with warning triangle icon
  - Low: Gray with question circle icon
- Key drivers clearly listed (bullet points)
- Time horizon displayed (e.g., "30-45 days", "60 days", "90 days")
- Supporting micro-copy: *"Updated continuously from live market, weather, supply and demand data"*

**Example Intelligence Card:**
```
Category: Cattle - Weaners
Confidence: HIGH
Time Horizon: 30-45 days

Prediction: "Weaner prices expected to strengthen by 8-12% 
over the next 30-45 days as seasonal supply tightens."

Key Drivers:
• Reduced supply from drought-affected regions
• Strong restocking demand
• Favorable seasonal outlook

Updated 2 hours ago
```

---

## 📊 New Data Models

### TopInsight
```swift
struct TopInsight {
    let text: String           // Daily market sentence
    let date: Date            // When generated
    let category: String      // Related livestock category
}
```

### SaleyardReport
```swift
struct SaleyardReport {
    let saleyardName: String  // e.g., "Roma", "Wagga Wagga"
    let state: String         // e.g., "QLD", "NSW"
    let date: Date           // Sale date
    let yardings: Int        // Number of head yarded
    let summary: String      // Brief report text
    let categories: [String] // Categories traded
}
```

### PhysicalSalesReport *(NEW - MLA-style reports)*
```swift
struct PhysicalSalesReport {
    let id: String
    let saleyard: String
    let reportDate: Date
    let comparisonDate: Date?    // Previous date for comparisons
    let totalYarding: Int
    let categories: [PhysicalSalesCategory]
    let state: String?           // State where saleyard is located
    let summary: String?         // Text summary of market
    let audioURL: String?        // Audio recording URL
}

struct PhysicalSalesCategory {
    let id: String
    let categoryName: String     // e.g., "Yearling Steer", "Cows"
    let weightRange: String      // e.g., "400-500", "600+"
    let salePrefix: String       // "Feeder", "Processor", "PTIC", "Restocker"
    let muscleScore: String?     // e.g., "A", "B", "C"
    let fatScore: Int?           // 1-5
    let headCount: Int
    let minPriceCentsPerKg: Double?
    let maxPriceCentsPerKg: Double?
    let avgPriceCentsPerKg: Double?
    let minPriceDollarsPerHead: Double?
    let maxPriceDollarsPerHead: Double?
    let avgPriceDollarsPerHead: Double?
    let priceChangePerKg: Double?      // Change from comparison
    let priceChangePerHead: Double?    // Change from comparison
}
```

### MarketIntelligence
```swift
struct MarketIntelligence {
    let category: String         // e.g., "Cattle - Weaners"
    let prediction: String       // Forward-looking insight
    let confidence: ConfidenceLevel  // High/Medium/Low
    let timeHorizon: String     // e.g., "30-60 days"
    let keyDrivers: [String]    // Factors influencing prediction
    let lastUpdated: Date
}

enum ConfidenceLevel {
    case high, medium, low
}
```

---

## 🔄 Updated ViewModel Methods

### New Methods
```swift
// Load daily market insight
func loadTopInsight() async

// Load saleyard reports with optional state filter
func loadSaleyardReports(state: String? = nil) async

// Load AI predictions filtered by categories
func loadMarketIntelligence(forCategories: [String] = []) async

// Load prices for user's specific herd categories
func loadCategoryPrices(forCategories: [String]) async

// Load physical sales report for specific saleyard and date
func loadPhysicalSalesReport(saleyard: String? = nil, date: Date = Date()) async

// Load available report dates (last 7 days)
func loadAvailableReportDates() async

// Update physical sales saleyard filter
func selectPhysicalSaleyard(_ saleyard: String) async

// Update physical sales report date filter
func selectReportDate(_ date: Date) async
```

### Physical Sales Filtering
The Market Pulse tab now includes comprehensive filtering for Physical Sales Reports:

1. **Saleyard Selection**
   - Dropdown menu with common saleyards
   - Updates report when changed
   - Default: "Mount Barker"

2. **Report Date Selection**
   - Dropdown showing last 7 days
   - Allows viewing historical reports
   - Default: Today's date

3. **State Filter** *(optional)*
   - Filter reports by state (NSW, VIC, QLD, SA, WA, TAS, NT, ACT)
   - Capsule button style
   - Default: All states

4. **Category Filter** *(in PhysicalSalesTableView)*
   - Filter by livestock category
   - Options: All, Bulls, Cows, Grown Heifer, Grown Steer, Yearling Heifer, Yearling Steer
   - Client-side filtering
   - Default: All

5. **Sale Prefix Filter** *(in PhysicalSalesTableView)*
   - Filter by sale type
   - Options: All, Feeder, Processor, PTIC, Restocker
   - Client-side filtering
   - Default: All

### Removed Methods
- `selectLivestockType()` - No longer needed (personalized to user's herds)
- `selectSaleyard()` - Removed from main filters
- `clearFilters()` - Simplified filtering approach
- `filteredPrices` - Now handled by category-based filtering
- `hasActiveFilters` - Simplified approach

---

## 🎨 Design Patterns

### Tabbed Navigation
- Native iOS segmented control (`.pickerStyle(.segmented)`)
- 4 tabs with clear labels
- Haptic feedback on tab switch
- Matches Portfolio page pattern

### Card Design
- Consistent rounded rectangles (12px radius)
- Theme.cardBackground color
- Proper spacing (12-16px between cards)
- Clean, modern aesthetic

### Loading States
- Skeleton loading or spinner
- Preserves layout while loading
- Non-blocking UI updates

### Empty States
- Clear messaging
- Appropriate icons
- Helpful guidance text
- Graceful handling

---

## 🚀 Future Integration

### MLA API Ready
All mock data methods are structured for easy replacement:
```swift
// Current: Mock data
func fetchTopInsight() async -> TopInsight?

// Future: Real API
func fetchTopInsight() async -> TopInsight? {
    // Replace with MLA API call
    let response = try await mlaAPI.getTopInsight()
    return TopInsight(from: response)
}
```

### User Preferences Integration
- Already reads from `UserPreferences.filteredSaleyards`
- Uses `UserPreferences.defaultState` for filtering
- Ready for additional user customization

### Herd-Based Filtering
- Dynamically filters prices based on user's actual herds
- Uses `@Query` to observe HerdGroup changes
- Automatically updates when livestock added/removed

---

## ✅ Testing Checklist

- [x] All tabs render correctly
- [x] Segmented control switches between tabs
- [x] Top Insight banner displays
- [x] My Markets shows only user's categories
- [x] Empty state when user has no livestock
- [x] National indicators display with trends
- [x] Saleyard reports load and filter by state
- [x] Intelligence cards show confidence levels
- [x] Price detail sheets still work
- [x] Pull-to-refresh functionality
- [x] Loading states display properly
- [x] No linter errors
- [x] Follows iOS HIG guidelines

---

## 📝 Notes

### Design Decisions

1. **Removed old filters**: The previous livestock type, saleyard, and state filters were removed from the main view. Now filtering is personalized based on user's actual herds.

2. **Tabbed navigation**: Chose tabs over scrolling sections for better organization and focused views. Each tab has a specific purpose.

3. **Overview as landing**: Overview tab provides a dashboard-style view with quick access to other sections, plus the daily market insight.

4. **Confidence indicators**: Visual badges (High/Medium/Low) make it easy to assess prediction reliability at a glance.

5. **Mock data structure**: All data models are designed to match expected MLA API structure for seamless integration.

6. **Sheet-based saleyard selector**: Uses the same large, searchable sheet selector as Dashboard for consistency and better UX with long lists (iOS HIG compliance).

7. **Removed duplicate sections**: Consolidated saleyard selection and reports into the Physical Sales Report section to avoid redundancy and confusion.

8. **Filter grouping**: All filters are now grouped at the top in a logical 3-row layout that matches the MLA website:
   - Row 1: Date and State (temporal/geographic)
   - Row 2: Category and Sale Prefix (livestock classification)
   - Row 3: Saleyard (location selection with sheet)

9. **Client-side filtering**: Category and Sale Prefix filters work client-side for instant results, while Date, State, and Saleyard trigger new report loads from the API.

10. **Change duration indicators**: All price change indicators (My Markets, National Indicators, Regional Prices) display a "24h" label to clarify the time period. This aligns with MLA reporting standards where daily changes are the norm. The duration is stored in the data models for future flexibility (e.g., adding weekly/monthly views).

### Future Enhancements

- [ ] Add favorites/bookmarks for specific categories
- [ ] Enable push notifications for significant market changes
- [ ] Add export functionality for reports
- [ ] Integrate real-time price updates
- [ ] Add market alerts based on user preferences
- [ ] Historical comparison charts (year-over-year)

---

## 🎓 Code Quality

- ✅ Follows project's `.cursorrules` conventions
- ✅ Uses @Observable pattern (not @StateObject)
- ✅ Proper accessibility labels
- ✅ Debug comments throughout
- ✅ Haptic feedback on interactions
- ✅ Theme consistency
- ✅ Clean separation of concerns
- ✅ No duplicate code
- ✅ Async/await for data loading
- ✅ Parallel data fetching for performance

---

## 📱 User Experience

### Key UX Improvements

1. **Personalization**: Only shows relevant market data for user's livestock
2. **Clear hierarchy**: Tabbed navigation makes information easy to find
3. **Actionable insights**: AI predictions with confidence levels help decision-making
4. **Engagement**: Daily insight at top drives repeat visits
5. **Performance**: Parallel data loading ensures fast page loads
6. **Discoverability**: Overview tab provides clear paths to all features

### Accessibility

- Screen reader support for all elements
- Proper heading hierarchy
- High contrast design
- Sufficient touch targets (44pt minimum)
- Clear focus indicators

---

## 🔗 Related Documentation

- [Portfolio Page Structure](./PORTFOLIO-REDESIGN.md) - Similar tabbed pattern
- [Market Data Service API](../Services/MarketDataService.swift) - Data layer
- [Valuation Engine](./VALUATION-ENGINE.md) - Price calculations

---

**Built with ❤️ for StockmansWallet**

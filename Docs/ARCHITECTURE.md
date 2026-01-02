# Stockman's Wallet - Architecture

High-level architecture documentation for the application.

---

## 🏗 **Architecture Pattern**

### MVVM + SwiftUI Observation
```
View ← Observable Model → SwiftData
  ↓           ↓
Services   Valuation Engine
```

**Why:**
- SwiftUI's native observation pattern (@Observable)
- Clean separation of concerns
- Testable business logic
- Reactive UI updates

---

## 📦 **Layer Breakdown**

### 1. **Views Layer** (`/Views`)
**Responsibility:** UI presentation and user interaction

```
Views/
├── Dashboard/        # Portfolio overview
├── Portfolio/        # Asset management
├── Market/          # Market data
├── Reports/         # PDF generation
├── Settings/        # User preferences
└── Onboarding/      # First-run experience
```

**Characteristics:**
- Pure SwiftUI views
- Minimal logic (presentation only)
- No direct SwiftData access (through Environment)
- Observable models passed as dependencies

**Example:**
```swift
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var herds: [HerdGroup]
    @StateObject private var valuationEngine = ValuationEngine.shared
    
    // View only renders, logic in ValuationEngine
}
```

---

### 2. **Models Layer** (`/Models`)
**Responsibility:** Data structures and persistence

```
Models/
├── HerdGroup.swift        # Core livestock asset
├── UserPreferences.swift  # User settings
├── MarketPrice.swift      # Market data
└── SalesRecord.swift      # Transaction history
```

**Characteristics:**
- SwiftData `@Model` macro
- Business rules and validation
- Relationships between entities
- Computed properties for derived data

**Key Model: HerdGroup**
```swift
@Model
final class HerdGroup {
    var livestockType: String
    var breed: String
    var headCount: Int
    var initialWeight: Double
    // ... business logic
}
```

---

### 3. **Services Layer** (`/Services`)
**Responsibility:** Business logic and calculations

```
Services/
├── ValuationEngine.swift          # Core valuation logic
├── SalesService.swift             # Sales operations
├── MockDataService.swift          # Test data
├── HistoricalMockDataService.swift # Historical data
└── ReportExportService.swift      # PDF generation
```

**Characteristics:**
- Singleton pattern where appropriate
- Pure business logic (no UI)
- Observable for reactive updates
- Testable (can mock)

**Key Service: ValuationEngine**
```swift
class ValuationEngine: ObservableObject {
    static let shared = ValuationEngine()
    
    func calculateHerdValue(
        herd: HerdGroup,
        preferences: UserPreferences,
        modelContext: ModelContext
    ) async -> HerdValuation {
        // Complex valuation logic
    }
}
```

---

### 4. **Data Layer** (`/Data`)
**Responsibility:** Static reference data

```
Data/
└── ReferenceData.swift   # Breeds, saleyards, regions
```

**Characteristics:**
- Static constants
- No persistence (compiled into app)
- Reference lists (breeds, locations)

---

### 5. **Assets** (`/Assets.xcassets`, `/Animations`)
**Responsibility:** Visual resources

- Images and icons
- Color definitions
- Lottie animations
- App icons

---

## 🔄 **Data Flow**

### Read Flow
```
User Action → View → @Query → SwiftData → Model → View Update
```

### Write Flow
```
User Action → View → Service → SwiftData.insert/update → @Query Update → View Refresh
```

### Valuation Flow
```
Herd Data → ValuationEngine → Market Prices → Calculations → Valuation Result
```

---

## 🎯 **Key Design Decisions**

### State Management
**Decision:** SwiftUI Observation (@Observable)
**Why:**
- Native to SwiftUI
- Automatic dependency tracking
- Better performance than @ObservedObject
- Less boilerplate

### Data Persistence
**Decision:** SwiftData (not Core Data)
**Why:**
- Modern Swift-first API
- Macro-based (less code)
- Better type safety
- Automatic relationships

### No Coordinators/Routers
**Decision:** SwiftUI native navigation
**Why:**
- NavigationStack is powerful enough
- Simpler for smaller apps
- Less abstraction
- Easier to maintain

### Singleton Services
**Decision:** ValuationEngine.shared
**Why:**
- Heavy calculations (cache results)
- Shared state across app
- Observable for reactivity
- Easy dependency injection

---

## 📊 **Core Flows**

### App Launch
```
1. StockmansWalletApp.swift (@main)
2. Initialize ModelContainer
3. Check onboarding status
4. Show RootView (Onboarding or MainTabView)
```

### Data Persistence
```
SwiftData ModelContainer → SQLite → App Support Directory
Location: ~/Library/Application Support/StockmansWallet.sqlite
```

### Valuation Calculation
```
1. Herd data + preferences
2. Fetch market prices
3. Apply formulas (Appendix A)
4. Calculate projections
5. Apply cost to carry
6. Return HerdValuation
```

### PDF Generation
```
1. Gather data (herds + valuations)
2. Create PDF context
3. Render views to PDF
4. Save to temp directory
5. Present share sheet
```

---

## 🧪 **Testing Strategy**

### Unit Tests (`StockmansWalletTests/`)
- Model validation logic
- Service calculations (ValuationEngine)
- Utility functions
- Mock data generation

### UI Tests (`StockmansWalletUITests/`)
- Critical user flows
- Onboarding completion
- Add herd flow
- PDF generation

### Preview Testing
- SwiftUI previews for rapid iteration
- Mock container for preview data
- Test all states (empty, loading, error)

---

## 🔐 **Security Architecture**

### Data Security
- **SwiftData encryption:** Automatic at rest
- **Keychain:** For sensitive credentials (when added)
- **No network:** Currently offline-first
- **No analytics tracking:** User data stays on device

### Future: API Security
When adding backend (Supabase):
- HTTPS only
- Token-based authentication
- Environment variables for keys
- Secure credential storage

---

## 🚀 **Performance Considerations**

### SwiftData Optimization
- Fetch only needed data (@Query with predicates)
- Lazy loading for large lists
- Batch operations for imports

### UI Performance
- LazyVStack for long lists
- Async image loading
- Debounced search
- Cached calculations

### Memory Management
- Proper cleanup in deinit
- Cancel async tasks on dismiss
- Avoid retain cycles with @ObservableObject

---

## 📱 **Platform Integration**

### iOS Features Used
- **SwiftUI:** 100% SwiftUI (no UIKit except representables)
- **Charts:** Native framework for graphs
- **PDFKit:** For PDF viewing/generation
- **CoreLocation:** For property location (optional)
- **Haptics:** Touch feedback

### System Integrations
- **Share Sheet:** PDF export
- **Dynamic Type:** Text scaling
- **Dark Mode:** Always enabled
- **SF Symbols:** All icons

---

## 🔮 **Future Architecture Considerations**

### When Adding Backend (Supabase)
```
Current: App → SwiftData → SQLite
Future:  App → SwiftData (cache) → Supabase (sync)
```

### When Adding Auth
```
Services/
└── AuthService.swift        # Authentication
    - Sign in/out
    - Token management
    - Session persistence
```

### When Adding Cloud Sync
```
Services/
└── SyncService.swift        # Data synchronization
    - Upload changes
    - Download updates
    - Conflict resolution
```

---

## 📚 **Key Files to Understand**

1. **StockmansWalletApp.swift** - App entry point
2. **Theme.swift** - Design system
3. **ValuationEngine.swift** - Core business logic
4. **HerdGroup.swift** - Main data model
5. **DashboardView.swift** - Main screen example

---

## 🎓 **Learning Resources**

### SwiftUI
- Apple's SwiftUI tutorials
- WWDC sessions on SwiftUI
- Hacking with Swift - 100 Days of SwiftUI

### SwiftData
- WWDC 2023: Meet SwiftData
- Apple's SwiftData documentation
- Our HistoricalMockDataService.swift (good example)

### Architecture Patterns
- Apple's Data Modeling guide
- SwiftUI Architecture (objc.io)
- Our code as examples!

---

**Last Updated:** January 2026  
**Review:** When adding major features or refactoring



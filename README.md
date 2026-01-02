# Stockman's Wallet

An iOS application for livestock portfolio management, providing real-time valuation, market insights, and comprehensive asset tracking for farmers and graziers.

## 📱 Project Overview

Stockman's Wallet helps agricultural professionals manage their livestock assets with features including:
- Real-time portfolio valuation
- Herd management and tracking
- Market price monitoring
- Sales recording and reporting
- Interactive dashboard with historical data
- PDF report generation (Asset Register & Sales Summary)

## 🛠 Tech Stack

- **Platform:** iOS 17.0+
- **Language:** Swift 5.0
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData
- **Architecture:** MVVM with Observable pattern
- **Dependencies:**
  - Lottie (4.5.2) - Animations
  - Charts (System Framework) - Data visualization

## 📂 Project Structure

```
StockmansWallet/
├── Stockmans Wallet.xcodeproj/   # Xcode project files
├── StockmansWallet/               # Main source code
│   ├── StockmansWalletApp.swift  # App entry point
│   ├── Models/                    # SwiftData models
│   ├── Views/                     # SwiftUI views by feature
│   ├── Services/                  # Business logic & engines
│   ├── Data/                      # Reference data & constants
│   ├── Assets.xcassets/          # Images, colors, icons
│   └── Animations/               # Lottie animation files
├── Docs/                          # Developer documentation
├── Resources/                     # Reference materials
│   ├── Specifications/           # PDFs, requirements docs
│   └── Design/                   # Design assets, mockups
├── Scripts/                       # Build & automation scripts
└── README.md                      # This file
```

## 🚀 Getting Started

### Prerequisites
- macOS with Xcode 16.1+
- iOS 17.0+ device or simulator
- Active Developer account for device testing

### Setup
1. Clone/download the project
2. Open `Stockmans Wallet.xcodeproj` in Xcode
3. Wait for Swift Package Manager to resolve dependencies
4. Select your target device/simulator
5. Build and run (⌘R)

### Development Environment
- Uses SweetPad extension for VS Code/Cursor development
- Xcode command line tools required: `xcode-select -p` should show `/Applications/Xcode.app/Contents/Developer`

## 📋 Key Features

### Dashboard
- Portfolio value tracking with interactive charts
- 24-hour value change indicators
- Capital concentration breakdown
- Performance metrics

### Portfolio Management
- Add herds with detailed information
- Track individual animals or bulk groups
- CSV import for large datasets
- Real-time valuation engine

### Market View
- Current market prices by category
- Price change indicators
- Regional market data

### Reports
- Asset Register (PDF)
- Sales Summary (PDF)
- Share/export functionality

### Settings
- User preferences & property details
- Livestock preferences (mortality, calving rates)
- Cost-to-carry parameters
- Display settings

## 🏗 Architecture

- **State Management:** SwiftUI's Observation framework (@Observable)
- **Data Layer:** SwiftData for persistence
- **Valuation Engine:** Core business logic in `ValuationEngine.swift`
- **Mock Data Service:** Historical data generation for development/preview

## 📖 Documentation

- See `/Docs` for development guides and architecture notes
- See `/Resources/Specifications` for business requirements and workflows
- See `.cursorrules` for AI coding guidelines and project conventions

## 🔧 Build Configuration

- **Bundle ID:** com.leonernst.StockmansWallet
- **Deployment Target:** iOS 26.1
- **Swift Version:** 5.0
- **Supported Devices:** iPhone & iPad (Universal)

## 👨‍💻 Development

This project follows iOS best practices:
- Uses SwiftUI lifecycle
- Implements modern concurrency (async/await)
- Follows SOLID principles
- Component-based architecture
- No third-party analytics/tracking (privacy-focused)

## 📝 Notes

- Main entry point: `StockmansWalletApp.swift`
- Theme system: `Theme.swift` for consistent styling
- All views organized by feature in `Views/` subdirectories
- Models use SwiftData `@Model` macro for persistence

---

**Version:** 1.0  
**Created:** December 2025  
**Platform:** iOS



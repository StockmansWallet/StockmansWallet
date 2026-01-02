# Project Folder Structure Guide

This document explains the folder structure used in Stockman's Wallet and follows iOS development best practices.

## 📂 Root Level Structure

```
StockmansWallet/
├── Stockmans Wallet.xcodeproj/  # Xcode project configuration
├── StockmansWallet/              # Main application source code
├── Docs/                         # Developer documentation (you are here!)
├── Resources/                    # Reference materials and assets
├── Scripts/                      # Build scripts and automation
├── .cursorrules                  # AI assistant coding guidelines
├── .gitignore                    # Git ignore patterns
├── .vscode/                      # VS Code/Cursor settings
├── buildServer.json              # SweetPad configuration
└── README.md                     # Project overview
```

## 🎯 Purpose of Each Folder

### `/StockmansWallet/` - Source Code
**DO:** Store all Swift source files, SwiftUI views, models, and assets that compile into the app.

**Structure:**
```
StockmansWallet/
├── StockmansWalletApp.swift     # App entry point (@main)
├── Theme.swift                   # Global theme/styling
├── Info.plist                    # App configuration
├── LaunchScreen.storyboard       # Launch screen
│
├── Models/                       # SwiftData models
│   ├── HerdGroup.swift
│   ├── UserPreferences.swift
│   ├── MarketPrice.swift
│   └── SalesRecord.swift
│
├── Views/                        # SwiftUI views organized by feature
│   ├── Dashboard/
│   ├── Portfolio/
│   ├── Market/
│   ├── Reports/
│   ├── Settings/
│   ├── Onboarding/
│   └── MainTabView.swift
│
├── Services/                     # Business logic
│   ├── ValuationEngine.swift
│   ├── SalesService.swift
│   ├── MockDataService.swift
│   └── ReportExportService.swift
│
├── Data/                         # Static reference data
│   └── ReferenceData.swift
│
├── Assets.xcassets/             # Images, colors, icons
│   ├── AppIcon.appiconset/
│   ├── backgrounds/
│   ├── Colours/
│   └── Images/
│
└── Animations/                   # Lottie animation files
    └── *.json
```

**Rules:**
- ✅ All Swift files go here
- ✅ Assets that compile into the app
- ❌ No documentation or reference PDFs
- ❌ No temporary/test files

---

### `/Docs/` - Developer Documentation
**DO:** Store markdown files explaining architecture, setup guides, and development notes.

**Contents:**
- Architecture decisions
- Setup and installation guides
- Code conventions
- API documentation
- Development workflows
- This file (FOLDER_STRUCTURE.md)

**Format:** Prefer Markdown (.md) for easy reading on GitHub/web

**Examples:**
```
Docs/
├── FOLDER_STRUCTURE.md          # This file
├── ARCHITECTURE.md               # System design
├── SETUP.md                      # Getting started
├── FEATURES.md                   # Feature documentation
└── DEPLOYMENT.md                 # Release process
```

---

### `/Resources/` - Reference Materials
**DO:** Store design specifications, business requirements, mockups, and reference images.

**Structure:**
```
Resources/
├── Specifications/               # Business requirements & specs
│   ├── ADD HERD Flow.pdf
│   ├── Parameters.pdf
│   ├── Workflow.pdf
│   └── StockmansWallet_MasterDoc.pdf
│
└── Design/                       # Design assets & mockups
    ├── MANAGE ASSETS.png
    ├── Mockups/
    └── Wireframes/
```

**Rules:**
- ✅ PDFs, Word docs, design files
- ✅ Reference images and mockups
- ✅ Business requirements
- ❌ Not compiled into the app
- ❌ Not version-controlled assets (use Assets.xcassets for those)

---

### `/Scripts/` - Automation Scripts
**DO:** Store build scripts, deployment automation, and development tools.

**Examples:**
```
Scripts/
├── build.sh                      # Custom build script
├── deploy.sh                     # Deployment automation
├── generate_icons.sh             # Asset generation
└── lint.sh                       # Code linting
```

**Rules:**
- ✅ Shell scripts (.sh)
- ✅ Python/Ruby automation tools
- ✅ CI/CD configuration
- ❌ Not source code

---

### `/.vscode/` - Editor Configuration
**DO:** Store Cursor/VS Code workspace settings.

**Contents:**
- `settings.json` - Editor preferences (SweetPad config, formatting)
- `launch.json` - Debug configurations
- `tasks.json` - Build tasks

**Note:** This is automatically managed by your editor.

---

## 🚫 What NOT to Put in Root

❌ **Temporary files** - Use system temp directories
❌ **Build artifacts** - These go in `DerivedData/` (auto-generated)
❌ **Source code** - Always in `/StockmansWallet/`
❌ **Test data** - Use mock services in code
❌ **Personal notes** - Keep in a separate notes app or private folder

---

## 📝 Best Practices

### 1. Keep Root Clean
Only essential project files at root level:
- Project configuration files (.xcodeproj, .gitignore, README)
- Top-level organizational folders (Docs, Resources, Scripts)
- Editor configuration (.vscode, .cursorrules)

### 2. Organize by Feature, Not Type
Inside `/Views/`, organize by feature area (Dashboard, Portfolio) rather than by component type (Buttons, Cards).

### 3. Use Descriptive Names
- Folders: PascalCase or lowercase (e.g., `Models`, `services`)
- Files: PascalCase for Swift (e.g., `DashboardView.swift`)
- Docs: UPPERCASE.md for important docs (e.g., `README.md`)

### 4. Leverage Xcode's File System Sync
The project uses `PBXFileSystemSynchronizedRootGroup`, meaning Xcode automatically detects new files in `/StockmansWallet/`. No need to manually add each file!

### 5. Separate Concerns
- **Source code** → `/StockmansWallet/`
- **Documentation** → `/Docs/`
- **Reference** → `/Resources/`
- **Automation** → `/Scripts/`

---

## 🔄 When Structure Changes

If you add new top-level folders:
1. Update this document
2. Update `README.md` project structure section
3. Update `.gitignore` if needed
4. Document the purpose in both places

---

## 📚 Additional Reading

- [Apple's Xcode Project Structure](https://developer.apple.com/documentation/xcode)
- [iOS Project Best Practices](https://github.com/futurice/ios-good-practices)
- [Swift Style Guide](https://google.github.io/swift/)

---

**Last Updated:** January 2026



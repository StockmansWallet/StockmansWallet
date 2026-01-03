# Onboarding Flow Restructure - Implementation Summary

## Overview
The onboarding flow has been restructured to support two distinct user paths based on user type, following the workflow diagram provided.

## Changes Implemented

### 1. **Updated User Roles & Types** (`Models/UserPreferences.swift`)
- Added new roles: `Accountant`, `Succession Planner`
- Created `UserType` enum to distinguish between:
  - **Farmer/Grazier** (Green Path)
  - **Advisory Users** (Pink Path)
- Added company-related fields for advisory users:
  - `companyName`
  - `companyType`
  - `companyAddress`
  - `roleInCompany`
- **Changed default state to QLD** (as requested)

### 2. **New Pages Created**

#### `UserTypeSelectionPage.swift`
- **First page** of onboarding (replaces landing page)
- Card-based grid layout for user type selection
- Shows Farmer/Grazier vs Advisory User options
- For Advisory users, displays role sub-selection grid (Agribusiness Banker, Insurer, Livestock Agent, Accountant, Succession Planner)
- Uses same visual design pattern as YourRolePage for consistency

#### `CompanyInfoPage.swift`
- Company information collection for advisory users
- Fields:
  - Company Name (required)
  - Company Type (dropdown)
  - Your Role in Company (required)
  - Company Address (optional)

#### `OnboardingSummaryPage.swift`
- Final page showing review of entered information
- Dynamically displays either property info (farmers) or company info (advisory)
- Two action buttons: "Complete Setup" and "Skip for Now"

### 3. **Updated Onboarding Flow** (`Views/Onboarding/OnboardingView.swift`)

#### Green Path (Farmer/Grazier) - 5 Pages:
```
Page 0: UserTypeSelectionPage
  ↓
Page 1: AboutYouPage
  ↓
Page 2: YourPropertyPage
  ↓
Page 3: SecurityPrivacyPage (SHARED)
  ↓
Page 4: OnboardingSummaryPage (SHARED) → Dashboard (Farmer)
```

#### Pink Path (Advisory Users) - 5 Pages:
```
Page 0: UserTypeSelectionPage (with role selection)
  ↓
Page 1: AboutYouPage
  ↓
Page 2: CompanyInfoPage
  ↓
Page 3: SecurityPrivacyPage (SHARED)
  ↓
Page 4: OnboardingSummaryPage (SHARED) → Dashboard (Advisory User) → Clients
```

**Note:** Security/Privacy and Onboarding Summary pages are SHARED between both paths.

### 4. **Updated Components**

#### `OnboardingPageTemplate` (`Views/Onboarding/OnboardingComponents.swift`)
- Added `totalPages` parameter for dynamic progress indicators
- Progress dots now show 5 dots for both paths (since both are now 5 pages)

#### Page Updates
- **AboutYouPage**: Updated nextPage to 2, totalPages = 5
- **YourPropertyPage**: Updated nextPage to 3, totalPages = 5
- **CompanyInfoPage**: Updated nextPage to 3, totalPages = 5
- **SecurityPrivacyPage**: Updated nextPage to 4, totalPages = 5 (SHARED)
- **OnboardingSummaryPage**: totalPages = 5 (SHARED)

### 5. **Removed from Onboarding Flow**
The following pages were removed from the initial onboarding:
- `MarketPreferencesPage` - Can be configured later in Settings
- `ConnectYourAccountsPage` - Can be connected later in Settings
- `YourRolePage` - Now integrated into UserTypeSelectionPage

## User Experience

### Farmer Flow (5 Pages)
1. User selects "Farmer/Grazier" on first screen
2. Enters personal information (name, email)
3. Enters property details (name, PIC, state=QLD by default, GPS location)
4. Configures security (2FA, privacy compliance) - **SHARED PAGE**
5. Reviews summary and completes setup - **SHARED PAGE**
6. Lands on Farmer Dashboard with full portfolio features

### Advisory User Flow (5 Pages)
1. User selects "Advisory User" on first screen
2. Selects specific role (Banker, Insurer, Agent, Accountant, Planner)
3. Enters personal information (name, email)
4. Enters company information (company name, type, role, address)
5. Configures security (2FA, privacy compliance) - **SHARED PAGE**
6. Reviews summary and completes setup - **SHARED PAGE**
7. Lands on Advisory Dashboard with client management features

## Technical Notes

### State Management
- Uses `@Observable` pattern for UserPreferences
- Role selection determines entire flow branching
- UserType helper determines if role is advisory: `UserType.isAdvisoryRole(_:)`

### Validation Rules
- **Page 0**: User type required; Advisory users must also select specific role
- **Page 1**: First name, last name, valid email required
- **Page 2 (Farmer)**: Property name and state required
- **Page 2 (Advisory)**: Company name and role in company required
- **Page 3 (Farmer)**: APPs compliance acceptance required
- Summary pages: Always valid (can skip or complete)

### Data Persistence
- All fields saved to SwiftData on completion
- Branching logic preserves appropriate fields:
  - Farmers: Property fields populated, company fields nil
  - Advisory: Company fields populated, property fields nil

## Rules Applied
- **Rule 0**: Simple solutions, checked for existing similar code
- **Rule 1**: Using @Observable for state management, proper view model patterns
- **Rule 10**: Checked for existing structs before declaring new ones
- **Debug logs & comments**: Added throughout for readability

## Next Steps (Optional Enhancements)
1. **Dashboard Variations**: Create separate dashboard views for Farmer vs Advisory users
2. **Clients Page**: Implement client management for advisory users
3. **Feature Access Control**: Restrict/enable features based on user role
4. **Settings Integration**: Allow users to update property/company info from Settings
5. **Welcome Screens**: Re-enable welcome/features screens if needed (currently bypassed)

## Testing Checklist
- [ ] Test Farmer flow (all 5 pages)
- [ ] Test each Advisory role flow (all 4 pages)
- [ ] Test back navigation
- [ ] Test validation on each page
- [ ] Test data persistence after completion
- [ ] Test progress indicators (5 dots for farmers, 4 for advisory)
- [ ] Verify QLD default state
- [ ] Test summary page shows correct info for each role type


# Portfolio Three-Section Update

## Overview
Updated the Portfolio page to reorganize content from 2 sections (Overview/Assets) to 3 sections (Overview/Herds/Individual) with integrated search functionality and sell buttons.

### Key Features Added
1. **Three-section layout** - Separate tabs for Overview, Herds, and Individual animals
2. **Search functionality** - Inline search fields for Herds and Individual sections
3. **Floating sell button** - Prominent button at bottom of Herds/Individual pages
4. **Card sell buttons** - Quick sell action on each card's bottom right

## Changes Made

### 1. Updated PortfolioViewMode Enum
- Changed from 2 cases to 3 cases:
  - `overview` - Shows portfolio summary stats and breakdowns
  - `herds` - Shows only herd groups (headCount > 1)
  - `individual` - Shows only individual animals (headCount == 1)

### 2. Added Search Functionality
- Added `herdsSearchText` and `individualSearchText` state variables
- Created `SearchField` component - Reusable search text field with clear button
- Search filters by:
  - Herd name
  - Breed
  - Category
  - Species
  - Paddock name
  - Additional info

### 3. Content Sections
- **Overview Content** - Unchanged, shows portfolio summary cards
- **Herds Content** - New section that:
  - Displays search field at top (below segmented control)
  - Shows only herds with headCount > 1
  - Filters results based on search text
  - Shows empty state when no results found
- **Individual Content** - New section that:
  - Displays search field at top (below segmented control)
  - Shows only individual animals with headCount == 1
  - Filters results based on search text
  - Shows empty state when no results found

### 4. New Components

#### SearchField
- Reusable text field component with magnifying glass icon
- Shows clear button (X) when text is not empty
- Uses Theme.inputFieldBackground for consistent styling
- Auto-corrects disabled for better search experience

#### EmptySearchResultView
- Displays when no results found in search
- Shows appropriate icon (tray or magnifying glass)
- Different messages for empty state vs no search results
- Suggests actions to user

### 5. Filtering Logic
- `filteredHerds` - Filters active herds (not sold) with headCount > 1
- `filteredIndividuals` - Filters active herds (not sold) with headCount == 1
- Both apply case-insensitive search across multiple fields

## User Experience

### Before
- 2-section layout: Overview | Assets
- Assets section showed all herds and individuals mixed together
- No inline search capability in Assets view

### After
- 3-section layout: Overview | Herds | Individual
- Clear separation between herd groups and individual animals
- Search fields in both Herds and Individual sections
- Better organization and easier to find specific animals
- Empty states guide users when no results found

## Technical Notes

### Following Project Rules
- ✅ Debug logs and comments added throughout
- ✅ Uses @Observable pattern for state management
- ✅ SwiftUI-first approach with proper property wrappers
- ✅ Reusable components (SearchField, EmptySearchResultView)
- ✅ Maintains consistency with existing Theme system
- ✅ Performance: Filtered computations only when needed

### SwiftData Context Management
- **Critical Fix**: Pass herd IDs between views, not SwiftData objects
- Each view fetches objects from its own context using the ID
- Prevents cross-context issues and ensures first-tap reliability
- Same pattern successfully used in HerdDetailView

### Card Button Architecture
- Sell button positioned **outside** NavigationLink wrapper
- Prevents tap gesture conflicts
- Uses `.plain` button style to avoid style inheritance
- Divider separates navigation area from action button

### File Changes
- Modified: `StockmansWallet/Views/Portfolio/PortfolioView.swift`
  - Added search functionality for Herds and Individual sections
  - Added card sell buttons with preselection
  - Updated to three-section layout
- Modified: `StockmansWallet/Views/Portfolio/HerdDetailView.swift`
  - Added floating sell button at bottom of detail page
  - Added sell sheet presentation
- Modified: `StockmansWallet/Views/Portfolio/SellStockView.swift`
  - Added preselectedHerd parameter
  - Added automatic form pre-filling with valuation data
  - Added ValuationEngine integration for price calculation
  - Added loading state during valuation calculation

## Sell Button Features (Added)

### 1. Detail Page Sell Button
- **Location**: At the bottom of HerdDetailView (individual herd/animal detail pages)
- Regular full-width button with accent background
- Only visible when the herd/animal is not already sold
- Opens SellStockView with the current herd preselected and form pre-filled
- Clean, prominent design integrated into scrollable content

### 2. Card Sell Button
- **Location**: Full-width button at bottom of each card on list pages
- **Style**: Bordered button (accent stroke, transparent background, accent text)
- Says "Sell" (no icon for clean look)
- Separated from card content with divider
- **Works on first tap** - positioned outside NavigationLink to avoid tap conflicts
- Opens SellStockView with the specific herd preselected and form pre-filled

### 3. SellStockView Enhancement & Layout Improvements
- Now accepts optional `preselectedHerd` parameter
- **Pre-fills form automatically** when herd is preselected:
  - Herd selection auto-populated
  - Head count set to herd's total head count
  - **Price per kg pre-filled** using ValuationEngine calculation
  - **Total price auto-calculated** based on current weight and price
  - **Notes field pre-populated** with comprehensive herd information
  - Loading indicator shown while calculating valuation
- When opened without preselection, user selects herd manually
- **Improved Layout:**
  - "Select Herd" field is full-width with searchable menu
  - "Head Sold" and "Sale Date" are side-by-side to save space
  - Cleaner, more compact design
- **Fixed timing issue:** Pre-fill now happens immediately on sheet presentation

## User Experience Flow

### Selling from Card Button (List Pages)
1. User taps "Sell" button on specific card in Herds or Individual list
2. SellStockView opens with:
   - Herd preselected
   - Price per kg pre-filled with current market price
   - Total value calculated and displayed
   - Price source noted in comments
3. User can adjust price if needed and confirm sale

### Selling from Floating Button (Detail Page)
1. User views herd/individual detail page
2. User taps "Sell Stock" floating button at bottom
3. SellStockView opens with:
   - Current herd preselected
   - All form fields pre-filled with calculated values
   - Ready to confirm or adjust and sell

## Testing Recommendations

### Basic Portfolio Functionality
1. Test with empty portfolio (no herds/individuals)
2. Test with only herds (no individuals)
3. Test with only individuals (no herds)
4. Test with mixed herds and individuals
5. Test search functionality in both sections
6. Test clearing search text
7. Test segmented control switching between all 3 sections
8. Verify empty states display correctly
9. Check that filtering works for all searchable fields
10. Verify navigation to HerdDetailView still works from cards

### Sell Button Functionality
11. **Test card sell button (list pages)**
    - Verify it opens SellStockView with herd preselected
    - Verify price per kg is pre-filled from valuation
    - Verify total price is calculated correctly
    - Verify notes field shows price source
    - Verify button doesn't interfere with card navigation
    
12. **Test floating sell button (detail page)**
    - Verify it appears at bottom of HerdDetailView
    - Verify it doesn't appear for sold herds
    - Verify it opens SellStockView with current herd preselected
    - Verify form is pre-filled with valuation data
    - Verify button doesn't overlap with scrollable content
    
13. **Test form pre-filling**
    - Verify loading indicator appears during valuation
    - Verify price fields are disabled during loading
    - Verify calculated values match expected valuation
    - Verify user can still modify pre-filled values
    - Verify form validation still works correctly
    
14. **Test sell flow completion**
    - Verify sale records correctly from pre-filled form
    - Verify sold herds disappear from active lists
    - Verify sold herds don't show sell button on detail page
    - Verify partial sales reduce head count correctly


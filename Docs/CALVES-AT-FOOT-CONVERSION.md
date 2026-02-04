# Calves at Foot Conversion Feature

## Overview

Manual "calves at foot" entries are now automatically converted into real `HerdGroup` entities with proper daily weight gain tracking (0.9 kg/day for cattle). This ensures consistency between automatic and manual calf tracking.

## Problem Solved

**Before:**
- Manual "calves at foot" were stored as plain text in `additionalInfo` field
- They had no valuation, no weight tracking, no daily weight gain
- Inconsistent with automatically generated calves (which had 0.9 kg/day DWG)

**After:**
- Manual calves are converted to real `HerdGroup` entities
- They receive the same 0.9 kg/day DWG as automatic calves
- Full valuation and weight projection tracking
- Birth dates are backdated based on age for accurate weight calculations

## How It Works

### 1. User Input (Add/Edit Herd Flow)

**Fields added:**
- **Head**: Number of calves at foot
- **Average Age (Months)**: How old the calves are
- **Average Weight (kg)**: Current average weight of the calves *(NEW)*

**Storage:**
- Temporarily stored in `additionalInfo` as: `"Calves at Foot: X head, Y months, Z kg"`

### 2. Automatic Conversion (On Portfolio Load)

**When:**
- Every time the Portfolio or Dashboard loads
- Triggered by `CalvingManager.shared.processManualCalvesAtFoot()`

**Process:**
1. Scans all breeding herds for "Calves at Foot" text in `additionalInfo`
2. Parses the head count, age, and average weight
3. Creates individual `HerdGroup` entities for each calf
4. Sets appropriate daily weight gain:
   - **Cattle**: 0.9 kg/day
   - **Sheep**: 0.25 kg/day
   - **Goats**: 0.15 kg/day
   - **Pigs**: 0.5 kg/day
5. Calculates birth weight using one of two methods:
   - **If user provided weight**: Work backward from current weight: `birthWeight = currentWeight - (DWG × daysOld)`
   - **If no weight provided**: Estimate from mother's weight: `birthWeight = motherWeight × 7%` (cattle)
6. Backdates `createdAt` to the birth date (current date - age in months)
7. Removes "Calves at Foot" text from `additionalInfo`

### 3. Post-Conversion

**Calves are now:**
- Fully tracked `HerdGroup` entities
- Appear in Portfolio with projected weights
- Contribute to portfolio value calculations
- Inherit breed, saleyard, and location from mother
- Tagged with note: `"Converted from manual 'calves at foot' entry on [Mother Name]"`

## Code Changes

### Files Modified

1. **`AddHerdFlowView.swift`**
   - Added `calvesAtFootAverageWeight` state variable
   - Updated calves at foot info string to include weight

2. **`BreedersFormSection.swift`**
   - Added "Average Weight (kg)" input field to UI
   - Field appears full-width below Head and Age fields

3. **`EditHerdView.swift`**
   - Added `calvesAtFootAverageWeight` state variable
   - Created `parseCalvesAtFoot()` helper to extract existing data
   - Created `updateAdditionalInfo()` to save data back
   - Added UI fields for Head, Age, and Weight in breeding section

4. **`AddIndividualAnimalView.swift`**
   - Added `calvesAtFootAverageWeight` for component compatibility

5. **`CalvingManager.swift`** *(NEW FUNCTIONALITY)*
   - **`processManualCalvesAtFoot()`**: Main conversion function
   - **`parseCalvesAtFootData()`**: Extracts head, age, weight from string
   - **`generateManualCalves()`**: Creates individual calf `HerdGroup` entities
   - **`removeCalvesAtFootFromInfo()`**: Cleans up `additionalInfo` after conversion

6. **`PortfolioView.swift`**
   - Added call to `CalvingManager.shared.processManualCalvesAtFoot()` after automatic calving

7. **`DashboardView.swift`**
   - Added call to `CalvingManager.shared.processManualCalvesAtFoot()` after automatic calving

## Daily Weight Gain Values

| Species | DWG (kg/day) | Notes |
|---------|--------------|-------|
| Cattle  | 0.9          | Australian beef cattle standard |
| Sheep   | 0.25         | Lambs |
| Goats   | 0.15         | Kids |
| Pigs    | 0.5          | Piglets |

## Birth Weight Calculation

### Method 1: User Provided Weight (Preferred)
```swift
let daysOld = Double(ageMonths) * 30.0
let birthWeight = max(userWeight - (dwg × daysOld), userWeight × 0.3)
// Ensures birth weight is at least 30% of current weight
```

**Example:**
- User enters: 150 kg calf, 4 months old
- Days old: 120 days
- Calculated birth weight: 150 - (0.9 × 120) = 42 kg ✓
- Projected current weight: 42 + (0.9 × 120) = 150 kg ✓

### Method 2: Mother's Weight (Fallback)
```swift
let birthWeight = motherWeight × birthWeightRatio
// Cattle: 7%, Sheep: 8%, Goats: 8%, Pigs: 2%
```

**Example:**
- Mother: 550 kg cow
- Calf birth weight: 550 × 0.07 = 38.5 kg
- After 4 months: 38.5 + (0.9 × 120) = 146.5 kg

## Integration Points

**Triggered at:**
1. Portfolio page load (`PortfolioView.loadPortfolioSummary()`)
2. Dashboard page load (`DashboardView.loadDataIfNeeded()`)

**Execution order:**
1. Process automatic calving events (pregnant herds past gestation)
2. **Process manual calves at foot conversion** ← NEW
3. Calculate valuations and display portfolio

## User Experience

**What the user sees:**
1. User adds breeding herd with "10 calves at foot, 3 months, 120 kg"
2. Info is saved and displayed in Herd Details
3. Next time they load Portfolio/Dashboard:
   - 10 individual calf records automatically appear
   - Each calf has 0.9 kg/day DWG
   - Original "calves at foot" text removed
   - Calves are fully valued and tracked

**No action required** - conversion is automatic and transparent.

## Debug Logging

```swift
// When conversion occurs:
🍼 CalvingManager: Converting manual calves at foot for [Herd Name]
   Head count: 10
   Age: 3 months
   Weight: 120 kg
   Birth weight: 42.0 kg
   Daily weight gain: 0.9 kg/day
   Birth date (backdated): Oct 15, 2025
✅ CalvingManager: Converted 10 manual calves to real entities
```

## Rules Applied

- **"Avoid duplication"**: Manual and automatic calves now use the same DWG logic
- **"No stubbing/fake data"**: All calves are real `HerdGroup` entities with proper tracking
- **"Debug logs & comments"**: Extensive logging for troubleshooting
- **"Simple solutions"**: Reuses existing `CalvingManager` service instead of creating new patterns

## Testing Checklist

- [ ] Add breeding herd with calves at foot (with weight)
- [ ] Add breeding herd with calves at foot (without weight)
- [ ] Verify calves appear in Portfolio after reload
- [ ] Check calf daily weight gain is 0.9 kg/day for cattle
- [ ] Verify birth weight calculation is realistic
- [ ] Confirm "Calves at Foot" text removed from mother herd
- [ ] Edit existing herd with calves at foot data
- [ ] Verify backdated `createdAt` for accurate weight projections
- [ ] Test with Sheep (0.25 kg/day DWG)
- [ ] Verify calves inherit breed, saleyard, location from mother

## Future Enhancements

1. **Sex randomization**: Currently all calves are "Mixed", could randomize Male/Female
2. **Breed-specific DWG**: Different DWG for Angus vs Hereford, etc.
3. **User notification**: Show toast when calves are converted
4. **Conversion history**: Track when/how many calves were converted

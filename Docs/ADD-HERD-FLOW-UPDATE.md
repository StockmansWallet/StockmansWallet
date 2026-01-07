# Add Herd Flow Update

**Date:** January 7, 2026  
**Status:** ✅ Complete

## Overview
Updated the Add Herd flow to match the new reference screenshots provided by the user. The flow now has clearer separation between breeder selection and breeding details, with improved UI/UX.

## Changes Made

### 1. BreedersFormSection.swift - Complete Redesign

#### New Components:
- **BreederSelectionScreen**: Initial screen showing all three breeding program options
  - Artificial Insemination (with AI badge)
  - Controlled Breeding
  - Uncontrolled Breeding
  - Radio button selection style with descriptions
  - Matches reference screenshot design exactly

- **BreedingDetailsScreen**: Second screen showing breeding-specific inputs
  - Dynamic title based on selected breeding program type
  - Date pickers for AI and Controlled Breeding (Insemination Period / Joining Period)
  - Estimated Calving slider (0-100% range)
  - **Calves at Foot** section (moved from Physical Attributes)
    - Head Count field
    - Average Age (Months) field
  - Info note about calving accrual timing (for AI and Controlled only)

#### Updated Enum:
- `BreedingProgramType` enum updated with:
  - Cleaner raw values (removed "(AI)" suffix)
  - Badge property for AI identification
  - Calving note property for timing information
  - Simplified descriptions

### 2. AddHerdFlowView.swift - Flow Logic Updates

#### New Flow Structure:
**For Breeder Categories (5 steps):**
1. Basic Info (Name, Species, Breed, Category)
2. Breeder Selection (choose AI/Controlled/Uncontrolled)
3. Breeding Details (dates, calving rate, calves at foot)
4. Physical Attributes (head, age, weight, DWG, mortality)
5. Saleyard Selection

**For Non-Breeder Categories (3 steps):**
1. Basic Info
2. Physical Attributes
3. Saleyard Selection

#### Physical Attributes Screen Updates:
- **Daily Weight Gain**: Changed from slider to Toggle + conditional Slider
  - Toggle on/off with "Estimated" label
  - Shows slider only when enabled
  - Matches reference screenshot design

- **Mortality Rate**: Changed from slider to Toggle + conditional Slider
  - Toggle on/off with "Estimated" label
  - Shows slider only when enabled
  - Matches reference screenshot design

- **Calves at Foot**: Removed from Physical Attributes
  - Now shown in Breeding Details screen (step 3)
  - Only relevant for breeder categories

#### Updated Step Validation:
- Updated validation logic to handle new 5-step flow for breeders
- Proper validation for each step based on category type

### 3. AddIndividualAnimalView.swift - Compatibility Updates

#### Changes:
- Added state variables for `calvesAtFootHeadCount` and `calvesAtFootAgeMonths`
- Updated BreedersFormSection call to include new parameters
- Maintains backward compatibility with minimal changes

## Design Compliance

### Reference Screenshots Matched:
✅ Breeder selection screen with three options and radio buttons  
✅ AI badge on Artificial Insemination option  
✅ Breeding-specific screens (AI, Controlled, Uncontrolled)  
✅ Date pickers for Insemination/Joining Period  
✅ Estimated Calving slider (0-100%)  
✅ Calves at Foot section in breeding details  
✅ Toggle-based Daily Weight Gain and Mortality Rate  
✅ Info notes about calving accrual timing  

### HIG Compliance:
- All touch targets meet 44pt minimum
- Proper use of Typography (Theme.title, Theme.body, Theme.caption)
- Consistent spacing and padding
- Proper accessibility labels and traits
- Smooth animations and transitions
- Haptic feedback on interactions

## Testing Recommendations

### Manual Testing Checklist:
- [ ] Test Add Herd flow for breeder categories (Breeding Cow, Heifer, etc.)
  - [ ] Verify 5-step flow appears correctly
  - [ ] Test all three breeding program selections
  - [ ] Verify date pickers work for AI and Controlled
  - [ ] Test Calves at Foot input fields
  - [ ] Verify calving rate slider (0-100%)
  
- [ ] Test Add Herd flow for non-breeder categories (Steers, Weaners, etc.)
  - [ ] Verify 3-step flow appears correctly
  - [ ] Confirm breeder screens are skipped
  
- [ ] Test Physical Attributes screen
  - [ ] Toggle Daily Weight Gain on/off
  - [ ] Toggle Mortality Rate on/off
  - [ ] Verify sliders appear/disappear correctly
  
- [ ] Test Add Individual Animal flow
  - [ ] Verify breeder section works for individual animals
  - [ ] Confirm compatibility with updated component

## Code Quality

### Debug Logs:
- Added comprehensive debug comments explaining each section
- Comments reference HIG compliance and design decisions

### Rules Applied:
- ✅ Simple solutions (toggle + conditional slider vs complex UI)
- ✅ No code duplication (shared BreederSelectionScreen and BreedingDetailsScreen)
- ✅ HIG compliance (proper touch targets, typography, spacing)
- ✅ Accessibility (labels, traits, values)
- ✅ Clean and organized code structure

## Files Modified

1. `StockmansWallet/Views/Portfolio/BreedersFormSection.swift` - Complete redesign
2. `StockmansWallet/Views/Portfolio/AddHerdFlowView.swift` - Flow logic and UI updates
3. `StockmansWallet/Views/Portfolio/AddIndividualAnimalView.swift` - Compatibility updates

## Notes

- Legacy BreedersFormSection wrapper provided for backward compatibility
- Calves at Foot data stored in `additionalInfo` field of HerdGroup
- Breeding program type stored in `additionalInfo` for reference
- No breaking changes to data models or database schema


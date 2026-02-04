-- ============================================
-- UPDATE BREED PREMIUMS TO MATCH REAL SALES DATA
-- ============================================
-- Based on comparison:
--   MLA NHSI (live weight): 352¢/kg = $3.52/kg
--   Real sales reports: $4.47/kg for Grown Steer
--   Premium needed: +27%
--
-- This adjusts premiums from current +5% to realistic +25-30% for premium breeds
-- ============================================

-- Update premium breeds (Angus, Wagyu, etc.) to +28%
UPDATE breed_premiums
SET premium_pct = 28.0
WHERE breed IN ('Angus', 'Wagyu', 'Red Angus', 'Black Angus')
  AND active = true;

-- Update good quality crossbreeds to +20%
UPDATE breed_premiums
SET premium_pct = 20.0
WHERE breed IN (
  'Angus X',
  'Charolais X Angus',
  'Black Baldy',
  'Black Hereford',
  'Limousin X Friesian',
  'Murray Grey X Friesian'
)
AND active = true;

-- Update standard crossbreeds to +15%
UPDATE breed_premiums
SET premium_pct = 15.0
WHERE breed IN (
  'Cross Breed',
  'European Cross',
  'Hereford X Friesian',
  'Shorthorn X Friesian'
)
AND active = true;

-- Update tropical breeds to +12% (good for northern climates)
UPDATE breed_premiums
SET premium_pct = 12.0
WHERE breed IN (
  'Brahman',
  'Droughtmaster',
  'Brangus',
  'Santa Gertrudis',
  'Charbray'
)
AND active = true;

-- Update dairy-influenced breeds to +8% (lower meat quality)
UPDATE breed_premiums
SET premium_pct = 8.0
WHERE breed IN (
  'Friesian',
  'Friesian Cross',
  'Holstein'
)
AND active = true;

-- Update standard beef breeds to +10%
UPDATE breed_premiums
SET premium_pct = 10.0
WHERE breed IN (
  'Hereford',
  'Poll Hereford',
  'Shorthorn',
  'Murray Grey',
  'Charolais',
  'Limousin',
  'Simmental',
  'Speckle Park'
)
AND active = true;

-- Verify the changes
SELECT 
  category,
  breed,
  premium_pct,
  active
FROM breed_premiums
WHERE active = true
ORDER BY category, premium_pct DESC, breed;

-- Show example price calculations
SELECT 
  'Angus' as breed,
  '352 cents/kg (NHSI base)' as base,
  '352 * 1.28 = 450 cents/kg' as with_premium,
  '$4.50/kg final price' as result
UNION ALL
SELECT 
  'Droughtmaster',
  '352 cents/kg (NHSI base)',
  '352 * 1.12 = 394 cents/kg',
  '$3.94/kg final price'
UNION ALL
SELECT 
  'Cross Breed',
  '352 cents/kg (NHSI base)',
  '352 * 1.15 = 405 cents/kg',
  '$4.05/kg final price';

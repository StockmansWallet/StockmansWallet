-- ============================================
-- INCREASE ALL BREED PREMIUMS BY 20%
-- ============================================
-- This brings prices closer to real-world saleyard pricing
-- National averages tend to be 15-20% below coastal saleyard prices
-- ============================================

-- Update all breed premiums by multiplying by 1.2
UPDATE breed_premiums
SET premium_pct = ROUND(premium_pct * 1.2)
WHERE active = true;

-- Verify the updates
SELECT 
  breed,
  premium_pct as new_premium,
  COUNT(*) as category_count
FROM breed_premiums
WHERE breed IN ('Angus', 'Red Angus', 'Wagyu', 'Droughtmaster', 'Holstein', 'Cross Breed')
  AND active = true
GROUP BY breed, premium_pct
ORDER BY premium_pct DESC, breed;

-- Show all unique breeds with new premiums
SELECT DISTINCT
  breed,
  premium_pct
FROM breed_premiums
WHERE active = true
ORDER BY premium_pct DESC, breed;

-- ============================================
-- UPDATE ANGUS X BREED NAME AND PREMIUM
-- ============================================
-- Changes:
-- 1. Rename breed from "Angus X Friesian" to "Angus X"
-- 2. Update breed premium from 7% to 8%
-- ============================================

-- Update the breed name and premium in breed_premiums table
UPDATE breed_premiums
SET 
    breed = 'Angus X',
    premium_pct = 8.0,
    updated_at = NOW()
WHERE breed = 'Angus X Friesian'
  AND species = 'Cattle'
  AND active = true;

-- Verify the changes
SELECT 
    category,
    breed,
    premium_pct,
    species,
    active,
    updated_at
FROM breed_premiums
WHERE breed = 'Angus X'
  AND species = 'Cattle'
ORDER BY category;

-- Confirm no old entries remain
SELECT COUNT(*) as old_entries_remaining
FROM breed_premiums
WHERE breed = 'Angus X Friesian';

-- Show summary
SELECT 
    'Total Angus X entries updated:' as summary,
    COUNT(*) as count
FROM breed_premiums
WHERE breed = 'Angus X'
  AND species = 'Cattle'
  AND active = true;

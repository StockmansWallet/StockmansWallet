-- ============================================
-- UPDATE ALL BREED PREMIUMS - FINAL NATIONAL AVERAGES
-- ============================================
-- Based on analysis of MLA data and market knowledge
-- One premium per breed across all categories
-- Cross Breed = 0% baseline
-- ============================================

-- First, delete all existing breed premiums to start fresh
DELETE FROM breed_premiums;

-- Define all categories we need to populate
DO $$
DECLARE
  categories TEXT[] := ARRAY[
    'Breeding Cow',
    'Grown Steer',
    'Yearling Steer', 
    'Weaner Steer',
    'Feeder Steer',
    'Heifer',
    'Dry Cow',
    'Grown Bull',
    'Yearling Bull',
    'Weaner Bull'
  ];
  cat TEXT;
BEGIN
  -- For each category, insert all breeds with their premiums
  FOREACH cat IN ARRAY categories
  LOOP
    -- Premium Breeds (9-18%)
    INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
    ('Cattle', cat, 'Angus', 10.0, true),
    ('Cattle', cat, 'Red Angus', 9.0, true),
    ('Cattle', cat, 'Black Angus', 10.0, true),
    ('Cattle', cat, 'Wagyu', 18.0, true);
    
    -- Premium Crossbreeds (7-9%)
    INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
    ('Cattle', cat, 'Angus X Friesian', 7.0, true),
    ('Cattle', cat, 'Charolais X Angus', 9.0, true),
    ('Cattle', cat, 'Black Baldy', 7.0, true),
    ('Cattle', cat, 'Black Hereford', 7.0, true);
    
    -- Standard Crossbreeds (5-6%)
    INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
    ('Cattle', cat, 'Limousin X Friesian', 5.0, true),
    ('Cattle', cat, 'Murray Grey X Friesian', 6.0, true);
    
    -- Tropical Premium (1-6%)
    INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
    ('Cattle', cat, 'Brangus', 6.0, true),
    ('Cattle', cat, 'Brahman', 1.0, true),
    ('Cattle', cat, 'Droughtmaster', 4.0, true),
    ('Cattle', cat, 'Santa Gertrudis', 3.0, true),
    ('Cattle', cat, 'Charbray', 4.0, true),
    ('Cattle', cat, 'Senepol', 3.0, true);
    
    -- European Breeds (2-5%)
    INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
    ('Cattle', cat, 'Charolais', 5.0, true),
    ('Cattle', cat, 'Limousin', 4.0, true),
    ('Cattle', cat, 'Hereford', 4.0, true),
    ('Cattle', cat, 'Poll Hereford', 4.0, true),
    ('Cattle', cat, 'Shorthorn', 2.0, true),
    ('Cattle', cat, 'Murray Grey', 5.0, true),
    ('Cattle', cat, 'Simmental', 5.0, true),
    ('Cattle', cat, 'Gelbvieh', 5.0, true),
    ('Cattle', cat, 'Devon', 3.0, true);
    
    -- Specialty Breeds (3-8%)
    INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
    ('Cattle', cat, 'Speckle Park', 8.0, true),
    ('Cattle', cat, 'Lowline Angus', 8.0, true),
    ('Cattle', cat, 'Belted Galloway', 3.0, true),
    ('Cattle', cat, 'Square Meaters', 4.0, true);
    
    -- Dairy Influence (-2% to 1%)
    INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
    ('Cattle', cat, 'Holstein', -2.0, true),
    ('Cattle', cat, 'Friesian', -1.0, true),
    ('Cattle', cat, 'Friesian Cross', 1.0, true);
    
    -- Baseline (0%)
    INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
    ('Cattle', cat, 'Cross Breed', 0.0, true),
    ('Cattle', cat, 'European Cross', 0.0, true),
    ('Cattle', cat, 'Mixed Breed', 0.0, true);
  END LOOP;
END $$;

-- Verify the updates
SELECT 
  category,
  COUNT(*) as breed_count,
  MIN(premium_pct) as min_premium,
  MAX(premium_pct) as max_premium,
  AVG(premium_pct)::numeric(10,2) as avg_premium
FROM breed_premiums
WHERE active = true
GROUP BY category
ORDER BY category;

-- Show all unique breeds and their premiums
SELECT DISTINCT
  breed,
  premium_pct,
  COUNT(*) as category_count
FROM breed_premiums
WHERE active = true
GROUP BY breed, premium_pct
ORDER BY premium_pct DESC, breed;

-- Count total records
SELECT COUNT(*) as total_breed_premium_records FROM breed_premiums WHERE active = true;

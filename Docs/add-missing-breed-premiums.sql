-- ============================================
-- ADD BREED PREMIUMS FOR MISSING CATEGORIES
-- ============================================
-- This ensures ALL MLA categories have breed premiums
-- Categories that were missing: Dry Cow, Weaner Steer, Feeder Steer, Weaner Bull, Yearling Bull, Grown Bull
-- ============================================

-- DRY COW (Cull Cow in app)
INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
('Cattle', 'Dry Cow', 'Angus', 28.0, true),
('Cattle', 'Dry Cow', 'Red Angus', 28.0, true),
('Cattle', 'Dry Cow', 'Black Angus', 28.0, true),
('Cattle', 'Dry Cow', 'Wagyu', 28.0, true),
('Cattle', 'Dry Cow', 'Angus X', 8.0, true),
('Cattle', 'Dry Cow', 'Charolais X Angus', 20.0, true),
('Cattle', 'Dry Cow', 'Black Baldy', 20.0, true),
('Cattle', 'Dry Cow', 'Black Hereford', 20.0, true),
('Cattle', 'Dry Cow', 'Cross Breed', 15.0, true),
('Cattle', 'Dry Cow', 'European Cross', 15.0, true),
('Cattle', 'Dry Cow', 'Brahman', 12.0, true),
('Cattle', 'Dry Cow', 'Droughtmaster', 12.0, true),
('Cattle', 'Dry Cow', 'Brangus', 12.0, true),
('Cattle', 'Dry Cow', 'Santa Gertrudis', 12.0, true),
('Cattle', 'Dry Cow', 'Charbray', 12.0, true),
('Cattle', 'Dry Cow', 'Hereford', 10.0, true),
('Cattle', 'Dry Cow', 'Poll Hereford', 10.0, true),
('Cattle', 'Dry Cow', 'Shorthorn', 10.0, true),
('Cattle', 'Dry Cow', 'Friesian', 8.0, true),
('Cattle', 'Dry Cow', 'Friesian Cross', 8.0, true)
ON CONFLICT (species, category, breed) DO UPDATE 
SET premium_pct = EXCLUDED.premium_pct, active = EXCLUDED.active;

-- WEANER STEER (Calves in app)
INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
('Cattle', 'Weaner Steer', 'Angus', 28.0, true),
('Cattle', 'Weaner Steer', 'Red Angus', 28.0, true),
('Cattle', 'Weaner Steer', 'Black Angus', 28.0, true),
('Cattle', 'Weaner Steer', 'Wagyu', 28.0, true),
('Cattle', 'Weaner Steer', 'Angus X', 8.0, true),
('Cattle', 'Weaner Steer', 'Charolais X Angus', 20.0, true),
('Cattle', 'Weaner Steer', 'Black Baldy', 20.0, true),
('Cattle', 'Weaner Steer', 'Cross Breed', 15.0, true),
('Cattle', 'Weaner Steer', 'Brahman', 12.0, true),
('Cattle', 'Weaner Steer', 'Droughtmaster', 12.0, true),
('Cattle', 'Weaner Steer', 'Brangus', 12.0, true),
('Cattle', 'Weaner Steer', 'Charbray', 12.0, true),
('Cattle', 'Weaner Steer', 'Hereford', 10.0, true),
('Cattle', 'Weaner Steer', 'Charolais', 10.0, true)
ON CONFLICT (species, category, breed) DO UPDATE 
SET premium_pct = EXCLUDED.premium_pct, active = EXCLUDED.active;

-- FEEDER STEER
INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
('Cattle', 'Feeder Steer', 'Angus', 28.0, true),
('Cattle', 'Feeder Steer', 'Red Angus', 28.0, true),
('Cattle', 'Feeder Steer', 'Black Angus', 28.0, true),
('Cattle', 'Feeder Steer', 'Wagyu', 28.0, true),
('Cattle', 'Feeder Steer', 'Angus X', 8.0, true),
('Cattle', 'Feeder Steer', 'Charolais X Angus', 20.0, true),
('Cattle', 'Feeder Steer', 'Black Baldy', 20.0, true),
('Cattle', 'Feeder Steer', 'Cross Breed', 15.0, true),
('Cattle', 'Feeder Steer', 'Brahman', 12.0, true),
('Cattle', 'Feeder Steer', 'Droughtmaster', 12.0, true),
('Cattle', 'Feeder Steer', 'Brangus', 12.0, true),
('Cattle', 'Feeder Steer', 'Charbray', 12.0, true),
('Cattle', 'Feeder Steer', 'Hereford', 10.0, true),
('Cattle', 'Feeder Steer', 'Charolais', 10.0, true)
ON CONFLICT (species, category, breed) DO UPDATE 
SET premium_pct = EXCLUDED.premium_pct, active = EXCLUDED.active;

-- WEANER BULL
INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
('Cattle', 'Weaner Bull', 'Angus', 28.0, true),
('Cattle', 'Weaner Bull', 'Red Angus', 28.0, true),
('Cattle', 'Weaner Bull', 'Black Angus', 28.0, true),
('Cattle', 'Weaner Bull', 'Wagyu', 28.0, true),
('Cattle', 'Weaner Bull', 'Brahman', 12.0, true),
('Cattle', 'Weaner Bull', 'Droughtmaster', 12.0, true),
('Cattle', 'Weaner Bull', 'Brangus', 12.0, true),
('Cattle', 'Weaner Bull', 'Hereford', 10.0, true),
('Cattle', 'Weaner Bull', 'Charolais', 10.0, true)
ON CONFLICT (species, category, breed) DO UPDATE 
SET premium_pct = EXCLUDED.premium_pct, active = EXCLUDED.active;

-- YEARLING BULL
INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
('Cattle', 'Yearling Bull', 'Angus', 28.0, true),
('Cattle', 'Yearling Bull', 'Red Angus', 28.0, true),
('Cattle', 'Yearling Bull', 'Black Angus', 28.0, true),
('Cattle', 'Yearling Bull', 'Wagyu', 28.0, true),
('Cattle', 'Yearling Bull', 'Brahman', 12.0, true),
('Cattle', 'Yearling Bull', 'Droughtmaster', 12.0, true),
('Cattle', 'Yearling Bull', 'Brangus', 12.0, true),
('Cattle', 'Yearling Bull', 'Hereford', 10.0, true),
('Cattle', 'Yearling Bull', 'Charolais', 10.0, true)
ON CONFLICT (species, category, breed) DO UPDATE 
SET premium_pct = EXCLUDED.premium_pct, active = EXCLUDED.active;

-- GROWN BULL
INSERT INTO breed_premiums (species, category, breed, premium_pct, active) VALUES
('Cattle', 'Grown Bull', 'Angus', 28.0, true),
('Cattle', 'Grown Bull', 'Red Angus', 28.0, true),
('Cattle', 'Grown Bull', 'Black Angus', 28.0, true),
('Cattle', 'Grown Bull', 'Wagyu', 28.0, true),
('Cattle', 'Grown Bull', 'Brahman', 12.0, true),
('Cattle', 'Grown Bull', 'Droughtmaster', 12.0, true),
('Cattle', 'Grown Bull', 'Brangus', 12.0, true),
('Cattle', 'Grown Bull', 'Hereford', 10.0, true),
('Cattle', 'Grown Bull', 'Charolais', 10.0, true)
ON CONFLICT (species, category, breed) DO UPDATE 
SET premium_pct = EXCLUDED.premium_pct, active = EXCLUDED.active;

-- Verify all categories now have breed premiums
SELECT 
  category,
  COUNT(*) as breed_count
FROM breed_premiums
WHERE active = true
GROUP BY category
ORDER BY category;

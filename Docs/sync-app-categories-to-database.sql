-- ============================================
-- SYNC APP CATEGORIES TO DATABASE
-- ============================================
-- Purpose: Add smart mapping rules for ALL categories in ReferenceData.swift
-- Run this in Supabase SQL Editor to ensure all app categories have price data

-- ============================================
-- CATTLE CATEGORY MAPPINGS
-- ============================================

-- Map "Breeder" to "Breeding Cow"
INSERT INTO smart_mapping_rules (rule_name, conditions, target_category, target_mla_category, priority, notes, active)
VALUES (
  'Breeder (App Category)',
  '{"species": "Cattle", "sex": "Female", "is_breeder": true}',
  'Breeder',
  'Breeding Cow',
  48,
  'Maps app "Breeder" to MLA "Breeding Cow" prices',
  true
)
ON CONFLICT (rule_name) DO UPDATE SET
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  updated_at = NOW();

-- Map "Weaner Heifer" to "Heifer"
INSERT INTO smart_mapping_rules (rule_name, conditions, target_category, target_mla_category, priority, notes, active)
VALUES (
  'Weaner Heifer (App Category)',
  '{"species": "Cattle", "sex": "Female", "min_age_months": 6, "max_age_months": 12}',
  'Weaner Heifer',
  'Heifer',
  13,
  'Maps app "Weaner Heifer" to MLA "Heifer" prices',
  true
)
ON CONFLICT (rule_name) DO UPDATE SET
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  updated_at = NOW();

-- Map "Heifer (Unjoined)" to "Heifer"
INSERT INTO smart_mapping_rules (rule_name, conditions, target_category, target_mla_category, priority, notes, active)
VALUES (
  'Heifer (Unjoined)',
  '{"species": "Cattle", "sex": "Female", "is_joined": false}',
  'Heifer (Unjoined)',
  'Heifer',
  23,
  'Maps app "Heifer (Unjoined)" to MLA "Heifer" prices',
  true
)
ON CONFLICT (rule_name) DO UPDATE SET
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  updated_at = NOW();

-- Map "Heifer (Joined)" to "Heifer"
INSERT INTO smart_mapping_rules (rule_name, conditions, target_category, target_mla_category, priority, notes, active)
VALUES (
  'Heifer (Joined)',
  '{"species": "Cattle", "sex": "Female", "is_joined": true}',
  'Heifer (Joined)',
  'Heifer',
  24,
  'Maps app "Heifer (Joined)" to MLA "Heifer" prices',
  true
)
ON CONFLICT (rule_name) DO UPDATE SET
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  updated_at = NOW();

-- Map "First Calf Heifer" to "Breeding Cow"
INSERT INTO smart_mapping_rules (rule_name, conditions, target_category, target_mla_category, priority, notes, active)
VALUES (
  'First Calf Heifer',
  '{"species": "Cattle", "sex": "Female", "first_calf": true}',
  'First Calf Heifer',
  'Breeding Cow',
  49,
  'Maps app "First Calf Heifer" to MLA "Breeding Cow" prices',
  true
)
ON CONFLICT (rule_name) DO UPDATE SET
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  updated_at = NOW();

-- Map "Feeder Heifer" to "Heifer"
INSERT INTO smart_mapping_rules (rule_name, conditions, target_category, target_mla_category, priority, notes, active)
VALUES (
  'Feeder Heifer',
  '{"species": "Cattle", "sex": "Female", "min_weight_kg": 300, "max_weight_kg": 450}',
  'Feeder Heifer',
  'Heifer',
  26,
  'Maps app "Feeder Heifer" to MLA "Heifer" prices',
  true
)
ON CONFLICT (rule_name) DO UPDATE SET
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  updated_at = NOW();

-- Map "Cull Cow" to "Dry Cow"
INSERT INTO smart_mapping_rules (rule_name, conditions, target_category, target_mla_category, priority, notes, active)
VALUES (
  'Cull Cow',
  '{"species": "Cattle", "sex": "Female", "cull": true}',
  'Cull Cow',
  'Dry Cow',
  56,
  'Maps app "Cull Cow" to MLA "Dry Cow" prices',
  true
)
ON CONFLICT (rule_name) DO UPDATE SET
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  updated_at = NOW();

-- Map "Calves" to "Weaner Steer"
INSERT INTO smart_mapping_rules (rule_name, conditions, target_category, target_mla_category, priority, notes, active)
VALUES (
  'Calves',
  '{"species": "Cattle", "max_age_months": 6}',
  'Calves',
  'Weaner Steer',
  5,
  'Maps app "Calves" to MLA "Weaner Steer" prices (young cattle)',
  true
)
ON CONFLICT (rule_name) DO UPDATE SET
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  updated_at = NOW();

-- Map "Slaughter Cattle" to "Grown Steer"
INSERT INTO smart_mapping_rules (rule_name, conditions, target_category, target_mla_category, priority, notes, active)
VALUES (
  'Slaughter Cattle',
  '{"species": "Cattle", "slaughter_ready": true}',
  'Slaughter Cattle',
  'Grown Steer',
  41,
  'Maps app "Slaughter Cattle" to MLA "Grown Steer" prices',
  true
)
ON CONFLICT (rule_name) DO UPDATE SET
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  updated_at = NOW();

-- ============================================
-- BREED PREMIUMS FOR MISSING BREEDS
-- ============================================
-- Add premiums for breeds in ReferenceData.swift that aren't in the database yet

-- Default neutral premiums (0%) for all breeds
INSERT INTO breed_premiums (species, breed, category, premium_pct, source, active) VALUES
-- Cattle breeds (neutral premiums for breeds not yet in database)
('Cattle', 'Angus X', 'Yearling Steer', 8.0, 'Premium Crossbreed', true),
('Cattle', 'Black Baldy', 'Yearling Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Black Hereford', 'Yearling Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Brangus', 'Yearling Steer', 3.0, 'Industry Standard', true),
('Cattle', 'Charbray', 'Yearling Steer', 0.0, 'Industry Standard', true),
('Cattle', 'Charolais X Angus', 'Yearling Steer', 4.0, 'Industry Standard', true),
('Cattle', 'Cross Breed', 'Yearling Steer', 0.0, 'Industry Standard', true),
('Cattle', 'Droughtmaster', 'Yearling Steer', -1.0, 'Industry Standard', true),
('Cattle', 'European Cross', 'Yearling Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Friesian', 'Yearling Steer', -3.0, 'Industry Standard', true),
('Cattle', 'Friesian Cross', 'Yearling Steer', -1.0, 'Industry Standard', true),
('Cattle', 'Hereford X Friesian', 'Yearling Steer', 1.0, 'Industry Standard', true),
('Cattle', 'Limousin X Friesian', 'Yearling Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Murray Grey X Friesian', 'Yearling Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Poll Hereford', 'Yearling Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Red Angus', 'Yearling Steer', 4.0, 'Industry Standard', true),
('Cattle', 'Santa Gertrudis', 'Yearling Steer', 1.0, 'Industry Standard', true),
('Cattle', 'Shorthorn', 'Yearling Steer', 1.0, 'Industry Standard', true),
('Cattle', 'Shorthorn X Friesian', 'Yearling Steer', 0.0, 'Industry Standard', true),
('Cattle', 'Simmental', 'Yearling Steer', 3.0, 'Industry Standard', true),

-- Add same breeds for Grown Steer category
('Cattle', 'Angus X', 'Grown Steer', 8.0, 'Premium Crossbreed', true),
('Cattle', 'Black Baldy', 'Grown Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Black Hereford', 'Grown Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Brangus', 'Grown Steer', 3.0, 'Industry Standard', true),
('Cattle', 'Charbray', 'Grown Steer', 0.0, 'Industry Standard', true),
('Cattle', 'Charolais X Angus', 'Grown Steer', 4.0, 'Industry Standard', true),
('Cattle', 'Cross Breed', 'Grown Steer', 0.0, 'Industry Standard', true),
('Cattle', 'Droughtmaster', 'Grown Steer', -1.0, 'Industry Standard', true),
('Cattle', 'European Cross', 'Grown Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Friesian', 'Grown Steer', -3.0, 'Industry Standard', true),
('Cattle', 'Friesian Cross', 'Grown Steer', -1.0, 'Industry Standard', true),
('Cattle', 'Hereford X Friesian', 'Grown Steer', 1.0, 'Industry Standard', true),
('Cattle', 'Limousin X Friesian', 'Grown Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Murray Grey X Friesian', 'Grown Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Poll Hereford', 'Grown Steer', 2.0, 'Industry Standard', true),
('Cattle', 'Red Angus', 'Grown Steer', 4.0, 'Industry Standard', true),
('Cattle', 'Santa Gertrudis', 'Grown Steer', 1.0, 'Industry Standard', true),
('Cattle', 'Shorthorn', 'Grown Steer', 1.0, 'Industry Standard', true),
('Cattle', 'Shorthorn X Friesian', 'Grown Steer', 0.0, 'Industry Standard', true),
('Cattle', 'Simmental', 'Grown Steer', 3.0, 'Industry Standard', true),

-- Add for Heifer category (used by Weaner Heifer, Heifer (Unjoined), etc.)
('Cattle', 'Angus X', 'Heifer', 8.0, 'Premium Crossbreed', true),
('Cattle', 'Black Baldy', 'Heifer', 2.0, 'Industry Standard', true),
('Cattle', 'Black Hereford', 'Heifer', 2.0, 'Industry Standard', true),
('Cattle', 'Brangus', 'Heifer', 3.0, 'Industry Standard', true),
('Cattle', 'Charbray', 'Heifer', 0.0, 'Industry Standard', true),
('Cattle', 'Charolais X Angus', 'Heifer', 4.0, 'Industry Standard', true),
('Cattle', 'Cross Breed', 'Heifer', 0.0, 'Industry Standard', true),
('Cattle', 'Droughtmaster', 'Heifer', -1.0, 'Industry Standard', true),
('Cattle', 'European Cross', 'Heifer', 2.0, 'Industry Standard', true),
('Cattle', 'Friesian', 'Heifer', -3.0, 'Industry Standard', true),
('Cattle', 'Friesian Cross', 'Heifer', -1.0, 'Industry Standard', true),
('Cattle', 'Hereford X Friesian', 'Heifer', 1.0, 'Industry Standard', true),
('Cattle', 'Limousin X Friesian', 'Heifer', 2.0, 'Industry Standard', true),
('Cattle', 'Murray Grey X Friesian', 'Heifer', 2.0, 'Industry Standard', true),
('Cattle', 'Poll Hereford', 'Heifer', 2.0, 'Industry Standard', true),
('Cattle', 'Red Angus', 'Heifer', 4.0, 'Industry Standard', true),
('Cattle', 'Santa Gertrudis', 'Heifer', 1.0, 'Industry Standard', true),
('Cattle', 'Shorthorn', 'Heifer', 1.0, 'Industry Standard', true),
('Cattle', 'Shorthorn X Friesian', 'Heifer', 0.0, 'Industry Standard', true),
('Cattle', 'Simmental', 'Heifer', 3.0, 'Industry Standard', true),

-- Add for Breeding Cow category (used by Breeder, First Calf Heifer)
('Cattle', 'Angus X', 'Breeding Cow', 8.0, 'Premium Crossbreed', true),
('Cattle', 'Black Baldy', 'Breeding Cow', 2.0, 'Industry Standard', true),
('Cattle', 'Black Hereford', 'Breeding Cow', 2.0, 'Industry Standard', true),
('Cattle', 'Brangus', 'Breeding Cow', 3.0, 'Industry Standard', true),
('Cattle', 'Charbray', 'Breeding Cow', 0.0, 'Industry Standard', true),
('Cattle', 'Charolais X Angus', 'Breeding Cow', 4.0, 'Industry Standard', true),
('Cattle', 'Cross Breed', 'Breeding Cow', 0.0, 'Industry Standard', true),
('Cattle', 'Droughtmaster', 'Breeding Cow', -1.0, 'Industry Standard', true),
('Cattle', 'European Cross', 'Breeding Cow', 2.0, 'Industry Standard', true),
('Cattle', 'Friesian', 'Breeding Cow', -3.0, 'Industry Standard', true),
('Cattle', 'Friesian Cross', 'Breeding Cow', -1.0, 'Industry Standard', true),
('Cattle', 'Hereford X Friesian', 'Breeding Cow', 1.0, 'Industry Standard', true),
('Cattle', 'Limousin X Friesian', 'Breeding Cow', 2.0, 'Industry Standard', true),
('Cattle', 'Murray Grey X Friesian', 'Breeding Cow', 2.0, 'Industry Standard', true),
('Cattle', 'Poll Hereford', 'Breeding Cow', 2.0, 'Industry Standard', true),
('Cattle', 'Red Angus', 'Breeding Cow', 4.0, 'Industry Standard', true),
('Cattle', 'Santa Gertrudis', 'Breeding Cow', 1.0, 'Industry Standard', true),
('Cattle', 'Shorthorn', 'Breeding Cow', 1.0, 'Industry Standard', true),
('Cattle', 'Shorthorn X Friesian', 'Breeding Cow', 0.0, 'Industry Standard', true),
('Cattle', 'Simmental', 'Breeding Cow', 3.0, 'Industry Standard', true)

ON CONFLICT (species, breed, category, state, saleyard) DO NOTHING;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check total smart mapping rules
SELECT COUNT(*) as total_rules FROM smart_mapping_rules WHERE active = true;

-- Check rules for app categories
SELECT rule_name, target_category, target_mla_category, priority 
FROM smart_mapping_rules 
WHERE target_category IN ('Breeder', 'Weaner Heifer', 'Heifer (Unjoined)', 'Heifer (Joined)', 'First Calf Heifer')
ORDER BY priority;

-- Check breed premiums count
SELECT COUNT(*) as total_breed_premiums FROM breed_premiums WHERE active = true;

-- Success message
SELECT '✅ All app categories synced to database! Run edge function to generate prices.' as status;

-- Add Yearling Steer mapping rule if it doesn't exist
INSERT INTO smart_mapping_rules (
  rule_name,
  conditions,
  target_category,
  target_mla_category,
  priority,
  active
)
VALUES (
  'Yearling Steer',
  '{"species": "Cattle", "sex": "Male", "castrated": true, "min_age_months": 12, "max_age_months": 24}'::jsonb,
  'Yearling Steer',
  'Yearling Steer',
  20,
  true
)
ON CONFLICT (rule_name) DO UPDATE
SET 
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  priority = EXCLUDED.priority,
  active = EXCLUDED.active;

-- Add Yearling Bull mapping rule if it doesn't exist
INSERT INTO smart_mapping_rules (
  rule_name,
  conditions,
  target_category,
  target_mla_category,
  priority,
  active
)
VALUES (
  'Yearling Bull',
  '{"species": "Cattle", "sex": "Male", "castrated": false, "min_age_months": 12, "max_age_months": 24}'::jsonb,
  'Yearling Bull',
  'Yearling Bull',
  20,
  true
)
ON CONFLICT (rule_name) DO UPDATE
SET 
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  priority = EXCLUDED.priority,
  active = EXCLUDED.active;

-- Add Feeder Steer mapping rule if it doesn't exist  
INSERT INTO smart_mapping_rules (
  rule_name,
  conditions,
  target_category,
  target_mla_category,
  priority,
  active
)
VALUES (
  'Feeder Steer',
  '{"species": "Cattle", "sex": "Male", "castrated": true, "min_age_months": 18, "max_age_months": 30}'::jsonb,
  'Feeder Steer',
  'Feeder Steer',
  20,
  true
)
ON CONFLICT (rule_name) DO UPDATE
SET 
  target_category = EXCLUDED.target_category,
  target_mla_category = EXCLUDED.target_mla_category,
  priority = EXCLUDED.priority,
  active = EXCLUDED.active;

-- Verify the rules were created
SELECT rule_name, target_category, target_mla_category, priority, active 
FROM smart_mapping_rules 
WHERE rule_name IN ('Yearling Steer', 'Yearling Bull', 'Feeder Steer')
ORDER BY rule_name;

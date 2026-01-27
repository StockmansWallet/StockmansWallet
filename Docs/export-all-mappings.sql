-- Export all category mappings for review
SELECT 
  rule_name as "App Category Name",
  target_category as "App Category Code",
  target_mla_category as "Maps to MLA Category",
  priority as "Priority",
  active as "Active"
FROM smart_mapping_rules
ORDER BY target_mla_category, priority;

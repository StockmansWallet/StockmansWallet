-- Check if breed premiums were actually updated
SELECT 
  breed,
  premium_pct,
  COUNT(*) as category_count
FROM breed_premiums
WHERE breed IN ('Angus', 'Red Angus', 'Droughtmaster', 'Holstein')
  AND active = true
GROUP BY breed, premium_pct
ORDER BY breed;

-- Check total count
SELECT COUNT(*) as total_records FROM breed_premiums WHERE active = true;

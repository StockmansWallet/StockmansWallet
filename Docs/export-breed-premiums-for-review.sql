-- Export all breed premiums for review
SELECT 
  category,
  breed,
  premium_pct,
  active,
  CASE 
    WHEN premium_pct > 20 THEN 'Premium'
    WHEN premium_pct > 10 THEN 'Above Average'
    WHEN premium_pct > 0 THEN 'Average+'
    WHEN premium_pct = 0 THEN 'BASELINE'
    WHEN premium_pct < 0 THEN 'Below Average'
  END as tier
FROM breed_premiums
WHERE active = true
ORDER BY category, premium_pct DESC, breed;

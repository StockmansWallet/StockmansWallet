-- Check if Red Angus + Dry Cow exists
SELECT * FROM breed_premiums 
WHERE breed = 'Red Angus' AND category = 'Dry Cow';

-- Check all breeds for Dry Cow category
SELECT breed, premium_pct, active 
FROM breed_premiums 
WHERE category = 'Dry Cow'
ORDER BY breed;

-- Check all categories that have NO breed premiums
SELECT DISTINCT category 
FROM breed_premiums 
WHERE active = true
ORDER BY category;

-- Verify the newly generated prices
SELECT 
  category,
  breed,
  base_price_per_kg,
  breed_premium_pct,
  final_price_per_kg,
  final_price_per_kg / 100.0 as price_in_dollars,
  saleyard,
  data_date
FROM category_prices
WHERE breed IN ('Angus', 'Red Angus', 'Droughtmaster', 'Holstein')
  AND category IN ('Breeding Cow', 'Grown Steer', 'Dry Cow')
ORDER BY category, breed, saleyard
LIMIT 20;

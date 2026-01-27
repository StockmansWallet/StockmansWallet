-- Check the newly generated prices to verify they're using NHSI (live weight)
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
WHERE breed IN ('Angus', 'Droughtmaster', 'Charbray')
  AND category IN ('Breeding Cow', 'Grown Steer', 'Heifer')
  AND data_date >= CURRENT_DATE
ORDER BY category, breed
LIMIT 10;

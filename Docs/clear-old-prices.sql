-- Delete all old prices to force regeneration with new logic
DELETE FROM category_prices;

-- Verify deletion
SELECT COUNT(*) as remaining_prices FROM category_prices;

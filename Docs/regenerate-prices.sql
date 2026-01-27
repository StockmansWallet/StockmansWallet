-- Clear all existing prices to force regeneration
DELETE FROM category_prices;

-- Verify deletion
SELECT COUNT(*) as remaining_prices FROM category_prices;

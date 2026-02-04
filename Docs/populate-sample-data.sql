-- ============================================
-- POPULATE SAMPLE DATA - RUN IN SUPABASE SQL EDITOR
-- ============================================
-- Purpose: Insert pre-generated sample herds and historical prices
-- Run this ONCE in Supabase SQL Editor (not from app)
-- ============================================

-- Insert Sample Herds (15 diverse configurations)
INSERT INTO sample_herds (name, species, breed, sex, category, age_months, head_count, initial_weight, current_weight, daily_weight_gain, is_breeder, calving_rate, paddock_name, selected_saleyard, is_pregnant, days_offset) VALUES
('Angus Breeding Cows', 'Cattle', 'Angus', 'Female', 'Breeding Cow', 54, 120, 550.0, 550.0, 0.3, true, 0.88, 'River Paddock', 'Wagga Wagga Livestock Marketing Centre', true, -1090),
('Wagyu Breeding Cows', 'Cattle', 'Wagyu', 'Female', 'Breeding Cow', 58, 85, 580.0, 580.0, 0.25, true, 0.82, 'Back Hill', 'Dubbo Regional Livestock Market', true, -1070),
('Brahman Breeding Cows', 'Cattle', 'Brahman', 'Female', 'Breeding Cow', 48, 150, 520.0, 520.0, 0.35, true, 0.85, 'The Flats', 'Roma Saleyards', false, -1050),
('Yearling Steers', 'Cattle', 'Angus', 'Male', 'Yearling Steer', 18, 95, 380.0, 380.0, 0.6, false, 0.0, 'North Ridge', 'Wagga Wagga Livestock Marketing Centre', false, -1000),
('Feeder Steers', 'Cattle', 'Hereford', 'Male', 'Grown Steer', 28, 75, 450.0, 450.0, 0.5, false, 0.0, 'South Pasture', 'Dubbo Regional Livestock Market', false, -950),
('Weaner Steers', 'Cattle', 'Angus X', 'Male', 'Weaner Steer', 9, 140, 250.0, 250.0, 0.8, false, 0.0, 'East Valley', 'Wagga Wagga Livestock Marketing Centre', false, -900),
('Yearling Heifers', 'Cattle', 'Charolais', 'Female', 'Heifer', 15, 110, 320.0, 320.0, 0.7, false, 0.0, 'West Slope', 'Tamworth Regional Livestock Exchange', false, -850),
('Weaner Bulls', 'Cattle', 'Murray Grey', 'Male', 'Weaner Bull', 10, 60, 280.0, 280.0, 0.9, false, 0.0, 'Central Plains', 'Forbes Central West Livestock Exchange', false, -800),
('Grown Steers', 'Cattle', 'Droughtmaster', 'Male', 'Grown Steer', 29, 80, 480.0, 480.0, 0.65, false, 0.0, 'Upper Meadow', 'Roma Saleyards', false, -700),
('Limousin Yearlings', 'Cattle', 'Limousin', 'Male', 'Yearling Steer', 17, 100, 360.0, 360.0, 0.85, false, 0.0, 'Lower Field', 'Dubbo Regional Livestock Market', false, -550),
('Santa Gertrudis Weaners', 'Cattle', 'Santa Gertrudis', 'Male', 'Weaner Steer', 9, 130, 240.0, 240.0, 1.0, false, 0.0, 'Hill Top', 'Wagga Wagga Livestock Marketing Centre', false, -400),
('Red Angus Heifers', 'Cattle', 'Red Angus', 'Female', 'Heifer', 15, 90, 310.0, 310.0, 0.75, false, 0.0, 'Bottom Paddock', 'Tamworth Regional Livestock Exchange', false, -250),
('Merino Breeding Ewes', 'Sheep', 'Merino', 'Female', 'Breeding Ewe', 48, 500, 65.0, 65.0, 0.05, true, 0.92, 'Green Valley', 'Wagga Wagga Livestock Marketing Centre', true, -1020),
('Poll Dorset Breeding Ewes', 'Sheep', 'Poll Dorset', 'Female', 'Breeding Ewe', 52, 400, 70.0, 70.0, 0.06, true, 0.90, 'Dry Creek', 'Dubbo Regional Livestock Market', true, -980),
('Merino Wethers', 'Sheep', 'Merino', 'Male', 'Wether Lamb', 12, 600, 45.0, 45.0, 0.08, false, 0.0, 'Sunset Ridge', 'Wagga Wagga Livestock Marketing Centre', false, -600);

-- Success message
SELECT '✅ Sample herds inserted successfully' as status;

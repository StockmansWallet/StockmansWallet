-- ============================================
-- CATEGORY PRICES TABLE (SMART MAPPED)
-- ============================================
-- Purpose: Store MLA data mapped to user-friendly categories
-- with breed premiums, location specificity, and accreditation loadings

CREATE TABLE IF NOT EXISTS category_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Category Info (User-facing)
    category TEXT NOT NULL,              -- e.g., "Yearling Steer", "Breeding Cow"
    species TEXT NOT NULL,                -- "Cattle", "Sheep", "Pigs", "Goats"
    
    -- Breed Premium Info
    breed TEXT,                           -- e.g., "Angus", "Hereford", "Brahman" (NULL = general)
    breed_premium_pct DOUBLE PRECISION DEFAULT 0.0,  -- Premium % for this breed
    
    -- Price Data
    base_price_per_kg DOUBLE PRECISION NOT NULL,     -- Base price (¢/kg)
    final_price_per_kg DOUBLE PRECISION NOT NULL,    -- After breed premium
    weight_range TEXT,                     -- e.g., "400-500kg"
    
    -- Location Specificity
    saleyard TEXT,                         -- Specific saleyard name
    state TEXT,                            -- State code (NSW, VIC, QLD, etc.)
    
    -- Accreditation Premiums (future use)
    grass_fed_premium_pct DOUBLE PRECISION DEFAULT 0.0,
    organic_premium_pct DOUBLE PRECISION DEFAULT 0.0,
    eu_accredited_premium_pct DOUBLE PRECISION DEFAULT 0.0,
    
    -- Source & Attribution
    source TEXT NOT NULL,                  -- "MLA Physical Report", "MLA API", "Calculated"
    mla_category TEXT,                     -- Original MLA category name
    data_date DATE NOT NULL,               -- Date this price is for
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours'),
    
    -- Unique constraint: one price per category/breed/location/date
    UNIQUE(category, breed, saleyard, data_date)
);

-- ============================================
-- SMART MAPPING RULES TABLE
-- ============================================
-- Purpose: Store the logic for mapping user inputs to MLA categories

CREATE TABLE IF NOT EXISTS smart_mapping_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Rule Definition
    rule_name TEXT NOT NULL UNIQUE,
    
    -- Input Conditions (JSON for flexibility)
    conditions JSONB NOT NULL,  -- e.g., {"species": "Cattle", "sex": "Male", "castrated": true, "min_weight": 400}
    
    -- Output Mapping
    target_category TEXT NOT NULL,         -- Maps to category_prices.category
    target_mla_category TEXT,              -- Original MLA category to fetch
    
    -- Rule Metadata
    priority INTEGER DEFAULT 100,          -- Lower = higher priority
    active BOOLEAN DEFAULT true,
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- BREED PREMIUMS TABLE
-- ============================================
-- Purpose: Store breed-specific premium percentages

CREATE TABLE IF NOT EXISTS breed_premiums (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    species TEXT NOT NULL,
    breed TEXT NOT NULL,
    category TEXT NOT NULL,                -- Which category this premium applies to
    
    premium_pct DOUBLE PRECISION NOT NULL, -- Premium percentage (e.g., 5.0 for 5%)
    
    -- Location context (optional)
    state TEXT,                            -- NULL = applies nationally
    saleyard TEXT,                         -- NULL = applies to all saleyards
    
    -- Source
    source TEXT,                           -- "MLA CSV", "Historical Data", "AI Learning"
    confidence_score DOUBLE PRECISION DEFAULT 1.0,  -- 0-1, for AI-learned premiums
    
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(species, breed, category, state, saleyard)
);

-- ============================================
-- INDEXES
-- ============================================

-- Fast lookup by category and location
CREATE INDEX IF NOT EXISTS idx_category_prices_lookup 
    ON category_prices(category, saleyard, data_date DESC);

-- Breed-specific queries
CREATE INDEX IF NOT EXISTS idx_category_prices_breed 
    ON category_prices(category, breed, state, data_date DESC);

-- Non-expired prices (index on expires_at for fast filtering)
CREATE INDEX IF NOT EXISTS idx_category_prices_fresh 
    ON category_prices(expires_at);

-- Species filtering
CREATE INDEX IF NOT EXISTS idx_category_prices_species 
    ON category_prices(species, category, data_date DESC);

-- Smart mapping rules by priority
CREATE INDEX IF NOT EXISTS idx_smart_mapping_priority 
    ON smart_mapping_rules(priority, active) WHERE active = true;

-- Breed premiums lookup
CREATE INDEX IF NOT EXISTS idx_breed_premiums_lookup 
    ON breed_premiums(species, breed, category, active) WHERE active = true;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE category_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE smart_mapping_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE breed_premiums ENABLE ROW LEVEL SECURITY;

-- Allow anonymous read access (public data)
CREATE POLICY "Allow anonymous read access to category prices"
    ON category_prices FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous read access to smart mapping rules"
    ON smart_mapping_rules FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous read access to breed premiums"
    ON breed_premiums FOR SELECT TO anon USING (true);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE category_prices IS 'Smart-mapped livestock prices with breed premiums and location specificity';
COMMENT ON TABLE smart_mapping_rules IS 'Rules for translating user farm data to MLA categories';
COMMENT ON TABLE breed_premiums IS 'Breed-specific price premiums extracted from MLA physical reports';

COMMENT ON COLUMN category_prices.category IS 'User-friendly category (Yearling Steer, Breeding Cow, etc.)';
COMMENT ON COLUMN category_prices.breed IS 'Specific breed (Angus, Hereford, etc.) or NULL for general prices';
COMMENT ON COLUMN category_prices.mla_category IS 'Original MLA category this was derived from';

-- ============================================
-- SAMPLE SMART MAPPING RULES
-- ============================================

-- Insert default smart mapping rules
INSERT INTO smart_mapping_rules (rule_name, conditions, target_category, target_mla_category, priority, notes) VALUES
-- Cattle - Steers
('Weaner Steer', '{"species": "Cattle", "sex": "Male", "castrated": true, "min_age_months": 6, "max_age_months": 12}', 'Weaner Steer', 'Weaner Steer', 10, 'Young castrated male, 6-12 months'),
('Yearling Steer', '{"species": "Cattle", "sex": "Male", "castrated": true, "min_age_months": 12, "max_age_months": 24}', 'Yearling Steer', 'Yearling Steer', 20, 'Castrated male, 12-24 months'),
('Feeder Steer', '{"species": "Cattle", "sex": "Male", "castrated": true, "min_weight_kg": 400, "max_weight_kg": 600}', 'Feeder Steer', 'Feeder Steer', 30, 'Medium weight steers suitable for feedlot'),
('Grown Steer', '{"species": "Cattle", "sex": "Male", "castrated": true, "min_weight_kg": 500}', 'Grown Steer', 'Grown Steer', 40, 'Heavy steers, processor ready'),

-- Cattle - Bulls
('Weaner Bull', '{"species": "Cattle", "sex": "Male", "castrated": false, "min_age_months": 6, "max_age_months": 12}', 'Weaner Bull', 'Weaner Bull', 15, 'Young intact male, 6-12 months'),
('Yearling Bull', '{"species": "Cattle", "sex": "Male", "castrated": false, "min_age_months": 12, "max_age_months": 24}', 'Yearling Bull', 'Yearling Bull', 25, 'Intact male, 12-24 months'),
('Grown Bull', '{"species": "Cattle", "sex": "Male", "castrated": false, "min_age_months": 24}', 'Grown Bull', 'Grown Bull', 45, 'Mature bull'),

-- Cattle - Females
('Weaner Heifer', '{"species": "Cattle", "sex": "Female", "min_age_months": 6, "max_age_months": 12}', 'Heifer', 'Heifer', 12, 'Young female, 6-12 months'),
('Yearling Heifer', '{"species": "Cattle", "sex": "Female", "min_age_months": 12, "max_age_months": 24}', 'Heifer', 'Heifer', 22, 'Young female, 12-24 months'),
('Breeding Cow', '{"species": "Cattle", "sex": "Female", "is_breeder": true}', 'Breeding Cow', 'Breeding Cow', 50, 'Mature breeding female'),
('Dry Cow', '{"species": "Cattle", "sex": "Female", "is_pregnant": false, "is_lactating": false}', 'Dry Cow', 'Dry Cow', 55, 'Non-pregnant, non-lactating cow'),

-- Sheep - Males
('Wether Lamb', '{"species": "Sheep", "sex": "Male", "castrated": true, "max_age_months": 12}', 'Wether Lamb', 'Wether Lamb', 100, 'Castrated male lamb'),
('Merino Wether', '{"species": "Sheep", "sex": "Male", "castrated": true, "breed": "Merino"}', 'Merino Wether', 'Merino Wether', 105, 'Castrated Merino male'),

-- Sheep - Females
('Breeding Ewe', '{"species": "Sheep", "sex": "Female", "is_breeder": true}', 'Breeding Ewe', 'Breeding Ewe', 110, 'Mature breeding ewe'),
('Maiden Ewe', '{"species": "Sheep", "sex": "Female", "is_breeder": false, "max_age_months": 18}', 'Maiden Ewe', 'Maiden Ewe', 115, 'Young female, not yet bred')

ON CONFLICT (rule_name) DO NOTHING;

-- ============================================
-- SAMPLE BREED PREMIUMS
-- ============================================

-- Insert common breed premiums (based on industry knowledge)
INSERT INTO breed_premiums (species, breed, category, premium_pct, source) VALUES
-- Cattle breed premiums
('Cattle', 'Angus', 'Yearling Steer', 5.0, 'Industry Standard'),
('Cattle', 'Angus', 'Grown Steer', 5.0, 'Industry Standard'),
('Cattle', 'Wagyu', 'Yearling Steer', 15.0, 'Industry Standard'),
('Cattle', 'Wagyu', 'Grown Steer', 20.0, 'Industry Standard'),
('Cattle', 'Hereford', 'Yearling Steer', 2.0, 'Industry Standard'),
('Cattle', 'Brahman', 'Yearling Steer', -2.0, 'Industry Standard'),
('Cattle', 'Charolais', 'Grown Steer', 3.0, 'Industry Standard'),
('Cattle', 'Murray Grey', 'Yearling Steer', 3.0, 'Industry Standard'),

-- Sheep breed premiums
('Sheep', 'Merino', 'Wether Lamb', 8.0, 'Industry Standard'),
('Sheep', 'Poll Dorset', 'Wether Lamb', 5.0, 'Industry Standard')

ON CONFLICT (species, breed, category, state, saleyard) DO NOTHING;

-- Success message
SELECT '✅ Category prices tables and smart mapping rules created successfully' as status;

-- ============================================
-- HISTORICAL INDICATOR CACHE TABLE
-- ============================================
-- Purpose: Cache MLA historical indicator data (EYCI, WYCI, etc.)
-- Reduces API calls and provides fast access to historical data

CREATE TABLE IF NOT EXISTS mla_historical_indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    indicator_id INTEGER NOT NULL,
    indicator_name TEXT NOT NULL,
    indicator_code TEXT NOT NULL, -- EYCI, WYCI, etc.
    calendar_date DATE NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    unit TEXT DEFAULT '¢/kg cwt',
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique combination of indicator + date
    UNIQUE(indicator_id, calendar_date)
);

-- Index for fast lookups by indicator and date range
CREATE INDEX IF NOT EXISTS idx_historical_indicators_lookup 
    ON mla_historical_indicators(indicator_id, calendar_date DESC);

-- Index for code-based queries (e.g., get EYCI history)
CREATE INDEX IF NOT EXISTS idx_historical_indicators_code 
    ON mla_historical_indicators(indicator_code, calendar_date DESC);

-- Enable RLS
ALTER TABLE mla_historical_indicators ENABLE ROW LEVEL SECURITY;

-- Allow anonymous read access
CREATE POLICY "Allow anonymous read access to historical indicators"
    ON mla_historical_indicators FOR SELECT
    TO anon
    USING (true);

-- Comment
COMMENT ON TABLE mla_historical_indicators IS 'Cached historical data from MLA API for charting (EYCI, WYCI, NSI, NHLI over time)';

-- Success message
SELECT '✅ Historical indicator cache table created successfully' as status;

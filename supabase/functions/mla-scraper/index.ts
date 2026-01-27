// ============================================
// SUPABASE EDGE FUNCTION: MLA Data Scraper with Smart Mapping
// ============================================
// File: supabase/functions/mla-scraper/index.ts
// Deploy: supabase functions deploy mla-scraper --project-ref YOUR_PROJECT_REF

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ============================================
// CONFIGURATION
// ============================================

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const MLA_API_BASE = 'https://api-mlastatistics.mla.com.au'

// Indicator IDs for fetching from MLA API
// Using multiple indicators for category-specific base prices
const INDICATOR_IDS = {
  NRYSI: 2,  // National Restocker Yearling Steer Indicator (¢/kg live weight) - for Yearling Steer
  NFSI: 3,   // National Feeder Steer Indicator (¢/kg live weight) - for Feeder Steer
  NHSI: 4,   // National Heavy Steer Indicator (¢/kg live weight) - for Grown Steer, Cows, etc.
}

// Map MLA indicators to MLA categories
const INDICATOR_CATEGORY_MAP: Record<string, string[]> = {
  'NRYSI': ['Yearling Steer', 'Yearling Bull'],  // Younger cattle get yearling prices
  'NFSI': ['Feeder Steer'],  // Feeders
  'NHSI': ['Grown Steer', 'Grown Bull', 'Breeding Cow', 'Dry Cow', 'Heifer', 'Weaner Steer', 'Weaner Bull'],  // Everything else
}

// State to saleyard mapping (simplified)
const SALEYARDS_BY_STATE = {
  'NSW': ['Wagga Wagga Livestock Marketing Centre', 'Dubbo Regional Livestock Market'],
  'VIC': ['Ballarat Central Victoria Livestock Exchange', 'Warrnambool Livestock Exchange'],
  'QLD': ['Roma Saleyards', 'Gracemere Central Queensland Livestock Exchange'],
  'SA': ['Mount Gambier Saleyards', 'Dublin South Australian Livestock Exchange'],
  'WA': ['Muchea Livestock Centre', 'Mount Barker Great Southern Regional Cattle Saleyards'],
}

// ============================================
// INTERFACES
// ============================================

interface MLAIndicatorResponse {
  message: string
  'total number rows': number
  data: Array<{
    calendar_date: string
    species_id: string
    indicator_id: number
    indicator_desc: string
    indicator_units: string
    head_count: number
    indicator_value: number
  }>
}

interface CategoryPrice {
  category: string
  species: string
  breed?: string
  breed_premium_pct: number
  base_price_per_kg: number
  final_price_per_kg: number
  weight_range?: string
  saleyard: string
  state: string
  source: string
  mla_category: string
  data_date: string
}

interface SmartMappingRule {
  rule_name: string
  conditions: any
  target_category: string
  target_mla_category: string
  priority: number
}

interface BreedPremium {
  species: string
  breed: string
  category: string
  premium_pct: number
}

// ============================================
// MAIN HANDLER
// ============================================

serve(async (req) => {
  // Allow OPTIONS for CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } })
  }
  
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    console.log('🚀 Starting MLA data fetch and smart mapping...')
    console.log('🔑 Request method:', req.method)

    // Step 1: Fetch MLA indicator data
    console.log('📊 Fetching MLA indicators...')
    const indicatorData = await fetchMLAIndicators()
    console.log(`✅ Fetched ${indicatorData.length} MLA indicators`)
    
    if (indicatorData.length === 0) {
      console.error('❌ No MLA indicator data fetched! Aborting.')
      throw new Error('Failed to fetch MLA indicators')
    }

    // Step 2: Load smart mapping rules
    console.log('🗺️ Loading smart mapping rules...')
    const mappingRules = await loadSmartMappingRules(supabase)
    console.log(`✅ Loaded ${mappingRules.length} mapping rules`)

    // Step 3: Load breed premiums
    console.log('🏆 Loading breed premiums...')
    const breedPremiums = await loadBreedPremiums(supabase)
    console.log(`✅ Loaded ${breedPremiums.length} breed premiums`)

    // Step 4: Apply smart mapping
    console.log('✨ Applying smart mapping...')
    const mappedPrices = await applySmartMapping(
      indicatorData,
      mappingRules,
      breedPremiums
    )
    console.log(`✅ Generated ${mappedPrices.length} mapped prices`)

    // Step 5: Store in database
    console.log('💾 Storing mapped prices...')
    await storeCategoryPrices(supabase, mappedPrices)
    console.log('✅ Prices stored successfully')

    // Step 6: Cleanup old data
    console.log('🧹 Cleaning up expired prices...')
    await cleanupExpiredPrices(supabase)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'MLA data fetched and smart-mapped successfully',
        prices_generated: mappedPrices.length,
        timestamp: new Date().toISOString()
      }),
      {
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        status: 200
      }
    )

  } catch (error) {
    console.error('❌ Fatal Error:', error)
    console.error('❌ Error stack:', error.stack)
    console.error('❌ Error message:', error.message)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message,
        stack: error.stack
      }),
      {
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        status: 500
      }
    )
  }
})

// ============================================
// FETCH MLA INDICATORS
// ============================================

async function fetchMLAIndicators(): Promise<any[]> {
  const allData: any[] = []

  for (const [name, id] of Object.entries(INDICATOR_IDS)) {
    try {
      const url = `${MLA_API_BASE}/report/5?indicatorID=${id}`
      const response = await fetch(url, {
        headers: { 'Accept': 'application/json' }
      })

      if (!response.ok) {
        console.warn(`⚠️ Failed to fetch ${name} (ID ${id})`)
        continue
      }

      const data: MLAIndicatorResponse = await response.json()
      
      // Get the most recent data point
      if (data.data && data.data.length > 0) {
        const latest = data.data[0]
        allData.push({
          indicator_name: name,
          indicator_id: id,
          mla_category: latest.indicator_desc,
          price_cents_per_kg: latest.indicator_value,
          date: latest.calendar_date,
          head_count: latest.head_count
        })
        console.log(`✅ Fetched ${name}: ${latest.indicator_value}¢/kg`)
      }
    } catch (error) {
      console.error(`❌ Error fetching indicator ${name}:`, error)
    }
  }

  return allData
}

// ============================================
// LOAD SMART MAPPING RULES
// ============================================

async function loadSmartMappingRules(supabase: any): Promise<SmartMappingRule[]> {
  const { data, error } = await supabase
    .from('smart_mapping_rules')
    .select('*')
    .eq('active', true)
    .order('priority', { ascending: true })

  if (error) {
    console.error('Error loading mapping rules:', error)
    return []
  }

  return data || []
}

// ============================================
// LOAD BREED PREMIUMS
// ============================================

async function loadBreedPremiums(supabase: any): Promise<BreedPremium[]> {
  const { data, error } = await supabase
    .from('breed_premiums')
    .select('*')
    .eq('active', true)

  if (error) {
    console.error('Error loading breed premiums:', error)
    return []
  }

  return data || []
}

// ============================================
// APPLY SMART MAPPING
// ============================================

async function applySmartMapping(
  indicatorData: any[],
  mappingRules: SmartMappingRule[],
  breedPremiums: BreedPremium[]
): Promise<CategoryPrice[]> {
  const mappedPrices: CategoryPrice[] = []
  const today = new Date().toISOString().split('T')[0]

  // For each indicator, create prices for its assigned categories only
  for (const indicator of indicatorData) {
    const basePriceCentsPerKg = indicator.price_cents_per_kg
    const indicatorName = indicator.indicator_name
    
    // Get the categories that should use this indicator
    const categoriesForThisIndicator = INDICATOR_CATEGORY_MAP[indicatorName] || []
    
    console.log(`📊 Indicator ${indicatorName} (${basePriceCentsPerKg}¢/kg) → Categories: ${categoriesForThisIndicator.join(', ')}`)

    // Find mapping rules for categories assigned to this indicator
    const allRelevantRules = mappingRules.filter(rule => {
      return rule.target_mla_category && categoriesForThisIndicator.includes(rule.target_mla_category)
    })
    
    // De-duplicate rules by target_mla_category to avoid duplicate prices
    const seenCategories = new Set<string>()
    const relevantRules = allRelevantRules.filter(rule => {
      if (seenCategories.has(rule.target_mla_category)) {
        return false
      }
      seenCategories.add(rule.target_mla_category)
      return true
    })
    
    console.log(`🎯 Processing ${relevantRules.length} categories for ${indicatorName}`)

    // For each state and saleyard, create category prices
    for (const [state, saleyards] of Object.entries(SALEYARDS_BY_STATE)) {
      for (const saleyard of saleyards) {
        for (const rule of relevantRules) {
          // Create base price (no breed)
          // Debug: Store MLA category in database, not app category
          mappedPrices.push({
            category: rule.target_mla_category,
            species: 'Cattle',
            breed_premium_pct: 0,
            base_price_per_kg: basePriceCentsPerKg,
            final_price_per_kg: basePriceCentsPerKg,
            weight_range: getWeightRangeForCategory(rule.target_mla_category),
            saleyard,
            state,
            source: 'MLA API + Smart Mapping',
            mla_category: indicator.mla_category,
            data_date: today
          })

          // Create breed-specific prices
          // Debug: Look up breed premiums using MLA category, not app category
          console.log(`🔍 Looking for breed premiums for category="${rule.target_mla_category}"`)
          const relevantBreedPremiums = breedPremiums.filter(bp =>
            bp.species === 'Cattle' &&
            bp.category === rule.target_mla_category
          )
          console.log(`✅ Found ${relevantBreedPremiums.length} breed premiums for ${rule.target_mla_category}`)

          for (const breedPremium of relevantBreedPremiums) {
            const premiumMultiplier = 1 + (breedPremium.premium_pct / 100)
            const finalPrice = basePriceCentsPerKg * premiumMultiplier

            // Debug: Store MLA category in database, not app category
            mappedPrices.push({
              category: rule.target_mla_category,
              species: 'Cattle',
              breed: breedPremium.breed,
              breed_premium_pct: breedPremium.premium_pct,
              base_price_per_kg: basePriceCentsPerKg,
              final_price_per_kg: finalPrice,
              weight_range: getWeightRangeForCategory(rule.target_mla_category),
              saleyard,
              state,
              source: 'MLA API + Smart Mapping + Breed Premium',
              mla_category: indicator.mla_category,
              data_date: today
            })
          }
        }
      }
    }
  }

  console.log(`✅ Generated ${mappedPrices.length} smart-mapped prices`)
  return mappedPrices
}

// ============================================
// HELPER: GET WEIGHT RANGE
// ============================================

function getWeightRangeForCategory(category: string): string {
  const weightRanges: { [key: string]: string } = {
    'Weaner Steer': '200-330kg',
    'Weaner Bull': '200-330kg',
    'Yearling Steer': '330-400kg',
    'Yearling Bull': '330-400kg',
    'Feeder Steer': '400-600kg',
    'Grown Steer': '500-750kg',
    'Grown Bull': '600+kg',
    'Heifer': '300-450kg',
    'Breeding Cow': '450-550kg',
    'Dry Cow': '400+kg'
  }

  return weightRanges[category] || '300-500kg'
}

// ============================================
// STORE CATEGORY PRICES
// ============================================

async function storeCategoryPrices(supabase: any, prices: CategoryPrice[]): Promise<void> {
  // Debug: Deduplicate prices in-memory before inserting to avoid ON CONFLICT errors
  const uniquePrices = new Map<string, CategoryPrice>()
  
  for (const price of prices) {
    // Create unique key: category + breed + saleyard + state
    const breed = price.breed || 'null'
    const key = `${price.category}|${breed}|${price.saleyard}|${price.state}`
    
    // Keep only the first occurrence of each unique combination
    if (!uniquePrices.has(key)) {
      uniquePrices.set(key, price)
    }
  }
  
  const deduplicatedPrices = Array.from(uniquePrices.values())
  console.log(`🧹 Deduplicated ${prices.length} prices down to ${deduplicatedPrices.length} unique entries`)
  
  // Insert in batches of 100
  const batchSize = 100
  for (let i = 0; i < deduplicatedPrices.length; i += batchSize) {
    const batch = deduplicatedPrices.slice(i, i + batchSize)

    const { error } = await supabase
      .from('category_prices')
      .insert(batch)

    if (error) {
      console.error(`Error inserting batch ${i / batchSize + 1}:`, error)
    } else {
      console.log(`✅ Inserted batch ${i / batchSize + 1} (${batch.length} records)`)
    }
  }
}

// ============================================
// CLEANUP EXPIRED PRICES
// ============================================

async function cleanupExpiredPrices(supabase: any): Promise<void> {
  const { error } = await supabase
    .from('category_prices')
    .delete()
    .lt('expires_at', new Date().toISOString())

  if (error) {
    console.error('Error cleaning up expired prices:', error)
  } else {
    console.log('✅ Expired prices cleaned up')
  }
}

/* 
============================================
DEPLOYMENT INSTRUCTIONS
============================================

1. Install Supabase CLI:
   brew install supabase/tap/supabase

2. Login to Supabase:
   supabase login

3. Link your project:
   supabase link --project-ref YOUR_PROJECT_REF

4. Create the function:
   supabase functions new mla-scraper

5. Copy this file to:
   supabase/functions/mla-scraper/index.ts

6. Deploy:
   supabase functions deploy mla-scraper

7. Set up a daily cron job in Supabase Dashboard:
   - Go to Database → Extensions → Enable "pg_cron"
   - Run this SQL:

SELECT cron.schedule(
  'mla-daily-scrape',
  '0 1 * * *',  -- Every day at 1 AM AEST
  $$
  SELECT net.http_post(
    url:='https://YOUR_PROJECT_REF.supabase.co/functions/v1/mla-scraper',
    headers:='{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb
  );
  $$
);

8. Test manually:
   curl -X POST \
     https://YOUR_PROJECT_REF.supabase.co/functions/v1/mla-scraper \
     -H "Authorization: Bearer YOUR_ANON_KEY"

============================================
*/

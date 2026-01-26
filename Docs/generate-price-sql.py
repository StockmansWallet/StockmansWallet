#!/usr/bin/env python3
"""
Generate SQL INSERT statements for 3 years of historical market prices
Run this locally, then copy the output SQL to Supabase SQL Editor
"""

import math
from datetime import datetime, timedelta
import random

# Configuration
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime.now()
TOTAL_DAYS = min((END_DATE - START_DATE).days, 1095)  # Max 3 years
BASE_PRICE = 3.30  # Base price for Grown Steer

# Categories
CATEGORIES = [
    # Cattle
    "Feeder Steer", "Feeder Heifer", "Yearling Steer", "Yearling Bull",
    "Grown Steer", "Grown Bull", "Weaner Steer", "Weaner Bull", "Weaner Heifer",
    "Breeding Cow", "Breeder", "Dry Cow", "Cull Cow", "Heifer", 
    "First Calf Heifer", "Slaughter Cattle", "Calves",
    # Sheep
    "Breeding Ewe", "Maiden Ewe", "Dry Ewe", "Cull Ewe",
    "Weaner Ewe", "Feeder Ewe", "Slaughter Ewe",
    "Wether Lamb", "Weaner Lamb", "Feeder Lamb", "Slaughter Lamb", "Lambs",
    # Pigs
    "Breeder", "Dry Sow", "Cull Sow", "Weaner Pig", "Feeder Pig", 
    "Grower Pig", "Finisher Pig", "Porker", "Baconer", 
    "Grower Barrow", "Finisher Barrow",
    # Goats
    "Breeder Doe", "Dry Doe", "Cull Doe", "Breeder Buck", "Sale Buck",
    "Mature Wether", "Rangeland Goat", "Capretto", "Chevon"
]

SALEYARDS = [
    "Wagga Wagga Livestock Marketing Centre",
    "Dubbo Regional Livestock Market",
    "Roma Saleyards",
    "Ballarat Regional Livestock Exchange",
    "Mount Gambier Livestock Exchange"
]

STATES = ["NSW", "VIC", "QLD", "SA", "WA"]

def get_category_multiplier(category):
    """Apply category-specific price multipliers"""
    # Cattle
    if "Weaner" in category and any(x in category for x in ["Steer", "Bull", "Heifer"]):
        return 1.18
    elif "Yearling" in category and any(x in category for x in ["Steer", "Bull"]):
        return 1.22
    elif any(x in category for x in ["Breeding", "Heifer", "Dry Cow"]) or (category == "Breeder"):
        return 1.15
    elif "Cull Cow" in category:
        return 0.95
    elif "Feeder" in category and any(x in category for x in ["Steer", "Heifer"]):
        return 1.18
    elif "Grown" in category and any(x in category for x in ["Steer", "Bull"]):
        return 1.0
    elif "Slaughter Cattle" in category:
        return 0.92
    elif "Calves" in category:
        return 1.25
    # Sheep
    elif any(x in category for x in ["Breeding Ewe", "Maiden Ewe", "Dry Ewe"]):
        return 3.2
    elif any(x in category for x in ["Cull Ewe", "Slaughter Ewe"]):
        return 2.8
    elif any(x in category for x in ["Wether Lamb", "Weaner Lamb", "Feeder Lamb"]):
        return 3.5
    elif any(x in category for x in ["Slaughter Lamb", "Lambs"]):
        return 3.3
    # Pigs
    elif ("Breeder" in category or "Dry Sow" in category) and "Sow" in category:
        return 0.66
    elif "Cull Sow" in category:
        return 0.60
    elif any(x in category for x in ["Weaner Pig", "Feeder Pig"]):
        return 0.70
    elif "Grower" in category or "Finisher" in category:
        return 0.65
    elif "Porker" in category or "Baconer" in category:
        return 0.66
    # Goats
    elif "Breeder Doe" in category or "Dry Doe" in category:
        return 1.30
    elif "Cull Doe" in category:
        return 1.20
    elif "Breeder Buck" in category or "Sale Buck" in category:
        return 1.35
    elif "Mature Wether" in category or "Rangeland Goat" in category:
        return 1.30
    elif "Capretto" in category:
        return 1.53
    elif "Chevon" in category:
        return 1.25
    else:
        return 1.0

def calculate_price(day_offset):
    """Calculate realistic market price for a given day"""
    progress = day_offset / 1095.0  # 0 to 1 over 3 years
    
    # Market trend
    if progress < 0.2:
        trend = -0.05 * (progress / 0.2)
    elif progress < 0.4:
        decline_progress = (progress - 0.2) / 0.2
        trend = -0.05 - (0.25 * decline_progress)
    elif progress < 0.6:
        recovery_progress = (progress - 0.4) / 0.2
        trend = -0.30 + (0.20 * recovery_progress)
    elif progress < 0.8:
        recovery_progress = (progress - 0.6) / 0.2
        trend = -0.10 + (0.15 * recovery_progress)
    else:
        growth_progress = (progress - 0.8) / 0.2
        trend = 0.05 + (0.10 * growth_progress)
    
    # Seasonal variation
    date = END_DATE - timedelta(days=(TOTAL_DAYS - day_offset))
    day_of_year = date.timetuple().tm_yday
    seasonal = math.sin((day_of_year / 365.0 * 2 * math.pi) - (math.pi / 2)) * 0.10
    
    # Weekly volatility
    week_number = day_offset // 7
    weekly_seed = week_number % 13
    weekly_volatility = math.sin(weekly_seed / 13.0 * 2 * math.pi) * 0.08
    
    # Daily variation
    random.seed(day_offset)  # Consistent randomness
    daily_volatility = random.uniform(-0.03, 0.03)
    
    # Calculate final price
    adjusted_price = BASE_PRICE * (1.0 + trend + seasonal + weekly_volatility + daily_volatility)
    return max(3.10, min(3.50, adjusted_price))

# Generate SQL
print("-- ============================================")
print("-- HISTORICAL MARKET PRICES (3 YEARS)")
print("-- ============================================")
print("-- Generated:", datetime.now().isoformat())
print("-- Total records:", TOTAL_DAYS * len(CATEGORIES))
print("-- ============================================\n")

batch_size = 500
current_batch = []
total_records = 0

for day_offset in range(TOTAL_DAYS):
    date = END_DATE - timedelta(days=(TOTAL_DAYS - day_offset - 1))
    date_str = date.strftime('%Y-%m-%d')
    base_price = calculate_price(day_offset)
    
    for category in CATEGORIES:
        # Apply category multiplier
        category_price = base_price * get_category_multiplier(category)
        
        # Random saleyard and state
        random.seed(day_offset + hash(category))
        saleyard = random.choice(SALEYARDS).replace("'", "''")  # Escape quotes
        state = random.choice(STATES)
        
        # Determine source
        if day_offset < 7:
            source = "Saleyard"
        elif day_offset < 30:
            source = "State Indicator"
        else:
            source = "National Benchmark"
        
        # Build INSERT value
        value = f"('{category}', '{saleyard}', '{state}', {category_price:.4f}, '{date_str}', '{source}', true)"
        current_batch.append(value)
        total_records += 1
        
        # Write batch when full
        if len(current_batch) >= batch_size:
            print("INSERT INTO historical_market_prices (category, saleyard, state, price_per_kg, price_date, source, is_historical) VALUES")
            print(",\n".join(current_batch))
            print("ON CONFLICT (category, saleyard, price_date) DO NOTHING;\n")
            current_batch = []
            
            # Progress indicator
            if total_records % 5000 == 0:
                print(f"-- Progress: {total_records:,} records...")

# Write remaining batch
if current_batch:
    print("INSERT INTO historical_market_prices (category, saleyard, state, price_per_kg, price_date, source, is_historical) VALUES")
    print(",\n".join(current_batch))
    print("ON CONFLICT (category, saleyard, price_date) DO NOTHING;\n")

print(f"\n-- ✅ Complete: {total_records:,} total records")
print("-- Run this in Supabase SQL Editor")

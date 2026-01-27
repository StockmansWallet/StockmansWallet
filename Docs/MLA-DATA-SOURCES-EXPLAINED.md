# MLA Data Sources - Complete Explanation

## Two Different Data Sources from MLA:

---

## 1️⃣ MLA INDICATORS API (What we're currently using)

**URL**: `https://api-mlastatistics.mla.com.au/report/5?indicatorID=X`

**What it provides**: 
- **ONE single price per indicator** (national average)
- No sub-categories
- No weight ranges
- No sale purpose breakdown

**Example**:
```json
{
  "indicator_desc": "National Restocker Yearling Steer Indicator",
  "indicator_value": 383.28,  // ← Just ONE price for ALL yearling steers nationally
  "indicator_units": "c/kg lwt"
}
```

### Available Indicators (19 total):

**CATTLE (13):**
- ID 0: EYCI - Eastern Young Cattle (cwt)
- ID 1: WYCI - Western Young Cattle (cwt)
- ID 2: NRYSI - Restocker Yearling Steer (lwt) ✅ Currently using
- ID 3: NFSI - Feeder Steer (lwt) ✅ Currently using
- ID 4: NHSI - Heavy Steer (lwt) ✅ Currently using
- ID 5: Heavy Dairy Cow (lwt)
- ID 12: Restocker Yearling Heifer (lwt)
- ID 13: Processor Cow (lwt)
- ID 14: Young Cattle (lwt)
- ID 15: Online Young Cattle (lwt)
- ID 17: Feeder Heifer (lwt)

**SHEEP (6):**
- ID 6-11: Various lamb/mutton categories
- ID 16, 18: Online lamb/sheep

---

## 2️⃣ MLA PHYSICAL SALEYARD REPORTS (CSV files)

**URL**: `https://www.mla.com.au/prices-markets/...` (Various CSV downloads per saleyard)

**What it provides**:
- **Detailed category breakdowns** by:
  - Category (Yearling Steer, Cows, Bulls, etc.)
  - Weight Range (200-280kg, 330-400kg, etc.)
  - Sale Prefix (Feeder, Restocker, Processor)
  - Muscle Score (C, D)
  - Fat Score (2, 3, 4)
- **Specific prices per saleyard** (not national averages)
- **Both live weight (lwt) AND carcass weight (cwt)** prices

**Example** (from Armidale 22/01/2026):
```
Category,Weight Range,Sale Prefix,Head Count,Avg Lwt c/kg
Yearling Steer,200-280,Feeder,12,443.92
Yearling Steer,200-280,Restocker,10,378.50
Yearling Steer,330-400,Feeder,87,497.52
Grown Steer,400-500,Processor,10,436.00
Cows,520+,Processor,189,372.06
Bulls,600+,Processor,32,387.56
```

### Categories Available in Physical Reports:

From analyzing the Armidale report, MLA uses these **official categories**:

**CATTLE CATEGORIES:**
1. **Calves** (80+ kg)
2. **Vealer Steer** (0-280kg) - Very young males
3. **Vealer Heifer** (200-280kg) - Very young females
4. **Yearling Steer** (200-450kg) - Young castrated males
5. **Yearling Heifer** (200-450kg) - Young females
6. **Grown Steer** (400-600kg) - Mature castrated males
7. **Grown Heifer** (0-540kg+) - Mature females
8. **Cows** (400-520kg+) - Mature breeding/cull females
9. **Bulls** (0-600kg+) - Intact males

**WITHIN each category**, the reports break down by:
- **Sale Prefix**: Feeder, Restocker, Processor
- **Weight Ranges**: 200-280, 280-330, 330-400, 400-500, 500-600, etc.
- **Muscle Score**: C (good), D (average), B (bulls)
- **Fat Score**: 2, 3, 4

---

## 🎯 How This Affects Your App:

### Current Approach:
✅ Using **MLA Indicators API** → Get 3 national average prices:
- NRYSI: 383¢/kg → Use for Yearling Steer, Yearling Bull
- NFSI: ~370¢/kg → Use for Feeder Steer
- NHSI: 356¢/kg → Use for everything else (Grown Steer, Cows, Bulls, Heifers, Weaners)

✅ Then apply breed premiums to these base prices

### Limitations:
❌ **Same base price for different categories**:
   - Breeding Cow = Grown Steer = Dry Cow = Bulls (all using NHSI)
   
❌ **National averages don't reflect local saleyard pricing**:
   - NHSI is 356¢/kg nationally
   - But Armidale Grown Steer was 436¢/kg (22% higher!)

❌ **No weight range consideration**:
   - A 400kg steer vs 600kg steer get same ¢/kg price

### Alternative Approach (Future):
Could scrape **Physical Saleyard Reports** to get:
- Category-specific prices (Cows ≠ Steers)
- Saleyard-specific prices (Armidale ≠ National)
- Weight range-specific prices (400-500kg ≠ 500-600kg)

But this requires:
- CSV scraping/parsing logic
- Handling missing data (not all saleyards report daily)
- More complex fallback hierarchy

---

## 📋 Summary for Your Mapping:

**For MLA API Indicators**, you can only map to these **13 cattle categories**:
1. EYCI (Eastern Young Cattle - cwt)
2. WYCI (Western Young Cattle - cwt)
3. NRYSI (Yearling Steer - lwt) ← Using
4. NFSI (Feeder Steer - lwt) ← Using
5. NHSI (Heavy Steer - lwt) ← Using
6. Heavy Dairy Cow (lwt)
7. Restocker Yearling Heifer (lwt)
8. Processor Cow (lwt)
9. Young Cattle (lwt)
10. Online Young Cattle (lwt)
11. Feeder Heifer (lwt)

**Each indicator = ONE price** (no sub-categories).

You map YOUR app categories → MLA indicator that's closest match.

**For Physical Reports**, there are **9 main cattle categories** with detailed breakdowns:
- Calves, Vealer Steer, Vealer Heifer, Yearling Steer, Yearling Heifer, Grown Steer, Grown Heifer, Cows, Bulls

---

## ✅ Recommendation:

**For MVP**: Stick with Indicators API (simpler, reliable)
- Add more specific indicators (ID 12, 13, 14, 17) to differentiate categories

**For Post-MVP**: Consider Physical Reports scraping
- More accurate local pricing
- Category-specific prices
- But more complex to implement

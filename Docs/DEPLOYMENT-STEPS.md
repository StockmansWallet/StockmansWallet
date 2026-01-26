# Smart Mapping Deployment - Step by Step Guide

**Start Here** 👇

---

## 📋 **STEP 1: Create Database Tables**

### Actions:
1. Open **Supabase SQL Editor**
2. Open file: `Docs/create-category-prices-table.sql`
3. **Copy all SQL** and paste into SQL Editor
4. Click **"Run"**

### Expected Result:
```
✅ Category prices tables and smart mapping rules created successfully
```

### Verify:
Run this to check tables were created:
```sql
SELECT COUNT(*) as rules FROM smart_mapping_rules;
SELECT COUNT(*) as premiums FROM breed_premiums;
```

Should show: ~12 rules, ~10 premiums

**✋ STOP HERE until you confirm this worked**

---

## 📋 **STEP 2: Install Supabase CLI**

### Actions:
```bash
# Install CLI
brew install supabase/tap/supabase

# Login (will open browser)
supabase login

# Link your project
supabase link --project-ref skgdpvsxwbtnxpgviteg
```

### Expected Result:
```
✅ Linked to project skgdpvsxwbtnxpgviteg
```

**✋ STOP HERE until CLI is installed and linked**

---

## 📋 **STEP 3: Create Edge Function**

### Actions:
```bash
# Navigate to project root
cd "/Users/leon/Desktop/CURRENT WORK/Stockmans Wallet/StockmansApp/StockmansWallet"

# Create function directory
supabase functions new mla-scraper
```

This creates: `supabase/functions/mla-scraper/index.ts`

### Then:
1. **Open** the file `Docs/supabase-edge-function-mla-scraper.ts`
2. **Copy all the TypeScript code**
3. **Paste into** `supabase/functions/mla-scraper/index.ts` (overwrite existing content)
4. **Save the file**

**✋ STOP HERE until function file is ready**

---

## 📋 **STEP 4: Deploy Edge Function**

### Actions:
```bash
# Deploy the function
supabase functions deploy mla-scraper --project-ref skgdpvsxwbtnxpgviteg
```

### Expected Result:
```
Deploying function mla-scraper...
✅ Function deployed successfully
URL: https://skgdpvsxwbtnxpgviteg.supabase.co/functions/v1/mla-scraper
```

### Test It:
```bash
# Run the function manually
supabase functions invoke mla-scraper --project-ref skgdpvsxwbtnxpgviteg
```

Should return:
```json
{
  "success": true,
  "prices_generated": 500,
  "message": "MLA data fetched and smart-mapped successfully"
}
```

**✋ STOP HERE until function runs successfully**

---

## 📋 **STEP 5: Set Up Daily Auto-Run**

### Actions:
1. Go to **Supabase SQL Editor**
2. Run this SQL:

```sql
-- Enable cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule daily run at 1 AM AEST (after MLA updates)
SELECT cron.schedule(
  'mla-daily-scrape',
  '0 1 * * *',
  $$
  SELECT net.http_post(
    url:='https://skgdpvsxwbtnxpgviteg.supabase.co/functions/v1/mla-scraper',
    headers:='{"Content-Type": "application/json", "Authorization": "Bearer sb_publishable_7a2QWHYFG4eWlRqAvmidKg_D8170ZDN"}'::jsonb
  );
  $$
);
```

### Verify:
```sql
-- Check scheduled jobs
SELECT * FROM cron.job;
```

Should show your `mla-daily-scrape` job.

**✋ STOP HERE until cron job is set up**

---

## 📋 **STEP 6: Verify Data in Database**

### Actions:
Run in Supabase SQL Editor:

```sql
-- Check how many prices were generated
SELECT COUNT(*) as total_prices FROM category_prices;

-- View sample prices
SELECT category, breed, saleyard, state, 
       final_price_per_kg, data_date 
FROM category_prices 
WHERE species = 'Cattle'
ORDER BY category, breed NULLS FIRST
LIMIT 20;
```

### Expected Result:
Should see ~500-1000 price records with different categories, breeds, saleyards.

**✋ STOP HERE until you see data in the table**

---

## 📋 **STEP 7: Update iOS App Config**

### Actions:
1. Open `Config.swift` in Xcode
2. Change these values:

```swift
static let useSupabaseBackend = true   // Enable Supabase
static let useMockData = false          // Disable mock data
```

3. **Save the file**

**✋ STOP HERE until Config.swift is updated**

---

## 📋 **STEP 8: Test in iOS App**

### Actions:
1. **Build and run** your app
2. **Go to Markets tab** → **"My Markets"**
3. **If you don't have a herd:** Add one (Portfolio → Add Herd → Yearling Steer)
4. **Refresh the Markets page** (pull down or tap refresh icon)
5. **Check console logs** in Xcode for:
   ```
   🔵 Debug: Attempting to fetch from Supabase category_prices...
   ✅ Debug: Got X prices from Supabase
   ```

### Expected Result:
- **Prices display instantly** (<1 second)
- **No lag or freezing**
- **Real data from MLA** (matches their website)
- **Breed premiums applied** (if you check Angus vs other breeds)

---

## 🎉 Success!

If all steps completed:

✅ **Server-side smart mapping** working  
✅ **Real MLA data** being used  
✅ **No client-side lag**  
✅ **Breed premiums** automatically applied  
✅ **Daily updates** scheduled  

---

## ⚠️ If Something Goes Wrong

### **App shows "No price data available":**
1. Check `category_prices` table has data: `SELECT COUNT(*) FROM category_prices;`
2. Check Config.swift has correct values
3. Check console logs for errors

### **Edge Function fails:**
```bash
# Check logs
supabase functions logs mla-scraper --project-ref skgdpvsxwbtnxpgviteg
```

### **Need help:**
1. Check the full documentation: `SMART-MAPPING-IMPLEMENTATION.md`
2. Post the error message and we'll debug

---

**Start with STEP 1 and work through each step!** 🚀

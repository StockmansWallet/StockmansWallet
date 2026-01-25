# Supabase Backend Setup Guide

**Date**: January 25, 2026  
**Status**: ✅ iOS Integration Complete - Backend Configuration Needed

---

## 🎯 Overview

This guide walks you through completing the Supabase backend setup for StockmansWallet. The iOS app is ready to connect to Supabase - you just need to add your credentials and configure the backend.

---

## ✅ What's Already Done

- ✅ Supabase Swift package added to Xcode project
- ✅ Database tables created in Supabase
- ✅ `Config.swift` created for storing credentials
- ✅ `SupabaseClient.swift` created for backend connection
- ✅ `SupabaseMarketService.swift` created for fetching market data
- ✅ `MarketViewModel` updated with physical report loading
- ✅ `.gitignore` updated to exclude Config.swift from git

---

## 📋 What You Need to Do Next

### Step 1: Add Your Supabase Credentials

1. Open the **Config.swift** file in Xcode
2. Go to your Supabase dashboard (https://supabase.com/dashboard)
3. Select your project
4. Go to **Settings → API**
5. Copy your **Project URL** and **anon/public key**
6. Update Config.swift:

```swift
enum Config {
    // Replace these with your actual values
    static let supabaseURL = "https://YOUR_ACTUAL_PROJECT_ID.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.YOUR_ACTUAL_KEY"
    
    // Keep these as-is for now
    static let useSupabaseBackend = false // Set to true when ready
    static let useMockData = true
}
```

7. **IMPORTANT**: Never commit this file to Git! It's already in `.gitignore`.

### Step 2: Create a Config.swift.example File

So your team knows what configuration is needed:

1. Copy `Config.swift` to `Config.swift.example`
2. Replace your real credentials with placeholders
3. Commit `Config.swift.example` to Git (but NOT `Config.swift`)

### Step 3: Test Supabase Connection

Add this test to your app to verify connection:

```swift
// In a test view or onAppear somewhere
Task {
    let success = await SupabaseClientManager.shared.testConnection()
    if success {
        print("✅ Supabase connected successfully!")
    } else {
        print("❌ Supabase connection failed")
    }
}
```

---

## 🗄️ Database Tables

These tables were created in Supabase to cache MLA data:

### 1. `mla_physical_reports`
Stores cached physical sales reports from MLA.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| saleyard_name | TEXT | Name of saleyard (e.g., "Mount Barker") |
| report_date | DATE | Date of the report |
| total_yarding | INTEGER | Total head yarded |
| report_summary | TEXT | Brief summary text |
| report_data | JSONB | Full report JSON |
| fetched_at | TIMESTAMP | When data was cached |
| expires_at | TIMESTAMP | When cache expires |

### 2. `mla_national_indicators`
Stores EYCI, WYCI, NSI, NHLI indicators.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| indicator_code | TEXT | 'EYCI', 'WYCI', 'NSI', 'NHLI' |
| indicator_name | TEXT | Full name |
| value | DECIMAL | Current value |
| change | DECIMAL | Change from previous |
| trend | TEXT | 'up', 'down', 'steady' |
| report_date | DATE | Date of the data |
| fetched_at | TIMESTAMP | When cached |
| expires_at | TIMESTAMP | When cache expires |

### 3. `mla_saleyard_reports`
Stores saleyard report summaries.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| saleyard_name | TEXT | Saleyard name |
| state | TEXT | State (NSW, VIC, QLD, etc.) |
| report_date | DATE | Report date |
| yardings | INTEGER | Head count |
| summary | TEXT | Report text |
| categories | JSONB | Categories traded |
| fetched_at | TIMESTAMP | When cached |
| expires_at | TIMESTAMP | When expires |

---

## 🔐 Supabase Edge Functions (Future)

Once you have MLA API access, you'll create Supabase Edge Functions to:

1. **Fetch from MLA API** (with your secure API key)
2. **Cache in database** (to reduce API costs)
3. **Serve to iOS app** (fast, cached responses)

### Creating Your First Edge Function

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Initialize in your project
cd /path/to/your/project
supabase init

# Create a new Edge Function
supabase functions new mla-physical-report

# Deploy the function
supabase functions deploy mla-physical-report
```

### Example Edge Function Structure

```typescript
// supabase/functions/mla-physical-report/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { saleyard, date } = await req.json()
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )
  
  // Check cache first
  const { data: cached } = await supabase
    .from('mla_physical_reports')
    .select('*')
    .eq('saleyard_name', saleyard)
    .eq('report_date', date)
    .gt('expires_at', new Date().toISOString())
    .single()
  
  if (cached) {
    return new Response(JSON.stringify(cached), {
      headers: { 'Content-Type': 'application/json' }
    })
  }
  
  // Fetch from MLA API
  const mlaKey = Deno.env.get('MLA_API_KEY')
  const mlaResponse = await fetch('https://app.nlrsreports.mla.com.au/api/...', {
    headers: {
      'Authorization': `Bearer ${mlaKey}`,
      'Content-Type': 'application/json'
    }
  })
  
  const mlaData = await mlaResponse.json()
  
  // Cache it (24 hour expiry)
  const expiresAt = new Date()
  expiresAt.setHours(expiresAt.getHours() + 24)
  
  await supabase
    .from('mla_physical_reports')
    .upsert({
      saleyard_name: saleyard,
      report_date: date,
      report_data: mlaData,
      expires_at: expiresAt.toISOString()
    })
  
  return new Response(JSON.stringify(mlaData), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

---

## 🔄 Data Flow Architecture

```
┌─────────────────────────────────────────┐
│          MLA API (Third-party)          │
│   Rate-limited, costs per request      │
└──────────────┬──────────────────────────┘
               │
               │ Supabase Edge Function
               │ (Your secure backend)
               ↓
┌─────────────────────────────────────────┐
│       Supabase PostgreSQL Database      │
│   ┌───────────────────────────────┐    │
│   │  mla_physical_reports         │    │
│   │  mla_national_indicators      │    │
│   │  mla_saleyard_reports         │    │
│   └───────────────────────────────┘    │
│   Cached for 24 hours                   │
└──────────────┬──────────────────────────┘
               │
               │ iOS App requests
               │ (authenticated)
               ↓
┌─────────────────────────────────────────┐
│      iOS App (StockmansWallet)          │
│   ┌───────────────────────────────┐    │
│   │  SupabaseMarketService        │    │
│   │  - Fetches cached data        │    │
│   │  - Handles errors             │    │
│   └───────────────────────────────┘    │
│   ┌───────────────────────────────┐    │
│   │  In-Memory Cache (1 hour)     │    │
│   │  - Fast UI updates            │    │
│   └───────────────────────────────┘    │
└─────────────────────────────────────────┘
```

---

## 🔧 Files Created

### New Files

1. **`StockmansWallet/Config.swift`** (NOT in Git)
   - Stores Supabase credentials
   - Feature flags
   - Environment settings

2. **`StockmansWallet/Services/SupabaseClient.swift`**
   - Singleton client for Supabase
   - Connection management
   - Health check method

3. **`StockmansWallet/Services/SupabaseMarketService.swift`**
   - Fetches market data from Supabase
   - Converts Supabase models to app models
   - Handles caching logic
   - Includes PhysicalSalesReport models

4. **`Docs/SUPABASE-SETUP-GUIDE.md`** (This file)
   - Complete setup instructions
   - Architecture documentation

### Modified Files

1. **`.gitignore`**
   - Added Config.swift to excluded files
   - Added .env and secret files

2. **`Views/Market/MarketViewModel.swift`**
   - Added `physicalSalesReport` state
   - Added `isLoadingPhysicalReport` flag
   - Added `loadPhysicalSalesReport()` method
   - Added mock data for testing UI
   - Added SupabaseMarketService dependency

---

## 🎨 Using Physical Sales Report in UI

The physical sales report is now available in `MarketViewModel`. To display it:

```swift
// In MarketView.swift or a new component

if let report = viewModel.physicalSalesReport {
    PhysicalSalesTableView(report: report)
} else if viewModel.isLoadingPhysicalReport {
    ProgressView()
} else {
    Text("No physical sales data available")
}
```

### Sample Physical Sales Table Component

```swift
struct PhysicalSalesTableView: View {
    let report: PhysicalSalesReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(report.saleyard)
                    .font(.headline)
                Spacer()
                Text("\(report.totalYarding) head")
                    .foregroundStyle(.secondary)
            }
            
            // Table
            ScrollView(.horizontal) {
                VStack(spacing: 0) {
                    // Header row
                    HStack(spacing: 8) {
                        Text("Category").frame(width: 100)
                        Text("Weight").frame(width: 70)
                        Text("Prefix").frame(width: 80)
                        Text("M").frame(width: 30)
                        Text("F").frame(width: 30)
                        Text("Head").frame(width: 50)
                        Text("Avg ¢/kg").frame(width: 70)
                        Text("Avg $/Hd").frame(width: 70)
                    }
                    .font(.caption.bold())
                    .padding(8)
                    .background(Color.secondary.opacity(0.2))
                    
                    // Data rows
                    ForEach(report.categories) { category in
                        HStack(spacing: 8) {
                            Text(category.categoryName).frame(width: 100, alignment: .leading)
                            Text(category.weightRange).frame(width: 70)
                            Text(category.salePrefix).frame(width: 80)
                            Text(category.muscleScore ?? "-").frame(width: 30)
                            Text(category.fatScore.map { "\($0)" } ?? "-").frame(width: 30)
                            Text("\(category.headCount)").frame(width: 50)
                            Text(formatPrice(category.avgPriceCentsPerKg)).frame(width: 70)
                            Text(formatPrice(category.avgPriceDollarsPerHead)).frame(width: 70)
                        }
                        .font(.caption)
                        .padding(8)
                    }
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    func formatPrice(_ price: Double?) -> String {
        guard let price = price else { return "NQ" }
        return String(format: "%.2f", price)
    }
}
```

---

## 🚀 Switching to Live Data

When you're ready to use Supabase instead of mock data:

1. Ensure Supabase credentials are set in `Config.swift`
2. Ensure database has data (either manually inserted or from Edge Functions)
3. In `Config.swift`, change:
   ```swift
   static let useSupabaseBackend = true // Enable Supabase
   static let useMockData = false // Disable mock data
   ```
4. Test the app - it should now fetch from Supabase!

---

## 🐛 Troubleshooting

### "Invalid Supabase URL" Error
- Check that `Config.supabaseURL` is correct
- Format should be: `https://xxxxx.supabase.co`

### "Connection Failed" Error
- Verify your anon key is correct
- Check internet connection
- Verify Supabase project is active

### "No Data Available" Error
- Check if database tables have data
- Verify data hasn't expired (check `expires_at` column)
- Manually insert test data in Supabase dashboard

### Adding Test Data Manually

Go to Supabase dashboard → Table Editor → `mla_physical_reports` → Insert Row:

```json
{
  "saleyard_name": "Mount Barker",
  "report_date": "2026-01-25",
  "total_yarding": 336,
  "report_data": {
    "categories": [
      {
        "category_name": "Yearling Steer",
        "weight_range": "400-500",
        "sale_prefix": "Processor",
        "muscle_score": "C",
        "fat_score": 3,
        "head_count": 4,
        "avg_price_cents_kg": 340.0,
        "avg_price_dollars_head": 1734.0
      }
    ]
  },
  "expires_at": "2026-01-26T00:00:00Z"
}
```

---

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Swift Client](https://github.com/supabase/supabase-swift)
- [Supabase Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [MLA API Documentation](https://app.nlrsreports.mla.com.au/statistics/documentation)

---

## ✅ Checklist

- [ ] Added Supabase credentials to `Config.swift`
- [ ] Created `Config.swift.example` for team
- [ ] Tested Supabase connection
- [ ] Verified database tables exist
- [ ] Added test data to database
- [ ] Tested loading physical report in app
- [ ] Set `useSupabaseBackend = true` when ready
- [ ] Created Supabase Edge Functions (when MLA API access obtained)
- [ ] Set MLA API key in Supabase secrets
- [ ] Deployed Edge Functions to production

---

**Next Steps**: Once you have MLA API access, we'll set up the Edge Functions to automatically fetch and cache data from MLA!

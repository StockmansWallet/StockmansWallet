# Pricing Data Sources

**Date**: January 2026  
**Status**: Current Implementation

---

## 📊 Overview

This document describes the current pricing data sources used in Stockmans Wallet and outlines future enhancements for improved pricing accuracy.

---

## 🏗️ Current Implementation

### Data Source Hierarchy

Market prices in the Dashboard are derived using the following fallback hierarchy:

1. **Saleyard Benchmark Data** (Primary)
   - Direct saleyard quotes when available
   - User can select specific saleyards for comparison via Dashboard selector
   - Falls back to state/national data if saleyard-specific data unavailable

2. **State Indicator** (Secondary)
   - State-level pricing indicators
   - Used when saleyard-specific data is not available

3. **National Benchmark** (Tertiary)
   - National-level pricing benchmarks
   - Final fallback when saleyard and state data unavailable

### Implementation Details

- **ValuationEngine**: Core service that implements the fallback hierarchy
- **MarketPrice Model**: Stores pricing data with source attribution (`source` field: "Saleyard", "State Indicator", "National Benchmark")
- **SaleyardSelector**: Dashboard component allowing users to compare valuations across different saleyards

### User-Facing Messaging

Users are informed via:
- **Dashboard**: Info note below SaleyardSelector card explaining current data sources
- **Add Herd Flow**: Info text stating "Valuation engine currently derived from this saleyard. You can change it later in Settings."

---

## 🚀 Future Enhancements

### Progressive Sale Channel Integration

As additional sale channels become available, they will be progressively integrated to improve pricing accuracy:

1. **Private Sales**
   - Direct farm-to-farm transactions
   - Private treaty sales
   - Contract sales

2. **Online Auctions**
   - Digital livestock marketplaces
   - Online auction platforms
   - Real-time bidding data

3. **Other Sale Channels**
   - Feedlot sales
   - Processor direct sales
   - Export market data

### Integration Strategy

- **Phase 1**: Continue with saleyard benchmark data (current)
- **Phase 2**: Integrate private sale data when available
- **Phase 3**: Add online auction data sources
- **Phase 4**: Comprehensive multi-channel pricing aggregation

### Benefits of Multi-Channel Integration

- **Improved Accuracy**: More data sources = better price representation
- **Regional Coverage**: Better pricing for areas with limited saleyard coverage
- **Market Completeness**: Captures full market activity, not just saleyard sales
- **User Confidence**: Transparent data sources build trust

---

## 📝 Technical Notes

### Code References

- **ValuationEngine.swift**: `fetchPrice()` method implements fallback hierarchy
- **MarketPrice.swift**: Model includes `source` field for data attribution
- **DashboardView.swift**: SaleyardSelector card with info note about data sources
- **MarketDataService.swift**: Service layer for fetching market data

### Data Attribution

All pricing data includes source attribution:
- Users can see which data source was used for each price
- Helps users understand pricing accuracy and coverage
- Enables transparency in valuation calculations

---

## 🔄 Related Documentation

- **MARKET-PAGE-REBUILD.md**: Market page implementation details
- **ARCHITECTURE.md**: Overall app architecture
- **DEVELOPMENT-SETUP.md**: Development environment setup

---

## ✅ Implementation Checklist

- [x] Current saleyard benchmark data integration
- [x] Fallback hierarchy (Saleyard → State → National)
- [x] User-facing messaging about data sources
- [x] SaleyardSelector for price comparison
- [ ] Private sale channel integration (Future)
- [ ] Online auction data integration (Future)
- [ ] Multi-channel pricing aggregation (Future)

---

**Note**: This is a living document and will be updated as new sale channels are integrated.

# Apple Guidelines & Documentation

This folder contains Apple's design and development guidelines relevant to Stockman's Wallet.

## 📚 Apple Documentation (Web-Based)

**Note:** Apple's documentation is now **web-only** (no PDFs). The strategy is to:
1. Bookmark key pages
2. Save critical pages as markdown
3. Create your own reference summaries
4. Use Cursor to reference online docs

---

### 1. **Human Interface Guidelines (HIG)**
**Source:** https://developer.apple.com/design/human-interface-guidelines/

**Key Pages to Bookmark:**
- [ ] iOS Overview: https://developer.apple.com/design/human-interface-guidelines/designing-for-ios
- [ ] Navigation: https://developer.apple.com/design/human-interface-guidelines/navigation
- [ ] Tab Bars: https://developer.apple.com/design/human-interface-guidelines/tab-bars
- [ ] Color: https://developer.apple.com/design/human-interface-guidelines/color
- [ ] Typography: https://developer.apple.com/design/human-interface-guidelines/typography
- [ ] Dark Mode: https://developer.apple.com/design/human-interface-guidelines/dark-mode

**Why:** Core design principles for iOS apps. Our app follows HIG for:
- Navigation patterns (Tab bar)
- Color schemes (Dark mode support)
- Typography (SF Pro)
- Iconography (SF Symbols)
- Touch targets and spacing

---

### 2. **App Store Review Guidelines**
**Source:** https://developer.apple.com/app-store/review/guidelines/

**Key Sections to Bookmark:**
- [ ] Complete Guidelines: https://developer.apple.com/app-store/review/guidelines/
- [ ] Section 3: Business (Financial Apps)
- [ ] Section 5: Legal (Privacy, Data Use)

**Why:** Ensure our app meets approval requirements, especially for:
- Financial data handling
- User privacy
- In-app purchases (RevenueCat integration)
- Data collection policies

---

### 3. **SwiftUI Documentation**
**Source:** https://developer.apple.com/documentation/swiftui/

**Key Pages to Bookmark:**
- [ ] SwiftUI Overview: https://developer.apple.com/documentation/swiftui
- [ ] State Management: https://developer.apple.com/documentation/swiftui/state-and-data-flow
- [ ] SwiftData: https://developer.apple.com/documentation/swiftdata

**Why:** We use SwiftUI exclusively. Key areas:
- Observable pattern (@Observable)
- SwiftData for persistence
- Modern lifecycle
- Navigation patterns

---

### 4. **Accessibility Guidelines**
**Source:** https://developer.apple.com/accessibility/

**Key Pages to Bookmark:**
- [ ] Accessibility Overview: https://developer.apple.com/accessibility/
- [ ] VoiceOver: https://developer.apple.com/documentation/accessibility/voiceover
- [ ] Dynamic Type: https://developer.apple.com/design/human-interface-guidelines/typography

**Why:** Ensure our app is usable by everyone:
- VoiceOver support
- Dynamic Type for text scaling
- Sufficient contrast ratios
- Accessibility labels

---

## 🎨 **Project-Specific Design Decisions**

Based on Apple HIG, Stockman's Wallet follows these patterns:

### Navigation
- ✅ Tab Bar navigation (5 tabs max) - using 5 tabs: Dashboard, Portfolio, Market, Reports, Settings
- ✅ NavigationStack for hierarchical navigation
- ✅ Back button consistency

### Color & Appearance
- ✅ Dark mode support (`.preferredColorScheme(.dark)`)
- ✅ System colors with semantic naming
- ✅ High contrast for critical information (prices, values)

### Typography
- ✅ SF Pro font (system default)
- ✅ Dynamic Type support
- ✅ Clear hierarchy (titles, body, captions)

### Data Presentation
- ✅ Charts for financial data (using native Charts framework)
- ✅ Cards for grouped information
- ✅ Lists for scrollable content
- ✅ Forms for data entry

### Touch Targets
- ✅ Minimum 44x44pt touch targets
- ✅ Adequate spacing between interactive elements
- ✅ Haptic feedback for actions

---

## 📖 **How to Use Web-Based Guidelines**

### Strategy for Working with Web-Only Docs

**Option 1: Browser Bookmarks (Simplest)**
1. Create a "StockmansWallet HIG" bookmark folder
2. Add all key pages to it
3. Reference URLs when asking Cursor for help

**Option 2: Save Key Pages as Markdown (Recommended)**
1. Use browser "Save as..." or "Print to PDF"
2. Convert to markdown using tools like Pandoc
3. Store in this folder for offline reference
4. Update before major releases

**Option 3: Create Your Own HIG Summary (Best)**
1. Read key HIG sections
2. Document decisions specific to YOUR app
3. Create `HIG-Summary.md` in this folder
4. Much more useful than full docs

### During Development
1. **Reference first**: Check HIG before implementing new UI patterns
2. **Ask Cursor**: "Implement this following iOS HIG for [component]" with URL
3. **Test on device**: HIG emphasizes real device testing
4. **Save notes**: Document your design decisions

### Before App Store Submission
1. Review App Store Guidelines thoroughly (online)
2. Complete Accessibility audit
3. Test on multiple devices and iOS versions
4. Verify data privacy compliance

---

## 🔗 **Quick Reference Links**

### Design
- [HIG - iOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-ios)
- [SF Symbols App](https://developer.apple.com/sf-symbols/) - Download this tool
- [Apple Design Resources](https://developer.apple.com/design/resources/) - Sketch/Figma templates

### Development
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)

### Testing
- [TestFlight Beta Testing](https://developer.apple.com/testflight/)
- [Xcode Cloud](https://developer.apple.com/xcode-cloud/)

---

## 💡 **Pro Tips**

### What to Download
✅ **DO Download:**
- Core HIG sections relevant to your app type (Finance, Data Display)
- App Store Review Guidelines (essential for approval)
- Accessibility guidelines
- SwiftUI specific guides

❌ **DON'T Download:**
- Entire developer library (too large, frequently updated online)
- Platform-specific guides you won't use (watchOS, tvOS, visionOS)
- Legacy iOS versions (< iOS 17)

### How to Use with Cursor
When asking Cursor for help, reference specific guidelines:
```
"Implement this following iOS HIG navigation patterns 
from Resources/Guidelines/[doc-name]"
```

### Keeping Updated
- Apple updates HIG regularly
- Check for updates before major releases
- Re-download before App Store submission
- Bookmark online versions for latest info

---

## 📱 **Specific to Stockman's Wallet**

### Our App Category: Finance
**Special Considerations:**
- Clear financial data presentation
- Secure data handling
- Transaction history clarity
- Export functionality (PDF reports)
- Offline capability for remote areas

### Our Target Users: Farmers/Graziers
**HIG Considerations:**
- Large touch targets (may use in field with gloves)
- High contrast (outdoor use in sunlight)
- Simple, clear navigation
- Minimal data entry requirements
- Reliable offline functionality

---

**Last Updated:** January 2026  
**iOS Version Target:** 26.1+  
**HIG Version:** Check online for latest


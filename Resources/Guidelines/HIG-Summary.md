# iOS HIG Summary - Stockman's Wallet

This document summarizes the key iOS Human Interface Guidelines principles we follow in Stockman's Wallet.

> **Source:** https://developer.apple.com/design/human-interface-guidelines/

---

## 🎯 **Our Design Principles**

### 1. Clarity
- **Text:** San Francisco font (system default)
- **Hierarchy:** Clear titles, body, and captions
- **Spacing:** Generous padding around interactive elements
- **Iconography:** SF Symbols for consistency

### 2. Deference
- **Content First:** Let livestock data be the star
- **Subtle UI:** Cards and backgrounds don't compete with content
- **Dark Mode:** Always-on for focus and battery life
- **Motion:** Subtle animations (Lottie for branding only)

### 3. Depth
- **Layers:** Cards float above background
- **Shadows:** Subtle to indicate elevation
- **Navigation:** Clear hierarchy (Tab → Stack → Detail)

---

## 🧭 **Navigation Structure**

### Tab Bar (Main Navigation)
**Following:** https://developer.apple.com/design/human-interface-guidelines/tab-bars

✅ **We Use:** 5 tabs (HIG max)
1. Dashboard 📊 - Portfolio overview
2. Portfolio 📁 - Asset management
3. Market 📈 - Price tracking
4. Reports 📄 - PDF generation
5. Settings ⚙️ - Preferences

✅ **Icons:** SF Symbols only
✅ **Labels:** Short, descriptive
✅ **Selection:** Accent color highlight
❌ **Avoid:** More than 5 tabs, custom icons

### Navigation Stack (Hierarchical)
**Following:** https://developer.apple.com/design/human-interface-guidelines/navigation

✅ **Back Button:** Always visible
✅ **Titles:** Clear, descriptive
✅ **Modal Sheets:** For focused tasks (Add Herd, Settings)
✅ **Transitions:** Standard push/pop animations

---

## 🎨 **Visual Design**

### Color System
**Following:** https://developer.apple.com/design/human-interface-guidelines/color

```swift
// Our Color Palette (from Theme.swift)
// Design Tokens - Organized by Apple HIG principles

Accent Colors:
- Primary Light: #B8AD9D (main accent)
- Primary: #7C6F5D
- Secondary: #5E5142
- Tertiary: #4A3C2D

Label Colors (Text):
- Primary: #B8AD9D (main text)
- Secondary: #7C6F5D (supporting text)
- Tertiary: #5E5142 (subtle text)
- Quaternary: #4A3C2D (disabled text)

Background Colors:
- Primary: #211A12 (main background)
- Secondary: #271F18 (cards/sections)
- Tertiary: #2D241A (nested grouping)
- Quaternary: #3A2F23 (elevated elements)

Status Colors (to be updated):
- Destructive: #C36F6F (delete/danger)
- Success: #9CA659 (positive actions)
- Warning: #A68C59 (caution)
- Info: #6FA7C3 (informational)
```

✅ **Dark Mode:** Always on (agricultural/outdoor use)
✅ **Contrast:** WCAG AA compliant minimum
✅ **Semantic:** Colors have meaning (destructive = danger, accent = interactive)
✅ **Apple HIG:** Following semantic naming conventions
❌ **Avoid:** Pure white on pure black (too harsh)

### Typography
**Following:** https://developer.apple.com/design/human-interface-guidelines/typography

```swift
// Our Type Scale (from Theme.swift)
Title: Large, bold - Key numbers ($123,456)
Headline: Section headers
Body: Primary content
Caption: Metadata, timestamps
```

✅ **SF Pro:** System font (readable, optimized)
✅ **Dynamic Type:** Support all sizes
✅ **Weight:** Bold for emphasis, regular for body
✅ **Alignment:** Left (natural reading)

---

## 📐 **Layout & Spacing**

### Touch Targets
**Minimum:** 44x44 points (HIG requirement)

✅ **Buttons:** All interactive elements meet minimum
✅ **List Rows:** Ample tap area
✅ **Form Fields:** Easy to tap, even with gloves
✅ **Charts:** Interactive with good hit areas

### Spacing
```
Section Spacing: 24pt between major sections
Card Padding: 16pt internal padding
Stack Spacing: 12-16pt between elements
List Spacing: 8-12pt between rows
```

---

## 📱 **Platform Features**

### SwiftUI Components We Use
✅ **NavigationStack** - Hierarchical navigation
✅ **TabView** - Main navigation
✅ **List** - Data display
✅ **Charts** - Native visualization
✅ **Sheet** - Modal presentations
✅ **Form** - Data entry

### iOS System Features
✅ **Dark Mode** - Always enabled
✅ **SF Symbols** - All icons
✅ **Haptics** - Touch feedback (HapticManager)
✅ **Dynamic Type** - Text scaling
✅ **Share Sheet** - PDF export
✅ **SwiftData** - Persistence

---

## ♿️ **Accessibility**

### VoiceOver Support
- [ ] TODO: Audit all screens
- [ ] Meaningful labels on all interactive elements
- [ ] Proper heading hierarchy
- [ ] Image descriptions where needed

### Dynamic Type
✅ **Support:** All text scales with system settings
✅ **Testing:** Test at largest size
❌ **Avoid:** Fixed text sizes

### Color Contrast
✅ **Text:** Minimum 4.5:1 ratio
✅ **Interactive Elements:** Minimum 3:1 ratio
✅ **Testing:** Use Accessibility Inspector

---

## 📊 **Data Display**

### Financial Information
**Following:** Best practices for financial apps

✅ **Clarity:** Large, readable numbers
✅ **Currency:** Always show symbol ($)
✅ **Precision:** 2 decimal places for money
✅ **Grouping:** Commas for thousands
✅ **Change Indicators:** ▲ ▼ with color (green/red)

### Charts
**Following:** https://developer.apple.com/documentation/charts

✅ **Native Framework:** Using iOS Charts
✅ **Interactive:** Tap to see details
✅ **Accessible:** VoiceOver compatible
✅ **Time Ranges:** Multiple views (24h, week, month, all)

### Lists
✅ **Scannable:** Clear hierarchy
✅ **Swipe Actions:** Delete, edit (standard gestures)
✅ **Empty States:** Helpful messages when no data
✅ **Loading States:** Progress indicators

---

## 🔔 **Feedback & Response**

### Haptics
**Following:** https://developer.apple.com/design/human-interface-guidelines/playing-haptics

✅ **Light:** Button taps, selections
✅ **Medium:** Notifications, alerts
✅ **Success:** Completed actions
✅ **Error:** Failed actions, warnings

### Loading States
✅ **Progress Indicators:** For loading data
✅ **Skeletons:** Placeholder content
✅ **Refresh:** Pull-to-refresh where appropriate

### Errors
✅ **Clear Messages:** Explain what went wrong
✅ **Actionable:** Tell user how to fix
✅ **Not Blaming:** "Unable to connect" vs "You lost connection"

---

## 📄 **Forms & Data Entry**

### Input Fields
✅ **Labels:** Clear, above field
✅ **Placeholders:** Example format
✅ **Validation:** Inline, immediate
✅ **Keyboard:** Appropriate type (number, decimal, email)

### Buttons
✅ **Primary:** Accent color, prominent
✅ **Secondary:** Subtle, less prominent
✅ **Destructive:** Red, requires confirmation
✅ **Disabled:** Reduced opacity

---

## 🚫 **What We Avoid**

❌ **Custom Navigation:** Use system patterns
❌ **Unusual Gestures:** Stick to standard iOS gestures
❌ **Over-Animation:** Keep it subtle
❌ **Tiny Text:** Minimum 11pt, prefer 15-17pt
❌ **Pure White/Black:** Too harsh, use off-white/dark gray
❌ **Unnecessary Modals:** Use navigation stack when possible
❌ **Cluttered Screens:** Generous whitespace
❌ **Inconsistent Spacing:** Use defined scale

---

## ✅ **Pre-Launch Checklist**

### Design Review
- [ ] All screens follow navigation patterns
- [ ] Consistent spacing throughout
- [ ] All interactive elements meet 44pt minimum
- [ ] Dark mode looks good on all screens
- [ ] Icons are all SF Symbols
- [ ] Typography scale is consistent

### Accessibility Review
- [ ] VoiceOver works on all screens
- [ ] Dynamic Type tested at largest size
- [ ] Color contrast meets WCAG AA
- [ ] All images have descriptions
- [ ] All buttons have labels

### Polish
- [ ] Haptics feel right
- [ ] Loading states are smooth
- [ ] Empty states are helpful
- [ ] Error messages are clear
- [ ] Animations are subtle

---

## 📚 **Quick Reference**

### Key HIG Pages
- Overview: https://developer.apple.com/design/human-interface-guidelines/
- iOS: https://developer.apple.com/design/human-interface-guidelines/designing-for-ios
- Navigation: https://developer.apple.com/design/human-interface-guidelines/navigation
- Color: https://developer.apple.com/design/human-interface-guidelines/color
- Typography: https://developer.apple.com/design/human-interface-guidelines/typography

### Tools
- SF Symbols App: https://developer.apple.com/sf-symbols/
- Accessibility Inspector: Xcode → Xcode → Open Developer Tools
- Color Contrast Checker: https://webaim.org/resources/contrastchecker/

---

**Last Updated:** January 2026  
**Based on:** iOS 17+ HIG  
**Review Before:** Major releases, design changes



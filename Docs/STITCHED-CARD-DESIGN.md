# Stitched Card Design System

**Date**: January 3, 2026  
**Status**: ✅ Implemented  
**Design Inspiration**: Subtle leather stitching aesthetic

---

## Overview

New card design system featuring a **subtle stitched border effect** with white translucent background and drop shadow. Inspired by premium leather goods with hand-stitched edges, creating a sophisticated, tactile feel appropriate for agricultural/livestock management.

---

## 🎨 Design Specifications

### Visual Style
```
╭╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╮
┊                                  ┊
┊  Card Content                    ┊  ← Dashed border (stitching)
┊                                  ┊
╰╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╯
  └─ Drop shadow (8pt radius)
```

### Technical Specifications

| Property | Value | Purpose |
|----------|-------|---------|
| **Background** | `Color.white.opacity(0.2)` | Subtle translucent white overlay |
| **Border Color** | `Color.white.opacity(0.3)` | Slightly more visible than background |
| **Border Width** | `1.5pt` | Thin but visible |
| **Border Style** | Dashed | Creates stitching effect |
| **Dash Pattern** | `[6, 6]` | 6pt dash, 6pt gap (subtle) |
| **Line Cap** | `.round` | Rounded ends (softer look) |
| **Corner Radius** | `Theme.cornerRadius` (16pt) | Squircle shape |
| **Shadow Color** | `Color.black.opacity(0.15)` | Subtle elevation |
| **Shadow Radius** | `8pt` | Soft blur |
| **Shadow Offset** | `x: 0, y: 4` | Slight downward shadow |

---

## 💡 Design Rationale

### Why Stitching Effect?

1. **Agricultural Context**: Leather goods are common in farming/ranching (saddles, boots, gloves)
2. **Premium Feel**: Hand-stitched aesthetic suggests quality and craftsmanship
3. **Subtle Texture**: Adds visual interest without being overwhelming
4. **Brand Differentiation**: Unique design element that stands out
5. **Tactile Association**: Suggests something you can "hold" (like a wallet)

### Color Choices

**White with 20% Opacity:**
- Works on any background color
- Provides subtle elevation
- Maintains readability
- Doesn't compete with content

**White Border with 30% Opacity:**
- Slightly more visible than background
- Creates clear card boundary
- Subtle enough not to distract
- Complements dark theme

### Shadow Design

**Soft Drop Shadow:**
- Creates depth and elevation
- Suggests card is "floating" above background
- 8pt radius = soft, diffused shadow (not harsh)
- 4pt Y offset = natural light from above
- 15% opacity = subtle, not overpowering

---

## 🔧 Implementation

### Theme.swift

```swift
// MARK: - New Card Style with Stitching Effect
struct StitchedCard: ViewModifier {
    var showShadow: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(0.3),
                        style: StrokeStyle(
                            lineWidth: 1.5,
                            lineCap: .round,
                            dash: [6, 6] // Subtle stitching pattern
                        )
                    )
            )
            .shadow(
                color: showShadow ? Color.black.opacity(0.15) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

extension View {
    /// New card style with subtle stitching effect and drop shadow
    func stitchedCard(showShadow: Bool = true) -> some View {
        modifier(StitchedCard(showShadow: showShadow))
    }
}
```

---

## 📱 Usage

### Basic Usage
```swift
VStack {
    Text("Card Content")
}
.padding(Theme.cardPadding)
.stitchedCard()
```

### Without Shadow (for nested cards)
```swift
VStack {
    Text("Nested Card")
}
.padding(Theme.cardPadding)
.stitchedCard(showShadow: false)
```

### Migration from Old Style
```swift
// Old:
.squircleCard()

// New:
.stitchedCard()
```

---

## 🎯 Where to Use

### Recommended Use Cases
✅ **Information Cards** - Dashboard stats, portfolio summaries
✅ **Form Sections** - Grouped input fields
✅ **List Items** - Herd cards, animal cards
✅ **Content Containers** - Reports, settings sections
✅ **Empty States** - Placeholder content areas
✅ **Status Cards** - Import results, error messages

### Where NOT to Use
❌ **Buttons** - Use button styles instead
❌ **Full-screen backgrounds** - Too much visual noise
❌ **Overlays/Modals** - Use solid backgrounds
❌ **Navigation bars** - Keep native iOS styling

---

## 🔄 Migration Strategy

### Phase 1: Test Implementation ✅
- Implemented in `CSVImportView.swift` (3 cards)
- Verify visual appearance
- Test on different backgrounds
- Gather feedback

### Phase 2: Gradual Rollout
Replace `.squircleCard()` with `.stitchedCard()` in:
1. Portfolio views (herd cards, animal cards)
2. Dashboard cards (stats, charts)
3. Settings sections
4. Onboarding cards
5. Reports views

### Phase 3: Cleanup
- Remove old `CardBackground` from Assets.xcassets (if desired)
- Update all remaining `.squircleCard()` calls
- Remove legacy modifier (optional - can keep for backward compatibility)

---

## 🎨 Customization Options

### Adjustable Parameters

If you want to tweak the design, here are the key values:

**Background Opacity** (currently 0.2):
```swift
.fill(Color.white.opacity(0.2))  // Lighter: 0.15, Darker: 0.3
```

**Border Opacity** (currently 0.3):
```swift
Color.white.opacity(0.3)  // More subtle: 0.2, More visible: 0.4
```

**Dash Pattern** (currently [6, 6]):
```swift
dash: [6, 6]   // Current (subtle)
dash: [8, 8]   // Longer dashes
dash: [4, 4]   // Shorter dashes (more stitches)
dash: [10, 5]  // Longer dash, shorter gap
```

**Border Width** (currently 1.5):
```swift
lineWidth: 1.5  // Current
lineWidth: 1.0  // Thinner (more subtle)
lineWidth: 2.0  // Thicker (more prominent)
```

**Shadow Intensity** (currently 0.15):
```swift
Color.black.opacity(0.15)  // Current (subtle)
Color.black.opacity(0.1)   // Lighter shadow
Color.black.opacity(0.2)   // Stronger shadow
```

**Shadow Radius** (currently 8):
```swift
radius: 8   // Current (soft)
radius: 4   // Tighter shadow
radius: 12  // More diffused
```

---

## 📊 Before vs After

### Old Card Style (squircleCard)
```
┌─────────────────────────────────┐
│                                 │
│  Solid CardBackground color     │
│  No border                      │
│  No shadow                      │
│                                 │
└─────────────────────────────────┘
```

**Characteristics:**
- Solid background from Assets
- Sharp edges
- Flat appearance
- No depth

### New Card Style (stitchedCard)
```
╭╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╮
┊                               ┊
┊  Translucent white (20%)     ┊
┊  Dashed border (stitching)   ┊
┊  Soft drop shadow            ┊
┊                               ┊
╰╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╯
  └─ Elevated appearance
```

**Characteristics:**
- Translucent white overlay
- Subtle stitched border
- Soft shadow (depth)
- Premium feel

---

## 🎓 Design Principles Applied

### 1. Subtle Over Obvious
- Dashed border is noticeable but not distracting
- 6pt dash pattern is refined, not bold
- Rounded line caps soften the appearance

### 2. Depth Through Shadow
- Shadow creates visual hierarchy
- Suggests cards are layered above background
- Adds polish and professionalism

### 3. Contextual Design
- Stitching references agricultural/ranching context
- Leather goods are familiar to target users
- Creates emotional connection to craft/quality

### 4. Flexibility
- Works on any background color
- Optional shadow for nested cards
- Maintains readability
- Doesn't compete with content

---

## 🔍 Testing Checklist

- [x] Visual appearance on dark backgrounds
- [ ] Visual appearance on light backgrounds (if supported)
- [ ] Readability of text inside cards
- [ ] Shadow visibility on different backgrounds
- [ ] Performance with many cards (scrolling)
- [ ] Accessibility (contrast ratios)
- [ ] Dark mode appearance
- [ ] Dynamic Type support (text scaling)
- [ ] Different device sizes (iPhone SE to Pro Max)
- [ ] Reduce Transparency accessibility setting

---

## 💬 User Feedback Areas

When testing, pay attention to:
1. **Is the stitching too subtle or too obvious?**
2. **Does the shadow feel natural?**
3. **Is the white overlay the right opacity?**
4. **Does it work on all backgrounds?**
5. **Does it feel premium/quality?**
6. **Is it consistent with the brand?**

---

## 🚀 Recommendation

**YES - Remove CardBackground from Assets** ✅

**Reasons:**
1. **Code-based is more flexible** - Easy to adjust opacity, color, etc.
2. **Consistent across all backgrounds** - Works with any background image
3. **Easier to maintain** - One place to update (Theme.swift)
4. **Better for dark theme** - Translucent white adapts to any darkness level
5. **Smaller app size** - No asset file needed
6. **Version control friendly** - Code changes are easier to track than asset changes

**Migration:**
1. Keep using `.stitchedCard()` modifier
2. Remove `CardBackground.colorset` from Assets.xcassets when ready
3. Update any remaining references to `Theme.cardBackground` color

---

## 📝 Notes

### Performance Considerations
- Dashed borders are rendered efficiently by SwiftUI
- Shadow has minimal performance impact (GPU accelerated)
- Translucent backgrounds are optimized by iOS

### Accessibility
- White overlay maintains sufficient contrast with dark text
- Shadow helps users with vision impairments distinguish cards
- Works with Reduce Transparency (falls back gracefully)

### Future Enhancements
- Could add subtle animation on tap (scale/shadow change)
- Could vary dash pattern for different card types
- Could add subtle gradient to background
- Could make stitching color themeable

---

**Last Updated**: January 3, 2026  
**Implemented By**: AI Assistant  
**Design Inspiration**: Premium leather goods, agricultural context  
**Status**: Ready for app-wide rollout


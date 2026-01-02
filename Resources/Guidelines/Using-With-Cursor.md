# Using Apple Guidelines with Cursor AI

Quick guide on how to effectively reference Apple's HIG and guidelines when working with Cursor.

---

## 🎯 **The Problem**

Apple's documentation is **web-only** (no PDFs), but Cursor works best with **local context**. Here's how to bridge that gap.

---

## ✅ **Best Practices**

### 1. Reference Specific HIG Pages
**Instead of:**
```
"Make this follow iOS HIG"
```

**Do this:**
```
"Implement this tab bar following iOS HIG tab bar guidelines at 
https://developer.apple.com/design/human-interface-guidelines/tab-bars"
```

Cursor can access web URLs and will reference the specific page!

---

### 2. Use Your HIG Summary
**Do this:**
```
"Implement this following the navigation patterns in 
Resources/Guidelines/HIG-Summary.md"
```

Your summary is **in the project**, so Cursor has full context without web access.

---

### 3. Quote Specific Guidelines
**Do this:**
```
"According to iOS HIG, tab bars should have 2-5 items with clear icons. 
Implement our 5-tab structure: Dashboard, Portfolio, Market, Reports, Settings"
```

Give Cursor the guideline principle directly.

---

## 💡 **Example Prompts**

### Navigation
```
"Create a NavigationStack that follows iOS HIG navigation patterns from 
https://developer.apple.com/design/human-interface-guidelines/navigation
Include back button, clear title, and proper hierarchy."
```

### Color
```
"Our color scheme (in Resources/Guidelines/HIG-Summary.md) uses dark mode 
with high contrast. Apply this to the new dashboard card."
```

### Accessibility
```
"Add VoiceOver labels to this view following iOS accessibility guidelines.
Minimum touch targets are 44x44pt per HIG."
```

### Typography
```
"Use our type scale from Theme.swift, which follows iOS HIG typography:
Title for main value, Body for details, Caption for metadata."
```

---

## 🔗 **Useful HIG URLs to Copy**

Keep these handy for quick reference:

```
Main HIG: 
https://developer.apple.com/design/human-interface-guidelines/

iOS Specific:
https://developer.apple.com/design/human-interface-guidelines/designing-for-ios

Navigation:
https://developer.apple.com/design/human-interface-guidelines/navigation

Tab Bars:
https://developer.apple.com/design/human-interface-guidelines/tab-bars

Color:
https://developer.apple.com/design/human-interface-guidelines/color

Typography:
https://developer.apple.com/design/human-interface-guidelines/typography

Dark Mode:
https://developer.apple.com/design/human-interface-guidelines/dark-mode

Accessibility:
https://developer.apple.com/design/human-interface-guidelines/accessibility
```

---

## 📝 **Building Your Own Reference**

### Create Component Documentation
As you build, document your decisions in `HIG-Summary.md`:

```markdown
### Portfolio Card Component
- **Pattern:** Follows HIG card design
- **Spacing:** 16pt padding (per HIG)
- **Touch Target:** 44pt minimum
- **Colors:** CardBackground with shadow
- **Why:** Provides clear hierarchy and tappable surface
```

Then reference it:
```
"Create a new card following the Portfolio Card pattern in 
Resources/Guidelines/HIG-Summary.md"
```

---

## 🎨 **For Design Questions**

### SF Symbols (Downloadable!)
```
"Use SF Symbols for all icons. Refer to the SF Symbols app 
(https://developer.apple.com/sf-symbols/) for available symbols."
```

### Color Contrast
```
"Ensure this text meets WCAG AA contrast (4.5:1 minimum) per iOS HIG 
accessibility guidelines."
```

---

## 🚀 **Advanced: Save Key Pages**

If you frequently reference specific HIG pages:

### Option 1: Browser Extension
1. Install "Save Page WE" or similar
2. Save key HIG pages as complete HTML
3. Place in `Resources/Guidelines/hig-pages/`
4. Reference local files

### Option 2: Screenshot + Notes
1. Screenshot key sections
2. Add to `Resources/Design/`
3. Add your own notes
4. Reference images in prompts

### Option 3: Your Own Markdown (Recommended)
1. Read HIG section
2. Write YOUR interpretation in `HIG-Summary.md`
3. Much more useful than copying Apple's words
4. Tailored to YOUR app

---

## ⚡️ **Quick Start Workflow**

1. **Before Implementing:**
   - Check HIG-Summary.md for existing pattern
   - If new pattern, check web HIG
   - Document decision in HIG-Summary.md

2. **When Asking Cursor:**
   - Reference HIG-Summary.md if you have pattern documented
   - Reference web URL if not yet documented
   - Explain the principle, not just "follow HIG"

3. **After Implementing:**
   - Update HIG-Summary.md with what you learned
   - Add screenshots to Resources/Design/ if helpful
   - Next time will be faster!

---

## 📚 **Example Project Conversation**

```
You: "I need to add a new settings section. What pattern should I follow?"

Cursor: [Checks Resources/Guidelines/HIG-Summary.md]
"Looking at your HIG summary, you're using NavigationStack with Forms 
for settings. I'll create a new Form section following that pattern..."

You: "Perfect! Also make sure the color contrast meets HIG requirements."

Cursor: [Checks HIG-Summary.md for color specs]
"Using your defined colors: PrimaryText on CardBackground. This meets 
the 4.5:1 contrast ratio you've documented..."
```

See? Your own documentation makes Cursor much more effective!

---

## 🎯 **Key Takeaway**

**Don't try to give Cursor the entire HIG.**
**Give Cursor YOUR design decisions based on HIG.**

Your `HIG-Summary.md` is way more valuable than the full HIG because:
- ✅ Tailored to YOUR app
- ✅ Shows YOUR interpretations
- ✅ Documents YOUR decisions
- ✅ Much shorter and focused
- ✅ Always available offline

---

**Last Updated:** January 2026



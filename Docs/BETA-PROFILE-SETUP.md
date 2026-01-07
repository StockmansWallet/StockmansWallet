# Beta Profile Setup Implementation

**Date:** January 8, 2026  
**Status:** ✅ Implemented for External Beta Testing  
**Purpose:** Capture user profile for personalization without authentication

## Overview

For external beta testing via TestFlight, we've converted the sign-in page to a simple **profile setup** page. This allows us to:
- Get feedback on the onboarding flow
- Capture user names for personalization (reports, settings, etc.)
- Avoid Apple Review issues with non-functional authentication
- Focus tester attention on core livestock management features

## What Changed

### SignInPage.swift
**Before:** Authentication page with sign in/sign up toggle, passwords, social login  
**After:** Profile setup page with just name and optional email

**Changes:**
- ✅ Removed password fields
- ✅ Removed sign-in/sign-up toggle
- ✅ Removed social sign-in buttons (Apple, Google)
- ✅ Made email optional
- ✅ Changed messaging to "Let's Get Started" / "Tell us a bit about yourself"
- ✅ Added beta disclaimer badge
- ✅ Simplified validation (only name required)

### OnboardingView.swift
**Changes:**
- ✅ Updated comments to reflect beta profile setup
- ✅ Removed unused auth handlers (kept commented for production)
- ✅ Simplified to only use `demoEmailSignUp()` handler

## User Experience Flow

```
1. Welcome/Features Page
   ↓
2. Profile Setup (SignInPage)
   - Enter First Name (required)
   - Enter Last Name (required)
   - Enter Email (optional)
   - See beta disclaimer
   - Click "Continue to App"
   ↓
3. User Type Selection (Farmer/Advisor)
   ↓
4. Property/Company Information
   ↓
5. Welcome Completion
   ↓
6. Subscription (skip for now)
   ↓
7. Main App Dashboard
```

## What Gets Captured

The profile setup captures:
- **First Name** (required) - Used in greetings, reports
- **Last Name** (required) - Used in reports, PDFs
- **Email** (optional) - For future contact/migration

Data is stored in `UserPreferences` model and persists locally.

## Beta Disclaimer

The page shows this badge:
```
ⓘ Beta Testing - User accounts coming soon
```

This sets clear expectations that:
- This is beta software
- Full authentication will come later
- Data is local-only during beta

## TestFlight Notes

Include this in your TestFlight "What to Test" section:

```
🎯 ONBOARDING FEEDBACK NEEDED

We'd love your feedback on the onboarding experience!

PROFILE SETUP:
• The "Let's Get Started" screen captures your name for personalization
• Email is optional during beta testing
• Your name will appear throughout the app (reports, settings, etc.)
• User accounts and authentication will be added before launch

PLEASE TEST:
✓ Is the profile setup clear and intuitive?
✓ Are the form fields easy to understand?
✓ Does the flow feel natural?
✓ Is the beta disclaimer clear?
✓ Any confusing or unclear steps?

DATA NOTE:
All data is stored locally on your device during beta testing.
Uninstalling the app will delete your data.
```

## For Testers

### What This Means:
- No password needed
- No account required
- Just personalization
- All data stays on your device

### Your Name Is Used For:
- Dashboard greeting ("Welcome back, [Name]")
- PDF report headers
- Settings display
- Email signatures (if exporting)

## Production Migration Plan

### When Ready to Launch:

1. **Add Supabase Authentication:**
   - Install Supabase Swift SDK
   - Configure API keys (via environment variables)
   - Set up Supabase project and auth tables

2. **Restore Authentication Features:**
   - Uncomment auth handlers in `OnboardingView.swift`
   - Re-implement sign-in/sign-up logic
   - Add password fields back
   - Re-enable social sign-in buttons
   - Update validation logic

3. **Update SignInPage.swift:**
   - Change header to "Sign In" / "Create Account"
   - Add password fields with proper security
   - Add "Forgot Password" flow
   - Re-enable sign-in toggle
   - Add social authentication buttons
   - Remove beta disclaimer

4. **Data Migration:**
   - Decide: Keep local + sync, or migrate to cloud?
   - Provide export feature before forcing migration
   - Handle existing local data gracefully
   - Test migration thoroughly

5. **Update Messaging:**
   - Remove all beta disclaimers
   - Update terms to reflect cloud storage
   - Add privacy policy for data handling
   - Update TestFlight notes

## Code Locations

### Files Modified:
- `StockmansWallet/Views/Onboarding/SignInPage.swift` - Profile setup UI
- `StockmansWallet/Views/Onboarding/OnboardingView.swift` - Flow coordination

### To Restore Auth Later:
Look for these comments:
- `// TODO: Restore for production authentication`
- `/* TODO: Restore for production authentication ... */`

### Key Markers:
```swift
// Debug: Beta testing - ...
// Rule: Simple solution for beta - ...
```

## Testing Checklist

Before submitting to TestFlight:

- [ ] Name fields are required
- [ ] Email field is optional
- [ ] Beta disclaimer is visible
- [ ] "Continue to App" button works
- [ ] Name persists through onboarding
- [ ] Name appears in dashboard
- [ ] Name appears in reports/PDFs
- [ ] No password fields visible
- [ ] No social sign-in buttons visible
- [ ] No sign-in/sign-up toggle

## Apple Review Considerations

### Why This Approach Passes Review:

✅ **Not Authentication** - It's profile setup, not login  
✅ **Clear Purpose** - Beta disclaimer sets expectations  
✅ **Functional** - Actually captures and uses the data  
✅ **Not Misleading** - Doesn't promise features that don't exist  
✅ **Complete Experience** - Doesn't block core functionality  

### Red Flags We Avoided:

❌ Fake login that doesn't authenticate  
❌ "Sign in with Apple" that doesn't work  
❌ Password fields that aren't validated  
❌ "Coming soon" features blocking usage  

## Benefits for Beta Testing

1. **Frictionless Entry**
   - No account creation barriers
   - No password to remember
   - No email verification wait
   - Straight to testing the app

2. **Focused Feedback**
   - Testers focus on livestock features
   - Not distracted by auth issues
   - Better quality feedback

3. **Clear Expectations**
   - Beta disclaimer is prominent
   - Testers know it's not final
   - Less confusion about accounts

4. **Faster Iteration**
   - No backend setup needed yet
   - Can iterate on core features
   - Auth can be added when ready

## Related Documentation

- See `DEVELOPMENT-SETUP.md` for Supabase setup guide
- See `FINAL-PRE-LAUNCH-CHECK.md` for production checklist
- See `ARCHITECTURE.md` for data flow overview

## Questions & Answers

**Q: Can users create multiple profiles?**  
A: No, it's one profile per device during beta. Data is local.

**Q: What if they uninstall?**  
A: All data is lost. Warn in TestFlight notes and consider export features.

**Q: Will their name migrate to production?**  
A: Depends on migration strategy. Consider export/import flow.

**Q: What about privacy?**  
A: Data never leaves device during beta. Update Privacy Policy before production.

**Q: Can they change their name later?**  
A: Yes, in Settings. Check `SettingsView.swift` for profile editing.

## Support

For questions about this implementation, see:
- Code comments in `SignInPage.swift`
- Supabase documentation: https://supabase.com/docs
- Apple Auth Services: https://developer.apple.com/documentation/authenticationservices

---

**Note:** This is a temporary solution for beta testing. Plan to implement proper authentication before public launch.


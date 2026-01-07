# Beta Testing Checklist

**Before submitting to TestFlight External Testing**

## ✅ Profile Setup Verification

Test the profile setup flow:

- [ ] App launches to Welcome/Features page
- [ ] "Get Started" shows profile setup page
- [ ] Page shows "Let's Get Started" header
- [ ] Beta disclaimer badge is visible and clear
- [ ] First Name field is present and required
- [ ] Last Name field is present and required
- [ ] Email field is present and marked "(Optional)"
- [ ] NO password fields visible
- [ ] NO social sign-in buttons (Apple/Google)
- [ ] NO "Sign In vs Sign Up" toggle
- [ ] "Continue to App" button is prominent
- [ ] Button is disabled when name fields empty
- [ ] Button enables when both names filled
- [ ] Email can be left empty and still proceed

## ✅ Data Capture & Flow

Test that data flows correctly:

- [ ] Enter first name and last name
- [ ] Click "Continue to App"
- [ ] Proceeds to User Type Selection page
- [ ] Complete onboarding flow
- [ ] Name appears in dashboard greeting
- [ ] Name appears in Settings
- [ ] Name appears on generated PDF reports
- [ ] Email (if entered) appears in Settings

## ✅ Onboarding Flow

Verify the complete onboarding:

- [ ] Profile Setup → User Type Selection works
- [ ] User Type Selection → Property/Company works
- [ ] All onboarding pages display correctly
- [ ] Can complete as Farmer
- [ ] Can complete as Advisor
- [ ] Reaches main dashboard after completion

## ✅ Visual & UX

Check the design and usability:

- [ ] Page matches app's visual style
- [ ] Text is readable on all backgrounds
- [ ] Input fields are clearly visible
- [ ] Beta disclaimer stands out but not distracting
- [ ] Spacing and padding looks good
- [ ] Works on iPhone SE (smallest screen)
- [ ] Works on iPhone 15 Pro Max (largest screen)
- [ ] Works in Light Mode
- [ ] Works in Dark Mode
- [ ] Keyboard appears for text fields
- [ ] Return key moves between fields correctly
- [ ] Keyboard dismisses after last field

## ✅ TestFlight Preparation

Before uploading to TestFlight:

- [ ] Remove or comment out dev skip buttons
- [ ] Archive builds successfully in Xcode
- [ ] No compiler warnings (check build log)
- [ ] App runs on physical device
- [ ] No crashes during onboarding
- [ ] Bundle ID is correct
- [ ] Version number incremented
- [ ] Build number incremented

## ✅ TestFlight Configuration

In App Store Connect:

- [ ] Build uploaded successfully
- [ ] Build processed without issues
- [ ] Test Information filled out
- [ ] "What to Test" notes added (see BETA-PROFILE-SETUP.md)
- [ ] Beta App Description updated
- [ ] Privacy Policy link added (if required)
- [ ] Export Compliance information provided
- [ ] External Testing enabled
- [ ] Tester groups created

## ✅ Tester Communication

Prepare communications:

- [ ] Email template ready for testers
- [ ] Clear instructions about beta nature
- [ ] Explain data is local-only
- [ ] Provide feedback channels
- [ ] Set expectations about timeline
- [ ] Include screenshots/video if helpful

## 📧 Sample TestFlight "What to Test"

Copy this into TestFlight notes:

```
🎯 WELCOME TO STOCKMANS WALLET BETA!

Thank you for helping us test the future of livestock portfolio management!

🔍 WHAT WE'RE TESTING:
This beta focuses on core livestock management features. We want your feedback on:

✓ Onboarding experience (including profile setup)
✓ Adding herds and individual animals
✓ Portfolio valuation accuracy
✓ Market price data relevance
✓ Report generation (PDF exports)
✓ Overall navigation and ease of use

📝 PROFILE SETUP:
• The "Let's Get Started" screen captures your name for personalization
• Email is optional during beta
• Your name will appear in reports and throughout the app
• Full user accounts coming before public launch

⚠️ IMPORTANT NOTES:
• This is BETA software - expect some rough edges
• All data is stored locally on your device
• Data will NOT sync between devices
• Uninstalling = data loss (export reports to back up)
• User authentication coming in production version

🐛 FOUND A BUG?
Please report via TestFlight feedback or email: [your-email@example.com]

Include:
- What you were doing
- What happened vs. what you expected
- Screenshots if possible
- Device model and iOS version

💡 FEEDBACK WELCOME ON:
- Missing features you'd like to see
- Confusing workflows
- UI/UX improvements
- Data accuracy concerns
- Performance issues

Thank you for your time and insights! Your feedback is invaluable to making this the best livestock management app possible. 🐄

Questions? Email us at [your-email@example.com]
```

## 🎯 First 3 Testers Checklist

For your first small group:

- [ ] Personally explain the beta to them
- [ ] Set expectations about data being local
- [ ] Ask them to focus on specific features
- [ ] Schedule a follow-up call/meeting
- [ ] Prepare to iterate quickly on feedback
- [ ] Have a way to push updates quickly

## 📊 Feedback to Collect

Key questions for testers:

**Onboarding:**
- Was the profile setup clear?
- Did you understand what information was needed?
- Was anything confusing about the flow?
- How long did onboarding take?

**Core Features:**
- Could you easily add a herd?
- Was the valuation calculation clear?
- Are the market prices relevant to you?
- Did the reports meet your needs?

**Overall:**
- Would you use this app regularly?
- What's the #1 thing we should improve?
- What features are you missing most?
- Any bugs or crashes?

## 🚀 Post-Launch Actions

After successful beta test:

- [ ] Collect and organize all feedback
- [ ] Prioritize bug fixes
- [ ] Plan feature additions based on feedback
- [ ] Prepare authentication implementation
- [ ] Plan data migration strategy
- [ ] Update documentation
- [ ] Plan for App Store launch

## 📱 Support Resources

Have these ready for testers:

- [ ] FAQ document
- [ ] Video walkthrough (optional but helpful)
- [ ] Email support address
- [ ] Response SLA (e.g., "within 24 hours")
- [ ] Known issues list
- [ ] Update schedule

## ⚠️ Red Flags to Watch For

Monitor for these issues:

- [ ] High crash rate (>5%)
- [ ] Onboarding completion rate (<80%)
- [ ] Immediate uninstalls
- [ ] Consistent confusion about same feature
- [ ] Performance complaints
- [ ] Data loss reports

## 🎉 Success Metrics

Beta is successful when:

- [ ] 80%+ testers complete onboarding
- [ ] 50%+ testers add at least one herd
- [ ] 30%+ testers generate a report
- [ ] <5% crash rate
- [ ] Positive feedback on core features
- [ ] Clear understanding of what to improve

---

**Remember:** This is beta! Iterate quickly based on feedback. Don't aim for perfection - aim for learning.


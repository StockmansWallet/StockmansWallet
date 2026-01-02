# Development Setup Checklist

Complete this checklist before starting active development.

---

## ✅ **Essential Setup (Do Now)**

### Development Tools
- [x] Xcode 16.1+ installed
- [ ] Xcode Command Line Tools activated (`xcode-select -p`)
- [ ] SF Symbols app downloaded
- [ ] SweetPad extension configured (if using Cursor)
- [ ] iOS Simulator set up and tested

### Project Configuration
- [x] Project structure organized
- [x] .cursorrules configured
- [x] .gitignore created
- [x] README.md created
- [x] Documentation folder structure

### Development Environment
- [ ] Test build successful in Xcode
- [ ] Test build successful in SweetPad
- [ ] Preview in Xcode working
- [ ] Simulator runs without errors
- [ ] Hot reload working

---

## 📋 **Recommended Setup (Do Before First Feature)**

### Version Control
- [ ] Initialize Git repository
- [ ] Create .gitattributes file
- [ ] Make first commit
- [ ] (Optional) Push to GitHub/GitLab

**Commands:**
```bash
cd "/path/to/StockmansWallet"
git init
git add .
git commit -m "Initial commit: Project structure and documentation"
```

### Environment Configuration
- [ ] Create .env template (if using external APIs)
- [ ] Document environment variables
- [ ] Set up development vs production configs
- [ ] Configure API keys securely

### Testing Setup
- [ ] Run unit test target successfully
- [ ] Run UI test target successfully
- [ ] Set up test data/mocks
- [ ] Document testing approach

### Third-Party Services
- [ ] Supabase project created (if starting backend)
- [ ] RevenueCat account set up (for monetization)
- [ ] TelemetryDeck configured (for analytics)
- [ ] API keys documented securely

---

## 🎯 **Nice to Have (Can Do Later)**

### Documentation
- [ ] Architecture documentation
- [ ] API documentation
- [ ] Contributing guidelines
- [ ] Code style guide

### Automation
- [ ] Build scripts
- [ ] Deployment scripts
- [ ] Icon generation script
- [ ] Screenshot automation

### Legal
- [ ] Privacy Policy draft
- [ ] Terms of Service draft
- [ ] EULA if needed
- [ ] Copyright notices

---

## 🚨 **Common Issues & Solutions**

### "xcodebuild not found"
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
# Restart Terminal/Cursor
```

### "Package resolution failed"
1. Close Xcode
2. Delete DerivedData
3. Delete Package.resolved
4. Reopen and File → Packages → Resolve Package Versions

### "Preview crashes"
1. Clean build folder (Cmd+Shift+K)
2. Restart Xcode
3. Check preview provider code

### "SwiftData migration errors"
- See StockmansWalletApp.swift - we auto-reset on migration failure
- Delete app from simulator to start fresh

---

## 📚 **Development Resources**

### Bookmarks to Create
```
📁 Stockman's Wallet Dev
├── Project GitHub/GitLab (when created)
├── Supabase Dashboard
├── RevenueCat Dashboard
├── TelemetryDeck Dashboard
├── TestFlight (when ready)
└── App Store Connect (when ready)
```

### Documentation to Read
- [ ] SwiftUI tutorials (if needed)
- [ ] SwiftData documentation
- [ ] Our HIG-Summary.md
- [ ] Project README.md

---

## 🎨 **Design Setup**

### Assets
- [x] App icons created (3 variants)
- [x] Background images added (17 farm backgrounds)
- [x] Color palette defined
- [x] Lottie animations added

### Missing Assets?
- [ ] Screenshots for App Store (when ready)
- [ ] App preview video (when ready)
- [ ] Marketing materials (when ready)

---

## ⚙️ **Xcode Configuration**

### Scheme Settings
1. Open Xcode
2. Product → Scheme → Edit Scheme
3. Run → Options → GPU Validation (Enable for debugging)
4. Test → Options → Set test data location

### Useful Build Settings
- Debug: Fast builds, all warnings
- Release: Optimized, no debug symbols

### Recommended Xcode Settings
- Editor → Show Line Numbers
- Editor → Show Invisibles
- Text Editing → Automatically trim whitespace
- Text Editing → Including whitespace-only lines

---

## 🔐 **Security Checklist**

### Code Security
- [ ] No hardcoded API keys
- [ ] No hardcoded passwords
- [ ] Sensitive data in .env (not in Git)
- [ ] .env in .gitignore

### Data Security
- [ ] User data encrypted at rest (SwiftData handles this)
- [ ] Network calls use HTTPS only
- [ ] API keys stored in Keychain (when added)

---

## 📱 **Testing Devices**

### Minimum Test Matrix
- [ ] iPhone SE (smallest screen)
- [ ] iPhone 15 Pro (current flagship)
- [ ] iPad Pro (largest screen)
- [ ] Dark mode enabled
- [ ] Different Dynamic Type sizes

### Simulators to Add
1. Xcode → Window → Devices and Simulators
2. Add: iPhone SE, iPhone 15 Pro, iPad Pro
3. Test your main flows on each

---

## 🚀 **Ready to Start Coding?**

### Pre-Flight Check
- [x] Project builds successfully
- [x] Documentation is in place
- [x] Structure is organized
- [ ] Git initialized (recommended)
- [ ] You understand the architecture
- [ ] You've read HIG-Summary.md
- [ ] SweetPad is working (or Xcode is ready)

### First Task Suggestions
1. **Run the app** - See what's already there
2. **Review existing code** - Understand current implementation
3. **Check mock data** - See how data flows
4. **Test navigation** - Verify all screens work
5. **Plan first feature** - Start small

---

## 📝 **Development Workflow**

### Before Each Session
1. Pull latest changes (if using Git)
2. Read any new docs
3. Check for Xcode updates
4. Review current TODOs

### During Development
1. Make small, focused commits
2. Test on device regularly
3. Update documentation as you go
4. Follow .cursorrules

### End of Session
1. Commit work in progress
2. Update TODOs
3. Document any issues
4. Clean build if needed

---

## 🎯 **Quick Wins to Build Confidence**

If you want to test everything works:

1. **Add a simple view**
   - Create TestView.swift
   - Add to navigation
   - Build and run

2. **Modify existing screen**
   - Change a color in Theme.swift
   - See it update everywhere

3. **Test SwiftData**
   - Add a test herd
   - See it persist
   - Delete and verify

4. **Test PDF generation**
   - Navigate to Reports
   - Generate Asset Register
   - Verify PDF creates

---

**Ready?** Let's build something amazing! 🚀



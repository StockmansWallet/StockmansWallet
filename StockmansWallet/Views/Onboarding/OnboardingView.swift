//
//  OnboardingView.swift
//  StockmansWallet
//
//  Main Onboarding Coordinator
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @State private var onboardingStep: OnboardingStep = .landing // Debug: Start with landing page as before
    @State private var currentPage = 0
    @State private var userPrefs = UserPreferences()
    @State private var showingSignIn = false
    @State private var isSigningIn = false
    
    // Debug: Terms & Privacy acceptance (shown before onboarding)
    @State private var showingTermsPrivacy = false
    @State private var hasAcceptedTerms = false
    
    // Intro animation state (HIG-aligned: subtle fade only)
    @State private var introOpacity: Double = 0.0
    @State private var introComplete: Bool = false
    
    enum OnboardingStep {
        case landing
        case features
        case signIn
        case onboardingPages
    }
    
    var body: some View {
        ZStack {
            // Background can and should fill the screen
            Theme.backgroundGradient
                .ignoresSafeArea(.all)
            
            Group {
                switch onboardingStep {
                case .landing, .features:
                    WelcomeFeaturesPage(
                        onboardingStep: $onboardingStep,
                        showingSignIn: $showingSignIn,
                        showingTermsPrivacy: $showingTermsPrivacy,
                        hasAcceptedTerms: $hasAcceptedTerms,
                        // Pass down intro completion so Lottie can start after fade
                        introComplete: introComplete,
                        // Debug: TEMPORARY - Skip onboarding for development (DELETE BEFORE LAUNCH) ⚠️
                        onSkipAsFarmer: skipAsFarmerForDev,
                        onSkipAsAdvisor: skipAsAdvisorForDev
                    )
                    
                case .signIn:
                    SignInPage(
                        currentPage: $currentPage,
                        showingSignIn: $showingSignIn,
                        isSigningIn: $isSigningIn,
                        userPrefs: $userPrefs,
                        onSignInComplete: {
                            onboardingStep = .onboardingPages
                        },
                        // Debug: Demo sign-in handlers
                        onEmailSignIn: demoEmailSignIn,
                        onEmailSignUp: demoEmailSignUp,
                        onAppleSignIn: demoAppleSignIn,
                        onGoogleSignIn: demoGoogleSignIn
                    )
                    
                case .onboardingPages:
                    // Debug: Branching onboarding flow based on user role (4 pages total)
                    // Green Path (Farmer): UserType → Property → Welcome → Subscription (4 pages)
                    // Pink Path (Advisory): UserType → Company → Welcome → Subscription (4 pages)
                    // Welcome & Subscription pages are SHARED between both paths
                    // Name/email collected in Sign Up, Security/Privacy in Terms sheet
                    Group {
                        switch currentPage {
                        case 0:
                            // First page: User Type Selection (both paths)
                            UserTypeSelectionPage(
                                userPrefs: $userPrefs,
                                currentPage: $currentPage
                            )
                        case 1:
                            // Second page: Branch based on user role
                            if userPrefs.userRole == .farmerGrazier {
                                // Green Path: Property Information
                                YourPropertyPage(
                                    userPrefs: $userPrefs,
                                    currentPage: $currentPage
                                )
                            } else {
                                // Pink Path: Company Information
                                CompanyInfoPage(
                                    userPrefs: $userPrefs,
                                    currentPage: $currentPage
                                )
                            }
                        case 2:
                            // Third page: Welcome/Completion (SHARED - both paths)
                            // Debug: Celebrates completion before subscription selection
                            WelcomeCompletionPage(
                                userPrefs: $userPrefs,
                                currentPage: $currentPage
                            )
                        case 3:
                            // Fourth page: Subscription/Pricing (SHARED - final page)
                            SubscriptionView(
                                userPrefs: $userPrefs,
                                onComplete: saveAndComplete
                            )
                        default:
                            // Fallback to first page
                            UserTypeSelectionPage(
                                userPrefs: $userPrefs,
                                currentPage: $currentPage
                            )
                        }
                    }
                    .transition(.opacity)
                }
            }
            // Removed .ignoresSafeArea() so content respects the top safe area
            // Subtle intro fade for first render (no scale to avoid layout perception shift)
            .opacity(introOpacity)
            .onAppear {
                if UIAccessibility.isReduceMotionEnabled {
                    introOpacity = 1.0
                    introComplete = true
                } else {
                    introOpacity = 0.0
                    withAnimation(.easeOut(duration: 0.28)) {
                        introOpacity = 1.0
                    }
                    // Mark complete slightly after fade so child animations can sequence
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                        introComplete = true
                    }
                }
            }
        }
        .onAppear {
            // Debug: Load existing preferences or prepare to create new ones
            // Don't insert yet - let the sign-in handlers do that
            if let existing = preferences.first {
                userPrefs = existing
            }
        }
        .sheet(isPresented: $showingTermsPrivacy) {
            // Debug: Terms & Privacy sheet shown after "Get Started" button (Option 1)
            TermsPrivacySheet(
                isPresented: $showingTermsPrivacy,
                hasAccepted: $hasAcceptedTerms
            )
            .interactiveDismissDisabled() // Debug: Must accept terms, can't dismiss
        }
        .sheet(isPresented: $showingSignIn) {
            SignInPage(
                currentPage: $currentPage,
                showingSignIn: $showingSignIn,
                isSigningIn: $isSigningIn,
                userPrefs: $userPrefs,
                onSignInComplete: {
                    onboardingStep = .onboardingPages
                },
                // Debug: Demo sign-in handlers
                onEmailSignIn: demoEmailSignIn,
                onEmailSignUp: demoEmailSignUp,
                onAppleSignIn: demoAppleSignIn,
                onGoogleSignIn: demoGoogleSignIn
            )
            // Native sheet with solid background from Theme - follows Apple HIG
            .presentationBackground(Theme.sheetBackground)
            .presentationCornerRadius(Theme.cornerRadius * 2)
            .presentationDragIndicator(.visible)
        }
    }
    
    private func saveAndComplete() {
        HapticManager.success()
        userPrefs.hasCompletedOnboarding = true
        
        if preferences.isEmpty {
            modelContext.insert(userPrefs)
        } else if let existing = preferences.first {
            // Debug: Update existing preferences with all onboarding data
            existing.hasCompletedOnboarding = true
            existing.firstName = userPrefs.firstName
            existing.lastName = userPrefs.lastName
            existing.email = userPrefs.email
            existing.role = userPrefs.role
            existing.twoFactorEnabled = userPrefs.twoFactorEnabled
            existing.appsComplianceAccepted = userPrefs.appsComplianceAccepted
            
            // Property fields (Farmer path)
            existing.propertyName = userPrefs.propertyName
            existing.propertyPIC = userPrefs.propertyPIC
            existing.propertyRole = userPrefs.propertyRole
            existing.propertyAddress = userPrefs.propertyAddress
            existing.defaultState = userPrefs.defaultState
            existing.latitude = userPrefs.latitude
            existing.longitude = userPrefs.longitude
            
            // Company fields (Advisory path)
            existing.companyName = userPrefs.companyName
            existing.companyType = userPrefs.companyType
            existing.companyAddress = userPrefs.companyAddress
            existing.roleInCompany = userPrefs.roleInCompany
            
            // Subscription tier
            existing.subscriptionTier = userPrefs.subscriptionTier
            
            // Legacy fields (can be set later in settings)
            existing.defaultSaleyard = userPrefs.defaultSaleyard
            existing.truckItEnabled = userPrefs.truckItEnabled
            existing.xeroConnected = userPrefs.xeroConnected
            existing.myobConnected = userPrefs.myobConnected
        }
        
        try? modelContext.save()
    }
    
    // Debug: TEMPORARY - Skip onboarding as Farmer for development testing (DELETE BEFORE LAUNCH) ⚠️
    // This allows quick access to the farmer dashboard without going through onboarding
    private func skipAsFarmerForDev() {
        HapticManager.tap()
        userPrefs.hasCompletedOnboarding = true
        userPrefs.role = UserRole.farmerGrazier.rawValue // Set as farmer
        
        if preferences.isEmpty {
            modelContext.insert(userPrefs)
        } else if let existing = preferences.first {
            existing.hasCompletedOnboarding = true
            existing.role = UserRole.farmerGrazier.rawValue
        }
        
        try? modelContext.save()
    }
    
    // Debug: TEMPORARY - Skip onboarding as Advisor for development testing (DELETE BEFORE LAUNCH) ⚠️
    // This allows quick access to the advisory dashboard without going through onboarding
    private func skipAsAdvisorForDev() {
        HapticManager.tap()
        userPrefs.hasCompletedOnboarding = true
        userPrefs.role = UserRole.livestockAgent.rawValue // Set as advisory user (livestock agent)
        
        if preferences.isEmpty {
            modelContext.insert(userPrefs)
        } else if let existing = preferences.first {
            existing.hasCompletedOnboarding = true
            existing.role = UserRole.livestockAgent.rawValue
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Demo Sign-In Methods (TEMPORARY - DELETE BEFORE LAUNCH) ⚠️
    
    // Debug: Demo Email/Password sign-in - Existing user goes to Farmer dashboard
    // In production, this would authenticate against backend
    private func demoEmailSignIn() {
        HapticManager.tap()
        
        // Debug: Get or create the user preferences object
        let prefsToUpdate: UserPreferences
        if let existing = preferences.first {
            prefsToUpdate = existing
        } else {
            prefsToUpdate = userPrefs
            modelContext.insert(prefsToUpdate)
        }
        
        // Debug: Mark as completed - existing user goes straight to dashboard
        prefsToUpdate.hasCompletedOnboarding = true
        prefsToUpdate.role = UserRole.farmerGrazier.rawValue // Default to farmer for demo
        prefsToUpdate.firstName = userPrefs.firstName
        prefsToUpdate.lastName = userPrefs.lastName
        prefsToUpdate.email = userPrefs.email
        
        try? modelContext.save()
    }
    
    // Debug: Demo Email/Password sign-up - New user goes through onboarding
    // In production, this would create account on backend then show onboarding
    private func demoEmailSignUp() {
        HapticManager.tap()
        
        // Debug: Dismiss sheet if shown as sheet, then navigate to onboarding
        showingSignIn = false
        isSigningIn = false
        
        // Debug: Delay to ensure sheet dismisses smoothly before navigation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                // Debug: Save name/email but DON'T mark onboarding complete
                // This will trigger the onboarding flow to collect role/property/company info
                self.onboardingStep = .onboardingPages
                self.currentPage = 0 // Start at User Type Selection
            }
        }
    }
    
    // Debug: Demo Apple sign-in - Goes to Farmer dashboard
    private func demoAppleSignIn() {
        HapticManager.tap()
        
        // Debug: Get or create the user preferences object
        let prefsToUpdate: UserPreferences
        if let existing = preferences.first {
            prefsToUpdate = existing
        } else {
            prefsToUpdate = userPrefs
            modelContext.insert(prefsToUpdate)
        }
        
        // Debug: Update the preferences with Apple sign-in data
        prefsToUpdate.hasCompletedOnboarding = true
        prefsToUpdate.role = UserRole.farmerGrazier.rawValue // Set as farmer for demo
        
        try? modelContext.save()
    }
    
    // Debug: Demo Google sign-in - Goes to Advisor dashboard
    private func demoGoogleSignIn() {
        HapticManager.tap()
        
        // Debug: Get or create the user preferences object
        let prefsToUpdate: UserPreferences
        if let existing = preferences.first {
            prefsToUpdate = existing
        } else {
            prefsToUpdate = userPrefs
            modelContext.insert(prefsToUpdate)
        }
        
        // Debug: Update the preferences with Google sign-in data
        prefsToUpdate.hasCompletedOnboarding = true
        prefsToUpdate.role = UserRole.livestockAgent.rawValue // Set as advisor for demo
        
        try? modelContext.save()
    }
}

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
                        }
                    )
                    
                case .onboardingPages:
                    // Debug: Branching onboarding flow based on user role (5 pages total)
                    // Green Path (Farmer): UserType → AboutYou → Property → Welcome → Subscription (5 pages)
                    // Pink Path (Advisory): UserType → AboutYou → Company → Welcome → Subscription (5 pages)
                    // Welcome & Subscription pages are SHARED between both paths
                    // Security/Privacy moved to Terms sheet (shown before onboarding)
                    Group {
                        switch currentPage {
                        case 0:
                            // First page: User Type Selection (both paths)
                            UserTypeSelectionPage(
                                userPrefs: $userPrefs,
                                currentPage: $currentPage
                            )
                        case 1:
                            // Second page: About You (both paths)
                            AboutYouPage(
                                userPrefs: $userPrefs,
                                currentPage: $currentPage
                            )
                        case 2:
                            // Third page: Branch based on user role
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
                        case 3:
                            // Fourth page: Welcome/Completion (SHARED - both paths)
                            // Debug: Celebrates completion before subscription selection
                            WelcomeCompletionPage(
                                userPrefs: $userPrefs,
                                currentPage: $currentPage
                            )
                        case 4:
                            // Fifth page: Subscription/Pricing (SHARED - final page)
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
            if preferences.isEmpty {
                modelContext.insert(userPrefs)
            } else if let existing = preferences.first {
                userPrefs = existing
            }
            
            // Debug: Show Terms & Privacy sheet on first launch if not already accepted
            if !hasAcceptedTerms && !userPrefs.hasCompletedOnboarding {
                // Small delay to let the view settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingTermsPrivacy = true
                }
            }
        }
        .sheet(isPresented: $showingTermsPrivacy) {
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
                }
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
}

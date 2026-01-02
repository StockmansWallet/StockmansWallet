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
    @State private var onboardingStep: OnboardingStep = .landing
    @State private var currentPage = 0
    @State private var userPrefs = UserPreferences()
    @State private var showingSignIn = false
    @State private var isSigningIn = false
    
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
            // Debug: Dark brown gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.15, blue: 0.1),
                    Color(red: 0.129, green: 0.102, blue: 0.086)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
            
            Group {
                switch onboardingStep {
                case .landing, .features:
                    WelcomeFeaturesPage(
                        onboardingStep: $onboardingStep,
                        showingSignIn: $showingSignIn,
                        // Pass down intro completion so Lottie can start after fade
                        introComplete: introComplete
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
                    TabView(selection: $currentPage) {
                        IdentityCredentialsPage(
                            userPrefs: $userPrefs,
                            currentPage: $currentPage
                        )
                        .tag(0)
                        
                        PersonaSecurityPage(
                            userPrefs: $userPrefs,
                            currentPage: $currentPage
                        )
                        .tag(1)
                        
                        PropertyLocalizationPage(
                            userPrefs: $userPrefs,
                            currentPage: $currentPage
                        )
                        .tag(2)
                        
                        MarketLogisticsPage(
                            userPrefs: $userPrefs,
                            currentPage: $currentPage
                        )
                        .tag(3)
                        
                        FinancialEcosystemPage(
                            userPrefs: $userPrefs,
                            onComplete: saveAndComplete
                        )
                        .tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
            }
            .ignoresSafeArea()
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
            // Debug: Native sheet with solid background - follows Apple HIG
            .presentationBackground(Color(red: 0.129, green: 0.102, blue: 0.086))
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
            // Update existing preferences
            existing.hasCompletedOnboarding = true
            existing.firstName = userPrefs.firstName
            existing.lastName = userPrefs.lastName
            existing.email = userPrefs.email
            existing.role = userPrefs.role
            existing.twoFactorEnabled = userPrefs.twoFactorEnabled
            existing.appsComplianceAccepted = userPrefs.appsComplianceAccepted
            existing.propertyName = userPrefs.propertyName
            existing.propertyPIC = userPrefs.propertyPIC
            existing.defaultState = userPrefs.defaultState
            existing.latitude = userPrefs.latitude
            existing.longitude = userPrefs.longitude
            existing.defaultSaleyard = userPrefs.defaultSaleyard
            existing.truckItEnabled = userPrefs.truckItEnabled
            existing.xeroConnected = userPrefs.xeroConnected
            existing.myobConnected = userPrefs.myobConnected
        }
        
        try? modelContext.save()
    }
}

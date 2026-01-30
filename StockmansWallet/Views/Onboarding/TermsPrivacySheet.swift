//
//  TermsPrivacySheet.swift
//  StockmansWallet
//
//  Terms, Privacy Policy, and APPs Compliance acceptance sheet
//  Debug: Shown on first app launch before onboarding begins
//

import SwiftUI

struct TermsPrivacySheet: View {
    @Binding var isPresented: Bool
    @Binding var hasAccepted: Bool
    @State private var hasScrolledToBottom = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var showingAPPs = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.accent)
                            .padding(.top, 20)
                        
                        Text("Terms & Conditions")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.LightTheme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Please review and accept our terms and conditions to continue.")
                            .font(Theme.body)
                            .foregroundStyle(Theme.LightTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Legal Documents Summary
                    VStack(spacing: 16) {
                        // Terms of Service
                        LegalDocumentRow(
                            icon: "doc.text.fill",
                            title: "Terms of Service",
                            description: "Outlines the rules and regulations of using Stockman's Wallet."
                        ) {
                            HapticManager.tap()
                            showingTerms = true
                        }
                        
                        // Privacy Policy
                        LegalDocumentRow(
                            icon: "hand.raised.fill",
                            title: "Privacy Policy",
                            description: "Explains how we collect, use, and protect your personal information."
                        ) {
                            HapticManager.tap()
                            showingPrivacy = true
                        }
                        
                        // Australian Privacy Principles
                        LegalDocumentRow(
                            icon: "building.columns.fill",
                            title: "Australian Privacy Principles",
                            description: "Our commitment to Australian privacy compliance standards."
                        ) {
                            HapticManager.tap()
                            showingAPPs = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Accept Button - Orange accent
                    Button(action: {
                        HapticManager.success()
                        hasAccepted = true
                        isPresented = false
                    }) {
                        Text("I Accept")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Theme.AccentButtonStyle())
                    .padding(.horizontal, 20)
                    
                    // Fine Print
                    Text("By accepting our Terms of Service, Privacy Policy, and acknowledge our compliance with Australian Privacy Principles.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.LightTheme.secondaryText.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 20)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.LightTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled() // Debug: Must accept, can't dismiss
        }
        .sheet(isPresented: $showingTerms) {
            TermsDetailView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyDetailView()
        }
        .sheet(isPresented: $showingAPPs) {
            APPsDetailView()
        }
    }
}

// MARK: - Legal Document Row Component
struct LegalDocumentRow: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.LightTheme.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.LightTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.LightTheme.secondaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: Theme.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Theme.LightTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View \(title)")
    }
}

// MARK: - Key Point Row Component
struct KeyPointRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.positiveChange)
                .frame(width: 24)
            
            Text(text)
                .font(Theme.subheadline)
                .foregroundStyle(Theme.LightTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Detail Views (Placeholder - Add actual content)

struct TermsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Service")
                        .font(.title.bold())
                        .padding(.bottom, 8)
                    
                    Text("Last Updated: January 2026")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    
                    // Debug: Add your actual terms here
                    Group {
                        SectionTitle("1. Acceptance of Terms")
                        SectionBody("By accessing and using Stockman's Wallet, you accept and agree to be bound by the terms and provision of this agreement.")
                        
                        SectionTitle("2. Use License")
                        SectionBody("Permission is granted to temporarily download one copy of Stockman's Wallet for personal, non-commercial transitory viewing only.")
                        
                        SectionTitle("3. User Data")
                        SectionBody("You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.")
                        
                        SectionTitle("4. Disclaimer")
                        SectionBody("The materials in Stockman's Wallet are provided on an 'as is' basis. Stockman's Wallet makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties.")
                        
                        // Debug: Add more sections as needed
                    }
                }
                .padding(20)
            }
            .background(Theme.backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PrivacyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title.bold())
                        .padding(.bottom, 8)
                    
                    Text("Last Updated: January 2026")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    
                    // Debug: Add your actual privacy policy here
                    Group {
                        SectionTitle("Information We Collect")
                        SectionBody("We collect information you provide directly to us, including your name, email address, property information, and livestock data you input into the app.")
                        
                        SectionTitle("How We Use Your Information")
                        SectionBody("We use the information we collect to provide, maintain, and improve our services, to develop new services, and to protect Stockman's Wallet and our users.")
                        
                        SectionTitle("Information Sharing")
                        SectionBody("We do not share your personal information with companies, organizations, or individuals outside of Stockman's Wallet except in limited circumstances described in this policy.")
                        
                        SectionTitle("Data Security")
                        SectionBody("We work hard to protect Stockman's Wallet and our users from unauthorized access to or unauthorized alteration, disclosure, or destruction of information we hold.")
                        
                        SectionTitle("Your Rights")
                        SectionBody("You have the right to access, update, or delete your personal information at any time through the app settings.")
                    }
                }
                .padding(20)
            }
            .background(Theme.backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct APPsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Australian Privacy Principles")
                        .font(.title.bold())
                        .padding(.bottom, 8)
                    
                    Text("Our Commitment to APPs Compliance")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                    
                    // Debug: Add actual APPs compliance info
                    Group {
                        SectionTitle("What are APPs?")
                        SectionBody("The Australian Privacy Principles (APPs) are the cornerstone of the privacy protection framework in the Privacy Act 1988. They apply to any organisation with an annual turnover of more than $3 million.")
                        
                        SectionTitle("Our Compliance")
                        SectionBody("Stockman's Wallet is committed to protecting your privacy in accordance with the Australian Privacy Principles. We handle your personal information transparently and give you control over how your information is used.")
                        
                        SectionTitle("Key Principles We Follow")
                        SectionBody("• Open and transparent management of personal information\n• Anonymity and pseudonymity where practicable\n• Collection of solicited personal information only\n• Dealing with unsolicited personal information appropriately\n• Notification of collection\n• Use and disclosure of personal information\n• Direct marketing compliance\n• Cross-border disclosure restrictions\n• Adoption, use, and disclosure of government-related identifiers\n• Quality of personal information\n• Security of personal information\n• Access to and correction of personal information")
                        
                        SectionTitle("Your Rights")
                        SectionBody("Under the APPs, you have the right to know what information we hold about you, request corrections, and make a complaint if you believe your privacy has been breached.")
                    }
                }
                .padding(20)
            }
            .background(Theme.backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Components
struct SectionTitle: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(Theme.headline)
            .foregroundStyle(Theme.primaryText)
            .padding(.top, 8)
    }
}

struct SectionBody: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(Theme.body)
            .foregroundStyle(Theme.secondaryText)
    }
}






//
//  ChatToolView.swift
//  StockmansWallet
//
//  Chat - Get help and support
//  Debug: Placeholder view for future implementation
//

import SwiftUI

// Debug: Chat tool - full screen view accessible from Tools menu
struct ChatToolView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.sectionSpacing) {
                    // Debug: Coming soon card
                    VStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Theme.positiveChange.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(Theme.positiveChange)
                        }
                        .padding(.top, 40)
                        
                        // Title and description
                        VStack(spacing: 8) {
                            Text("Chat")
                                .font(Theme.title)
                                .foregroundStyle(Theme.primaryText)
                            
                            Text("Coming Soon")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.accent)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Theme.accent.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        
                        // Feature description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Planned Features:")
                                .font(Theme.headline)
                                .foregroundStyle(Theme.primaryText)
                            
                            FeatureRow(icon: "message", text: "Real-time support chat")
                            FeatureRow(icon: "questionmark.circle", text: "FAQs and help articles")
                            FeatureRow(icon: "bell", text: "Important notifications")
                            FeatureRow(icon: "person.2", text: "Community discussions")
                        }
                        .padding(Theme.cardPadding)
                        .cardStyle()
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 100)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                // Debug: Back button to dismiss
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.tap()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Tools")
                                .font(Theme.body)
                        }
                        .foregroundStyle(Theme.accent)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Chat")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
        }
    }
}



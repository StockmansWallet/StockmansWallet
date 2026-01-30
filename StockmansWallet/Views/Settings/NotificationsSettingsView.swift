//
//  NotificationsSettingsView.swift
//  StockmansWallet
//
//  Notification Preferences - Control alerts and updates
//  Debug: Comprehensive notification settings with categories and delivery options
//

import SwiftUI

// Debug: Enhanced notifications settings with category-based controls
struct NotificationsSettingsView: View {
    // Debug: Live Export Orders category
    @State private var liveExportEnabled = true
    @State private var liveExportDashboard = true
    @State private var liveExportEmail = false
    @State private var showLiveExportExamples = false
    
    // Debug: Private Sale and Buy/Sell category
    @State private var privateSaleEnabled = true
    @State private var privateSaleDashboard = true
    @State private var privateSaleEmail = false
    @State private var showPrivateSaleExamples = false
    
    // Debug: Industry News category
    @State private var industryNewsEnabled = true
    @State private var industryNewsDashboard = false
    @State private var industryNewsEmail = true
    @State private var showIndustryNewsExamples = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                // Debug: Header section explaining notifications
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.accentColor)
                        Text("Notifications")
                            .font(Theme.title)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    Text("Control what updates you receive and where you see them.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                    
                    Text("This section lets you manage alerts for market activity, sales opportunities, and industry updates.\n\nUse it to stay informed without being overwhelmed.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.cardPadding)
                .cardStyle()
                .padding(.horizontal)
                .padding(.top)
                
                // Debug: Live Export Orders category
                NotificationCategoryCard(
                    title: "Live Export Orders",
                    icon: "shippingbox.fill",
                    iconColor: .blue,
                    description: "Alerts when live export buyers are seeking stock that matches your herd.",
                    isEnabled: $liveExportEnabled,
                    showOnDashboard: $liveExportDashboard,
                    sendToEmail: $liveExportEmail,
                    showExamples: $showLiveExportExamples,
                    examples: [
                        "Species, weight range, or region match",
                        "New or updated orders"
                    ]
                )
                .padding(.horizontal)
                
                // Debug: Private Sale and Buy/Sell category
                NotificationCategoryCard(
                    title: "Private Sale and Buy/Sell",
                    icon: "handshake.fill",
                    iconColor: .orange,
                    description: "Notifications for private listings and direct sale opportunities.",
                    isEnabled: $privateSaleEnabled,
                    showOnDashboard: $privateSaleDashboard,
                    sendToEmail: $privateSaleEmail,
                    showExamples: $showPrivateSaleExamples,
                    examples: [
                        "Buyers looking for cattle or sheep",
                        "New classified listings",
                        "Updates to existing listings"
                    ]
                )
                .padding(.horizontal)
                
                // Debug: Industry News category
                NotificationCategoryCard(
                    title: "Industry News",
                    icon: "newspaper.fill",
                    iconColor: Theme.positiveChange,
                    description: "Updates from trusted industry sources.",
                    isEnabled: $industryNewsEnabled,
                    showOnDashboard: $industryNewsDashboard,
                    sendToEmail: $industryNewsEmail,
                    showExamples: $showIndustryNewsExamples,
                    examples: [
                        "Market movements",
                        "Policy or regulation changes",
                        "Seasonal and regional insights"
                    ]
                )
                .padding(.horizontal)
                
                // Debug: Notification delivery controls
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "gearshape.2.fill")
                            .foregroundStyle(Theme.accentColor)
                        Text("Notification delivery controls")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    Divider()
                        .background(Theme.separator)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DeliveryControlRow(icon: "app.badge", text: "In-app alerts")
                        DeliveryControlRow(icon: "square.grid.2x2", text: "Dashboard feature cards")
                        DeliveryControlRow(icon: "envelope", text: "Email delivery per category")
                    }
                    
                    Text("Each category can be managed independently.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .padding(.top, 4)
                }
                .padding(Theme.cardPadding)
                .cardStyle()
                .padding(.horizontal)
                
                // Debug: Behaviour information
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Theme.accentColor)
                        Text("Behaviour")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    Divider()
                        .background(Theme.separator)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BehaviourRow(text: "Toggles apply instantly")
                        BehaviourRow(text: "Dashboard shows only enabled items")
                        BehaviourRow(text: "Email notifications follow your preferences")
                        BehaviourRow(text: "No duplicate alerts across channels")
                    }
                }
                .padding(Theme.cardPadding)
                .cardStyle()
                .padding(.horizontal)
            }
            .padding(.bottom, 100)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Notification Category Card
// Debug: Reusable card component for each notification category
struct NotificationCategoryCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let description: String
    
    @Binding var isEnabled: Bool
    @Binding var showOnDashboard: Bool
    @Binding var sendToEmail: Bool
    @Binding var showExamples: Bool
    let examples: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Debug: Category header with icon
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                
                Text(title)
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Spacer()
            }
            
            // Debug: Description
            Text(description)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
            
            Divider()
                .background(Theme.separator)
            
            // Debug: Main toggle
            Toggle(isOn: $isEnabled) {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(isEnabled ? Theme.accentColor : Theme.secondaryText)
                        .frame(width: 20)
                    Text("Enable notifications")
                        .font(Theme.body)
                        .foregroundStyle(Theme.primaryText)
                }
            }
            .tint(Theme.accentColor)
            .onChange(of: isEnabled) { _, _ in
                HapticManager.tap()
            }
            
            // Debug: Options (disabled when main toggle is off)
            VStack(spacing: 12) {
                Toggle(isOn: $showOnDashboard) {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 14))
                            .foregroundStyle(showOnDashboard && isEnabled ? iconColor : Theme.secondaryText)
                            .frame(width: 20)
                        Text("Show on dashboard")
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                    }
                }
                .tint(iconColor)
                .disabled(!isEnabled)
                .onChange(of: showOnDashboard) { _, _ in
                    HapticManager.tap()
                }
                
                Toggle(isOn: $sendToEmail) {
                    HStack {
                        Image(systemName: "envelope")
                            .font(.system(size: 14))
                            .foregroundStyle(sendToEmail && isEnabled ? iconColor : Theme.secondaryText)
                            .frame(width: 20)
                        Text("Send to email")
                            .font(Theme.body)
                            .foregroundStyle(Theme.primaryText)
                    }
                }
                .tint(iconColor)
                .disabled(!isEnabled)
                .onChange(of: sendToEmail) { _, _ in
                    HapticManager.tap()
                }
            }
            .opacity(isEnabled ? 1.0 : 0.5)
            
            // Debug: Examples disclosure
            Button {
                HapticManager.tap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    showExamples.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.yellow)
                        .frame(width: 20)
                    Text("Examples")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.accentColor)
                    Spacer()
                    Image(systemName: showExamples ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .buttonStyle(.plain)
            
            // Debug: Examples list (expandable)
            if showExamples {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(examples, id: \.self) { example in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(Theme.caption)
                                .foregroundStyle(iconColor)
                                .frame(width: 20, alignment: .leading)
                            Text(example)
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.cardPadding)
        .cardStyle()
    }
}

// MARK: - Delivery Control Row
// Debug: Simple row component for delivery control information
struct DeliveryControlRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.accentColor)
                .frame(width: 20)
            Text(text)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText)
        }
    }
}

// MARK: - Behaviour Row
// Debug: Simple row component for behaviour information
struct BehaviourRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.positiveChange)
                .frame(width: 20, alignment: .leading)
                .padding(.top, 2)
            Text(text)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

//
//  DashboardCardHeader.swift
//  StockmansWallet
//
//  Unified title bar for dashboard cards
//  Debug: Includes icon, title, time range pill, and reorder handle
//

import SwiftUI

// MARK: - Dashboard Card Header
struct DashboardCardHeader<TimeRangeMenu: View>: View {
    let title: String
    let iconName: String
    let iconColor: Color
    let timeRangeLabel: String?
    let timeRangeMenu: TimeRangeMenu
    
    init(
        title: String,
        iconName: String,
        iconColor: Color,
        timeRangeLabel: String? = nil,
        @ViewBuilder timeRangeMenu: () -> TimeRangeMenu
    ) {
        self.title = title
        self.iconName = iconName
        self.iconColor = iconColor
        self.timeRangeLabel = timeRangeLabel
        self.timeRangeMenu = timeRangeMenu()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Debug: Icon background changed from rounded rectangle to circle shape
                ZStack {
                    Circle()
                        .fill(Theme.dashboardIconBackground)
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
                
                Text(title)
                    .font(Theme.headline)
                    .foregroundStyle(Theme.primaryText)
                
                Spacer(minLength: 8)
                
                if let timeRangeLabel {
                    DashboardTimeRangePill(label: timeRangeLabel) {
                        timeRangeMenu
                    }
                }
                
            }
            .padding(.horizontal, Theme.dashboardCardPadding)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Theme.tertiaryBackground)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Time Range Pill
struct DashboardTimeRangePill<MenuContent: View>: View {
    let label: String
    let menuContent: MenuContent
    
    init(label: String, @ViewBuilder menuContent: () -> MenuContent) {
        self.label = label
        self.menuContent = menuContent()
    }
    
    var body: some View {
        Menu {
            menuContent
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.accentColor)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.accentColor.opacity(0.18))
            )
        }
        .accessibilityLabel("Select time range")
    }
}


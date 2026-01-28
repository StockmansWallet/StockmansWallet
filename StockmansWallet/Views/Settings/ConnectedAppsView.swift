//
//  ConnectedAppsView.swift
//  StockmansWallet
//
//  Connected Apps - Third-party integrations
//  Debug: Displays and manages connections to Xero, MYOB, TruckIt, and other services
//

import SwiftUI
import SwiftData

// Debug: Connected apps view for third-party integrations
struct ConnectedAppsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Debug: Header section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.blue)
                        Text("Connected Apps")
                            .font(Theme.title)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    Text("Connect third-party services to sync data and streamline your workflow.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.cardPadding)
                .cardStyle()
                .padding(.horizontal)
                .padding(.top)
                
                // Debug: Accounting Software section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal.fill")
                            .foregroundStyle(Theme.accent)
                        Text("Accounting Software")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    Divider()
                        .background(Theme.separator)
                    
                    // Debug: Xero connection
                    ConnectedAppCard(
                        icon: "xmark.circle.fill",
                        name: "Xero",
                        description: "Export financial reports and sync transactions",
                        isConnected: userPrefs.xeroConnected,
                        accentColor: .blue,
                        onConnect: {
                            HapticManager.tap()
                            // TODO: Implement Xero OAuth connection
                            print("Connect to Xero")
                        },
                        onDisconnect: {
                            HapticManager.tap()
                            // TODO: Implement Xero disconnection
                            print("Disconnect from Xero")
                        }
                    )
                    
                    // Debug: MYOB connection
                    ConnectedAppCard(
                        icon: "m.circle.fill",
                        name: "MYOB",
                        description: "Sync livestock records and financial data",
                        isConnected: userPrefs.myobConnected,
                        accentColor: .orange,
                        onConnect: {
                            HapticManager.tap()
                            // TODO: Implement MYOB OAuth connection
                            print("Connect to MYOB")
                        },
                        onDisconnect: {
                            HapticManager.tap()
                            // TODO: Implement MYOB disconnection
                            print("Disconnect from MYOB")
                        }
                    )
                }
                .padding(Theme.cardPadding)
                .cardStyle()
                .padding(.horizontal)
                
                // Debug: Logistics & Transport section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundStyle(Theme.accent)
                        Text("Logistics & Transport")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                    }
                    
                    Divider()
                        .background(Theme.separator)
                    
                    // Debug: TruckIt connection
                    ConnectedAppCard(
                        icon: "truck.box.fill",
                        name: "TruckIt",
                        description: "Arrange livestock transport and track deliveries",
                        isConnected: userPrefs.truckItEnabled,
                        accentColor: .purple,
                        onConnect: {
                            HapticManager.tap()
                            // TODO: Implement TruckIt OAuth connection
                            print("Connect to TruckIt")
                        },
                        onDisconnect: {
                            HapticManager.tap()
                            // TODO: Implement TruckIt disconnection
                            print("Disconnect from TruckIt")
                        }
                    )
                }
                .padding(Theme.cardPadding)
                .cardStyle()
                .padding(.horizontal)
                
                // Debug: Info footer
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Theme.secondaryText)
                        .font(.caption)
                    Text("Third-party connections are secure and can be revoked at any time.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.bottom, 100)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Connected Apps")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Connected App Card
// Debug: Reusable card component for connected app with connect/disconnect actions
struct ConnectedAppCard: View {
    let icon: String
    let name: String
    let description: String
    let isConnected: Bool
    let accentColor: Color
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Debug: App icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                        
                        if isConnected {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                Text("Connected")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(Theme.positiveChange)
                        }
                    }
                    
                    Text(description)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Debug: Connect/Disconnect button
            Button(action: isConnected ? onDisconnect : onConnect) {
                Text(isConnected ? "Disconnect" : "Connect")
                    .font(Theme.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(isConnected ? Theme.destructive : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isConnected ? Theme.destructive.opacity(0.1) : accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(true) // Debug: Will be enabled when OAuth integration is implemented
            .opacity(0.6)
        }
        .padding(Theme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.cardBackground.opacity(0.5))
        )
    }
}





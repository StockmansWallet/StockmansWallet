//
//  ClientsView.swift
//  StockmansWallet
//
//  Clients Management View for Advisory Users
//  Debug: Shows list of clients with property info, valuations, reports, and chat
//

import SwiftUI
import SwiftData

struct ClientsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @State private var searchText = ""
    @State private var showingAddClient = false
    
    // Debug: Placeholder for clients - will be replaced with actual Client model
    @State private var clients: [ClientItem] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                Theme.backgroundGradient.ignoresSafeArea()
                
                if clients.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Clients list
                    clientsListView
                }
            }
            .navigationTitle("Clients")
            .searchable(text: $searchText, prompt: "Search clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.tap()
                        showingAddClient = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Add client")
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientSheet()
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent.opacity(0.5))
            
            // Title and message
            VStack(spacing: 12) {
                Text("No Clients Yet")
                    .font(Theme.title)
                    .foregroundStyle(Theme.primaryText)
                
                Text("Add your first client to get started managing their properties and livestock")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Add client button
            Button(action: {
                HapticManager.tap()
                showingAddClient = true
            }) {
                Label("Add Client", systemImage: "plus")
                    .frame(maxWidth: 200)
            }
            .buttonStyle(Theme.PrimaryButtonStyle())
            
            Spacer()
        }
    }
    
    // MARK: - Clients List
    private var clientsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredClients) { client in
                    NavigationLink(destination: ClientDetailView(client: client)) {
                        ClientCard(client: client)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // Debug: Filter clients based on search text
    private var filteredClients: [ClientItem] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText) ||
                (client.propertyName ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Client Card Component
struct ClientCard: View {
    let client: ClientItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Client name and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    if let propertyName = client.propertyName {
                        Text(propertyName)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                
                Spacer()
                
                // Unread messages indicator
                if client.unreadMessages > 0 {
                    ZStack {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 24, height: 24)
                        
                        Text("\(client.unreadMessages)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            
            // Quick stats
            HStack(spacing: 16) {
                StatBadge(icon: "chart.line.uptrend.xyaxis", value: client.portfolioValue, label: "Portfolio")
                StatBadge(icon: "text.document.fill", value: "\(client.reportCount)", label: "Reports")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.separator.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Stat Badge Component
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(Theme.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}

// MARK: - Client Item Model (Placeholder)
// Debug: This will be replaced with a proper SwiftData model
struct ClientItem: Identifiable {
    let id: UUID
    var name: String
    var propertyName: String?
    var portfolioValue: String
    var reportCount: Int
    var unreadMessages: Int
    
    init(id: UUID = UUID(), name: String, propertyName: String? = nil, portfolioValue: String = "$0", reportCount: Int = 0, unreadMessages: Int = 0) {
        self.id = id
        self.name = name
        self.propertyName = propertyName
        self.portfolioValue = portfolioValue
        self.reportCount = reportCount
        self.unreadMessages = unreadMessages
    }
}

// MARK: - Add Client Sheet (Placeholder)
struct AddClientSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack {
                    Text("Add Client Form")
                        .font(Theme.title)
                        .foregroundStyle(Theme.primaryText)
                    
                    Text("Coming soon...")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .navigationTitle("Add Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Client Detail View (Placeholder)
struct ClientDetailView: View {
    let client: ClientItem
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Client header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(client.name)
                            .font(Theme.title)
                            .foregroundStyle(Theme.primaryText)
                        
                        if let propertyName = client.propertyName {
                            Text(propertyName)
                                .font(Theme.body)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Quick actions
                    VStack(spacing: 12) {
                        ClientDetailActionButton(icon: "message.fill", title: "Messages", subtitle: "\(client.unreadMessages) unread")
                        ClientDetailActionButton(icon: "chart.bar.fill", title: "Portfolio Valuation", subtitle: client.portfolioValue)
                        ClientDetailActionButton(icon: "doc.text.fill", title: "Reports", subtitle: "\(client.reportCount) reports")
                        ClientDetailActionButton(icon: "house.fill", title: "Property Details", subtitle: "View property info")
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle("Client Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Client Detail Action Button
struct ClientDetailActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        Button(action: {
            HapticManager.tap()
            // TODO: Navigate to specific section
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.subheadline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Text(subtitle)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}







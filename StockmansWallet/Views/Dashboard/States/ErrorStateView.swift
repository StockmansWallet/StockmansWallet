//
//  ErrorStateView.swift
//  StockmansWallet
//
//  Error state view with retry action
//

import SwiftUI

struct ErrorStateView: View {
    let errorMessage: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red.opacity(0.7))
                .accessibilityHidden(true)
            
            Text("Something went wrong")
                .font(Theme.title)
                .foregroundStyle(Theme.primaryText)
            
            Text(errorMessage)
                .font(Theme.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                HapticManager.tap()
                retryAction()
            }) {
                Text("Try Again")
                    .font(Theme.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Theme.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            }
            .buttonBorderShape(.roundedRectangle)
            .accessibilityLabel("Try again")
            .accessibilityHint("Retry loading the dashboard data")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
}

#Preview {
    ErrorStateView(errorMessage: "Unable to load dashboard data") {
        print("Retry tapped")
    }
}


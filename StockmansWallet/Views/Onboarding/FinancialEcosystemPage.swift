//
//  FinancialEcosystemPage.swift
//  StockmansWallet
//
//  Page 5: Financial Ecosystem Integration
//

import SwiftUI

struct FinancialEcosystemPage: View {
    @Binding var userPrefs: UserPreferences
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Financial Ecosystem")
                    .font(Theme.title)
                    .foregroundStyle(Theme.primaryText)
                
                Text("Connect your accounting software for seamless integration")
                    .font(Theme.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                Button(action: {
                    HapticManager.tap()
                    // Demo toggle
                    userPrefs.xeroConnected.toggle()
                }) {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal.fill")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 30)
                        
                        Text("Connect Xero")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                        
                        Spacer()
                        
                        if userPrefs.xeroConnected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
                .buttonStyle(Theme.RowButtonStyle())
                .padding(.horizontal, 20)
                
                Button(action: {
                    HapticManager.tap()
                    // Demo toggle
                    userPrefs.myobConnected.toggle()
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 30)
                        
                        Text("Connect MYOB")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                        
                        Spacer()
                        
                        if userPrefs.myobConnected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
                .buttonStyle(Theme.RowButtonStyle())
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button {
                    HapticManager.tap()
                    onComplete()
                } label: {
                    Text("Complete Setup")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
                .padding(.horizontal, 20)
                
                Button {
                    HapticManager.tap()
                    onComplete()
                } label: {
                    Text("Skip for Now")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(Theme.SecondaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Theme.background.ignoresSafeArea())
    }
}


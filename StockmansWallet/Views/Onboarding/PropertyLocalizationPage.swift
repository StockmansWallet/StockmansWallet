//
//  PropertyLocalizationPage.swift
//  StockmansWallet
//
//  Page 3: Property Localization
//  Debug: Uses @Observable pattern for LocationManager
//

import SwiftUI
import CoreLocation

struct PropertyLocalizationPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    
    // Debug: Use @State with @Observable instead of @StateObject
    @State private var locationManager = LocationManager()
    @State private var isRequestingLocation = false
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Property Localization",
            subtitle: "Help us localize market data for you",
            currentPage: $currentPage,
            nextPage: 3
        ) {
            VStack(spacing: 16) {
                TextField("Property Name", text: Binding(
                    get: { userPrefs.propertyName ?? "" },
                    set: { userPrefs.propertyName = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(OnboardingTextFieldStyle())
                .autocapitalization(.words)
                
                TextField("Property Identification Code (PIC)", text: Binding(
                    get: { userPrefs.propertyPIC ?? "" },
                    set: { userPrefs.propertyPIC = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(OnboardingTextFieldStyle())
                .autocapitalization(.none)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("State")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    Menu {
                        ForEach(ReferenceData.states, id: \.self) { state in
                            Button(action: {
                                HapticManager.tap()
                                userPrefs.defaultState = state
                            }) {
                                HStack {
                                    Text(state)
                                    if userPrefs.defaultState == state {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(userPrefs.defaultState)
                                .font(Theme.body)
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .buttonStyle(Theme.RowButtonStyle())
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 20)
                }
                
                Button(action: {
                    HapticManager.tap()
                    isRequestingLocation = true
                    locationManager.requestLocation { location in
                        userPrefs.latitude = location.coordinate.latitude
                        userPrefs.longitude = location.coordinate.longitude
                        isRequestingLocation = false
                        HapticManager.success()
                    }
                }) {
                    Label(isRequestingLocation ? "Getting Location..." : "Use Current GPS Location", systemImage: "location.fill")
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(Theme.SecondaryButtonStyle())
                .padding(.horizontal, 20)
                .disabled(isRequestingLocation)
                
                if userPrefs.latitude != nil && userPrefs.longitude != nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Location captured")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}


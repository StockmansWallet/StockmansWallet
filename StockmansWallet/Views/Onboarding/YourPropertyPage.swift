//
//  YourPropertyPage.swift
//  StockmansWallet
//
//  Page 4: Your Property
//  Debug: Uses @Observable pattern for LocationManager
//

import SwiftUI
import CoreLocation

struct YourPropertyPage: View {
    @Binding var userPrefs: UserPreferences
    @Binding var currentPage: Int
    
    // Debug: Use @State with @Observable instead of @StateObject
    @State private var locationManager = LocationManager()
    @State private var isRequestingLocation = false
    
    // Debug: Validation - property name and state are required
    private var isValid: Bool {
        !(userPrefs.propertyName ?? "").isEmpty && !userPrefs.defaultState.isEmpty
    }
    
    var body: some View {
        OnboardingPageTemplate(
            title: "Your Property",
            subtitle: "Tell us about your property",
            currentPage: $currentPage,
            nextPage: 3,
            isValid: isValid,
            totalPages: 6 // Debug: Farmer path has 6 pages (includes Subscription)
        ) {
            // Debug: Organized layout following HIG - clear sections with logical grouping
            VStack(spacing: 24) {
                // Property Information Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Property Information")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        TextField("Property Name", text: Binding(
                            get: { userPrefs.propertyName ?? "" },
                            set: { userPrefs.propertyName = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .autocapitalization(.words)
                        .accessibilityLabel("Property name")
                        
                        TextField("Property Identification Code (PIC)", text: Binding(
                            get: { userPrefs.propertyPIC ?? "" },
                            set: { userPrefs.propertyPIC = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .autocapitalization(.none)
                        .accessibilityLabel("Property Identification Code")
                        .accessibilityHint("Optional")
                    }
                    .padding(.horizontal, 20)
                }
                
                // Location Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        // State Selection Menu
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
                                Text(userPrefs.defaultState.isEmpty ? "Select State" : userPrefs.defaultState)
                                    .font(Theme.body)
                                    .foregroundStyle(userPrefs.defaultState.isEmpty ? Theme.secondaryText : Theme.primaryText)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(Theme.secondaryText)
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(Theme.RowButtonStyle())
                        .accessibilityLabel("Select state")
                        .accessibilityValue(userPrefs.defaultState)
                        
                        // GPS Location Button
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
                            HStack {
                                if isRequestingLocation {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                                } else {
                                    Image(systemName: "location.fill")
                                }
                                Text(isRequestingLocation ? "Getting Location..." : "Use Current GPS Location")
                                    .font(Theme.body)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(Theme.SecondaryButtonStyle())
                        .disabled(isRequestingLocation)
                        .accessibilityLabel("Use current GPS location")
                        
                        // Debug: Show success indicator when location is captured
                        if userPrefs.latitude != nil && userPrefs.longitude != nil {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Location successful")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Location successful")
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 8)
        }
    }
}


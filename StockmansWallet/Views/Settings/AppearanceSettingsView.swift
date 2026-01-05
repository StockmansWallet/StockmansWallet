//
//  AppearanceSettingsView.swift
//  StockmansWallet
//
//  Appearance and Display Settings
//  Debug: Includes background image selection, text size, and accessibility options
//

import SwiftUI

struct AppearanceSettingsView: View {
    @State private var useSystemAppearance = true
    @State private var selectedAppearance = 0 // 0: Light, 1: Dark
    @State private var contentSizeCategory = ContentSizeCategory.large
    @State private var reduceMotion = UIAccessibility.isReduceMotionEnabled
    @State private var reduceTransparency = UIAccessibility.isReduceTransparencyEnabled

    var body: some View {
        List {
            // Debug: Background image selection section
            Section("Background") {
                NavigationLink(destination: BackgroundImageSelectorView()) {
                    SettingsListRow(
                        icon: "photo.fill",
                        title: "Dashboard Background",
                        subtitle: "Customize your dashboard image"
                    )
                }
            }
            .listRowBackground(Theme.cardBackground)
            
            Section("Appearance") {
                Toggle("Match System", isOn: $useSystemAppearance)
                if !useSystemAppearance {
                    Picker("Appearance", selection: $selectedAppearance) {
                        Text("Light").tag(0)
                        Text("Dark").tag(1)
                    }
                }
            }
            .listRowBackground(Theme.cardBackground)

            Section("Text") {
                Picker("Text Size", selection: $contentSizeCategory) {
                    ForEach(ContentSizeCategory.allCases, id: \.self) { size in
                        Text(label(for: size)).tag(size)
                    }
                }
            }
            .listRowBackground(Theme.cardBackground)

            Section("Accessibility") {
                HStack {
                    Text("Reduce Motion")
                    Spacer()
                    Text(reduceMotion ? "On" : "Off")
                        .foregroundStyle(Theme.secondaryText)
                }
                HStack {
                    Text("Reduce Transparency")
                    Spacer()
                    Text(reduceTransparency ? "On" : "Off")
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func label(for size: ContentSizeCategory) -> String {
        switch size {
        case .extraSmall: return "XS"
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L (Default)"
        case .extraLarge: return "XL"
        case .extraExtraLarge: return "XXL"
        case .extraExtraExtraLarge: return "XXXL"
        case .accessibilityMedium: return "Accessibility M"
        case .accessibilityLarge: return "Accessibility L"
        case .accessibilityExtraLarge: return "Accessibility XL"
        case .accessibilityExtraExtraLarge: return "Accessibility XXL"
        case .accessibilityExtraExtraExtraLarge: return "Accessibility XXXL"
        @unknown default: return "Unknown"
        }
    }
}

// ContentSizeCategory already conforms to CaseIterable in SwiftUI, no extension needed




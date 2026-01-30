import SwiftUI

struct SettingsListRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var isCustomIcon: Bool = false // Debug: Flag to use custom asset icon instead of SF Symbol

    var body: some View {
        HStack(spacing: 12) {
            // Debug: Support both system icons and custom asset icons
            if isCustomIcon {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Theme.accentColor)
                    .frame(width: 24)
            } else {
                Image(systemName: icon)
                    .foregroundStyle(Theme.accentColor)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityText))
    }
    
    private var accessibilityText: String {
        if let subtitle, !subtitle.isEmpty {
            return "\(title), \(subtitle)"
        }
        return title
    }
}

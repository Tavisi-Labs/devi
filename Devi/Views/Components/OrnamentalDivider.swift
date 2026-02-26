// MARK: - Views/Components/OrnamentalDivider.swift
// Decorative section divider with ornamental accents

import SwiftUI

struct OrnamentalDivider: View {
    let label: String?
    let theme: DeviTheme

    init(_ label: String? = nil, theme: DeviTheme) {
        self.label = label
        self.theme = theme
    }

    var body: some View {
        HStack(spacing: 8) {
            line

            if let label {
                Text("\u{2726}")
                    .font(.system(size: 12))
                    .foregroundColor(theme.accentColor.opacity(0.8))

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text("\u{2726}")
                    .font(.system(size: 12))
                    .foregroundColor(theme.accentColor.opacity(0.8))
            } else {
                Text("\u{25C6}")
                    .font(.system(size: 12))
                    .foregroundColor(theme.accentColor.opacity(0.8))
            }

            line
        }
        .padding(.horizontal)
    }

    private var line: some View {
        Rectangle()
            .fill(theme.primaryText.opacity(0.25))
            .frame(height: 1.0)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "0B1026").ignoresSafeArea()

        VStack(spacing: 40) {
            OrnamentalDivider("TODAY", theme: DeviTheme.forPeriod(.brahmaMuhurta))
            OrnamentalDivider(theme: DeviTheme.forPeriod(.brahmaMuhurta))
            OrnamentalDivider("UPCOMING", theme: DeviTheme.forPeriod(.evening))
        }
    }
}

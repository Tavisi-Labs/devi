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
                    .font(.system(size: 8))
                    .foregroundColor(theme.accentColor.opacity(0.6))

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text("\u{2726}")
                    .font(.system(size: 8))
                    .foregroundColor(theme.accentColor.opacity(0.6))
            } else {
                Text("\u{25C6}")
                    .font(.system(size: 6))
                    .foregroundColor(theme.accentColor.opacity(0.6))
            }

            line
        }
        .padding(.horizontal)
    }

    private var line: some View {
        Rectangle()
            .fill(theme.primaryText.opacity(0.15))
            .frame(height: 0.5)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "1a0a2e").ignoresSafeArea()

        VStack(spacing: 40) {
            OrnamentalDivider("TODAY", theme: DeviTheme.forPeriod(.brahmaMuhurta))
            OrnamentalDivider(theme: DeviTheme.forPeriod(.brahmaMuhurta))
            OrnamentalDivider("UPCOMING", theme: DeviTheme.forPeriod(.evening))
        }
    }
}

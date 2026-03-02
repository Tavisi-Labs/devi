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
        HStack(spacing: 10) {
            line

            if let label {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                    .textCase(.uppercase)
                    .tracking(2.0)
            }

            line
        }
        .padding(.horizontal)
    }

    private var line: some View {
        Rectangle()
            .fill(theme.primaryText.opacity(0.10))
            .frame(height: 0.5)
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

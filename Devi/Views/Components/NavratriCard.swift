// MARK: - Views/Components/NavratriCard.swift
// Special card shown during Navratri periods

import SwiftUI

struct NavratriCard: View {
    let day: NavratriDay
    let theme: DeviTheme

    private var dayColor: Color {
        Color(hex: day.colorHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: day indicator
            HStack {
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundColor(dayColor)

                Text("NAVRATRI DAY \(day.dayNumber)")
                    .scaledFont(size: 13, weight: .bold)
                    .foregroundColor(dayColor)
                    .tracking(2)

                Spacer()

                ShareLink(item: ShareTextBuilder.navratriDay(day)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(dayColor)
                }

                // Day dots (9 dots, filled up to current day)
                HStack(spacing: 4) {
                    ForEach(1...9, id: \.self) { num in
                        Circle()
                            .fill(num <= day.dayNumber ? dayColor : theme.primaryText.opacity(0.2))
                            .frame(width: 5, height: 5)
                    }
                }
            }

            // Goddess name (bumped to 30pt serif)
            VStack(alignment: .leading, spacing: 4) {
                Text(day.goddessName)
                    .scaledFont(size: 30, weight: .semibold, design: .serif)
                    .foregroundColor(theme.primaryText)

                Text(day.goddessEpithet)
                    .scaledFont(size: 15)
                    .foregroundColor(theme.secondaryText)
            }

            // Color and offering
            HStack(spacing: 24) {
                // Color to wear
                HStack(spacing: 8) {
                    Circle()
                        .fill(dayColor)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(theme.primaryText.opacity(0.3), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text("WEAR")
                            .scaledFont(size: 10, weight: .medium)
                            .foregroundColor(theme.secondaryText)
                            .tracking(1)
                        Text(day.colorName)
                            .scaledFont(size: 14, weight: .medium)
                            .foregroundColor(theme.primaryText)
                    }
                }

                // Offering
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                        .foregroundColor(dayColor.opacity(0.7))

                    VStack(alignment: .leading, spacing: 1) {
                        Text("OFFERING")
                            .scaledFont(size: 10, weight: .medium)
                            .foregroundColor(theme.secondaryText)
                            .tracking(1)
                        Text(day.offering)
                            .scaledFont(size: 14, weight: .medium)
                            .foregroundColor(theme.primaryText)
                    }
                }
            }

            // Mantra (wrapped in flat inner card)
            VStack(alignment: .leading, spacing: 6) {
                Text(day.mantra)
                    .scaledFont(size: 17)
                    .foregroundColor(theme.primaryText.opacity(0.9))
                    .lineSpacing(4)

                Text(day.mantraTranslit)
                    .scaledFont(size: 13, design: .serif)
                    .foregroundColor(theme.secondaryText)
                    .italic()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
        }
        .padding(20)
        .background(
            ZStack {
                // Corner accent glow
                RadialGradient(
                    colors: [dayColor.opacity(0.08), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 200
                )
            }
        )
        .deviCard(theme: theme, elevation: .prominent, cornerRadius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(dayColor.opacity(0.2), lineWidth: 1)
        )
        .deviEntrance()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "0F1B33").ignoresSafeArea()

        NavratriCard(
            day: NavratriDay.chaitraNavratri2026[4], // Day 5 - Skandamata
            theme: DeviTheme.forPeriod(.evening)
        )
        .padding()
    }
}

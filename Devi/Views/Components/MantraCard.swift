// MARK: - Views/Components/MantraCard.swift
// Object-first Home teaser for the Living Mandala ritual.

import SwiftUI

struct MantraCard: View {
    let mantra: DailyMantra
    let snapshot: MantraRitualSnapshot
    let theme: DeviTheme
    let motionGate: RitualMotionGate
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("MANTRA")
                            .deviLabel(.caption, theme: theme)

                        Text(snapshot.continuityText)
                            .scaledFont(size: 13, weight: .medium, design: .serif)
                            .foregroundColor(theme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryText.opacity(0.42))
                }

                LivingMandalaView(
                    snapshot: snapshot,
                    theme: theme,
                    diameter: 170,
                    motionGate: motionGate,
                    emphasis: .teaser
                )

                Text(mantra.devanagari)
                    .scaledFont(size: 24, design: .serif)
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                HStack(spacing: 10) {
                    Text("Tap to enter ritual")
                        .scaledFont(size: 12, weight: .medium)
                        .foregroundColor(theme.secondaryText)

                    Spacer()

                    if let dayLabel = snapshot.dayLabel {
                        Text(dayLabel)
                            .scaledFont(size: 12, weight: .semibold)
                            .foregroundColor(theme.accentColor.opacity(0.86))
                    }
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    theme.accentColor.opacity(0.05)
                    RadialGradient(
                        colors: [theme.accentColor.opacity(0.09), .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: 220
                    )
                }
            )
            .deviCard(theme: theme, elevation: .prominent)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(snapshot.accessibilitySummary)
            .accessibilityHint("Opens the full ritual view.")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.mantraCard")
    }
}

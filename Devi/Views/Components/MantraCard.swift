// MARK: - Views/Components/MantraCard.swift
// Prominent card displaying the daily weekday mantra — spiritual morning anchor

import SwiftUI

struct MantraCard: View {
    let mantra: DailyMantra
    let theme: DeviTheme
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 14) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MANTRA")
                            .deviLabel(.caption, theme: theme)
                        Text("for \(mantra.deity)")
                            .font(.system(size: 13, weight: .regular, design: .serif))
                            .foregroundColor(theme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryText.opacity(0.4))
                }

                // Devanagari mantra
                Text(mantra.devanagari)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                // Transliteration
                Text(mantra.transliteration)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(theme.secondaryText)
                    .italic()

                // Meaning in flat inner card
                Text(mantra.meaning)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(theme.secondaryText.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)

                // Repetition hint
                HStack(spacing: 4) {
                    Image(systemName: "repeat")
                        .font(.system(size: 10))
                        .foregroundColor(theme.accentColor.opacity(0.7))
                    Text("Chant \(mantra.repetitions) times · \(mantra.bestTimeToChant)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryText.opacity(0.6))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    theme.accentColor.opacity(0.06)
                    RadialGradient(
                        colors: [theme.accentColor.opacity(0.08), .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: 200
                    )
                }
            )
            .deviCard(theme: theme, elevation: .prominent)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

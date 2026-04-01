// MARK: - Views/Components/MantraCard.swift
// Prominent card displaying the daily weekday mantra — spiritual morning anchor

import SwiftUI

struct MantraCard: View {
    let mantra: DailyMantra
    let theme: DeviTheme
    var onTap: (() -> Void)? = nil

    @State private var glowPhase: Bool = false

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
                            .scaledFont(size: 13, design: .serif)
                            .foregroundColor(theme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryText.opacity(0.4))
                }

                // Devanagari mantra with breathing glow
                ZStack {
                    // Breathing gold glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.accentColor.opacity(glowPhase ? 0.12 : 0.04),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 80)

                    Text(mantra.devanagari)
                        .scaledFont(size: 26)
                        .foregroundColor(theme.primaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)

                // Ornamental divider: ─── ॐ ───
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(theme.accentColor.opacity(0.3))
                        .frame(width: 20, height: 0.5)
                    Text("ॐ")
                        .scaledFont(size: 11)
                        .foregroundColor(theme.accentColor.opacity(0.5))
                    Rectangle()
                        .fill(theme.accentColor.opacity(0.3))
                        .frame(width: 20, height: 0.5)
                }

                // Transliteration
                Text(mantra.transliteration)
                    .scaledFont(size: 15, design: .serif)
                    .foregroundColor(theme.secondaryText)
                    .italic()
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
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
        }
    }
}

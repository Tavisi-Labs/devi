// MARK: - Views/Components/HoroscopeWhySheet.swift
// Transparency sheet showing why today's horoscope reading was generated

import SwiftUI

struct HoroscopeWhySheet: View {
    let transitContext: TransitContext
    let theme: DeviTheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: — Header
                    Text("Why this reading?")
                        .scaledFont(size: 28, weight: .regular, design: .serif)
                        .foregroundColor(theme.primaryText)
                        .padding(.top, 8)

                    Text("Today's reading is based on the current positions of the planets relative to your birth Moon.")
                        .deviLabel(.detail, theme: theme)
                        .lineSpacing(4)

                    // MARK: — Moon Transit Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(theme.accentColor)
                            Text("MOON TRANSIT")
                                .deviLabel(.section, theme: theme)
                        }

                        // Moon house rule
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(theme.accentColor)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 7)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Moon is in your \(ordinalString(transitContext.moonHouse)) house (\(transitContext.moonHouseVedicName)) from \(transitContext.birthRashi.sanskritName) (\(transitContext.birthRashi.westernName))")
                                        .deviLabel(.body, theme: theme)
                                        .lineSpacing(3)

                                    if let houseTheme = TransitContext.houseThemes[transitContext.moonHouse] {
                                        Text(houseTheme)
                                            .deviLabel(.insight, theme: theme)
                                    }
                                }
                            }

                            // Current nakshatra
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(theme.accentColor)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 7)

                                Text("Moon is in \(transitContext.moonNakshatra) nakshatra")
                                    .deviLabel(.body, theme: theme)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .deviCard(theme: theme, elevation: .raised)

                    // MARK: — Significant Aspects Card
                    if !transitContext.significantAspects.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.accentColor)
                                Text("ACTIVE TRANSITS")
                                    .deviLabel(.section, theme: theme)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(transitContext.significantAspects, id: \.self) { aspect in
                                    HStack(alignment: .top, spacing: 10) {
                                        Circle()
                                            .fill(theme.secondaryText.opacity(0.5))
                                            .frame(width: 5, height: 5)
                                            .padding(.top, 7)

                                        Text(aspect)
                                            .deviLabel(.body, theme: theme)
                                            .lineSpacing(3)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .deviCard(theme: theme, elevation: .raised)
                    }

                    // MARK: — Birth Time Disclaimer
                    if !transitContext.birthTimeKnown {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(theme.cautionColor)
                                .padding(.top, 2)

                            Text("Your birth time is unknown. Moon defaults to noon. For more accurate readings, add your birth time in Settings.")
                                .scaledFont(size: 14, weight: .medium)
                                .foregroundColor(theme.cautionColor)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(theme.cautionColor.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(theme.cautionColor.opacity(0.25), lineWidth: 0.5)
                        )
                    }

                    // MARK: — Birth Rashi Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR BIRTH MOON")
                            .deviLabel(.section, theme: theme)

                        HStack(spacing: 12) {
                            Text(transitContext.birthRashi.symbol)
                                .font(.system(size: 32))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(transitContext.birthRashi.sanskritName)
                                    .scaledFont(size: 18, weight: .medium, design: .serif)
                                    .foregroundColor(theme.primaryText)

                                Text("\(transitContext.birthRashi.westernName) \u{2022} Ruled by \(transitContext.birthRashi.rulingPlanet)")
                                    .deviLabel(.detail, theme: theme)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .deviCard(theme: theme, elevation: .flat)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.accentColor)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Returns an ordinal string for a house number (1st, 2nd, 3rd, ..., 12th).
    private func ordinalString(_ n: Int) -> String {
        switch n {
        case 1:  return "1st"
        case 2:  return "2nd"
        case 3:  return "3rd"
        default: return "\(n)th"
        }
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            HoroscopeWhySheet(
                transitContext: TransitContext(
                    moonHouse: 7,
                    moonHouseVedicName: "Kalatra",
                    moonNakshatra: "Rohini",
                    significantAspects: [
                        "Jupiter transits your 7th house",
                        "Saturn aspects your natal Moon",
                        "Venus conjunct Mercury in 5th house"
                    ],
                    birthRashi: .vrishabha,
                    birthTimeKnown: false
                ),
                theme: DeviTheme.forPeriod(.evening)
            )
        }
}

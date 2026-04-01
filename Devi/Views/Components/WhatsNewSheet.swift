// MARK: - Views/Components/WhatsNewSheet.swift
// "What's New" feature list — shown from Settings

import SwiftUI

struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let theme = DeviTheme.forPeriod(.brahmaMuhurta)

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.9.0"

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Version header
                        VStack(spacing: 8) {
                            Text("Devi")
                                .font(.system(size: 32, weight: .light, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "D4A857"), Color(hex: "C9A96E")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            HStack(spacing: 8) {
                                Text("v\(appVersion)")
                                    .scaledFont(size: 14, weight: .medium)
                                    .foregroundColor(theme.secondaryText)

                                Text("EARLY ACCESS")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(theme.accentColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().stroke(theme.accentColor.opacity(0.4), lineWidth: 0.5))
                            }
                        }
                        .padding(.top, 8)

                        // Feature rows
                        VStack(spacing: 10) {
                            featureRow(
                                icon: "function",
                                title: "Live Vedic Calculations",
                                description: "Tithi, nakshatra, yoga, and karana computed in real-time using the Swiss Ephemeris with Lahiri ayanamsa."
                            )
                            featureRow(
                                icon: "circle.grid.3x3",
                                title: "Navagraha Positions",
                                description: "All nine Vedic planets with sidereal longitudes, rashi, and nakshatra placement."
                            )
                            featureRow(
                                icon: "sparkles",
                                title: "Immersive Experiences",
                                description: "Full-screen views for tithi, nakshatra, hora, eclipse, and Navratri — with rich mythology and mantra."
                            )
                            featureRow(
                                icon: "calendar.badge.plus",
                                title: "Festival Calendar",
                                description: "Major Hindu festivals, regional celebrations, fasting days, and monthly observances for 60 days ahead."
                            )
                            featureRow(
                                icon: "gyroscope",
                                title: "Vedic Sky View",
                                description: "Gyroscope-driven ecliptic strip showing planet positions along the zodiac in real time."
                            )
                            featureRow(
                                icon: "circle.lefthalf.filled",
                                title: "Light & Dark Mode",
                                description: "Automatic appearance switching based on time of day, or lock to your preference."
                            )
                            featureRow(
                                icon: "bell.badge",
                                title: "Smart Notifications",
                                description: "Daily summary, sunrise, sunset, Rahu Kalam warnings, and festival alerts — all configurable."
                            )
                            featureRow(
                                icon: "paintpalette",
                                title: "Five Theme Palettes",
                                description: "Classic, Vivid Temple, Sunrise Garden, Cosmic Jewel, and Golden Dawn — each with unique color stories."
                            )
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("What's New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "d4a857"))
                }
            }
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(theme.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .scaledFont(size: 15, weight: .semibold)
                    .foregroundColor(theme.primaryText)
                Text(description)
                    .scaledFont(size: 13)
                    .foregroundColor(theme.secondaryText)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised)
    }
}

#Preview {
    WhatsNewSheet()
}

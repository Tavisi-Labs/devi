// MARK: - Views/Components/NavratriImmersiveView.swift
// Full-screen goddess darshan — immersive Navratri experience

import SwiftUI

struct NavratriImmersiveView: View {
    let day: NavratriDay
    let theme: DeviTheme
    let timezoneIdentifier: String

    @Environment(\.dismiss) private var dismiss
    @State private var appeared: Bool = false
    @State private var dotsRevealed: Int = 0
    @State private var glowPhase: Bool = false

    private var dayColor: Color {
        Color(hex: day.colorHex)
    }

    var body: some View {
        ZStack {
            // Color-tinted atmosphere
            theme.backgroundGradient.ignoresSafeArea()

            // Day-color corner radial glow
            RadialGradient(
                colors: [dayColor.opacity(0.12), dayColor.opacity(0.03), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            StarFieldView(isDaytime: false, timePeriod: .evening)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    topBar.padding(.top, 8)

                    // 9-day journey dots
                    journeyDots
                        .padding(.top, 8)

                    // Giant color swatch
                    colorSwatch
                        .scaleEffect(appeared ? 1 : 0.3)
                        .opacity(appeared ? 1 : 0)

                    // Goddess name
                    VStack(spacing: 6) {
                        Text(day.goddessName)
                            .font(.system(size: 34, weight: .semibold, design: .serif))
                            .foregroundColor(theme.primaryText)
                            .tracking(1)

                        Text(day.goddessEpithet)
                            .deviLabel(.insight, theme: theme)

                        Text("Day \(day.dayNumber) of Navratri")
                            .deviLabel(.caption, theme: theme)
                    }
                    .deviReveal(delay: 0.2, direction: .fadeUp)

                    // Color and Offering cards
                    HStack(spacing: 12) {
                        // Color card
                        VStack(spacing: 8) {
                            Circle()
                                .fill(dayColor)
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(theme.primaryText.opacity(0.3), lineWidth: 1))

                            VStack(spacing: 2) {
                                Text("WEAR")
                                    .deviLabel(.caption, theme: theme)
                                Text(day.colorName)
                                    .scaledFont(size: 15, weight: .medium)
                                    .foregroundColor(theme.primaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)

                        // Offering card
                        VStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 22))
                                .foregroundColor(dayColor.opacity(0.7))

                            VStack(spacing: 2) {
                                Text("OFFERING")
                                    .deviLabel(.caption, theme: theme)
                                Text(day.offering)
                                    .scaledFont(size: 15, weight: .medium)
                                    .foregroundColor(theme.primaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
                    }
                    .deviReveal(delay: 0.25, direction: .fadeUp)

                    // Mantra card (prominent)
                    mantraCard
                        .deviReveal(delay: 0.3, direction: .scale)

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SIGNIFICANCE")
                            .deviLabel(.caption, theme: theme)

                        Text("Day \(day.dayNumber) of Navratri is dedicated to Goddess \(day.goddessName) \u{2014} \(day.goddessEpithet). Wear \(day.colorName) and offer \(day.offering) to receive her blessings.")
                            .deviLabel(.body, theme: theme)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
                    .deviReveal(delay: 0.35, direction: .fadeUp)

                    // Observances
                    observancesCard
                        .deviReveal(delay: 0.4, direction: .fadeUp)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
            // Cascade dot reveals
            for i in 1...day.dayNumber {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dotsRevealed = i
                    }
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            Spacer()
            ShareLink(item: ShareTextBuilder.panchangElement(
                .navratriDay(day),
                timezoneIdentifier: timezoneIdentifier
            )) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                    Text("Share")
                        .scaledFont(size: 13, weight: .medium)
                }
                .foregroundColor(theme.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Journey Dots

    private var journeyDots: some View {
        HStack(spacing: 10) {
            ForEach(1...9, id: \.self) { num in
                Circle()
                    .fill(num <= dotsRevealed ? dayColor : theme.primaryText.opacity(0.15))
                    .frame(width: num == day.dayNumber ? 14 : 8,
                           height: num == day.dayNumber ? 14 : 8)
                    .overlay {
                        if num == day.dayNumber {
                            Circle()
                                .stroke(dayColor.opacity(glowPhase ? 0.6 : 0.2), lineWidth: 2)
                                .frame(width: 20, height: 20)
                        }
                    }
            }
        }
    }

    // MARK: - Color Swatch

    private var colorSwatch: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [dayColor.opacity(glowPhase ? 0.25 : 0.1), .clear],
                        center: .center, startRadius: 20, endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)

            Circle()
                .fill(dayColor)
                .frame(width: 60, height: 60)
                .overlay(Circle().stroke(theme.primaryText.opacity(0.15), lineWidth: 1))
                .shadow(color: dayColor.opacity(0.3), radius: 8, y: 2)
        }
    }

    // MARK: - Mantra Card

    private var mantraCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 12))
                    .foregroundColor(dayColor)
                Text("Mantra for \(day.goddessName)")
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.primaryText)
            }

            VStack(alignment: .center, spacing: 8) {
                Text(day.mantra)
                    .scaledFont(size: 20, weight: .regular)
                    .foregroundColor(theme.primaryText.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(day.mantraTranslit)
                    .scaledFont(size: 14, weight: .regular, design: .serif)
                    .foregroundColor(theme.secondaryText)
                    .italic()
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .deviCard(theme: theme, elevation: .flat, cornerRadius: 14)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RadialGradient(
                colors: [dayColor.opacity(0.06), .clear],
                center: .topLeading, startRadius: 0, endRadius: 200
            )
        )
        .deviCard(theme: theme, elevation: .prominent, cornerRadius: 18)
    }

    // MARK: - Observances

    private var observancesCard: some View {
        let items = [
            "Worship Goddess \(day.goddessName)",
            "Wear \(day.colorName) clothing",
            "Offer \(day.offering) to the Goddess",
            "Chant the daily Navratri mantra",
            "Observe the Navratri fast (phalahar)"
        ]

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.auspiciousColor)
                Text("Observances")
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.primaryText)
            }

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\u{2022}").foregroundColor(theme.secondaryText)
                    Text(item).deviLabel(.detail, theme: theme)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
    }
}

// MARK: - Views/Components/EclipseCard.swift
// Hero card shown when an eclipse is imminent (within 7 days) or occurring today

import SwiftUI

struct EclipseCard: View {
    let eclipse: EclipseEvent
    let todayDateString: String
    let theme: DeviTheme
    let timezoneIdentifier: String
    let cityName: String
    var onTap: (() -> Void)? = nil

    // Cool lunar blue-silver palette — eclipses are shadow events
    private let eclipseBlue = Color(hex: "7B8EC4")
    private let eclipseSilver = Color(hex: "A8B4D4")
    private let eclipseDark = Color(hex: "3A4570")

    private var daysAway: Int {
        eclipse.daysFrom(todayDateString)
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Header: GRAHAN label + proximity badge
                headerRow

                // Sanskrit name + eclipse type
                nameSection

                // Contact times timeline
                contactTimesSection

                // Magnitude + moon visibility
                detailsRow

                // Mythology note in flat inner card
                if let note = eclipse.mythologyNote {
                    mythologyCard(note)
                }
            }
            .padding(20)
            .background(
                ZStack {
                    // Corner accent glow — cool blue for shadow events
                    RadialGradient(
                        colors: [eclipseBlue.opacity(0.10), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 200
                    )
                }
            )
            .deviCard(theme: theme, elevation: .prominent, cornerRadius: 18)
        }
        .buttonStyle(.plain)
        .deviEntrance()
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: eclipse.body == .lunar ? "moon.circle" : "sun.dust")
                    .font(.system(size: 14))
                    .foregroundColor(eclipseBlue)

                Text("GRAHAN")
                    .scaledFont(size: 13, weight: .bold)
                    .foregroundColor(eclipseBlue)
                    .tracking(2)
            }

            Spacer()

            ShareLink(item: ShareTextBuilder.eclipseAlert(
                eclipse: eclipse,
                cityName: cityName,
                timezoneIdentifier: timezoneIdentifier
            )) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(eclipseBlue)
            }

            // Proximity badge
            Text(eclipse.proximityLabel(from: todayDateString))
                .scaledFont(size: 11, weight: .bold)
                .foregroundColor(daysAway == 0 ? .white : eclipseBlue)
                .tracking(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(daysAway == 0
                              ? eclipseBlue
                              : eclipseBlue.opacity(0.15))
                )
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Devanagari
            Text(eclipse.body.devanagari)
                .scaledFont(size: 15)
                .foregroundColor(eclipseSilver.opacity(0.8))

            // Sanskrit name
            Text(eclipse.body.sanskritName)
                .scaledFont(size: 30, weight: .semibold, design: .serif)
                .foregroundColor(theme.primaryText)

            // Eclipse type subtitle
            Text(eclipse.displayName)
                .scaledFont(size: 15)
                .foregroundColor(theme.secondaryText)
        }
    }

    // MARK: - Contact Times

    private var contactTimesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CONTACT TIMES")
                .scaledFont(size: 10, weight: .medium)
                .foregroundColor(theme.secondaryText)
                .tracking(1)

            VStack(spacing: 6) {
                ForEach(eclipse.contactTimeline, id: \.label) { contact in
                    HStack {
                        // Timeline dot + line
                        Circle()
                            .fill(contact.label == "Maximum" ? eclipseBlue : eclipseSilver.opacity(0.4))
                            .frame(width: contact.label == "Maximum" ? 8 : 5,
                                   height: contact.label == "Maximum" ? 8 : 5)

                        Text(contact.label)
                            .scaledFont(size: 13, weight: contact.label == "Maximum" ? .semibold : .regular)
                            .foregroundColor(contact.label == "Maximum" ? theme.primaryText : theme.secondaryText)

                        Spacer()

                        Text(deviFormatTime(contact.time, timezoneIdentifier: timezoneIdentifier))
                            .scaledFont(size: 13, weight: .medium, design: .monospaced)
                            .foregroundColor(theme.primaryText)
                    }
                }
            }
            .padding(12)
            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
        }
    }

    // MARK: - Details Row

    private var detailsRow: some View {
        HStack(spacing: 24) {
            // Magnitude
            HStack(spacing: 8) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 12))
                    .foregroundColor(eclipseSilver.opacity(0.7))

                VStack(alignment: .leading, spacing: 1) {
                    Text("MAGNITUDE")
                        .scaledFont(size: 10, weight: .medium)
                        .foregroundColor(theme.secondaryText)
                        .tracking(1)
                    Text(String(format: "%.3f", eclipse.magnitude))
                        .scaledFont(size: 14, weight: .medium)
                        .foregroundColor(theme.primaryText)
                }
            }

            // Moon visibility warning
            if eclipse.moonBelowHorizon {
                HStack(spacing: 8) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 12))
                        .foregroundColor(theme.cautionColor)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("VISIBILITY")
                            .scaledFont(size: 10, weight: .medium)
                            .foregroundColor(theme.secondaryText)
                            .tracking(1)
                        Text("Below Horizon")
                            .scaledFont(size: 14, weight: .medium)
                            .foregroundColor(theme.cautionColor)
                    }
                }
            }
        }
    }

    // MARK: - Mythology Card

    private func mythologyCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note)
                .scaledFont(size: 13, design: .serif)
                .foregroundColor(theme.secondaryText)
                .lineSpacing(4)
                .italic()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "0F1B33").ignoresSafeArea()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let maximum = calendar.date(bySettingHour: 5, minute: 34, second: 0, of: today)!

        EclipseCard(
            eclipse: EclipseEvent(
                body: .lunar,
                type: .total,
                dateString: "2026-03-03",
                maxEclipseTime: maximum,
                magnitude: 1.151,
                lunarContactTimes: LunarEclipseContactTimes(
                    penumbralBegin: calendar.date(bySettingHour: 3, minute: 30, second: 0, of: today),
                    partialBegin: calendar.date(bySettingHour: 4, minute: 32, second: 0, of: today),
                    totalBegin: calendar.date(bySettingHour: 5, minute: 4, second: 0, of: today),
                    maximum: maximum,
                    totalEnd: calendar.date(bySettingHour: 6, minute: 4, second: 0, of: today),
                    partialEnd: calendar.date(bySettingHour: 7, minute: 17, second: 0, of: today),
                    penumbralEnd: calendar.date(bySettingHour: 8, minute: 17, second: 0, of: today)
                ),
                solarContactTimes: nil,
                moonBelowHorizon: true,
                mythologyNote: "Rahu swallows Chandra — the shadow of the Earth envelops the Moon, turning it a deep blood red."
            ),
            todayDateString: "2026-02-27",
            theme: DeviTheme.forPeriod(.evening),
            timezoneIdentifier: "America/New_York",
            cityName: "New York"
        )
        .padding()
    }
}

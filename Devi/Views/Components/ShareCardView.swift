// MARK: - Views/Components/ShareCardView.swift
// Static SwiftUI view designed for image rendering (no animations, no interactivity).
// Fixed 1080x1920 (9:16 story format) for Instagram/WhatsApp sharing.

import SwiftUI

struct ShareCardView: View {
    let panchang: DailyPanchang
    let city: UserCity
    let navratriDay: NavratriDay?
    let theme: DeviTheme

    var body: some View {
        ZStack {
            // Background gradient
            theme.backgroundGradient

            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                // App name
                Text("DEVI")
                    .font(.system(size: 48, weight: .light, design: .serif))
                    .foregroundColor(theme.primaryText)
                    .tracking(12)

                Spacer().frame(height: 12)

                // Decorative divider
                HStack(spacing: 8) {
                    Rectangle().fill(Color(hex: "d4a857").opacity(0.4)).frame(width: 60, height: 1)
                    Image(systemName: "sparkle")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "d4a857").opacity(0.6))
                    Rectangle().fill(Color(hex: "d4a857").opacity(0.4)).frame(width: 60, height: 1)
                }

                Spacer().frame(height: 40)

                // Date + City
                Text(formattedGregorianDate)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(theme.primaryText)

                Spacer().frame(height: 6)

                Text("\(panchang.lunarMonth) \u{00B7} \(panchang.tithi.paksha.rawValue) Paksha \u{00B7} \(city.name)")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(theme.secondaryText)

                Spacer().frame(height: 60)

                // Tithi (hero)
                Text(panchang.tithi.name.uppercased())
                    .font(.system(size: 56, weight: .regular, design: .serif))
                    .foregroundColor(theme.primaryText)
                    .tracking(3)

                Spacer().frame(height: 8)

                Text("\(panchang.tithi.paksha.rawValue) \(panchang.tithi.name)")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundColor(theme.secondaryText)

                Spacer().frame(height: 50)

                // Nakshatra
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "d4a857"))
                    Text(panchang.nakshatra.name)
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundColor(theme.primaryText)
                }

                Text("Ruler: \(panchang.nakshatra.ruler) \u{00B7} Deity: \(panchang.nakshatra.deity)")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(theme.secondaryText)
                    .padding(.top, 4)

                Spacer().frame(height: 50)

                // Sunrise / Sunset
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "f59e0b"))
                        Text("SUNRISE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.secondaryText)
                            .tracking(1)
                        Text(formatTime(panchang.solar.sunrise))
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(theme.primaryText)
                    }

                    Rectangle()
                        .fill(theme.primaryText.opacity(0.1))
                        .frame(width: 1, height: 50)

                    VStack(spacing: 4) {
                        Image(systemName: "sunset.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "ea580c"))
                        Text("SUNSET")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.secondaryText)
                            .tracking(1)
                        Text(formatTime(panchang.solar.sunset))
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(theme.primaryText)
                    }
                }

                Spacer().frame(height: 50)

                // Mantra (if available)
                if let mantra = dayMantra {
                    VStack(spacing: 8) {
                        Text(mantra.devanagari)
                            .font(.system(size: 26, weight: .regular, design: .serif))
                            .foregroundColor(Color(hex: "d4a857"))

                        Text(mantra.transliteration)
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundColor(theme.secondaryText)
                    }
                    .padding(.horizontal, 40)
                }

                // Navratri info (if active)
                if let navDay = navratriDay {
                    Spacer().frame(height: 40)

                    VStack(spacing: 6) {
                        Text("NAVRATRI DAY \(navDay.dayNumber)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.secondaryText)
                            .tracking(2)

                        Text(navDay.goddessName)
                            .font(.system(size: 28, weight: .medium, design: .serif))
                            .foregroundColor(theme.primaryText)

                        Text("\"\(navDay.goddessEpithet)\"")
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundColor(theme.secondaryText)
                            .italic()

                        HStack(spacing: 16) {
                            Label(navDay.colorName, systemImage: "paintpalette")
                            Label(navDay.offering, systemImage: "leaf")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: navDay.colorHex))
                        .padding(.top, 4)
                    }
                }

                Spacer()

                // Gold border line
                Rectangle()
                    .fill(Color(hex: "d4a857").opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 60)

                Spacer().frame(height: 20)

                // Footer watermark
                Text("deviapp.com")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(theme.secondaryText.opacity(0.5))
                    .tracking(2)

                Spacer().frame(height: 40)
            }

            // Gold border frame
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(hex: "d4a857").opacity(0.2), lineWidth: 2)
                .padding(20)
        }
        .frame(width: 1080, height: 1920)
    }

    // MARK: - Helpers

    private var formattedGregorianDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: city.timezoneIdentifier) ?? .current
        guard let date = formatter.date(from: panchang.dateString) else { return panchang.dateString }
        let display = DateFormatter()
        display.dateFormat = "EEEE, MMMM d"
        display.timeZone = TimeZone(identifier: city.timezoneIdentifier) ?? .current
        return display.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: city.timezoneIdentifier)
    }

    private var dayMantra: DailyMantra? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: city.timezoneIdentifier) ?? .current
        guard let date = formatter.date(from: panchang.dateString) else { return nil }
        let weekday = Calendar.current.component(.weekday, from: date)
        return PanchangDescriptions.dailyMantra(for: weekday)
    }
}

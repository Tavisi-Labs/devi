// MARK: - Views/Components/TodayDetailsSection.swift
// Three visually distinct groups: Vara card, Yoga+Karana duo, Moon mini-arc

import SwiftUI

struct TodayDetailsSection: View {
    let panchang: DailyPanchang
    let theme: DeviTheme
    let timezoneIdentifier: String
    var onTapYoga: (() -> Void)? = nil
    var onTapKarana: (() -> Void)? = nil
    var onTapVara: (() -> Void)? = nil

    @State private var accentBreathing = false

    var body: some View {
        VStack(spacing: 14) {
            // A. Vara Card — full-width with colored left accent
            varaCard
                .deviReveal(delay: 0.04, direction: .fadeLeft)

            // B. Yoga + Karana Side-by-Side Duo
            HStack(spacing: 10) {
                yogaCard
                    .deviReveal(delay: 0.08, direction: .fadeUp)
                karanaCard
                    .deviReveal(delay: 0.12, direction: .fadeUp)
            }

            // Moon times now integrated into CelestialHeroView
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                accentBreathing = true
            }
        }
    }

    // MARK: - A. Vara Card

    private var varaCard: some View {
        let weekdayName = currentWeekdayName()
        let accentColor = varaAccentColor(for: weekdayName)

        return Button {
            onTapVara?()
        } label: {
            HStack(spacing: 0) {
                // Colored left accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor.opacity(accentBreathing ? 0.8 : 0.5))
                    .frame(width: 3)
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("VARA")
                            .deviLabel(.caption, theme: theme)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.secondaryText.opacity(0.4))
                    }

                    HStack(spacing: 8) {
                        let vi = varaIcon(for: weekdayName)
                        Image(systemName: vi.icon)
                            .font(.system(size: 16))
                            .foregroundColor(vi.color)
                            .symbolEffect(.pulse, options: .speed(0.3), isActive: true)

                        Text(panchang.varaDeity)
                            .scaledFont(size: 16, weight: .medium, design: .serif)
                            .foregroundColor(theme.primaryText)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .deviCard(theme: theme, elevation: .raised)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - B. Yoga Card

    private var yogaCard: some View {
        let info = PanchangDescriptions.yogaInfo(forName: panchang.yoga.name)

        return Button {
            onTapYoga?()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("YOGA")
                        .deviLabel(.caption, theme: theme)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.secondaryText.opacity(0.4))
                }

                Text(panchang.yoga.name)
                    .scaledFont(size: 15, weight: .medium, design: .serif)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let info = info {
                    // Quality badge
                    Text(info.quality)
                        .scaledFont(size: 9, weight: .semibold)
                        .foregroundColor(yogaQualityColor(info.quality))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(yogaQualityColor(info.quality).opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .deviCard(theme: theme, elevation: .raised, cornerRadius: 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - B. Karana Card

    private var karanaCard: some View {
        let primaryKarana = panchang.karana
        let info = PanchangDescriptions.karanaInfo(for: primaryKarana.name)

        return Button {
            onTapKarana?()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("KARANA")
                        .deviLabel(.caption, theme: theme)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.secondaryText.opacity(0.4))
                }

                Text(karanaDisplayValue())
                    .scaledFont(size: 15, weight: .medium, design: .serif)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let info = info {
                    // Type badge (Fixed/Movable)
                    Text(info.type)
                        .scaledFont(size: 9, weight: .semibold)
                        .foregroundColor(theme.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.primaryText.opacity(0.06))
                        .clipShape(Capsule())
                }

                // Multi-karana transition indicator
                if panchang.karanas.count > 1 {
                    Text("\(panchang.karanas.count) transitions")
                        .scaledFont(size: 9)
                        .foregroundColor(theme.secondaryText.opacity(0.5))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .deviCard(theme: theme, elevation: .raised, cornerRadius: 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func varaIcon(for weekday: String) -> (icon: String, color: Color) {
        switch weekday {
        case "Sunday":    return ("sun.max.fill", Graha.sun.color)
        case "Monday":    return ("moon.fill", Graha.moon.color)
        case "Tuesday":   return ("flame.fill", Graha.mars.color)
        case "Wednesday": return ("leaf.fill", Graha.mercury.color)
        case "Thursday":  return ("crown.fill", Graha.jupiter.color)
        case "Friday":    return ("heart.fill", Graha.venus.color)
        case "Saturday":  return ("circle.hexagonpath.fill", Graha.saturn.color)
        default:          return ("circle.fill", Color(hex: "888888"))
        }
    }

    private func currentWeekdayName() -> String {
        guard let date = ISO8601DateFormatter().date(from: panchang.dateString + "T00:00:00Z") else { return "" }
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return ""
        }
    }

    private func varaAccentColor(for weekday: String) -> Color {
        switch weekday {
        case "Sunday":    return Graha.sun.color
        case "Monday":    return Graha.moon.color
        case "Tuesday":   return Graha.mars.color
        case "Wednesday": return Graha.mercury.color
        case "Thursday":  return Graha.jupiter.color
        case "Friday":    return Graha.venus.color
        case "Saturday":  return Graha.saturn.color
        default:          return Color(hex: "888888")
        }
    }

    private func yogaQualityColor(_ quality: String) -> Color {
        switch quality.lowercased() {
        case let q where q.contains("inauspicious") || q.contains("malefic") || q.contains("harmful"):
            return theme.inauspiciousColor
        case let q where q.contains("auspicious") || q.contains("benefic") || q.contains("excellent"):
            return theme.auspiciousColor
        default:
            return theme.cautionColor
        }
    }

    private func karanaDisplayValue() -> String {
        if panchang.karanas.count <= 1 {
            return panchang.karana.name
        }
        return panchang.karanas.map(\.name).joined(separator: " → ")
    }

}

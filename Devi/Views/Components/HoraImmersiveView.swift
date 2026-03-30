// MARK: - Views/Components/HoraImmersiveView.swift
// Full-screen planetary orrery — immersive hora experience

import SwiftUI

struct HoraImmersiveView: View {
    let hora: Hora
    let allHoras: [Hora]
    let theme: DeviTheme
    let timezoneIdentifier: String

    @Environment(\.dismiss) private var dismiss
    @State private var appeared: Bool = false
    @State private var glowPhase: Bool = false

    private var pColor: Color { planetColor(hora.planetName) }
    private var horaInfo: (deity: String, nature: String, quality: String, description: String, auspiciousActivities: [String], avoidActivities: [String])? {
        guard let info = PanchangDescriptions.horaInfo(for: hora.planetName) else { return nil }
        return (info.deity, info.nature, info.quality, info.description, info.auspiciousActivities, info.avoidActivities)
    }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()

            // Planet-colored atmosphere glow
            RadialGradient(
                colors: [pColor.opacity(0.06), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()

            StarFieldView(isDaytime: false, timePeriod: .night)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    topBar.padding(.top, 8)

                    // Giant planet orb
                    planetHero
                        .scaleEffect(appeared ? 1 : 0.2)
                        .opacity(appeared ? 1 : 0)

                    // Planet name
                    VStack(spacing: 6) {
                        Text(hora.planetSanskrit)
                            .font(.system(size: 28, weight: .medium, design: .serif))
                            .foregroundColor(theme.primaryText)
                            .tracking(1)

                        Text(hora.planetName)
                            .deviLabel(.insight, theme: theme)

                        if let info = horaInfo {
                            Text(info.deity)
                                .scaledFont(size: 15, weight: .regular, design: .serif)
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                    .deviReveal(delay: 0.15, direction: .fadeUp)

                    // Nature + Quality badges
                    if let info = horaInfo {
                        HStack(spacing: 12) {
                            // Nature
                            VStack(spacing: 4) {
                                Text(info.nature)
                                    .scaledFont(size: 14, weight: .semibold)
                                    .foregroundColor(qualityColor(info.nature))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(qualityColor(info.nature).opacity(0.15))
                                    .clipShape(Capsule())
                                Text("NATURE")
                                    .deviLabel(.caption, theme: theme)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .deviCard(theme: theme, elevation: .flat, cornerRadius: 14)

                            // Quality
                            VStack(spacing: 4) {
                                Text(info.quality)
                                    .scaledFont(size: 14, weight: .semibold)
                                    .foregroundColor(qualityColor(info.quality))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(qualityColor(info.quality).opacity(0.15))
                                    .clipShape(Capsule())
                                Text("QUALITY")
                                    .deviLabel(.caption, theme: theme)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .deviCard(theme: theme, elevation: .flat, cornerRadius: 14)
                        }
                        .deviReveal(delay: 0.2, direction: .fadeUp)
                    }

                    // 24-hour hora strip
                    horaStrip
                        .deviReveal(delay: 0.25, direction: .fadeUp)

                    // Timing
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("START")
                                .deviLabel(.caption, theme: theme)
                            Text(deviFormatTime(hora.startTime, timezoneIdentifier: timezoneIdentifier))
                                .deviLabel(.body, theme: theme)
                        }
                        Rectangle()
                            .fill(pColor.opacity(0.3))
                            .frame(height: 1)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("END")
                                .deviLabel(.caption, theme: theme)
                            Text(deviFormatTime(hora.endTime, timezoneIdentifier: timezoneIdentifier))
                                .deviLabel(.body, theme: theme)
                        }
                    }
                    .padding(14)
                    .deviCard(theme: theme, elevation: .flat, cornerRadius: 14)
                    .deviReveal(delay: 0.3, direction: .fadeUp)

                    // Description
                    if let info = horaInfo {
                        descriptionSection(info.description)
                            .deviReveal(delay: 0.35, direction: .fadeUp)
                    }

                    // Auspicious activities
                    if let info = horaInfo, !info.auspiciousActivities.isEmpty {
                        activitiesCard("Auspicious For", items: info.auspiciousActivities, color: theme.auspiciousColor)
                            .deviReveal(delay: 0.4, direction: .fadeUp)
                    }

                    // Avoid activities
                    if let info = horaInfo, !info.avoidActivities.isEmpty {
                        activitiesCard("Avoid", items: info.avoidActivities, color: theme.inauspiciousColor)
                            .deviReveal(delay: 0.45, direction: .fadeUp)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowPhase = true
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
                .hora(hora),
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

    // MARK: - Planet Hero

    private var planetHero: some View {
        ZStack {
            // Large radial glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [pColor.opacity(glowPhase ? 0.35 : 0.12), .clear],
                        center: .center,
                        startRadius: 15,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            // Planet orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [pColor, pColor.opacity(0.7)],
                        center: .init(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: 35
                    )
                )
                .frame(width: 60, height: 60)
                .shadow(color: pColor.opacity(0.4), radius: 12, y: 0)
        }
    }

    // MARK: - 24-Hour Hora Strip

    private var horaStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("24-HOUR PLANETARY HOURS")
                .deviLabel(.caption, theme: theme)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        ForEach(allHoras) { h in
                            let isCurrent = h.id == hora.id
                            let isPast = Date() > h.endTime

                            VStack(spacing: 3) {
                                Circle()
                                    .fill(planetColor(h.planetName))
                                    .frame(width: isCurrent ? 16 : 8, height: isCurrent ? 16 : 8)

                                if isCurrent {
                                    Text(h.planetSanskrit.prefix(3))
                                        .scaledFont(size: 10, weight: .semibold, design: .serif)
                                        .foregroundColor(theme.primaryText)
                                        .lineLimit(1)

                                    Text("NOW")
                                        .scaledFont(size: 7, weight: .bold)
                                        .foregroundColor(pColor)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(pColor.opacity(0.2))
                                        .clipShape(Capsule())
                                        .breathing()
                                }

                                Text(deviFormatTime(h.startTime, timezoneIdentifier: timezoneIdentifier))
                                    .scaledFont(size: 8)
                                    .foregroundColor(theme.secondaryText)
                                    .monospacedDigit()
                                    .lineLimit(1)
                            }
                            .frame(width: isCurrent ? 54 : 32)
                            .opacity(isPast && !isCurrent ? 0.25 : 1.0)
                            .id(h.id)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .onAppear {
                    proxy.scrollTo(hora.id, anchor: .center)
                }
            }
        }
        .padding(12)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Description

    private func descriptionSection(_ text: String) -> some View {
        let parts = splitDescription(text)
        return VStack(alignment: .leading, spacing: 12) {
            Text(parts.pullQuote)
                .deviLabel(.sacredBody, theme: theme)
                .lineSpacing(4)
            if let rest = parts.remainder {
                Text(rest)
                    .deviLabel(.detail, theme: theme)
                    .lineSpacing(3)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .deviCard(theme: theme, elevation: .flat, cornerRadius: 14)
            }
        }
    }

    // MARK: - Activities

    private func activitiesCard(_ title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: title == "Avoid" ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.primaryText)
            }
            ForEach(items.prefix(5), id: \.self) { item in
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

    // MARK: - Helpers

    private func planetColor(_ name: String) -> Color {
        switch name {
        case "Sun":     return Color(hex: "D4A040")
        case "Moon":    return Color(hex: "B8C4D8")
        case "Mars":    return Color(hex: "C45050")
        case "Mercury": return Color(hex: "4AAD6E")
        case "Jupiter": return Color(hex: "C9A96E")
        case "Venus":   return Color(hex: "D47AAD")
        case "Saturn":  return Color(hex: "7B8EC4")
        default:        return theme.secondaryText
        }
    }

    private func qualityColor(_ text: String) -> Color {
        let t = text.lowercased()
        if t.contains("malefic") || t.contains("inauspicious") { return theme.inauspiciousColor }
        if t.contains("benefic") || t.contains("auspicious") { return theme.auspiciousColor }
        return theme.cautionColor
    }

    private func splitDescription(_ text: String) -> (pullQuote: String, remainder: String?) {
        guard let range = text.range(of: ". ") else { return (text, nil) }
        let quote = String(text[text.startIndex..<range.lowerBound]) + "."
        let rest = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        return (quote, rest.isEmpty ? nil : rest)
    }
}

// MARK: - Views/Components/HoraCard.swift
// Planetary hora strip with active spotlight expansion + planetary ribbon

import SwiftUI

struct HoraCard: View {
    let horas: [Hora]
    let theme: DeviTheme
    let timezoneIdentifier: String
    var effectiveNow: Date = Date()
    var onTapHora: ((Hora) -> Void)? = nil

    @State private var glowPhase: Bool = false

    private var currentHoraId: String? {
        horas.first(where: { $0.isActive(at: effectiveNow) })?.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("HORA")
                    .deviLabel(.caption, theme: theme)
                Text("· Planetary Hours")
                    .scaledFont(size: 11)
                    .foregroundColor(theme.secondaryText.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Horizontal strip
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(horas) { hora in
                            Button {
                                onTapHora?(hora)
                            } label: {
                                if hora.isActive(at: effectiveNow) {
                                    expandedHoraColumn(hora)
                                } else {
                                    compactHoraColumn(hora)
                                }
                            }
                            .buttonStyle(.plain)
                            .id(hora.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }
                .onAppear {
                    if let id = currentHoraId {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
                .onChange(of: currentHoraId) { _, newId in
                    if let newId {
                        withAnimation(.spring(response: 0.4)) {
                            proxy.scrollTo(newId, anchor: .center)
                        }
                    }
                }
            }

            // Planetary ribbon — 3pt gradient bar segmented by planet colors
            planetaryRibbon
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
        }
        .deviCard(theme: theme, elevation: .raised)
        .deviEntrance(delay: 0.12)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
        }
    }

    // MARK: - Expanded Active Hora Column

    private func expandedHoraColumn(_ hora: Hora) -> some View {
        let info = PanchangDescriptions.horaInfo(for: hora.planetName)

        return VStack(spacing: 4) {
            // Planet dot with radial glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [planetColor(hora.planetName).opacity(glowPhase ? 0.5 : 0.2), .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: 14
                        )
                    )
                    .frame(width: 28, height: 28)

                Circle()
                    .fill(planetColor(hora.planetName))
                    .frame(width: 10, height: 10)
            }

            // Planet name (serif, larger)
            Text(hora.planetSanskrit)
                .scaledFont(size: 16, weight: .medium, design: .serif)
                .foregroundColor(theme.primaryText)
                .lineLimit(1)

            // Deity name
            if let deity = info?.deity {
                Text(deity)
                    .deviLabel(.insight, theme: theme)
                    .lineLimit(1)
            }

            // Quality badge
            if let quality = info?.quality {
                Text(quality)
                    .scaledFont(size: 9, weight: .semibold)
                    .foregroundColor(qualityColor(quality))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(qualityColor(quality).opacity(0.15))
                    .clipShape(Capsule())
            }

            // First auspicious activity
            if let activity = info?.auspiciousActivities.first {
                Text(activity)
                    .scaledFont(size: 10)
                    .foregroundColor(theme.secondaryText.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // Time
            Text(formatTime(hora.startTime))
                .scaledFont(size: 11)
                .foregroundColor(theme.secondaryText)
                .monospacedDigit()

            // NOW badge
            Text("NOW")
                .scaledFont(size: 8, weight: .bold)
                .foregroundColor(planetColor(hora.planetName))
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(planetColor(hora.planetName).opacity(0.2))
                .clipShape(Capsule())
                .breathing()
        }
        .frame(width: 130)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.primaryText.opacity(0.06))
        )
        .contentShape(Rectangle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hora.isActive(at: effectiveNow))
    }

    // MARK: - Compact Inactive Hora Column

    private func compactHoraColumn(_ hora: Hora) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(planetColor(hora.planetName))
                .frame(width: 8, height: 8)

            Text(hora.planetSanskrit.prefix(3))
                .scaledFont(size: 11, weight: .medium, design: .serif)
                .foregroundColor(theme.primaryText)
                .lineLimit(1)

            Text(formatTime(hora.startTime))
                .scaledFont(size: 10)
                .foregroundColor(theme.secondaryText)
                .monospacedDigit()
        }
        .frame(width: 50)
        .padding(.vertical, 6)
        .opacity(isPast(hora) ? 0.25 : 1.0)
        .contentShape(Rectangle())
    }

    // MARK: - Planetary Ribbon

    private var planetaryRibbon: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(horas) { hora in
                    Rectangle()
                        .fill(planetColor(hora.planetName).opacity(isPast(hora) ? 0.2 : 0.7))
                        .frame(width: geo.size.width / CGFloat(max(horas.count, 1)))
                }
            }
        }
        .frame(height: 3)
        .clipShape(Capsule())
    }

    // MARK: - Helpers

    private func isPast(_ hora: Hora) -> Bool {
        effectiveNow > hora.endTime
    }

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

    private func qualityColor(_ quality: String) -> Color {
        switch quality.lowercased() {
        case let q where q.contains("inauspicious"): return theme.inauspiciousColor
        case let q where q.contains("malefic"):       return theme.inauspiciousColor
        case let q where q.contains("auspicious"):    return theme.auspiciousColor
        case let q where q.contains("benefic"):       return theme.auspiciousColor
        default:                                       return theme.cautionColor
        }
    }

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
    }
}

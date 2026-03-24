// MARK: - Views/Components/HoraCard.swift
// Shows current hora + next 4 upcoming, with planet-colored dots

import SwiftUI

struct HoraCard: View {
    let horas: [Hora]
    let theme: DeviTheme
    let timezoneIdentifier: String
    var onTapHora: ((Hora) -> Void)? = nil

    /// Current and next 4 horas for display
    private var visibleHoras: [Hora] {
        // Find the current or next-upcoming hora
        let now = Date()
        guard let currentIdx = horas.firstIndex(where: { now < $0.endTime }) else {
            return Array(horas.suffix(5))
        }
        let endIdx = min(currentIdx + 5, horas.count)
        return Array(horas[currentIdx..<endIdx])
    }

    var body: some View {
        VStack(spacing: 0) {
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
            .padding(.bottom, 8)

            ForEach(Array(visibleHoras.enumerated()), id: \.element.id) { index, hora in
                if let onTap = onTapHora {
                    Button {
                        onTap(hora)
                    } label: {
                        HoraRow(hora: hora, theme: theme, timezoneIdentifier: timezoneIdentifier, showChevron: true)
                    }
                    .buttonStyle(.plain)
                } else {
                    HoraRow(hora: hora, theme: theme, timezoneIdentifier: timezoneIdentifier)
                }

                if index < visibleHoras.count - 1 {
                    Divider()
                        .background(theme.primaryText.opacity(0.08))
                }
            }
        }
        .deviCard(theme: theme, elevation: .raised)
        .deviEntrance(delay: 0.12)
    }
}

// MARK: - Hora Row

struct HoraRow: View {
    let hora: Hora
    let theme: DeviTheme
    let timezoneIdentifier: String
    var showChevron: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Planet-colored dot
            Circle()
                .fill(planetColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(hora.planetSanskrit)
                        .scaledFont(size: 15, weight: .medium, design: .serif)
                        .foregroundColor(theme.primaryText)

                    Text("(\(hora.planetName))")
                        .scaledFont(size: 13)
                        .foregroundColor(theme.secondaryText)

                    if hora.isActive {
                        Text("NOW")
                            .scaledFont(size: 10, weight: .bold)
                            .foregroundColor(planetColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(planetColor.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Text("\(formatTime(hora.startTime)) — \(formatTime(hora.endTime))")
                    .scaledFont(size: 13)
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.secondaryText.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .opacity(isPast ? 0.4 : 1.0)
    }

    private var isPast: Bool {
        Date() > hora.endTime
    }

    private var planetColor: Color {
        switch hora.planetName {
        case "Sun":     return Color(hex: "D4A040")  // gold
        case "Moon":    return Color(hex: "B8C4D8")  // silver
        case "Mars":    return Color(hex: "C45050")  // red
        case "Mercury": return Color(hex: "4AAD6E")  // green
        case "Jupiter": return Color(hex: "C9A96E")  // yellow-gold
        case "Venus":   return Color(hex: "D47AAD")  // pink
        case "Saturn":  return Color(hex: "7B8EC4")  // blue
        default:        return theme.secondaryText
        }
    }

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
    }
}

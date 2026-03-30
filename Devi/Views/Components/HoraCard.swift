// MARK: - Views/Components/HoraCard.swift
// Apple Weather-style horizontal scroll strip showing all 24 horas

import SwiftUI

struct HoraCard: View {
    let horas: [Hora]
    let theme: DeviTheme
    let timezoneIdentifier: String
    /// The effective "now" for active/past checks (supports sun arc scrubbing)
    var effectiveNow: Date = Date()
    var onTapHora: ((Hora) -> Void)? = nil

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
                                horaColumn(hora)
                            }
                            .buttonStyle(.plain)
                            .id(hora.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)
                }
                .onAppear {
                    if let id = currentHoraId {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .deviCard(theme: theme, elevation: .raised)
        .deviEntrance(delay: 0.12)
    }

    // MARK: - Column

    private func horaColumn(_ hora: Hora) -> some View {
        VStack(spacing: 4) {
            // Planet dot
            Circle()
                .fill(planetColor(hora.planetName))
                .frame(width: 8, height: 8)

            // Sanskrit name
            Text(hora.planetSanskrit)
                .scaledFont(size: 12, weight: .medium, design: .serif)
                .foregroundColor(theme.primaryText)
                .lineLimit(1)

            // English name
            Text(hora.planetName)
                .scaledFont(size: 10)
                .foregroundColor(theme.secondaryText)
                .lineLimit(1)

            // Start time
            Text(formatTime(hora.startTime))
                .scaledFont(size: 11)
                .foregroundColor(theme.secondaryText)
                .monospacedDigit()

            // NOW badge
            if hora.isActive(at: effectiveNow) {
                Text("NOW")
                    .scaledFont(size: 8, weight: .bold)
                    .foregroundColor(planetColor(hora.planetName))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(planetColor(hora.planetName).opacity(0.2))
                    .clipShape(Capsule())
                    .breathing()
            }
        }
        .frame(width: 60)
        .padding(.vertical, 6)
        .background(
            hora.isActive(at: effectiveNow)
                ? RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.primaryText.opacity(0.06))
                : nil
        )
        .opacity(isPast(hora) ? 0.35 : 1.0)
        .contentShape(Rectangle())
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

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
    }
}

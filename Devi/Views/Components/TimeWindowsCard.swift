// MARK: - Views/Components/TimeWindowsCard.swift
// Vertical branching timeline — auspicious right, inauspicious left

import SwiftUI

struct TimeWindowsCard: View {
    let windows: [TimeWindow]
    let theme: DeviTheme
    let timezoneIdentifier: String
    var effectiveNow: Date = Date()
    var onTapWindow: ((TimeWindow) -> Void)? = nil

    private var sortedWindows: [TimeWindow] {
        windows.sorted { $0.start < $1.start }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("MUHURTA & KALAM")
                    .deviLabel(.caption, theme: theme)
                Spacer()

                // Legend
                HStack(spacing: 12) {
                    legendDot(color: theme.auspiciousColor, label: "Auspicious")
                    legendDot(color: theme.inauspiciousColor, label: "Avoid")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // Branching timeline
            VStack(spacing: 0) {
                ForEach(Array(sortedWindows.enumerated()), id: \.element.id) { index, window in
                    Button {
                        onTapWindow?(window)
                    } label: {
                        timelineNode(window: window, index: index)
                    }
                    .buttonStyle(.plain)
                    .deviReveal(
                        delay: 0.1 + Double(index) * 0.08,
                        direction: window.isAuspicious ? .fadeRight : .fadeLeft
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .deviCard(theme: theme, elevation: .raised)
        .deviEntrance(delay: 0.08)
    }

    // MARK: - Timeline Node

    private func timelineNode(window: TimeWindow, index: Int) -> some View {
        let isActive = window.isActive(at: effectiveNow)
        let past = isPast(window)
        let color = statusColor(window)
        let isRight = window.isAuspicious

        return HStack(spacing: 0) {
            if isRight {
                // Left spacer for right-branching (auspicious)
                Spacer()
                    .frame(maxWidth: .infinity)

                // Center spine dot
                timelineDot(color: color, isActive: isActive)

                // Right content
                nodeContent(window: window, color: color, isActive: isActive, past: past)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
            } else {
                // Left content (inauspicious)
                nodeContent(window: window, color: color, isActive: isActive, past: past)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 10)

                // Center spine dot
                timelineDot(color: color, isActive: isActive)

                // Right spacer
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .opacity(past ? 0.4 : 1.0)
        .contentShape(Rectangle())
    }

    // MARK: - Timeline Dot

    private func timelineDot(color: Color, isActive: Bool) -> some View {
        ZStack {
            if isActive {
                Circle()
                    .fill(color.opacity(0.25))
                    .frame(width: 20, height: 20)
                    .breathing()
            }

            Circle()
                .fill(color)
                .frame(width: isActive ? 10 : 6, height: isActive ? 10 : 6)

            // Vertical line segment above and below
            VStack(spacing: 0) {
                Rectangle()
                    .fill(theme.primaryText.opacity(0.1))
                    .frame(width: 2)
            }
            .frame(width: 2, height: 40)
            .opacity(0.6)
        }
        .frame(width: 24)
    }

    // MARK: - Node Content

    private func nodeContent(window: TimeWindow, color: Color, isActive: Bool, past: Bool) -> some View {
        VStack(alignment: window.isAuspicious ? .leading : .trailing, spacing: 4) {
            HStack(spacing: 6) {
                if !window.isAuspicious {
                    statusBadge(window: window, color: color, isActive: isActive, past: past)
                }

                let wi = windowIcon(for: window.type)
                Image(systemName: wi.icon)
                    .font(.system(size: 12))
                    .foregroundColor(wi.color)

                Text(window.type.rawValue)
                    .scaledFont(size: 14, weight: .medium)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)

                if window.isAuspicious {
                    statusBadge(window: window, color: color, isActive: isActive, past: past)
                }
            }

            Text("\(formatTime(window.start)) – \(formatTime(window.end))")
                .scaledFont(size: 11)
                .foregroundColor(theme.secondaryText)
                .monospacedDigit()

        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isActive ? color.opacity(0.08) : theme.primaryText.opacity(0.02))
        )
    }

    // MARK: - Status Badge

    @ViewBuilder
    private func statusBadge(window: TimeWindow, color: Color, isActive: Bool, past: Bool) -> some View {
        if isActive {
            Text("NOW")
                .scaledFont(size: 8, weight: .bold)
                .foregroundColor(color)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(color.opacity(0.2))
                .clipShape(Capsule())
                .breathing()
        } else if past {
            Text("PASSED")
                .scaledFont(size: 8, weight: .medium)
                .foregroundColor(theme.secondaryText.opacity(0.5))
        } else {
            let mins = minutesUntil(window.start)
            if mins < 60 {
                Text("\(mins)m")
                    .scaledFont(size: 9)
                    .foregroundColor(theme.secondaryText)
            } else {
                Text("\(mins / 60)h")
                    .scaledFont(size: 9)
                    .foregroundColor(theme.secondaryText)
            }
        }
    }

    // MARK: - Legend Dot

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(label)
                .scaledFont(size: 9)
                .foregroundColor(theme.secondaryText.opacity(0.6))
        }
    }

    // MARK: - Helpers

    private func isPast(_ window: TimeWindow) -> Bool {
        effectiveNow > window.end
    }

    private func minutesUntil(_ date: Date) -> Int {
        max(0, Int(date.timeIntervalSince(effectiveNow) / 60))
    }

    private func statusColor(_ window: TimeWindow) -> Color {
        switch window.statusColor {
        case .auspicious:   return theme.auspiciousColor
        case .inauspicious: return theme.inauspiciousColor
        case .caution:      return theme.cautionColor
        }
    }

    private func timeWindowInfoKey(for window: TimeWindow) -> String? {
        switch window.type {
        case .brahmaMuhurta: return "brahmaMuhurta"
        case .abhijitMuhurta: return "abhijitMuhurta"
        case .rahuKalam: return "rahuKalam"
        case .gulikaKalam: return "gulikaKalam"
        case .yamaganda: return "yamaganda"
        }
    }

    private func windowIcon(for type: TimeWindow.WindowType) -> (icon: String, color: Color) {
        switch type {
        case .brahmaMuhurta:  return ("sunrise.fill", theme.auspiciousColor)
        case .abhijitMuhurta: return ("sparkle", theme.auspiciousColor)
        case .rahuKalam:      return ("xmark.octagon.fill", theme.inauspiciousColor)
        case .gulikaKalam:    return ("exclamationmark.triangle.fill", theme.inauspiciousColor)
        case .yamaganda:      return ("bolt.trianglebadge.exclamationmark.fill", theme.inauspiciousColor)
        }
    }

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
    }
}

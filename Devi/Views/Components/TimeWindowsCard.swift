// MARK: - Views/Components/TimeWindowsCard.swift
// 2-column status grid for auspicious/inauspicious time windows

import SwiftUI

struct TimeWindowsCard: View {
    let windows: [TimeWindow]
    let theme: DeviTheme
    let timezoneIdentifier: String
    /// The effective "now" for active/past checks (supports sun arc scrubbing)
    var effectiveNow: Date = Date()
    var onTapWindow: ((TimeWindow) -> Void)? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("MUHURTA & KALAM")
                    .deviLabel(.caption, theme: theme)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(windows) { window in
                    Button {
                        onTapWindow?(window)
                    } label: {
                        windowCell(window)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .deviCard(theme: theme, elevation: .raised)
        .deviEntrance(delay: 0.08)
    }

    // MARK: - Cell

    private func windowCell(_ window: TimeWindow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: statusIcon(window))
                    .font(.system(size: 10))
                    .foregroundColor(statusColor(window))
                    .symbolEffect(.pulse, isActive: window.isActive(at: effectiveNow) && !window.isAuspicious)

                Text(window.type.rawValue)
                    .scaledFont(size: 13, weight: .medium)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text("\(formatTime(window.start)) – \(formatTime(window.end))")
                .scaledFont(size: 11)
                .foregroundColor(theme.secondaryText)
                .monospacedDigit()

            // Status label
            statusLabel(window)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(window.isActive(at: effectiveNow) ? statusColor(window).opacity(0.08) : theme.primaryText.opacity(0.03))
        )
        .overlay(
            window.isActive(at: effectiveNow)
                ? RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(statusColor(window).opacity(0.3), lineWidth: 1)
                : nil
        )
        .opacity(isPast(window) ? 0.4 : 1.0)
        .contentShape(Rectangle())
    }

    // MARK: - Status Label

    @ViewBuilder
    private func statusLabel(_ window: TimeWindow) -> some View {
        if window.isActive(at: effectiveNow) {
            Text("NOW")
                .scaledFont(size: 9, weight: .bold)
                .foregroundColor(statusColor(window))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor(window).opacity(0.2))
                .clipShape(Capsule())
                .breathing()
        } else if isPast(window) {
            Text("PASSED")
                .scaledFont(size: 9, weight: .medium)
                .foregroundColor(theme.secondaryText.opacity(0.5))
        } else {
            let mins = minutesUntil(window.start)
            if mins < 60 {
                Text("\(mins)m away")
                    .scaledFont(size: 10)
                    .foregroundColor(theme.secondaryText)
            } else {
                let hours = mins / 60
                Text("\(hours)h away")
                    .scaledFont(size: 10)
                    .foregroundColor(theme.secondaryText)
            }
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

    private func statusIcon(_ window: TimeWindow) -> String {
        switch window.statusColor {
        case .auspicious:   return "checkmark.circle.fill"
        case .inauspicious: return "xmark.circle.fill"
        case .caution:      return "exclamationmark.circle.fill"
        }
    }

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
    }
}

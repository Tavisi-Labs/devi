// MARK: - Views/Components/TimeWindowsCard.swift
// Displays auspicious/inauspicious time windows for the day

import SwiftUI

struct TimeWindowsCard: View {
    let windows: [TimeWindow]
    let theme: DeviTheme
    let timezoneIdentifier: String

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                TimeWindowRow(window: window, theme: theme, timezoneIdentifier: timezoneIdentifier)
                
                if index < windows.count - 1 {
                    Divider()
                        .background(theme.primaryText.opacity(0.1))
                }
            }
        }
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct TimeWindowRow: View {
    let window: TimeWindow
    let theme: DeviTheme
    let timezoneIdentifier: String
    
    private var statusColor: Color {
        switch window.statusColor {
        case .auspicious: return theme.auspiciousColor
        case .inauspicious: return theme.inauspiciousColor
        case .caution: return theme.cautionColor
        }
    }
    
    private var statusIcon: String {
        switch window.statusColor {
        case .auspicious: return "checkmark.circle.fill"
        case .inauspicious: return "xmark.circle.fill"
        case .caution: return "exclamationmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Image(systemName: statusIcon)
                .font(.system(size: 10))
                .foregroundColor(statusColor)
            
            // Window name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(window.type.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.primaryText)
                    
                    if window.isActive {
                        Text("NOW")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                Text("\(formatTime(window.start)) — \(formatTime(window.end))")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(isPast ? 0.4 : 1.0)
    }
    
    private var isPast: Bool {
        Date() > window.end
    }
    
    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
    }
}

// MARK: - Preview

#Preview {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())

    ZStack {
        Color(hex: "1a0a2e").ignoresSafeArea()

        TimeWindowsCard(
            windows: [
                TimeWindow(type: .abhijitMuhurta,
                          start: cal.date(bySettingHour: 11, minute: 42, second: 0, of: today)!,
                          end: cal.date(bySettingHour: 12, minute: 30, second: 0, of: today)!),
                TimeWindow(type: .rahuKalam,
                          start: cal.date(bySettingHour: 13, minute: 30, second: 0, of: today)!,
                          end: cal.date(bySettingHour: 15, minute: 0, second: 0, of: today)!),
                TimeWindow(type: .gulikaKalam,
                          start: cal.date(bySettingHour: 12, minute: 0, second: 0, of: today)!,
                          end: cal.date(bySettingHour: 13, minute: 30, second: 0, of: today)!),
            ],
            theme: DeviTheme.forPeriod(.brahmaMuhurta),
            timezoneIdentifier: "America/New_York"
        )
        .padding()
    }
}

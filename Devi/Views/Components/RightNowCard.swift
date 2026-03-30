// MARK: - Views/Components/RightNowCard.swift
// "What's happening now" — aggregates active hora, choghadiya, and time windows

import SwiftUI

struct RightNowCard: View {
    let items: [PanchangViewModel.RightNowItem]
    let theme: DeviTheme
    let timezoneIdentifier: String
    var onTapItem: ((PanchangElement) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundColor(theme.auspiciousColor)
                    .symbolEffect(.pulse, isActive: true)

                Text("RIGHT NOW")
                    .deviLabel(.caption, theme: theme)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button {
                    onTapItem?(item.element)
                } label: {
                    rightNowRow(item)
                }
                .buttonStyle(.plain)

                if index < items.count - 1 {
                    Divider()
                        .background(theme.primaryText.opacity(0.08))
                }
            }
        }
        .deviCard(theme: theme, elevation: .prominent)
        .deviEntrance(delay: 0.04)
    }

    // MARK: - Row

    private func rightNowRow(_ item: PanchangViewModel.RightNowItem) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(item.statusColor)
                .frame(width: 8, height: 8)

            Text(item.label)
                .scaledFont(size: 14, weight: .medium)
                .foregroundColor(theme.primaryText)
                .lineLimit(1)

            if item.isActive {
                Text("NOW")
                    .scaledFont(size: 9, weight: .bold)
                    .foregroundColor(item.statusColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(item.statusColor.opacity(0.2))
                    .clipShape(Capsule())
                    .breathing()
            } else {
                Text("NEXT")
                    .scaledFont(size: 9, weight: .bold)
                    .foregroundColor(theme.secondaryText)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(theme.primaryText.opacity(0.06))
                    .clipShape(Capsule())
            }

            Spacer()

            Text(item.isActive ? "until \(formatTime(item.endTime))" : "at \(formatTime(item.endTime))")
                .scaledFont(size: 12)
                .foregroundColor(theme.secondaryText)
                .contentTransition(.numericText())

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(theme.secondaryText.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
    }
}

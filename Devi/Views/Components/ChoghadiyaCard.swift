// MARK: - Views/Components/ChoghadiyaCard.swift
// Day/Night choghadiya sections with quality-colored rows

import SwiftUI

struct ChoghadiyaCard: View {
    let choghadiyas: [Choghadiya]
    let theme: DeviTheme
    let timezoneIdentifier: String
    var onTapChoghadiya: ((Choghadiya) -> Void)? = nil

    private var dayChoghadiyas: [Choghadiya] {
        choghadiyas.filter { $0.isDaytime }
    }

    private var nightChoghadiyas: [Choghadiya] {
        choghadiyas.filter { !$0.isDaytime }
    }

    var body: some View {
        VStack(spacing: 16) {
            // DAY section
            choghadiyaSection(title: "CHOGHADIYA · Day", items: dayChoghadiyas)

            // NIGHT section
            choghadiyaSection(title: "CHOGHADIYA · Night", items: nightChoghadiyas)
        }
        .deviEntrance(delay: 0.16)
    }

    @ViewBuilder
    private func choghadiyaSection(title: String, items: [Choghadiya]) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .deviLabel(.caption, theme: theme)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            ForEach(Array(items.enumerated()), id: \.element.id) { index, chog in
                if let onTap = onTapChoghadiya {
                    Button {
                        onTap(chog)
                    } label: {
                        ChoghadiyaRow(choghadiya: chog, theme: theme, timezoneIdentifier: timezoneIdentifier, showChevron: true)
                    }
                    .buttonStyle(.plain)
                } else {
                    ChoghadiyaRow(choghadiya: chog, theme: theme, timezoneIdentifier: timezoneIdentifier)
                }

                if index < items.count - 1 {
                    Divider()
                        .background(theme.primaryText.opacity(0.08))
                }
            }
        }
        .deviCard(theme: theme, elevation: .raised)
    }
}

// MARK: - Choghadiya Row

struct ChoghadiyaRow: View {
    let choghadiya: Choghadiya
    let theme: DeviTheme
    let timezoneIdentifier: String
    var showChevron: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Quality icon
            Image(systemName: qualityIcon)
                .font(.system(size: 10))
                .foregroundColor(qualityColor)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(choghadiya.name)
                        .scaledFont(size: 15, weight: .medium)
                        .foregroundColor(theme.primaryText)

                    Text("(\(choghadiya.quality.rawValue))")
                        .scaledFont(size: 12)
                        .foregroundColor(qualityColor.opacity(0.8))

                    if choghadiya.isActive {
                        Text("NOW")
                            .scaledFont(size: 10, weight: .bold)
                            .foregroundColor(qualityColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(qualityColor.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Text("\(formatTime(choghadiya.startTime)) — \(formatTime(choghadiya.endTime))")
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
        Date() > choghadiya.endTime
    }

    private var qualityColor: Color {
        switch choghadiya.quality {
        case .auspicious: return theme.auspiciousColor
        case .inauspicious: return theme.inauspiciousColor
        case .neutral: return theme.cautionColor
        }
    }

    private var qualityIcon: String {
        switch choghadiya.quality {
        case .auspicious: return "checkmark.circle.fill"
        case .inauspicious: return "xmark.circle.fill"
        case .neutral: return "exclamationmark.circle.fill"
        }
    }

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
    }
}

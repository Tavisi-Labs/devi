// MARK: - Views/Components/ChoghadiyaCard.swift
// Dual horizontal scroll strips for Day and Night choghadiya periods

import SwiftUI

struct ChoghadiyaCard: View {
    let choghadiyas: [Choghadiya]
    let theme: DeviTheme
    let timezoneIdentifier: String
    /// The effective "now" for active/past checks (supports sun arc scrubbing)
    var effectiveNow: Date = Date()
    var onTapChoghadiya: ((Choghadiya) -> Void)? = nil

    private var dayChoghadiyas: [Choghadiya] {
        choghadiyas.filter { $0.isDaytime }
    }

    private var nightChoghadiyas: [Choghadiya] {
        choghadiyas.filter { !$0.isDaytime }
    }

    private var currentDayId: String? {
        dayChoghadiyas.first(where: { $0.isActive(at: effectiveNow) })?.id
    }

    private var currentNightId: String? {
        nightChoghadiyas.first(where: { $0.isActive(at: effectiveNow) })?.id
    }

    var body: some View {
        VStack(spacing: 12) {
            choghadiyaStrip(title: "CHOGHADIYA · Day", items: dayChoghadiyas, currentId: currentDayId)
            choghadiyaStrip(title: "CHOGHADIYA · Night", items: nightChoghadiyas, currentId: currentNightId)
        }
        .deviEntrance(delay: 0.16)
    }

    // MARK: - Strip

    @ViewBuilder
    private func choghadiyaStrip(title: String, items: [Choghadiya], currentId: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .deviLabel(.caption, theme: theme)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Horizontal strip
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(items) { chog in
                            Button {
                                onTapChoghadiya?(chog)
                            } label: {
                                choghadiyaColumn(chog)
                            }
                            .buttonStyle(.plain)
                            .id(chog.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)
                }
                .onAppear {
                    if let id = currentId {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .deviCard(theme: theme, elevation: .raised)
    }

    // MARK: - Column

    private func choghadiyaColumn(_ chog: Choghadiya) -> some View {
        VStack(spacing: 4) {
            // Quality dot
            Circle()
                .fill(qualityColor(chog.quality))
                .frame(width: 8, height: 8)

            // Name
            Text(chog.name)
                .scaledFont(size: 13, weight: .medium)
                .foregroundColor(theme.primaryText)
                .lineLimit(1)

            // Quality label
            Text(chog.quality.rawValue)
                .scaledFont(size: 9)
                .foregroundColor(qualityColor(chog.quality).opacity(0.8))
                .lineLimit(1)

            // Start time
            Text(formatTime(chog.startTime))
                .scaledFont(size: 11)
                .foregroundColor(theme.secondaryText)
                .monospacedDigit()

            // NOW badge
            if chog.isActive(at: effectiveNow) {
                Text("NOW")
                    .scaledFont(size: 8, weight: .bold)
                    .foregroundColor(qualityColor(chog.quality))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(qualityColor(chog.quality).opacity(0.2))
                    .clipShape(Capsule())
                    .breathing()
            }
        }
        .frame(width: 68)
        .padding(.vertical, 6)
        .background(
            chog.isActive(at: effectiveNow)
                ? RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.primaryText.opacity(0.06))
                : nil
        )
        .opacity(isPast(chog) ? 0.35 : 1.0)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private func isPast(_ chog: Choghadiya) -> Bool {
        effectiveNow > chog.endTime
    }

    private func qualityColor(_ quality: ChoghadiyaQuality) -> Color {
        switch quality {
        case .auspicious:   return theme.auspiciousColor
        case .inauspicious: return theme.inauspiciousColor
        case .neutral:      return theme.cautionColor
        }
    }

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
    }
}

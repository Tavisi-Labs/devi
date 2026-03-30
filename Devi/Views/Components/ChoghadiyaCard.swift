// MARK: - Views/Components/ChoghadiyaCard.swift
// Horizontal scroll strip for Day and Night choghadiya periods with active spotlight expansion

import SwiftUI

struct ChoghadiyaCard: View {
    let choghadiyas: [Choghadiya]
    let theme: DeviTheme
    let timezoneIdentifier: String
    var effectiveNow: Date = Date()
    var onTapChoghadiya: ((Choghadiya) -> Void)? = nil

    @State private var glowPhase: Bool = false

    private var dayChoghadiyas: [Choghadiya] {
        choghadiyas.filter { $0.isDaytime }
    }

    private var nightChoghadiyas: [Choghadiya] {
        choghadiyas.filter { !$0.isDaytime }
    }

    var body: some View {
        VStack(spacing: 12) {
            choghadiyaStrip(title: "CHOGHADIYA", subtitle: "Day", items: dayChoghadiyas, icon: "sun.min")
            choghadiyaStrip(title: "CHOGHADIYA", subtitle: "Night", items: nightChoghadiyas, icon: "moon.stars")
        }
        .deviEntrance(delay: 0.16)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
        }
    }

    // MARK: - Choghadiya Strip

    private func choghadiyaStrip(title: String, subtitle: String, items: [Choghadiya], icon: String) -> some View {
        let currentId = items.first(where: { $0.isActive(at: effectiveNow) })?.id

        return VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(theme.secondaryText.opacity(0.5))
                Text(title)
                    .deviLabel(.caption, theme: theme)
                Text("· \(subtitle)")
                    .scaledFont(size: 11)
                    .foregroundColor(theme.secondaryText.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Horizontal scroll strip
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(items) { chog in
                            Button {
                                onTapChoghadiya?(chog)
                            } label: {
                                if chog.isActive(at: effectiveNow) {
                                    expandedColumn(chog)
                                } else {
                                    compactColumn(chog)
                                }
                            }
                            .buttonStyle(.plain)
                            .id(chog.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }
                .onAppear {
                    if let id = currentId {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
                .onChange(of: currentId) { _, newId in
                    if let newId {
                        withAnimation(.spring(response: 0.4)) {
                            proxy.scrollTo(newId, anchor: .center)
                        }
                    }
                }
            }

            // Quality color ribbon
            qualityRibbon(items: items)
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
        }
        .deviCard(theme: theme, elevation: .raised)
    }

    // MARK: - Expanded Active Column

    private func expandedColumn(_ chog: Choghadiya) -> some View {
        let color = qualityColor(chog.quality)
        let info = PanchangDescriptions.choghadiyaInfo(for: chog.name)

        return VStack(spacing: 4) {
            // Quality color dot with radial glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(glowPhase ? 0.5 : 0.2), .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: 14
                        )
                    )
                    .frame(width: 28, height: 28)

                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }

            // Full name (serif)
            Text(chog.name)
                .scaledFont(size: 16, weight: .medium, design: .serif)
                .foregroundColor(theme.primaryText)
                .lineLimit(1)

            // Meaning text
            if let meaning = info?.meaning {
                Text(meaning)
                    .deviLabel(.insight, theme: theme)
                    .lineLimit(1)
            }

            // Quality capsule badge
            Text(chog.quality.rawValue)
                .scaledFont(size: 9, weight: .semibold)
                .foregroundColor(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .clipShape(Capsule())

            // First activity
            if let activity = info?.auspiciousActivities.first {
                Text(activity)
                    .scaledFont(size: 10)
                    .foregroundColor(theme.secondaryText.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // Start time
            Text(formatTime(chog.startTime))
                .scaledFont(size: 11)
                .foregroundColor(theme.secondaryText)
                .monospacedDigit()

            // NOW badge
            Text("NOW")
                .scaledFont(size: 8, weight: .bold)
                .foregroundColor(color)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(color.opacity(0.2))
                .clipShape(Capsule())
                .breathing()
        }
        .frame(width: 120)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.primaryText.opacity(0.06))
        )
        .contentShape(Rectangle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: chog.isActive(at: effectiveNow))
    }

    // MARK: - Compact Inactive Column

    private func compactColumn(_ chog: Choghadiya) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(qualityColor(chog.quality))
                .frame(width: 8, height: 8)

            Text(String(chog.name.prefix(3)))
                .scaledFont(size: 11, weight: .medium, design: .serif)
                .foregroundColor(theme.primaryText)
                .lineLimit(1)

            Text(formatTime(chog.startTime))
                .scaledFont(size: 10)
                .foregroundColor(theme.secondaryText)
                .monospacedDigit()
        }
        .frame(width: 50)
        .padding(.vertical, 6)
        .opacity(isPast(chog) ? 0.5 : 1.0)
        .contentShape(Rectangle())
    }

    // MARK: - Quality Ribbon

    private func qualityRibbon(items: [Choghadiya]) -> some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(items) { chog in
                    Rectangle()
                        .fill(qualityColor(chog.quality).opacity(isPast(chog) ? 0.2 : 0.7))
                        .frame(width: geo.size.width / CGFloat(max(items.count, 1)))
                }
            }
        }
        .frame(height: 3)
        .clipShape(Capsule())
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

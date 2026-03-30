// MARK: - Views/Components/TithiImmersiveView.swift
// Full-screen lunar observatory — immersive tithi experience

import SwiftUI

struct TithiImmersiveView: View {
    let tithi: Tithi
    let theme: DeviTheme
    let timezoneIdentifier: String
    var panchangContext: DailyPanchang?

    @Environment(\.dismiss) private var dismiss
    @State private var glowPhase: Bool = false
    @State private var appeared: Bool = false

    private var illuminationFraction: CGFloat {
        let num = CGFloat(tithi.number)
        if tithi.paksha == .shukla {
            return num / 15.0
        } else {
            return 1.0 - (num / 15.0)
        }
    }

    private var tithiInfo: (meaning: String, description: String, rulingDeity: String, significance: String, auspiciousActivities: [String])? {
        guard let info = PanchangDescriptions.tithiInfo(for: tithi.name) else { return nil }
        return (info.meaning, info.description, info.rulingDeity, info.significance, info.auspiciousActivities)
    }

    var body: some View {
        ZStack {
            // Dark starfield background — forced night for maximum stars
            theme.backgroundGradient.ignoresSafeArea()
            StarFieldView(isDaytime: false, timePeriod: .night)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Top bar: dismiss + share
                    topBar
                        .padding(.top, 8)

                    // Giant moon phase (200pt)
                    moonHero
                        .scaleEffect(appeared ? 1 : 0.3)
                        .opacity(appeared ? 1 : 0)

                    // Title
                    VStack(spacing: 6) {
                        Text(tithi.name.uppercased())
                            .deviLabel(.sacredTitle, theme: theme)
                            .tracking(2)

                        if let info = tithiInfo {
                            Text(info.meaning)
                                .deviLabel(.insight, theme: theme)
                        }

                        Text("\(tithi.paksha.rawValue) Paksha")
                            .deviLabel(.caption, theme: theme)
                    }
                    .deviReveal(delay: 0.15, direction: .fadeUp)

                    // Paksha journey — 15 mini moon phases
                    pakshaJourney
                        .deviReveal(delay: 0.2, direction: .fadeUp)

                    // Ruling deity card
                    if let info = tithiInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RULING DEITY")
                                .deviLabel(.caption, theme: theme)
                            Text(info.rulingDeity)
                                .scaledFont(size: 18, weight: .medium, design: .serif)
                                .foregroundColor(theme.primaryText)
                            Text(info.significance)
                                .deviLabel(.detail, theme: theme)
                                .lineSpacing(3)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
                        .deviReveal(delay: 0.25, direction: .fadeUp)
                    }

                    // Description pull-quote
                    if let info = tithiInfo {
                        descriptionSection(info.description)
                            .deviReveal(delay: 0.3, direction: .fadeUp)
                    }

                    // Timing
                    timingCard
                        .deviReveal(delay: 0.35, direction: .fadeUp)

                    // Auspicious activities
                    if let info = tithiInfo, !info.auspiciousActivities.isEmpty {
                        activitiesCard(info.auspiciousActivities)
                            .deviReveal(delay: 0.4, direction: .fadeUp)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            Spacer()
            ShareLink(item: ShareTextBuilder.panchangElement(
                .tithi(tithi),
                timezoneIdentifier: timezoneIdentifier
            )) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                    Text("Share")
                        .scaledFont(size: 13, weight: .medium)
                }
                .foregroundColor(theme.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Moon Hero (200pt)

    private var moonHero: some View {
        ZStack {
            // Large breathing silver glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "B8C4D8").opacity(glowPhase ? 0.3 : 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)

            // Moon canvas — scaled up from TithiHeroSection
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2

                // Full silver disc
                let moonPath = Path(ellipseIn: CGRect(
                    x: center.x - radius, y: center.y - radius,
                    width: radius * 2, height: radius * 2
                ))
                context.fill(moonPath, with: .color(Color(hex: "B8C4D8").opacity(0.9)))

                let darkColor = Color(hex: "0B1026").opacity(0.92)
                let isWaxing = tithi.paksha == .shukla

                // Dark half
                var darkHalf = Path()
                if isWaxing {
                    darkHalf.addArc(center: center, radius: radius,
                                    startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
                } else {
                    darkHalf.addArc(center: center, radius: radius,
                                    startAngle: .degrees(270), endAngle: .degrees(90), clockwise: false)
                }
                darkHalf.closeSubpath()
                context.fill(darkHalf, with: .color(darkColor))

                // Terminator ellipse
                let terminatorWidth = radius * 2 * abs(illuminationFraction * 2 - 1)
                let terminatorRect = CGRect(
                    x: center.x - terminatorWidth / 2, y: center.y - radius,
                    width: terminatorWidth, height: radius * 2
                )
                let terminatorPath = Path(ellipseIn: terminatorRect)

                if illuminationFraction > 0.5 {
                    context.fill(terminatorPath, with: .color(Color(hex: "B8C4D8").opacity(0.9)))
                } else {
                    context.fill(terminatorPath, with: .color(darkColor))
                }
            }
            .frame(width: 200, height: 200)
            .clipShape(Circle())
        }
    }

    // MARK: - Paksha Journey (15 mini moons)

    private var pakshaJourney: some View {
        VStack(spacing: 8) {
            Text("PAKSHA JOURNEY")
                .deviLabel(.caption, theme: theme)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(1...15, id: \.self) { num in
                        let isCurrent = num == tithi.number
                        let fraction: CGFloat = tithi.paksha == .shukla
                            ? CGFloat(num) / 15.0
                            : 1.0 - (CGFloat(num) / 15.0)

                        ZStack {
                            if isCurrent {
                                Circle()
                                    .stroke(Color(hex: "B8C4D8").opacity(0.5), lineWidth: 1.5)
                                    .frame(width: 30, height: 30)
                            }

                            Canvas { context, size in
                                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                                let r = min(size.width, size.height) / 2

                                let disc = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                                context.fill(disc, with: .color(Color(hex: "B8C4D8").opacity(0.85)))

                                let dark = Color(hex: "0B1026").opacity(0.9)
                                let isW = tithi.paksha == .shukla
                                var dh = Path()
                                if isW {
                                    dh.addArc(center: c, radius: r, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
                                } else {
                                    dh.addArc(center: c, radius: r, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: false)
                                }
                                dh.closeSubpath()
                                context.fill(dh, with: .color(dark))

                                let tw = r * 2 * abs(fraction * 2 - 1)
                                let tr = CGRect(x: c.x - tw / 2, y: c.y - r, width: tw, height: r * 2)
                                let tp = Path(ellipseIn: tr)
                                if fraction > 0.5 {
                                    context.fill(tp, with: .color(Color(hex: "B8C4D8").opacity(0.85)))
                                } else {
                                    context.fill(tp, with: .color(dark))
                                }
                            }
                            .frame(width: isCurrent ? 24 : 18, height: isCurrent ? 24 : 18)
                            .clipShape(Circle())
                        }
                        .frame(width: 32, height: 32)
                        .opacity(isCurrent ? 1.0 : 0.5)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Description

    private func descriptionSection(_ text: String) -> some View {
        let parts = splitDescription(text)
        return VStack(alignment: .leading, spacing: 12) {
            // Pull quote
            Text(parts.pullQuote)
                .deviLabel(.sacredBody, theme: theme)
                .lineSpacing(4)

            // Remainder
            if let rest = parts.remainder {
                Text(rest)
                    .deviLabel(.detail, theme: theme)
                    .lineSpacing(3)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .deviCard(theme: theme, elevation: .flat, cornerRadius: 14)
            }
        }
    }

    // MARK: - Timing

    private var timingCard: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryText)
            Text("Ends at")
                .deviLabel(.detail, theme: theme)
            Spacer()
            Text(deviFormatTime(tithi.endTime, timezoneIdentifier: timezoneIdentifier))
                .deviLabel(.body, theme: theme)
        }
        .padding(14)
        .deviCard(theme: theme, elevation: .flat, cornerRadius: 14)
    }

    // MARK: - Activities

    private func activitiesCard(_ activities: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.auspiciousColor)
                Text("Auspicious For")
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.primaryText)
            }

            ForEach(activities.prefix(5), id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(theme.secondaryText)
                    Text(item)
                        .deviLabel(.detail, theme: theme)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Helpers

    private func splitDescription(_ text: String) -> (pullQuote: String, remainder: String?) {
        guard let range = text.range(of: ". ") else { return (text, nil) }
        let quote = String(text[text.startIndex..<range.lowerBound]) + "."
        let rest = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        return (quote, rest.isEmpty ? nil : rest)
    }
}

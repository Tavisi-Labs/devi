// MARK: - Views/Components/NakshatraImmersiveView.swift
// Full-screen constellation theater — immersive nakshatra experience

import SwiftUI

struct NakshatraImmersiveView: View {
    let nakshatra: Nakshatra
    let theme: DeviTheme
    let timezoneIdentifier: String

    @Environment(\.dismiss) private var dismiss
    @State private var appeared: Bool = false
    @State private var constellationDrawn: Bool = false

    /// Forced dark theme — this is a night-sky theater that must stay dark in both light/dark modes.
    private var skyTheme: DeviTheme {
        DeviTheme.forPeriod(.night, style: .classic, appearance: .alwaysDark)
    }

    private var info: (meaning: String, description: String, rulingPlanet: String, presidingDeity: String, symbol: String, quality: String, auspiciousActivities: [String])? {
        guard let i = PanchangDescriptions.nakshatraInfo(for: nakshatra.name) else { return nil }
        return (i.meaning, i.description, i.rulingPlanet, i.presidingDeity, i.symbol, i.quality, i.auspiciousActivities)
    }

    var body: some View {
        ZStack {
            // Forced dark sky background — must not inherit adaptive theme
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "0A0E1C"), location: 0.0),
                    .init(color: Color(hex: "121A2C"), location: 0.5),
                    .init(color: Color(hex: "1C2438"), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            StarFieldView(isDaytime: false, timePeriod: .night)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    topBar.padding(.top, 8)

                    // Constellation hero
                    constellationHero
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)

                    // Name & meaning
                    VStack(spacing: 6) {
                        Text(nakshatra.name.uppercased())
                            .deviLabel(.sacredTitle, theme: skyTheme)
                            .tracking(2)

                        if let info = info {
                            Text(info.meaning)
                                .deviLabel(.insight, theme: skyTheme)
                        }
                    }
                    .deviReveal(delay: 0.15, direction: .fadeUp)

                    // Planet + Deity row
                    if let info = info {
                        HStack(spacing: 16) {
                            // Planet
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [planetColor(info.rulingPlanet).opacity(0.4), .clear],
                                                center: .center, startRadius: 2, endRadius: 16
                                            )
                                        )
                                        .frame(width: 32, height: 32)
                                    Circle()
                                        .fill(planetColor(info.rulingPlanet))
                                        .frame(width: 14, height: 14)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("RULER")
                                        .deviLabel(.caption, theme: skyTheme)
                                    Text(info.rulingPlanet)
                                        .scaledFont(size: 15, weight: .medium, design: .serif)
                                        .foregroundColor(skyTheme.primaryText)
                                }
                            }

                            Spacer()

                            // Deity
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("DEITY")
                                    .deviLabel(.caption, theme: skyTheme)
                                Text(info.presidingDeity)
                                    .scaledFont(size: 15, weight: .medium, design: .serif)
                                    .foregroundColor(skyTheme.primaryText)
                            }
                        }
                        .padding(14)
                        .deviCard(theme: skyTheme, elevation: .raised, cornerRadius: 16)
                        .deviReveal(delay: 0.2, direction: .fadeUp)
                    }

                    // Symbol + Quality
                    if let info = info {
                        HStack(spacing: 12) {
                            // Symbol card
                            VStack(spacing: 6) {
                                Text(info.symbol)
                                    .scaledFont(size: 24)
                                    .foregroundColor(skyTheme.primaryText)
                                Text("SYMBOL")
                                    .deviLabel(.caption, theme: skyTheme)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .deviCard(theme: skyTheme, elevation: .flat, cornerRadius: 14)

                            // Quality card
                            VStack(spacing: 6) {
                                Text(info.quality)
                                    .scaledFont(size: 14, weight: .semibold)
                                    .foregroundColor(qualityColor(info.quality))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(qualityColor(info.quality).opacity(0.15))
                                    .clipShape(Capsule())
                                Text("QUALITY")
                                    .deviLabel(.caption, theme: skyTheme)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .deviCard(theme: skyTheme, elevation: .flat, cornerRadius: 14)
                        }
                        .deviReveal(delay: 0.25, direction: .fadeUp)
                    }

                    // Description
                    if let info = info {
                        descriptionSection(info.description)
                            .deviReveal(delay: 0.3, direction: .fadeUp)
                    }

                    // Timing
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(skyTheme.secondaryText)
                        Text("Ends at")
                            .deviLabel(.detail, theme: skyTheme)
                        Spacer()
                        Text(deviFormatTime(nakshatra.endTime, timezoneIdentifier: timezoneIdentifier))
                            .deviLabel(.body, theme: skyTheme)
                    }
                    .padding(14)
                    .deviCard(theme: skyTheme, elevation: .flat, cornerRadius: 14)
                    .deviReveal(delay: 0.35, direction: .fadeUp)

                    // Activities
                    if let info = info, !info.auspiciousActivities.isEmpty {
                        activitiesCard(info.auspiciousActivities)
                            .deviReveal(delay: 0.4, direction: .fadeUp)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.5).delay(0.3)) {
                constellationDrawn = true
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(skyTheme.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            Spacer()
            ShareLink(item: ShareTextBuilder.panchangElement(
                .nakshatra(nakshatra),
                timezoneIdentifier: timezoneIdentifier
            )) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                    Text("Share")
                        .scaledFont(size: 13, weight: .medium)
                }
                .foregroundColor(skyTheme.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Constellation Hero

    private var constellationHero: some View {
        let template = constellationTemplate(for: nakshatra.number)
        return ZStack {
            // Subtle glow behind constellation
            Circle()
                .fill(
                    RadialGradient(
                        colors: [planetColor(nakshatra.ruler).opacity(0.08), .clear],
                        center: .center, startRadius: 20, endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)

            Canvas { context, size in
                let lunar = skyTheme.lunarColor
                let scale = min(size.width, size.height) / 2
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                // Draw connecting lines
                if constellationDrawn {
                    for line in template.lines {
                        let from = template.points[line.0]
                        let to = template.points[line.1]
                        var path = Path()
                        path.move(to: CGPoint(x: center.x + from.x * scale, y: center.y + from.y * scale))
                        path.addLine(to: CGPoint(x: center.x + to.x * scale, y: center.y + to.y * scale))
                        context.stroke(path, with: .color(lunar.opacity(0.35)), lineWidth: 0.8)
                    }
                }

                // Draw star points
                for (idx, point) in template.points.enumerated() {
                    let pos = CGPoint(x: center.x + point.x * scale, y: center.y + point.y * scale)
                    let starSize: CGFloat = idx == 0 ? 5 : 3.5

                    // Glow
                    let glowRect = CGRect(x: pos.x - starSize * 2, y: pos.y - starSize * 2,
                                          width: starSize * 4, height: starSize * 4)
                    context.fill(
                        Path(ellipseIn: glowRect),
                        with: .color(lunar.opacity(0.2))
                    )

                    // Star point
                    let starRect = CGRect(x: pos.x - starSize / 2, y: pos.y - starSize / 2,
                                          width: starSize, height: starSize)
                    context.fill(
                        Path(ellipseIn: starRect),
                        with: .color(lunar.opacity(0.9))
                    )
                }
            }
            .frame(width: 180, height: 180)
        }
    }

    // MARK: - Description

    private func descriptionSection(_ text: String) -> some View {
        let parts = splitDescription(text)
        return VStack(alignment: .leading, spacing: 12) {
            Text(parts.pullQuote)
                .deviLabel(.sacredBody, theme: skyTheme)
                .lineSpacing(4)
            if let rest = parts.remainder {
                Text(rest)
                    .deviLabel(.detail, theme: skyTheme)
                    .lineSpacing(3)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .deviCard(theme: skyTheme, elevation: .flat, cornerRadius: 14)
            }
        }
    }

    // MARK: - Activities

    private func activitiesCard(_ activities: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(skyTheme.auspiciousColor)
                Text("Auspicious For")
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(skyTheme.primaryText)
            }
            ForEach(activities.prefix(5), id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\u{2022}")
                        .foregroundColor(skyTheme.secondaryText)
                    Text(item)
                        .deviLabel(.detail, theme: skyTheme)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: skyTheme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Helpers

    private func planetColor(_ name: String) -> Color {
        Graha.named(name)?.color ?? Color(hex: "888888")
    }

    private func qualityColor(_ quality: String) -> Color {
        let q = quality.lowercased()
        if q.contains("inauspicious") || q.contains("malefic") { return skyTheme.inauspiciousColor }
        if q.contains("auspicious") || q.contains("benefic") { return skyTheme.auspiciousColor }
        return skyTheme.cautionColor
    }

    private func splitDescription(_ text: String) -> (pullQuote: String, remainder: String?) {
        guard let range = text.range(of: ". ") else { return (text, nil) }
        let quote = String(text[text.startIndex..<range.lowerBound]) + "."
        let rest = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        return (quote, rest.isEmpty ? nil : rest)
    }

    // 4 geometric constellation templates based on nakshatra number
    private struct ConstellationTemplate {
        let points: [CGPoint] // normalized -0.7...0.7
        let lines: [(Int, Int)]
    }

    private func constellationTemplate(for number: Int) -> ConstellationTemplate {
        switch number % 4 {
        case 0: // Diamond
            return ConstellationTemplate(
                points: [
                    CGPoint(x: 0, y: -0.6),
                    CGPoint(x: 0.5, y: 0),
                    CGPoint(x: 0, y: 0.6),
                    CGPoint(x: -0.5, y: 0),
                    CGPoint(x: 0.25, y: -0.3),
                    CGPoint(x: -0.25, y: 0.3)
                ],
                lines: [(0, 1), (1, 2), (2, 3), (3, 0), (0, 4), (2, 5)]
            )
        case 1: // Arc/bow
            return ConstellationTemplate(
                points: [
                    CGPoint(x: -0.55, y: 0.3),
                    CGPoint(x: -0.3, y: -0.2),
                    CGPoint(x: 0, y: -0.5),
                    CGPoint(x: 0.3, y: -0.2),
                    CGPoint(x: 0.55, y: 0.3),
                    CGPoint(x: 0, y: 0.15),
                    CGPoint(x: 0.15, y: -0.35)
                ],
                lines: [(0, 1), (1, 2), (2, 3), (3, 4), (1, 5), (5, 3), (2, 6)]
            )
        case 2: // Cross/star
            return ConstellationTemplate(
                points: [
                    CGPoint(x: 0, y: -0.6),
                    CGPoint(x: 0, y: 0.6),
                    CGPoint(x: -0.6, y: 0),
                    CGPoint(x: 0.6, y: 0),
                    CGPoint(x: 0, y: 0),
                    CGPoint(x: -0.3, y: -0.3),
                    CGPoint(x: 0.3, y: 0.3)
                ],
                lines: [(0, 4), (4, 1), (2, 4), (4, 3), (0, 5), (1, 6)]
            )
        default: // Zigzag
            return ConstellationTemplate(
                points: [
                    CGPoint(x: -0.5, y: -0.4),
                    CGPoint(x: -0.2, y: 0.2),
                    CGPoint(x: 0.15, y: -0.35),
                    CGPoint(x: 0.45, y: 0.25),
                    CGPoint(x: 0.6, y: -0.15),
                    CGPoint(x: -0.35, y: -0.1)
                ],
                lines: [(0, 1), (1, 2), (2, 3), (3, 4), (0, 5), (5, 1)]
            )
        }
    }
}

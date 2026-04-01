// MARK: - Views/Components/GrahaImmersiveView.swift
// Full-screen cosmic portrait for each of the 9 Vedic planets (graha)

import SwiftUI

struct GrahaImmersiveView: View {

    let graha: Graha
    let longitude: Double
    let grahaSnapshot: GrahaSnapshot?
    let theme: DeviTheme
    let timezoneIdentifier: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var motionManager = VedicSkyMotionManager()
    @State private var appeared: Bool = false
    @State private var glowPhase: Bool = false
    @State private var arcProgress: CGFloat = 0
    @State private var computedSnapshot: GrahaSnapshot?

    // MARK: - Derived

    private var skyTheme: DeviTheme {
        DeviTheme.forPeriod(.night, style: .classic, appearance: .alwaysDark)
    }

    private var info: GrahaInfo? {
        PanchangDescriptions.grahaInfo(for: graha.rawValue)
    }

    private var currentSnapshot: GrahaSnapshot? {
        grahaSnapshot ?? computedSnapshot
    }

    private var moonNakshatraIdx: Int? {
        guard let snap = currentSnapshot else { return nil }
        return GrahaSnapshot.nakshatraIndex(forLongitude: snap.longitude(of: .moon))
    }

    private var currentNakshatraName: String {
        let idx = GrahaSnapshot.nakshatraIndex(forLongitude: longitude)
        return Self.nakshatraNames[idx]
    }

    // MARK: - Static Data

    private static let nakshatraNames: [String] = [
        "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira",
        "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha",
        "Purva Phalguni", "Uttara Phalguni", "Hasta", "Chitra", "Swati",
        "Vishakha", "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha",
        "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
        "Purva Bhadrapada", "Uttara Bhadrapada", "Revati"
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            // Forced dark sky background
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

            // Planet-colored atmospheric glow
            RadialGradient(
                colors: [graha.color.opacity(0.06), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    topBar.padding(.top, 8)

                    // Planet orb hero
                    planetHero
                        .scaleEffect(appeared ? 1 : 0.2)
                        .opacity(appeared ? 1 : 0)

                    // Title section
                    titleSection
                        .deviReveal(delay: 0.15, direction: .fadeUp)

                    // Zodiac arc position
                    zodiacArc
                        .deviReveal(delay: 0.2, direction: .fadeUp)

                    // Nature + Guna + Gemstone badges
                    if let info = info {
                        triptychBadges(info: info)
                            .deviReveal(delay: 0.25, direction: .fadeUp)
                    }

                    // Description card
                    if let info = info {
                        descriptionSection(info.description)
                            .deviReveal(delay: 0.3, direction: .fadeUp)
                    }

                    // Ornamental divider + Beej Mantra
                    if let info = info {
                        VStack(spacing: 16) {
                            Text("─── \u{0950} ───")
                                .font(.system(size: 14, design: .serif))
                                .foregroundColor(.white.opacity(0.3))

                            mantraCard(info: info)
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 1.5).delay(0.4), value: appeared)
                    }

                    // Ruled Nakshatras trio
                    ruledNakshatrasTrio
                        .deviReveal(delay: 0.45, direction: .fadeUp)

                    // Auspicious activities
                    if let info = info, !info.auspiciousActivities.isEmpty {
                        activitiesCard("Auspicious For", items: info.auspiciousActivities, color: skyTheme.auspiciousColor)
                            .deviReveal(delay: 0.5, direction: .fadeUp)
                    }

                    // Avoid activities
                    if let info = info, !info.avoidActivities.isEmpty {
                        activitiesCard("Avoid", items: info.avoidActivities, color: skyTheme.inauspiciousColor)
                            .deviReveal(delay: 0.5, direction: .fadeUp)
                    }

                    // Position card
                    positionCard
                        .deviReveal(delay: 0.5, direction: .fadeUp)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if grahaSnapshot == nil {
                let jd = VedicCalculator.shared.julianDay(from: Date())
                computedSnapshot = PanchangCalculator.computeGrahaSnapshot(julianDay: jd)
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.8)) {
                    arcProgress = 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                motionManager.startUpdates()
            }
        }
        .onDisappear {
            motionManager.stopUpdates()
        }
        .preferredColorScheme(.dark)
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
                .graha(graha, longitude),
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

    // MARK: - Planet Hero

    private var planetHero: some View {
        ZStack {
            // Large radial glow — parallax from gyroscope
            Circle()
                .fill(
                    RadialGradient(
                        colors: [graha.color.opacity(glowPhase ? 0.35 : 0.12), .clear],
                        center: .center,
                        startRadius: 15,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: motionManager.scrollOffset * 0.03)

            // Planet orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [graha.color, graha.color.opacity(0.7)],
                        center: .init(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: 35
                    )
                )
                .frame(width: 60, height: 60)
                .shadow(color: graha.color.opacity(0.4), radius: 12, y: 0)

            // Shadow planet dashed ring overlay
            if graha.isShadow {
                Circle()
                    .strokeBorder(graha.color.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .frame(width: 68, height: 68)
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 6) {
            Text("GRAHA")
                .scaledFont(size: 11, weight: .semibold)
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))

            Text(graha.sanskritName)
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundColor(skyTheme.primaryText)
                .tracking(1)

            Text(graha.rawValue)
                .deviLabel(.insight, theme: skyTheme)

            if let info = info {
                Text(info.deity)
                    .scaledFont(size: 15, weight: .regular, design: .serif)
                    .foregroundColor(skyTheme.secondaryText)
            }
        }
    }

    // MARK: - Zodiac Arc

    private var zodiacArc: some View {
        VStack(spacing: 8) {
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let centerX = w / 2
                let baseY = h - 10
                let radiusX = (w - 40) / 2
                let radiusY = h - 30

                // Draw main arc path (180-degree semicircle, left to right)
                var mainArc = Path()
                for i in 0...180 {
                    let angle = Double(i) * .pi / 180.0
                    let x = centerX - radiusX * cos(angle)
                    let y = baseY - radiusY * sin(angle)
                    if i == 0 {
                        mainArc.move(to: CGPoint(x: x, y: y))
                    } else {
                        mainArc.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                context.stroke(mainArc, with: .color(.white.opacity(0.15)), lineWidth: 1.5)

                // 12 rashi tick marks at 30-degree intervals
                let planetRashiIndex = Int(longitude / 30.0) % 12
                for tick in 0...12 {
                    let angleDeg = Double(tick) * 15.0 // 12 segments across 180 degrees
                    let angle = angleDeg * .pi / 180.0
                    let innerR: CGFloat = 1.0
                    let outerR: CGFloat = 1.06
                    let x1 = centerX - radiusX * innerR * cos(angle)
                    let y1 = baseY - radiusY * innerR * sin(angle)
                    let x2 = centerX - radiusX * outerR * cos(angle)
                    let y2 = baseY - radiusY * outerR * sin(angle)

                    var tickPath = Path()
                    tickPath.move(to: CGPoint(x: x1, y: y1))
                    tickPath.addLine(to: CGPoint(x: x2, y: y2))
                    context.stroke(tickPath, with: .color(.white.opacity(0.2)), lineWidth: 1)
                }

                // Bright arc segment for the rashi containing the planet
                let segStartDeg = Double(planetRashiIndex) * 15.0
                let segEndDeg = segStartDeg + 15.0
                var brightArc = Path()
                let segStart = max(0, Int(segStartDeg))
                let segEnd = min(180, Int(segEndDeg))
                for i in segStart...segEnd {
                    let angle = Double(i) * .pi / 180.0
                    let x = centerX - radiusX * cos(angle)
                    let y = baseY - radiusY * sin(angle)
                    if i == segStart {
                        brightArc.move(to: CGPoint(x: x, y: y))
                    } else {
                        brightArc.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                context.stroke(brightArc, with: .color(graha.color.opacity(0.6)), lineWidth: 2.5)

                // Planet dot at longitude position
                let planetAngleDeg = (longitude / 360.0) * 180.0
                let planetAngle = planetAngleDeg * .pi / 180.0
                let px = centerX - radiusX * cos(planetAngle)
                let py = baseY - radiusY * sin(planetAngle)

                // Glow behind dot
                let glowRect = CGRect(x: px - 8, y: py - 8, width: 16, height: 16)
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .color(graha.color.opacity(0.4))
                )
                // Dot
                let dotRect = CGRect(x: px - 4, y: py - 4, width: 8, height: 8)
                context.fill(
                    Path(ellipseIn: dotRect),
                    with: .color(graha.color)
                )
            }
            .frame(width: 300, height: 140)

            // Current nakshatra label below the arc
            Text(currentNakshatraName)
                .scaledFont(size: 13, weight: .medium, design: .serif)
                .foregroundColor(graha.color)
        }
        .padding(16)
        .deviCard(theme: skyTheme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Triptych Badges

    private func triptychBadges(info: GrahaInfo) -> some View {
        HStack(spacing: 8) {
            // Nature
            VStack(spacing: 4) {
                Text(info.nature)
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(qualityColor(info.nature))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(qualityColor(info.nature).opacity(0.15))
                    .clipShape(Capsule())
                Text("NATURE")
                    .deviLabel(.caption, theme: skyTheme)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .deviCard(theme: skyTheme, elevation: .flat, cornerRadius: 14)

            // Guna
            VStack(spacing: 4) {
                Text(info.guna)
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(qualityColor(info.guna))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(qualityColor(info.guna).opacity(0.15))
                    .clipShape(Capsule())
                Text("GUNA")
                    .deviLabel(.caption, theme: skyTheme)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .deviCard(theme: skyTheme, elevation: .flat, cornerRadius: 14)

            // Gemstone
            VStack(spacing: 4) {
                Text(info.gemstone)
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(graha.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(graha.color.opacity(0.15))
                    .clipShape(Capsule())
                Text("GEMSTONE")
                    .deviLabel(.caption, theme: skyTheme)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .deviCard(theme: skyTheme, elevation: .flat, cornerRadius: 14)
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: skyTheme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Mantra Card

    private func mantraCard(info: GrahaInfo) -> some View {
        VStack(spacing: 12) {
            ZStack {
                // Breathing glow behind Devanagari text
                RadialGradient(
                    colors: [graha.color.opacity(glowPhase ? 0.15 : 0.04), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 80
                )
                .frame(width: 200, height: 60)

                Text(info.mantra.devanagari)
                    .font(.system(size: 26, design: .serif))
                    .foregroundColor(skyTheme.primaryText)
                    .multilineTextAlignment(.center)
            }

            Text(info.mantra.transliteration)
                .scaledFont(size: 14, weight: .regular, design: .serif)
                .foregroundColor(skyTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .deviCard(theme: skyTheme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Ruled Nakshatras Trio

    private var ruledNakshatrasTrio: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RULED NAKSHATRAS")
                .deviLabel(.caption, theme: skyTheme)
                .padding(.leading, 4)

            HStack(spacing: 0) {
                ForEach(Array(graha.ruledNakshatras.enumerated()), id: \.offset) { idx, nk in
                    nakshatraTrioCard(name: nk.name, number: nk.index, isMoonHere: moonNakshatraIdx == nk.index - 1)
                    if idx < graha.ruledNakshatras.count - 1 {
                        Rectangle().fill(graha.color.opacity(0.3)).frame(height: 1)
                            .overlay(
                                Rectangle()
                                    .stroke(graha.color.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                    .frame(height: 1)
                            )
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func nakshatraTrioCard(name: String, number: Int, isMoonHere: Bool) -> some View {
        VStack(spacing: 4) {
            Text("\(number)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(skyTheme.secondaryText)

            Text(name)
                .scaledFont(size: 13, weight: .medium, design: .serif)
                .foregroundColor(skyTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Circle()
                .fill(graha.color)
                .frame(width: 6, height: 6)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .deviCard(theme: skyTheme, elevation: .flat, cornerRadius: 12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isMoonHere ? Color(hex: "D4A040") : .clear,
                    lineWidth: isMoonHere ? 1.5 : 0
                )
                .breathing()
                .opacity(isMoonHere ? 1 : 0)
        )
    }

    // MARK: - Activities

    private func activitiesCard(_ title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: title == "Avoid" ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(skyTheme.primaryText)
            }
            ForEach(items.prefix(5), id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\u{2022}").foregroundColor(skyTheme.secondaryText)
                    Text(item).deviLabel(.detail, theme: skyTheme)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: skyTheme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Position Card

    private var positionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SIDEREAL POSITION")
                .deviLabel(.caption, theme: skyTheme)

            Text("\(String(format: "%.1f\u{00B0}", longitude)) \u{00B7} \(currentNakshatraName)")
                .deviLabel(.body, theme: skyTheme)

            if let info = info {
                Text("Day: \(info.day) \u{00B7} Element: \(info.element)")
                    .deviLabel(.detail, theme: skyTheme)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: skyTheme, elevation: .flat, cornerRadius: 14)
    }

    // MARK: - Helpers

    private func qualityColor(_ text: String) -> Color {
        let t = text.lowercased()
        if t.contains("malefic") || t.contains("inauspicious") || t.contains("tamasic") { return skyTheme.inauspiciousColor }
        if t.contains("benefic") || t.contains("auspicious") || t.contains("sattvic") { return skyTheme.auspiciousColor }
        return skyTheme.cautionColor
    }

    private func splitDescription(_ text: String) -> (pullQuote: String, remainder: String?) {
        guard let range = text.range(of: ". ") else { return (text, nil) }
        let quote = String(text[text.startIndex..<range.lowerBound]) + "."
        let rest = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        return (quote, rest.isEmpty ? nil : rest)
    }
}

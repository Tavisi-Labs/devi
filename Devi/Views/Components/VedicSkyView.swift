// MARK: - Views/Components/VedicSkyView.swift
// Full-screen Vedic sky — scrollable ecliptic strip with navagraha grid

import SwiftUI

struct VedicSkyView: View {

    let theme: DeviTheme
    let timezoneIdentifier: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var motionManager = VedicSkyMotionManager()

    // MARK: - State

    @State private var appeared: Bool = false
    @State private var glowPhase: Bool = false
    @State private var grahaSnapshot: GrahaSnapshot?

    // MARK: - Refresh Timer (60s)

    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    // MARK: - Static Data

    private static let nakshatraNames: [String] = [
        "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira",
        "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha",
        "Purva Phalguni", "Uttara Phalguni", "Hasta", "Chitra", "Swati",
        "Vishakha", "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha",
        "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
        "Purva Bhadrapada", "Uttara Bhadrapada", "Revati"
    ]

    private static let nakshatraRulers: [String] = [
        "Ketu", "Venus", "Sun", "Moon", "Mars",
        "Rahu", "Jupiter", "Saturn", "Mercury", "Ketu",
        "Venus", "Sun", "Moon", "Mars", "Rahu",
        "Jupiter", "Saturn", "Mercury", "Ketu", "Venus",
        "Sun", "Moon", "Mars", "Rahu", "Jupiter",
        "Saturn", "Mercury"
    ]

    // MARK: - Derived

    private var moonNakshatraIndex: Int? {
        guard let snap = grahaSnapshot else { return nil }
        let moonLon = snap.longitude(of: .moon)
        return min(Int(moonLon / (360.0 / 27.0)), 26)
    }

    private var moonNakshatraName: String? {
        guard let idx = moonNakshatraIndex else { return nil }
        return Self.nakshatraNames[idx]
    }

    private var moonLongitude: Double? {
        grahaSnapshot?.longitude(of: .moon)
    }

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

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    topBar.padding(.top, 8)

                    // Moon hero
                    moonHero
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)

                    // Title section
                    titleSection
                        .deviReveal(delay: 0.15, direction: .fadeUp)

                    // Ecliptic strip
                    eclipticStrip
                        .deviReveal(delay: 0.20, direction: .fadeUp)

                    // Navagraha grid
                    navagrahaGrid
                        .deviReveal(delay: 0.25, direction: .fadeUp)

                    // Nakshatra info card
                    nakshatraInfoCard
                        .deviReveal(delay: 0.30, direction: .fadeUp)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            refreshGrahaPositions()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                motionManager.startUpdates()
            }
        }
        .onDisappear {
            motionManager.stopUpdates()
        }
        .onReceive(refreshTimer) { _ in
            refreshGrahaPositions()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            Spacer()
        }
    }

    // MARK: - Moon Hero

    private var moonHero: some View {
        ZStack {
            // Breathing radial glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "B8C4D8").opacity(glowPhase ? 0.3 : 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            // Moon glyph
            Text("☽")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "B8C4D8"))
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 6) {
            Text("VEDIC SKY")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(2)

            if let name = moonNakshatraName {
                Text("Chandra in **\(name)**")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.9))
            }

            if let lon = moonLongitude {
                Text(String(format: "%.1f° sidereal", lon))
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Ecliptic Strip (native horizontal ScrollView)

    private var eclipticStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ECLIPTIC — 27 NAKSHATRAS")
                .deviLabel(.caption, theme: theme)
                .padding(.leading, 4)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(0..<27, id: \.self) { idx in
                            let isCurrent = idx == moonNakshatraIndex
                            nakshatraSegment(index: idx, isCurrent: isCurrent)
                                .id(idx)
                        }
                    }
                    .padding(.horizontal, 8)
                    // Subtle gyro parallax
                    .offset(x: min(max(motionManager.scrollOffset * 0.1, -30), 30))
                }
                .onAppear {
                    if let idx = moonNakshatraIndex {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(idx, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
    }

    private func nakshatraSegment(index: Int, isCurrent: Bool) -> some View {
        let grahasInSegment = grahasInNakshatra(index: index)
        let rulerColor = planetColor(Self.nakshatraRulers[index])

        return VStack(spacing: 4) {
            // Number
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))

            // Name
            Text(Self.nakshatraNames[index])
                .font(.system(size: 13, weight: isCurrent ? .semibold : .regular, design: .serif))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Ruler dot + name
            HStack(spacing: 3) {
                Circle()
                    .fill(rulerColor)
                    .frame(width: 6, height: 6)
                Text(Self.nakshatraRulers[index])
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(rulerColor.opacity(0.8))
            }

            // Graha indicators
            if !grahasInSegment.isEmpty {
                HStack(spacing: 2) {
                    ForEach(grahasInSegment, id: \.graha) { pos in
                        Circle()
                            .fill(planetColor(pos.graha.rawValue))
                            .frame(width: 5, height: 5)
                    }
                }
                .padding(.top, 2)
            } else {
                // Keep consistent height
                Spacer().frame(height: 7)
            }
        }
        .frame(width: isCurrent ? 72 : 60)
        .frame(height: 120)
        .padding(.vertical, 6)
        .opacity(isCurrent ? 1.0 : 0.4)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "D4A040").opacity(isCurrent ? 0.6 : 0), lineWidth: 1)
        )
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "D4A040").opacity(isCurrent ? 0.06 : 0))
        )
    }

    // MARK: - Navagraha Grid

    private var navagrahaGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NAVAGRAHA POSITIONS")
                .deviLabel(.caption, theme: theme)
                .padding(.leading, 4)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                if let snap = grahaSnapshot {
                    ForEach(snap.positions, id: \.graha) { pos in
                        grahaCard(pos)
                    }
                }
            }
        }
    }

    private func grahaCard(_ position: GrahaSnapshot.Position) -> some View {
        let graha = position.graha
        let color = planetColor(graha.rawValue)
        let isMoon = graha == .moon
        let nakshatraIdx = min(Int(position.longitude / (360.0 / 27.0)), 26)

        return VStack(spacing: 6) {
            // Planet dot with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.4), .clear],
                            center: .center, startRadius: 2, endRadius: 14
                        )
                    )
                    .frame(width: 28, height: 28)
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }

            // Sanskrit name
            Text(graha.sanskritName)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundColor(.white)
                .lineLimit(1)

            // English name
            Text(graha.rawValue)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.5))

            // Longitude
            Text(String(format: "%.1f°", position.longitude))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))

            // Nakshatra position
            Text(Self.nakshatraNames[nakshatraIdx])
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.white.opacity(0.4))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .deviCard(theme: theme, elevation: .flat, cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isMoon ? Color(hex: "D4A040").opacity(0.4) : Color.clear,
                    lineWidth: isMoon ? 1 : 0
                )
        )
        .overlay(
            // Dashed border for shadow planets
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    graha.isShadow ? color.opacity(0.3) : Color.clear,
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
        )
    }

    // MARK: - Nakshatra Info Card

    @ViewBuilder
    private var nakshatraInfoCard: some View {
        if let name = moonNakshatraName,
           let info = PanchangDescriptions.nakshatraInfo(for: name) {
            VStack(alignment: .leading, spacing: 10) {
                Text("CURRENT NAKSHATRA")
                    .deviLabel(.caption, theme: theme)

                Text(info.name)
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(.white)

                // Deity + Ruler row
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DEITY")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        Text(info.presidingDeity)
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("RULER")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(planetColor(info.rulingPlanet))
                                .frame(width: 8, height: 8)
                            Text(info.rulingPlanet)
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }

                // Meaning pull-quote
                if !info.meaning.isEmpty {
                    Text("\u{201C}\(info.meaning)\u{201D}")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                        .italic()
                        .padding(.top, 4)
                }

                // Description
                if !info.description.isEmpty {
                    Text(info.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .lineSpacing(3)
                        .padding(.top, 2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
        }
    }

    // MARK: - Helpers

    private func refreshGrahaPositions() {
        let jd = VedicCalculator.shared.julianDay(from: Date())
        grahaSnapshot = PanchangCalculator.computeGrahaSnapshot(julianDay: jd)
    }

    /// Returns graha positions that fall within the given nakshatra segment.
    private func grahasInNakshatra(index: Int) -> [GrahaSnapshot.Position] {
        guard let snap = grahaSnapshot else { return [] }
        return snap.positions.filter { pos in
            min(Int(pos.longitude / (360.0 / 27.0)), 26) == index
        }
    }

    private func planetColor(_ name: String) -> Color {
        switch name.lowercased() {
        case "sun", "surya":     return Color(hex: "D4A040")
        case "moon", "chandra":  return Color(hex: "B8C4D8")
        case "mars", "mangala":  return Color(hex: "C45050")
        case "mercury", "budha": return Color(hex: "4AAD6E")
        case "jupiter", "guru", "brihaspati": return Color(hex: "C9A96E")
        case "venus", "shukra":  return Color(hex: "D47AAD")
        case "saturn", "shani":  return Color(hex: "7B8EC4")
        case "rahu":             return Color(hex: "5A6A8A")
        case "ketu":             return Color(hex: "8A5A5A")
        default:                 return Color(hex: "888888")
        }
    }
}

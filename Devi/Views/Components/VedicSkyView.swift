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
    @State private var selectedNakshatraIndex: Int? = nil
    @State private var selectedGrahaElement: PanchangElement? = nil
    @State private var hasScrolledToMoon: Bool = false

    /// Forced dark theme — card backgrounds must stay dark regardless of app appearance mode.
    private var skyTheme: DeviTheme {
        DeviTheme.forPeriod(.night, style: .classic, appearance: .alwaysDark)
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
        return GrahaSnapshot.nakshatraIndex(forLongitude: moonLon)
    }

    private var moonNakshatraName: String? {
        guard let idx = moonNakshatraIndex else { return nil }
        return Self.nakshatraNames[idx]
    }

    private var moonLongitude: Double? {
        grahaSnapshot?.longitude(of: .moon)
    }

    private var displayedNakshatraIndex: Int? {
        selectedNakshatraIndex ?? moonNakshatraIndex
    }

    private var displayedNakshatraName: String? {
        guard let idx = displayedNakshatraIndex else { return nil }
        return Self.nakshatraNames[idx]
    }

    private var isManualSelection: Bool {
        selectedNakshatraIndex != nil
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
        .fullScreenCover(item: $selectedGrahaElement) { element in
            if case .graha(let g, let lon) = element {
                GrahaImmersiveView(
                    graha: g,
                    longitude: lon,
                    grahaSnapshot: grahaSnapshot,
                    theme: theme,
                    timezoneIdentifier: timezoneIdentifier
                )
            }
        }
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
        .task {
            // (#1) Auto-cancelled on view disappear — no timer leak
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                refreshGrahaPositions()
            }
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
                            skyTheme.lunarColor.opacity(glowPhase ? 0.3 : 0.1),
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
                .foregroundColor(skyTheme.lunarColor)
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
                .deviLabel(.caption, theme: skyTheme)
                .padding(.leading, 4)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(0..<27, id: \.self) { idx in
                            let isCurrent = idx == moonNakshatraIndex
                            let isSelected = idx == selectedNakshatraIndex
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedNakshatraIndex = (selectedNakshatraIndex == idx) ? nil : idx
                                }
                            } label: {
                                nakshatraSegment(index: idx, isCurrent: isCurrent, isSelected: isSelected)
                            }
                            .buttonStyle(.plain)
                            .id(idx)
                        }
                    }
                    .padding(.horizontal, 8)
                    // Subtle gyro parallax
                    .offset(x: min(max(motionManager.scrollOffset * 0.1, -30), 30))
                }
                .onChange(of: grahaSnapshot?.computedAt) { _, _ in
                    if !hasScrolledToMoon, let idx = moonNakshatraIndex {
                        hasScrolledToMoon = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(idx, anchor: .center)
                            }
                        }
                    }
                }
                .onChange(of: selectedNakshatraIndex) { _, newIdx in
                    if let idx = newIdx {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(idx, anchor: .center)
                        }
                    }
                }
            }
        }
        .padding(12)
        .deviCard(theme: skyTheme, elevation: .raised, cornerRadius: 16)
    }

    private func nakshatraSegment(index: Int, isCurrent: Bool, isSelected: Bool = false) -> some View {
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
        .frame(width: isCurrent || isSelected ? 72 : 60)
        .frame(height: 120)
        .padding(.vertical, 6)
        .opacity(isCurrent || isSelected ? 1.0 : 0.4)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isCurrent ? skyTheme.accentColor.opacity(isSelected ? 0.8 : 0.6) :
                    isSelected ? Color.white.opacity(0.5) : Color.clear,
                    lineWidth: 1
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isCurrent ? skyTheme.accentColor.opacity(isSelected ? 0.10 : 0.06) :
                    isSelected ? Color.white.opacity(0.06) : Color.clear
                )
        )
    }

    // MARK: - Navagraha Grid

    private var navagrahaGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NAVAGRAHA POSITIONS")
                .deviLabel(.caption, theme: skyTheme)
                .padding(.leading, 4)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                if let snap = grahaSnapshot {
                    ForEach(snap.positions, id: \.graha) { pos in
                        Button {
                            selectedGrahaElement = .graha(pos.graha, pos.longitude)
                        } label: {
                            grahaCard(pos)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func grahaCard(_ position: GrahaSnapshot.Position) -> some View {
        let graha = position.graha
        let color = planetColor(graha.rawValue)
        let isMoon = graha == .moon
        let nakshatraIdx = GrahaSnapshot.nakshatraIndex(forLongitude: position.longitude)

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
        .deviCard(theme: skyTheme, elevation: .flat, cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isMoon ? skyTheme.accentColor.opacity(0.4) : Color.clear,
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
        if let name = displayedNakshatraName,
           let info = PanchangDescriptions.nakshatraInfo(for: name) {
            VStack(alignment: .leading, spacing: 10) {
                // Header with reset button
                HStack {
                    Text(isManualSelection ? "SELECTED NAKSHATRA" : "CURRENT NAKSHATRA")
                        .deviLabel(.caption, theme: skyTheme)
                    Spacer()
                    if isManualSelection {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedNakshatraIndex = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("\u{263D}")
                                    .font(.system(size: 12))
                                Text("Moon")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(skyTheme.lunarColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(skyTheme.lunarColor.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(info.name)
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(.white)

                // Symbol + Quality row
                HStack(spacing: 16) {
                    if !info.symbol.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SYMBOL")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                            Text(info.symbol)
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    Spacer()
                    if !info.quality.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("QUALITY")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                            Text(info.quality)
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }

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

                // Grahas in this nakshatra
                if let nkIdx = displayedNakshatraIndex {
                    let grahasHere = grahasInNakshatra(index: nkIdx)
                    if !grahasHere.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("GRAHAS HERE")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                            HStack(spacing: 10) {
                                ForEach(grahasHere, id: \.graha) { pos in
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(planetColor(pos.graha.rawValue))
                                            .frame(width: 8, height: 8)
                                        Text(pos.graha.sanskritName)
                                            .font(.system(size: 13, weight: .medium, design: .serif))
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
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

                // Auspicious activities (first 4)
                if !info.auspiciousActivities.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AUSPICIOUS FOR")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                        ForEach(info.auspiciousActivities.prefix(4), id: \.self) { activity in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "4AAD6E"))
                                Text(activity)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
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
            .deviCard(theme: skyTheme, elevation: .raised, cornerRadius: 16)
            .animation(.easeInOut(duration: 0.3), value: displayedNakshatraIndex)
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
            GrahaSnapshot.nakshatraIndex(forLongitude: pos.longitude) == index
        }
    }

    private func planetColor(_ name: String) -> Color {
        Graha.named(name)?.color ?? Color(hex: "888888")
    }
}

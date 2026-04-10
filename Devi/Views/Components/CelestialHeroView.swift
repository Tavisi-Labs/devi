// MARK: - Views/Components/CelestialHeroView.swift
// Unified "Celestial Observatory" hero — sun arc with embedded moon phase,
// nakshatra + live sky row, and cosmic signature one-liner

import SwiftUI

struct CelestialHeroView: View {
    // Sun arc parameters (from SunArcView)
    let progress: Double      // 0.0 (sunrise) to 1.0 (sunset)
    let isDaytime: Bool
    let sunrise: Date
    let sunset: Date
    let moonrise: Date?
    let moonset: Date?
    let currentTime: String
    let countdownText: String
    let countdownLabel: String
    let theme: DeviTheme
    let timePeriod: TimePeriod
    let themeStyle: DeviThemeStyle
    let timezoneIdentifier: String

    // Tithi/Nakshatra (optional — view still works without panchang data)
    var tithi: Tithi? = nil
    var nakshatra: Nakshatra? = nil

    // Cosmic signature
    var cosmicSignature: String? = nil
    var isLoadingSignature: Bool = false

    // Callbacks
    var onScrub: ((Double) -> Void)? = nil
    var onScrubEnd: (() -> Void)? = nil
    var onTapTithi: (() -> Void)? = nil
    var onTapNakshatra: (() -> Void)? = nil
    var onTapVedicSky: (() -> Void)? = nil

    // MARK: - State

    @State private var isScrubbing = false
    @State private var scrubProgress: Double = 0.0
    @State private var lastHourTick: Int = -1
    @State private var clockBreathing: Bool = false

    // Moon state
    @State private var glowPhase: Bool = false
    @State private var moonAppeared: Bool = false

    // Cosmic signature sheet
    @State private var showFullSignature = false

    private let arcSize: CGFloat = 360

    // MARK: - Computed

    private var displayProgress: Double {
        isScrubbing ? scrubProgress : progress
    }

    private var scrubTime: Date {
        let total = sunset.timeIntervalSince(sunrise)
        return sunrise.addingTimeInterval(total * scrubProgress)
    }

    private var scrubPillStrokeColor: Color {
        scrubTime < Date() ? theme.accentColor.opacity(0.35) : theme.lunarColor.opacity(0.35)
    }

    // Moon illumination fraction: 0 = new moon, 1 = full moon
    private var illuminationFraction: CGFloat {
        guard let tithi else { return 0.5 }
        let num = CGFloat(tithi.number)
        if tithi.paksha == .shukla {
            return num / 15.0
        } else {
            return 1.0 - (num / 15.0)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // The arc + sun dot + center content
            ZStack {
                // Dashed track arc
                SunArcShape()
                    .stroke(
                        theme.primaryText.opacity(0.12),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6])
                    )
                    .frame(width: arcSize, height: arcSize / 2)
                    .overlay {
                        if isDaytime || isScrubbing {
                            ZStack {
                                SunArcShape()
                                    .trim(from: 0, to: displayProgress)
                                    .stroke(
                                        DeviTheme.arcGradient(for: timePeriod, style: themeStyle, appearance: theme.isLight ? .alwaysLight : .alwaysDark),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .shadow(color: DeviTheme.arcShadowColor(for: timePeriod, style: themeStyle, appearance: theme.isLight ? .alwaysLight : .alwaysDark).opacity(0.35), radius: 6, x: 0, y: 0)

                                SunDot(
                                    progress: displayProgress,
                                    arcSize: arcSize,
                                    theme: theme
                                )
                            }
                        }
                    }
                    // Interactive drag gesture overlay
                    .overlay {
                        if isDaytime {
                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(arcDragGesture)
                        }
                    }

                // Scrub time pill (shown during drag)
                if isScrubbing {
                    let angle = Angle.degrees(180 + (scrubProgress * 180))
                    let radius = arcSize / 2
                    let rawX = arcSize / 2 + radius * CGFloat(cos(angle.radians))
                    let rawY = arcSize / 2 + radius * CGFloat(sin(angle.radians))
                    let cx = min(max(rawX, 44), arcSize - 44)
                    let cy = max(rawY - 30, 18)

                    Text(formatTime(scrubTime))
                        .scaledFont(size: 12, weight: .semibold)
                        .foregroundColor(theme.primaryText)
                        .monospacedDigit()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(theme.isLight ? Color.white.opacity(0.92) : theme.deepBackground.opacity(0.88))
                        )
                        .overlay(
                            Capsule()
                                .stroke(scrubPillStrokeColor, lineWidth: 0.75)
                        )
                        .clipShape(Capsule())
                        .shadow(color: theme.deepBackground.opacity(theme.isLight ? 0.08 : 0.22), radius: 8, x: 0, y: 4)
                        .position(x: cx, y: cy)
                        .transition(.opacity)
                }

                // Center content: moon + tithi + countdown
                VStack(spacing: 2) {
                    // Moon + Tithi (hidden during scrub)
                    if !isScrubbing, let tithi {
                        Button { onTapTithi?() } label: {
                            moonPhaseCanvas(tithi: tithi)
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))

                        Text(tithi.name.uppercased())
                            .scaledFont(size: 15, weight: .semibold, design: .serif)
                            .foregroundColor(theme.primaryText)
                            .tracking(2)
                            .contentTransition(.interpolate)
                            .transition(.opacity)

                        pakshaDotsRow(tithi: tithi)
                            .transition(.opacity)
                    }

                    // Countdown label
                    Text(isScrubbing ? "AT THIS TIME" : countdownLabel)
                        .scaledFont(size: 13, weight: .regular, design: .serif)
                        .italic()
                        .foregroundColor(theme.secondaryText)
                        .tracking(3.0)
                        .contentTransition(.interpolate)

                    // Countdown text
                    if isScrubbing {
                        Text(formatTime(scrubTime))
                            .scaledFont(size: 40, weight: .light, design: .serif)
                            .foregroundColor(theme.primaryText)
                            .monospacedDigit()
                            .minimumScaleFactor(0.8)
                            .contentTransition(.numericText())
                    } else {
                        Text(countdownText)
                            .scaledFont(size: 40, weight: .light, design: .serif)
                            .foregroundColor(theme.primaryText)
                            .monospacedDigit()
                            .minimumScaleFactor(0.8)
                            .contentTransition(.numericText(countsDown: true))
                            .opacity(clockBreathing ? 0.85 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: clockBreathing)
                            .onAppear { clockBreathing = true }
                    }

                    // Current time
                    Text(currentTime)
                        .scaledFont(size: 15, weight: .regular)
                        .foregroundColor(theme.secondaryText)
                        .contentTransition(.numericText())
                        .opacity(isScrubbing ? 0.3 : 1.0)
                }
                .offset(y: isScrubbing ? 30 : 20)
                .animation(.easeInOut(duration: 0.3), value: isScrubbing)
            }
            .frame(height: arcSize / 2 + 60)

            // Sun + Moon times below the arc
            VStack(spacing: 16) {
                // Sun times
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 10))
                            .foregroundColor(theme.accentColor.opacity(0.7))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Sunrise")
                                .deviLabel(.caption, theme: theme)
                            Text(formatTime(sunrise))
                                .deviLabel(.body, theme: theme)
                        }
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("Sunset")
                                .deviLabel(.caption, theme: theme)
                            Text(formatTime(sunset))
                                .deviLabel(.body, theme: theme)
                        }
                        Image(systemName: "sunset.fill")
                            .font(.system(size: 10))
                            .foregroundColor(theme.accentColor.opacity(0.7))
                    }
                }

                // Moon times
                if moonrise != nil || moonset != nil {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "moonrise.fill")
                                .font(.system(size: 10))
                                .foregroundColor(theme.lunarColor.opacity(0.6))
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Moonrise")
                                    .deviLabel(.caption, theme: theme)
                                Text(formatOptionalTime(moonrise))
                                    .deviLabel(.body, theme: theme)
                            }
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("Moonset")
                                    .deviLabel(.caption, theme: theme)
                                Text(formatOptionalTime(moonset))
                                    .deviLabel(.body, theme: theme)
                            }
                            Image(systemName: "moonset.fill")
                                .font(.system(size: 10))
                                .foregroundColor(theme.lunarColor.opacity(0.6))
                        }
                    }
                }
            }
            .padding(.horizontal, 48)

            // Nakshatra + Live Sky row
            if let nakshatra {
                HStack(spacing: 0) {
                    // Nakshatra tap (left)
                    Button { onTapNakshatra?() } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(planetColor(nakshatra.ruler))
                                .frame(width: 7, height: 7)
                            Text(nakshatra.name)
                                .scaledFont(size: 14, weight: .regular, design: .serif)
                                .foregroundColor(theme.secondaryText)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Live Sky tap (right)
                    Button { onTapVedicSky?() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(LinearGradient(
                                    colors: [Color(hex: "D4A040"), Color(hex: "C9A96E")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .symbolEffect(.pulse, options: .speed(0.3), isActive: true)
                            Text("Live Sky")
                                .scaledFont(size: 13, weight: .medium)
                                .foregroundColor(theme.secondaryText)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(theme.secondaryText.opacity(0.4))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }

            // Cosmic signature one-liner
            if let sig = cosmicSignature {
                Button { showFullSignature = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundColor(theme.accentColor.opacity(0.6))
                        Text(extractFirstSentence(sig))
                            .scaledFont(size: 13, weight: .regular, design: .serif)
                            .foregroundColor(theme.primaryText.opacity(0.7))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 12)
            } else if isLoadingSignature {
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.primaryText.opacity(0.04))
                    .frame(height: 16).frame(maxWidth: 200)
                    .padding(.top, 12)
            }
        }
        .onAppear {
            // Moon glow breathing
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
            // Moon entrance spring
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                moonAppeared = true
            }
        }
        .animation(.easeInOut(duration: 0.8), value: tithi?.number)
        .animation(.easeInOut(duration: 0.8), value: tithi?.paksha)
        .sheet(isPresented: $showFullSignature) {
            CosmicSignatureCard(signature: cosmicSignature, isLoading: false, theme: theme)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Moon Phase Canvas (migrated from TithiHeroSection, 56px)

    @ViewBuilder
    private func moonPhaseCanvas(tithi: Tithi) -> some View {
        ZStack {
            // Silver glow (sized for 44px moon)
            Circle()
                .fill(RadialGradient(
                    colors: [theme.lunarColor.opacity(glowPhase ? 0.2 : 0.08), .clear],
                    center: .center, startRadius: 14, endRadius: 32
                ))
                .frame(width: 64, height: 64)

            // Moon canvas — terminator logic from TithiHeroSection
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2

                // Full silver moon disc
                let moonPath = Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.fill(moonPath, with: .color(theme.lunarColor.opacity(0.9)))

                // Adaptive dark color for light/dark mode
                let darkColor = theme.isLight ? Color.black.opacity(0.82) : theme.deepBackground.opacity(0.92)
                let isWaxing = tithi.paksha == .shukla

                // Dark half
                var darkHalf = Path()
                if isWaxing {
                    darkHalf.addArc(center: center, radius: radius, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
                    darkHalf.closeSubpath()
                } else {
                    darkHalf.addArc(center: center, radius: radius, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: false)
                    darkHalf.closeSubpath()
                }
                context.fill(darkHalf, with: .color(darkColor))

                // Terminator ellipse
                let terminatorWidth = radius * 2 * abs(illuminationFraction * 2 - 1)
                let terminatorRect = CGRect(
                    x: center.x - terminatorWidth / 2,
                    y: center.y - radius,
                    width: terminatorWidth,
                    height: radius * 2
                )
                let terminatorPath = Path(ellipseIn: terminatorRect)

                if illuminationFraction > 0.5 {
                    context.fill(terminatorPath, with: .color(theme.lunarColor.opacity(0.9)))
                } else {
                    context.fill(terminatorPath, with: .color(darkColor))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
        }
        .scaleEffect(moonAppeared ? 1 : 0.85)
        .opacity(moonAppeared ? 1 : 0.4)
    }

    // MARK: - Paksha Dots Row

    @ViewBuilder
    private func pakshaDotsRow(tithi: Tithi) -> some View {
        HStack(spacing: 3) {
            ForEach(1...15, id: \.self) { i in
                Circle()
                    .fill(i == tithi.number
                        ? theme.cautionColor
                        : theme.lunarColor.opacity(0.2))
                    .frame(width: i == tithi.number ? 6 : 4,
                           height: i == tithi.number ? 6 : 4)
            }
        }
        .contentTransition(.interpolate)
    }

    // MARK: - Drag Gesture

    private var arcDragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                let center = CGPoint(x: arcSize / 2, y: arcSize / 2)
                let dx = value.location.x - center.x
                let dy = value.location.y - center.y

                let p: Double
                if dy < 0 {
                    let angle = atan2(dy, dx)
                    p = 1.0 - (Double(-angle) / .pi)
                } else {
                    let halfWidth = arcSize / 2
                    p = Double((dx + halfWidth) / (2 * halfWidth))
                }
                let clampedProgress = max(0.01, min(0.99, p))

                if !isScrubbing {
                    isScrubbing = true
                    lastHourTick = -1
                }
                scrubProgress = clampedProgress
                onScrub?(clampedProgress)

                let total = sunset.timeIntervalSince(sunrise)
                let scrubbedDate = sunrise.addingTimeInterval(total * clampedProgress)
                let currentHour = Calendar.current.component(.hour, from: scrubbedDate)
                if currentHour != lastHourTick {
                    lastHourTick = currentHour
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isScrubbing = false
                }
                onScrubEnd?()
            }
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
    }

    private func formatOptionalTime(_ date: Date?) -> String {
        guard let date else { return "—" }
        return formatTime(date)
    }

    private func planetColor(_ name: String) -> Color {
        Graha.named(name)?.color ?? Color(hex: "888888")
    }

    private func extractFirstSentence(_ text: String) -> String {
        // Find first sentence
        var sentence = text
        if let range = text.range(of: ". ") {
            sentence = String(text[text.startIndex...range.lowerBound])
        } else if let range = text.range(of: ".") {
            sentence = String(text[text.startIndex...range.lowerBound])
        }
        // Cap at ~80 chars for clean one-liner
        if sentence.count > 80 {
            let prefix = String(sentence.prefix(80))
            if let lastSpace = prefix.lastIndex(of: " ") {
                return String(prefix[prefix.startIndex..<lastSpace]) + "..."
            }
            return prefix + "..."
        }
        return sentence
    }
}

// MARK: - Sun Arc Shape (semicircle, open at bottom)

struct SunArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )

        return path
    }
}

// MARK: - Sun Dot (positioned along the arc, with organic 4-phase heartbeat)

struct SunDot: View {
    let progress: Double
    let arcSize: CGFloat
    let theme: DeviTheme

    private var sunGold: Color { theme.solarGlow }

    enum PulsePhase: CaseIterable {
        case rest, inhale, peak, exhale

        var scale: CGFloat {
            switch self {
            case .rest:    return 1.0
            case .inhale:  return 1.04
            case .peak:    return 1.08
            case .exhale:  return 1.0
            }
        }

        var glowOpacity: Double {
            switch self {
            case .rest:    return 0.06
            case .inhale:  return 0.08
            case .peak:    return 0.12
            case .exhale:  return 0.06
            }
        }

        var haloRadius: CGFloat {
            switch self {
            case .rest:    return 12
            case .inhale:  return 14
            case .peak:    return 16
            case .exhale:  return 12
            }
        }
    }

    var body: some View {
        let angle = Angle.degrees(180 + (progress * 180))
        let radius = arcSize / 2
        let center = CGPoint(x: arcSize / 2, y: arcSize / 2)

        let x = center.x + radius * CGFloat(cos(angle.radians))
        let y = center.y + radius * CGFloat(sin(angle.radians))

        PhaseAnimator(PulsePhase.allCases) { phase in
            ZStack {
                Circle()
                    .fill(sunGold.opacity(phase.glowOpacity))
                    .frame(width: 80, height: 80)
                    .blur(radius: phase.haloRadius)

                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: sunGold.opacity(0.25), location: 0),
                                .init(color: sunGold.opacity(0.08), location: 0.5),
                                .init(color: .clear, location: 1.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 28
                        )
                    )
                    .frame(width: 56, height: 56)
                    .scaleEffect(phase.scale)

                Circle()
                    .fill(sunGold.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .scaleEffect(phase.scale * 0.98)

                Circle()
                    .fill(theme.accentColor)
                    .frame(width: 14, height: 14)

                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 5, height: 5)
            }
        } animation: { phase in
            switch phase {
            case .rest:    .easeOut(duration: 1.5)
            case .inhale:  .easeIn(duration: 2.0)
            case .peak:    .easeInOut(duration: 0.8)
            case .exhale:  .easeOut(duration: 2.5)
            }
        }
        .position(x: x, y: y)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "0B1026")
            .ignoresSafeArea()

        CelestialHeroView(
            progress: 0.65,
            isDaytime: true,
            sunrise: Calendar.current.date(bySettingHour: 6, minute: 18, second: 0, of: Date())!,
            sunset: Calendar.current.date(bySettingHour: 18, minute: 42, second: 0, of: Date())!,
            moonrise: Calendar.current.date(bySettingHour: 19, minute: 30, second: 0, of: Date()),
            moonset: Calendar.current.date(bySettingHour: 5, minute: 40, second: 0, of: Date()),
            currentTime: "6:42 PM",
            countdownText: "10.33.00",
            countdownLabel: "SUNSET IN",
            theme: DeviTheme.forPeriod(.evening),
            timePeriod: .evening,
            themeStyle: .classic,
            timezoneIdentifier: "America/New_York",
            tithi: Tithi(number: 15, name: "Purnima", paksha: .shukla, endTime: Date()),
            nakshatra: Nakshatra(number: 12, name: "U.Phalguni", ruler: "Sun", deity: "Aryaman", endTime: Date()),
            cosmicSignature: "The Purnima tithi brings the peak of lunar energy. A powerful day for spiritual practice and gratitude."
        )
    }
}

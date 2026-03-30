// MARK: - Views/Components/SunArcView.swift
// The hero visual element — semicircular arc showing sun position

import SwiftUI

struct SunArcView: View {
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
    /// Called during drag with the scrubbed progress (0.0–1.0)
    var onScrub: ((Double) -> Void)? = nil
    /// Called when drag ends — snap back to live
    var onScrubEnd: (() -> Void)? = nil

    @State private var isScrubbing = false
    @State private var scrubProgress: Double = 0.0
    @State private var lastHourTick: Int = -1
    @State private var clockBreathing: Bool = false

    private let arcSize: CGFloat = 320

    /// The progress value to display — scrubbed or live
    private var displayProgress: Double {
        isScrubbing ? scrubProgress : progress
    }

    /// The time represented by the current scrub position
    private var scrubTime: Date {
        let total = sunset.timeIntervalSince(sunrise)
        return sunrise.addingTimeInterval(total * scrubProgress)
    }

    var body: some View {
        VStack(spacing: 8) {
            // The arc + sun dot + time display
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
                    let cx = arcSize / 2 + radius * CGFloat(cos(angle.radians))
                    let cy = arcSize / 2 + radius * CGFloat(sin(angle.radians))

                    Text(formatTime(scrubTime))
                        .scaledFont(size: 12, weight: .semibold)
                        .foregroundColor(theme.primaryText)
                        .monospacedDigit()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .position(x: cx, y: cy - 30)
                        .transition(.opacity)
                }

                // Center content: label → hero countdown → current time
                VStack(spacing: 4) {
                    Text(isScrubbing ? "AT THIS TIME" : countdownLabel)
                        .scaledFont(size: 13, weight: .regular, design: .serif)
                        .italic()
                        .foregroundColor(theme.secondaryText)
                        .tracking(3.0)
                        .contentTransition(.interpolate)

                    if isScrubbing {
                        Text(formatTime(scrubTime))
                            .scaledFont(size: 48, weight: .light, design: .serif)
                            .foregroundColor(theme.primaryText)
                            .monospacedDigit()
                            .minimumScaleFactor(0.8)
                            .contentTransition(.numericText())
                    } else {
                        Text(countdownText)
                            .scaledFont(size: 48, weight: .light, design: .serif)
                            .foregroundColor(theme.primaryText)
                            .monospacedDigit()
                            .minimumScaleFactor(0.8)
                            .contentTransition(.numericText(countsDown: true))
                            .opacity(clockBreathing ? 0.85 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: clockBreathing)
                            .onAppear { clockBreathing = true }
                    }

                    Text(currentTime)
                        .scaledFont(size: 15, weight: .regular)
                        .foregroundColor(theme.secondaryText)
                        .contentTransition(.numericText())
                        .opacity(isScrubbing ? 0.3 : 1.0)
                }
                .offset(y: 30)
            }
            .frame(height: arcSize / 2 + 60)

            // Sun + Moon times below the arc
            VStack(spacing: 10) {
                // Sun times (always visible)
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

                // Moon times (when available)
                if moonrise != nil || moonset != nil {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "moonrise.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "B8C4D8").opacity(0.6))
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
                                .foregroundColor(Color(hex: "B8C4D8").opacity(0.6))
                        }
                    }
                }
            }
            .padding(.horizontal, 48)
        }
    }

    // MARK: - Drag Gesture

    private var arcDragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                let center = CGPoint(x: arcSize / 2, y: arcSize / 2)
                let dx = value.location.x - center.x
                let dy = value.location.y - center.y

                // Convert drag position to progress along the arc
                let p: Double
                if dy < 0 {
                    // Above center — use angular mapping (works perfectly for the arc)
                    let angle = atan2(dy, dx)
                    p = 1.0 - (Double(-angle) / .pi)
                } else {
                    // Below center — use horizontal position as linear proxy
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

                // Track hour crossings for haptic feedback
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

    private let sunGold = Color(hex: "f0c040")

    /// 4-phase heartbeat: asymmetric timing mimics a living pulse
    /// (fast peak, slow exhale → subconsciously reads as "alive")
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
                // Faint halo layer — breathes with phase
                Circle()
                    .fill(sunGold.opacity(phase.glowOpacity))
                    .frame(width: 80, height: 80)
                    .blur(radius: phase.haloRadius)

                // Warm radial glow (3-stop)
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

                // Outer ring
                Circle()
                    .fill(sunGold.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .scaleEffect(phase.scale * 0.98)

                // Inner dot
                Circle()
                    .fill(theme.accentColor)
                    .frame(width: 14, height: 14)

                // Center highlight
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

        SunArcView(
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
            timezoneIdentifier: "America/New_York"
        )
    }
}

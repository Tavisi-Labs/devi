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
    let timezoneIdentifier: String

    // Animation state for the sun dot pulse
    @State private var isPulsing = false

    private let arcSize: CGFloat = 320

    var body: some View {
        VStack(spacing: 8) {
            // The arc + sun dot + time display
            ZStack {
                // Dashed track arc (textured background), with daytime progress + dot overlaid
                SunArcShape()
                    .stroke(
                        theme.primaryText.opacity(0.12),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6])
                    )
                    .frame(width: arcSize, height: arcSize / 2)
                    .overlay {
                        if isDaytime {
                            ZStack {
                                SunArcShape()
                                    .trim(from: 0, to: progress)
                                    .stroke(
                                        DeviTheme.arcGradient(for: timePeriod),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .shadow(color: DeviTheme.arcShadowColor(for: timePeriod).opacity(0.35), radius: 6, x: 0, y: 0)

                                SunDot(
                                    progress: progress,
                                    arcSize: arcSize,
                                    theme: theme,
                                    isPulsing: isPulsing
                                )
                            }
                        }
                    }

                // Center content: label → hero countdown → current time
                VStack(spacing: 4) {
                    Text(countdownLabel)
                        .deviLabel(.section, theme: theme)
                        .tracking(3.0)

                    Text(countdownText)
                        .font(.system(size: 52, weight: .light, design: .rounded))
                        .foregroundColor(theme.primaryText)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text(currentTime)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(theme.secondaryText)
                }
                .offset(y: 30) // More breathing room from arc center
            }
            .frame(height: arcSize / 2 + 60)

            // Sunrise / Sunset labels below the arc
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isDaytime ? "Sunrise" : "Moonrise")
                        .deviLabel(.section, theme: theme)
                    Text(isDaytime ? formatTime(sunrise) : formatOptionalTime(moonrise))
                        .deviLabel(.body, theme: theme)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(isDaytime ? "Sunset" : "Moonset")
                        .deviLabel(.section, theme: theme)
                    Text(isDaytime ? formatTime(sunset) : formatOptionalTime(moonset))
                        .deviLabel(.body, theme: theme)
                }
            }
            .padding(.horizontal, 48)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

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

// MARK: - Sun Dot (positioned along the arc)

struct SunDot: View {
    let progress: Double
    let arcSize: CGFloat
    let theme: DeviTheme
    let isPulsing: Bool

    private let sunGold = Color(hex: "f0c040")

    var body: some View {
        let angle = Angle.degrees(180 + (progress * 180))
        let radius = arcSize / 2
        let center = CGPoint(x: arcSize / 2, y: arcSize / 2)

        let x = center.x + radius * CGFloat(cos(angle.radians))
        let y = center.y + radius * CGFloat(sin(angle.radians))

        ZStack {
            // Faint halo layer
            Circle()
                .fill(sunGold.opacity(0.06))
                .frame(width: 80, height: 80)
                .blur(radius: 12)

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
                .scaleEffect(isPulsing ? 1.04 : 1.0)

            // Outer ring
            Circle()
                .fill(sunGold.opacity(0.3))
                .frame(width: 28, height: 28)
                .scaleEffect(isPulsing ? 1.02 : 1.0)

            // Inner dot
            Circle()
                .fill(theme.accentColor)
                .frame(width: 14, height: 14)

            // Center highlight
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 5, height: 5)
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
            timezoneIdentifier: "America/New_York"
        )
    }
}

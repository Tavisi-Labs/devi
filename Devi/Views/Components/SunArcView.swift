// MARK: - Views/Components/SunArcView.swift
// The hero visual element — semicircular arc showing sun position

import SwiftUI

struct SunArcView: View {
    let progress: Double      // 0.0 (sunrise) to 1.0 (sunset)
    let isDaytime: Bool
    let sunrise: Date
    let sunset: Date
    let currentTime: String
    let countdownText: String
    let countdownLabel: String
    let theme: DeviTheme
    let timezoneIdentifier: String
    
    // Animation state for the sun dot pulse
    @State private var isPulsing = false
    
    private let arcSize: CGFloat = 280
    
    var body: some View {
        VStack(spacing: 8) {
            // The arc + sun dot + time display
            ZStack {
                // Arc track glow (blurred behind track)
                SunArcShape()
                    .stroke(
                        theme.primaryText.opacity(0.05),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: arcSize, height: arcSize / 2)
                    .blur(radius: 4)

                // Background arc (track)
                SunArcShape()
                    .stroke(
                        theme.primaryText.opacity(0.1),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: arcSize, height: arcSize / 2)

                // Progress arc glow (blurred behind progress arc)
                if isDaytime {
                    SunArcShape()
                        .trim(from: 0, to: progress)
                        .stroke(
                            theme.arcGradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: arcSize, height: arcSize / 2)
                        .blur(radius: 8)
                        .opacity(0.4)
                }

                // Filled arc (progress)
                if isDaytime {
                    SunArcShape()
                        .trim(from: 0, to: progress)
                        .stroke(
                            theme.arcGradient,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: arcSize, height: arcSize / 2)
                }

                // Sun/Moon dot
                SunDot(
                    progress: isDaytime ? progress : 0,
                    arcSize: arcSize,
                    isDaytime: isDaytime,
                    theme: theme,
                    isPulsing: isPulsing
                )

                // Center content: current time + countdown
                VStack(spacing: 4) {
                    Text(currentTime)
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(theme.primaryText.opacity(0.8))

                    Text(countdownLabel)
                        .deviLabel(.section, theme: theme)

                    Text(countdownText)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .foregroundColor(theme.primaryText)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .offset(y: 20) // Push down from arc center
            }
            .frame(height: arcSize / 2 + 50)
            
            // Sunrise / Sunset labels below the arc
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isDaytime ? "Sunrise" : "Moonrise")
                        .deviLabel(.section, theme: theme)
                    Text(formatTime(isDaytime ? sunrise : sunset))
                        .deviLabel(.body, theme: theme)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(isDaytime ? "Sunset" : "Moonset")
                        .deviLabel(.section, theme: theme)
                    Text(formatTime(isDaytime ? sunset : sunrise))
                        .deviLabel(.body, theme: theme)
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: timezoneIdentifier)
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
    let isDaytime: Bool
    let theme: DeviTheme
    let isPulsing: Bool

    private let sunGold = Color(hex: "f0c040")
    private let moonSilver = Color(hex: "a8b8d4")

    var body: some View {
        let angle = Angle.degrees(180 + (progress * 180))
        let radius = arcSize / 2
        let center = CGPoint(x: arcSize / 2, y: arcSize / 2)

        let x = center.x + radius * CGFloat(cos(angle.radians))
        let y = center.y + radius * CGFloat(sin(angle.radians))

        ZStack {
            if isDaytime {
                // Warm radial glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [sunGold.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)

                // Outer ring
                Circle()
                    .fill(sunGold.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)

                // Inner dot
                Circle()
                    .fill(theme.accentColor)
                    .frame(width: 14, height: 14)

                // Center highlight
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 5, height: 5)
            } else {
                // Cool radial glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [moonSilver.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 18
                        )
                    )
                    .frame(width: 36, height: 36)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)

                // Moon icon
                Image(systemName: "moon.fill")
                    .font(.system(size: 16))
                    .foregroundColor(moonSilver)
                    .shadow(color: moonSilver.opacity(0.5), radius: 4)
            }
        }
        .position(x: x, y: y)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "1a0a2e")
            .ignoresSafeArea()
        
        SunArcView(
            progress: 0.65,
            isDaytime: true,
            sunrise: Calendar.current.date(bySettingHour: 6, minute: 18, second: 0, of: Date())!,
            sunset: Calendar.current.date(bySettingHour: 18, minute: 42, second: 0, of: Date())!,
            currentTime: "6:42 PM",
            countdownText: "10:33:00",
            countdownLabel: "SUNSET IN",
            theme: DeviTheme.forPeriod(.evening),
            timezoneIdentifier: "America/New_York"
        )
    }
}

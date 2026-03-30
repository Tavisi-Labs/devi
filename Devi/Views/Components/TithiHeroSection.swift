// MARK: - Views/Components/TithiHeroSection.swift
// Lunar phase medallion with inline Vedic content for tithi + nakshatra

import SwiftUI

struct TithiHeroSection: View {
    let tithi: Tithi
    let nakshatra: Nakshatra
    let theme: DeviTheme
    var onTapTithi: (() -> Void)? = nil
    var onTapNakshatra: (() -> Void)? = nil

    @State private var glowPhase: Bool = false
    @State private var moonAppeared: Bool = false

    // Moon illumination fraction: 0 = new moon, 1 = full moon
    private var illuminationFraction: CGFloat {
        let num = CGFloat(tithi.number)
        if tithi.paksha == .shukla {
            // Shukla: 1=new→15=full
            return num / 15.0
        } else {
            // Krishna: 1=full→15=new
            return 1.0 - (num / 15.0)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Moon phase medallion
            Button {
                onTapTithi?()
            } label: {
                VStack(spacing: 12) {
                    ZStack {
                        // Silver glow behind moon
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "B8C4D8").opacity(glowPhase ? 0.25 : 0.12),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)

                        // Moon canvas
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
                            context.fill(moonPath, with: .color(Color(hex: "B8C4D8").opacity(0.9)))

                            // Shadow overlay — an ellipse whose x-scale encodes phase
                            // shadowScale: 1.0 = full shadow (new moon), 0.0 = no shadow (full moon)
                            let shadowScale = 1.0 - (illuminationFraction * 2.0 - 1.0).magnitude
                            let shadowWidth = radius * 2 * shadowScale

                            // Shadow side: shukla → shadow on left, krishna → shadow on right
                            let isWaxing = tithi.paksha == .shukla
                            let shadowCenterX: CGFloat
                            if illuminationFraction <= 0.5 {
                                // Less than half illuminated: shadow covers the lit side boundary
                                shadowCenterX = isWaxing ? center.x - (radius - shadowWidth / 2) * 0.0 + center.x * 0.0 : center.x
                                // Actually, simpler: just place shadow ellipse at center, clipped to the correct half
                            } else {
                                shadowCenterX = center.x
                            }
                            _ = shadowCenterX // suppress unused

                            // Simpler geometric approach:
                            // Draw a dark half-circle on one side, then overlay a light/dark ellipse to create the terminator
                            let darkColor = Color(hex: "0B1026").opacity(0.92)

                            // Step 1: Dark half
                            var darkHalf = Path()
                            if isWaxing {
                                // Shadow on the left half
                                darkHalf.addArc(center: center, radius: radius, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
                                darkHalf.closeSubpath()
                            } else {
                                // Shadow on the right half
                                darkHalf.addArc(center: center, radius: radius, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: false)
                                darkHalf.closeSubpath()
                            }
                            context.fill(darkHalf, with: .color(darkColor))

                            // Step 2: Terminator ellipse — reveals or hides the dark half
                            let terminatorWidth = radius * 2 * abs(illuminationFraction * 2 - 1)
                            let terminatorRect = CGRect(
                                x: center.x - terminatorWidth / 2,
                                y: center.y - radius,
                                width: terminatorWidth,
                                height: radius * 2
                            )
                            let terminatorPath = Path(ellipseIn: terminatorRect)

                            if illuminationFraction > 0.5 {
                                // More than half lit: terminator reveals light on the dark side
                                context.fill(terminatorPath, with: .color(Color(hex: "B8C4D8").opacity(0.9)))
                            } else {
                                // Less than half lit: terminator adds darkness on the light side
                                context.fill(terminatorPath, with: .color(darkColor))
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    }
                    .scaleEffect(moonAppeared ? 1 : 0.85)
                    .opacity(moonAppeared ? 1 : 0.4)

                    // Tithi name + meaning
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Text(tithi.name.uppercased())
                                .deviLabel(.sacredTitle, theme: theme)
                                .tracking(2)
                                .contentTransition(.interpolate)

                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(theme.secondaryText.opacity(0.6))
                        }

                        if let info = PanchangDescriptions.tithiInfo(for: tithi.name) {
                            Text("\(info.meaning) · \(info.rulingDeity)")
                                .deviLabel(.insight, theme: theme)
                                .multilineTextAlignment(.center)
                                .contentTransition(.interpolate)
                        }
                    }
                    .deviReveal(delay: 0.15, direction: .fadeUp)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Nakshatra row
            Button {
                onTapNakshatra?()
            } label: {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        // Ruling planet color dot
                        Circle()
                            .fill(planetColor(nakshatra.ruler))
                            .frame(width: 6, height: 6)

                        Text("\(nakshatra.name) Nakshatra")
                            .scaledFont(size: 15, weight: .regular, design: .serif)
                            .foregroundColor(theme.secondaryText)
                            .contentTransition(.interpolate)
                    }

                    if let info = PanchangDescriptions.nakshatraInfo(for: nakshatra.name) {
                        Text("\(info.symbol) \(info.presidingDeity) · \(info.rulingPlanet)")
                            .deviLabel(.insight, theme: theme)
                            .contentTransition(.interpolate)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .deviReveal(delay: 0.25, direction: .fadeUp)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                moonAppeared = true
            }
        }
        .animation(.easeInOut(duration: 0.8), value: tithi.number)
        .animation(.easeInOut(duration: 0.8), value: tithi.paksha)
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

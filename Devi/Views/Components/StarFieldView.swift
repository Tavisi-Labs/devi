// MARK: - Views/Components/StarFieldView.swift
// Canvas-based ambient star field with time-of-day reactivity

import SwiftUI

struct StarFieldView: View {
    let isDaytime: Bool
    let timePeriod: TimePeriod

    @State private var stars: [Star] = []
    @State private var wisps: [CloudWisp] = []

    private var fieldOpacity: Double {
        switch timePeriod {
        case .night:          return 0.55
        case .brahmaMuhurta:  return 0.4
        case .evening:        return 0.3
        case .morning:        return 0.1
        case .afternoon:      return 0.04
        }
    }

    private var visibleFraction: Double {
        switch timePeriod {
        case .night:          return 1.0
        case .brahmaMuhurta:  return 0.85
        case .evening:        return 0.6
        case .morning:        return 0.3
        case .afternoon:      return 0.15
        }
    }

    private var wispOpacityCap: Double {
        switch timePeriod {
        case .afternoon:      return 0.08
        case .morning:        return 0.06
        case .evening:        return 0.05
        case .brahmaMuhurta:  return 0.03
        case .night:          return 0.02
        }
    }

    private var wispTintColor: Color {
        switch timePeriod {
        case .morning, .evening: return Color(hex: "FFE8CC")
        default:                 return .white
        }
    }

    var body: some View {
        if fieldOpacity == 0 {
            Color.clear
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let visibleCount = Int(Double(stars.count) * visibleFraction)
                    let wispScale = wispOpacityCap / 0.06

                    // Draw atmospheric wisps first, then stars above them.
                    for wisp in wisps {
                        let driftX = sin(time / wisp.driftPeriodX + wisp.phaseX) * wisp.driftAmplitudeX
                        let driftY = cos(time / wisp.driftPeriodY + wisp.phaseY) * wisp.driftAmplitudeY

                        let x = wisp.normalizedX * size.width + driftX
                        let y = wisp.normalizedY * size.height + driftY

                        let opacity = min(wisp.opacity * wispScale, wispOpacityCap)
                        let rect = CGRect(
                            x: x - wisp.width / 2,
                            y: y - wisp.height / 2,
                            width: wisp.width,
                            height: wisp.height
                        )
                        let path = Ellipse().path(in: rect)

                        context.drawLayer { layer in
                            layer.opacity = opacity
                            layer.addFilter(.blur(radius: wisp.blurRadius))
                            layer.fill(path, with: .color(wispTintColor))
                        }
                    }

                    for i in 0..<visibleCount {
                        let star = stars[i]
                        let driftX = sin(time / star.driftPeriodX + star.phaseX) * star.driftAmplitude
                        let driftY = cos(time / star.driftPeriodY + star.phaseY) * star.driftAmplitude * 0.6

                        let x = star.normalizedX * size.width + driftX
                        let y = star.normalizedY * size.height + driftY

                        let twinkle = (sin(time * star.twinkleSpeed + star.twinklePhase) + 1) / 2
                        let brightness = star.baseBrightness * (0.5 + 0.5 * twinkle)
                        let alpha = brightness * fieldOpacity

                        let rect = CGRect(
                            x: x - star.size / 2,
                            y: y - star.size / 2,
                            width: star.size,
                            height: star.size
                        )

                        context.opacity = alpha
                        context.fill(
                            Ellipse().path(in: rect),
                            with: .color(star.tintColor)
                        )
                    }
                }
            }
            .allowsHitTesting(false)
            .onAppear {
                if stars.isEmpty {
                    stars = (0..<80).map { _ in Star.random() }
                }
                if wisps.isEmpty {
                    wisps = (0..<5).map { _ in CloudWisp.random() }
                }
            }
        }
    }
}

// MARK: - Star Model

private struct Star {
    let normalizedX: Double
    let normalizedY: Double
    let size: Double
    let baseBrightness: Double
    let twinkleSpeed: Double
    let twinklePhase: Double
    let driftAmplitude: Double
    let driftPeriodX: Double
    let driftPeriodY: Double
    let phaseX: Double
    let phaseY: Double
    let tintColor: Color

    static func random() -> Star {
        // 10% of stars get a warm bisque tint
        let isWarm = Double.random(in: 0...1) < 0.10
        let color: Color = isWarm ? Color(hex: "FFE4C4") : .white

        return Star(
            normalizedX: Double.random(in: 0...1),
            normalizedY: Double.random(in: 0...1),
            size: Double.random(in: 0.5...1.8),
            baseBrightness: Double.random(in: 0.15...0.6),
            twinkleSpeed: Double.random(in: 0.2...0.8),
            twinklePhase: Double.random(in: 0...(.pi * 2)),
            driftAmplitude: Double.random(in: 0.5...2.0),
            driftPeriodX: Double.random(in: 30...60),
            driftPeriodY: Double.random(in: 30...60),
            phaseX: Double.random(in: 0...(.pi * 2)),
            phaseY: Double.random(in: 0...(.pi * 2)),
            tintColor: color
        )
    }
}

// MARK: - Cloud Wisp Model

private struct CloudWisp {
    let normalizedX: Double
    let normalizedY: Double
    let width: Double
    let height: Double
    let driftAmplitudeX: Double
    let driftAmplitudeY: Double
    let driftPeriodX: Double
    let driftPeriodY: Double
    let phaseX: Double
    let phaseY: Double
    let opacity: Double
    let blurRadius: Double

    static func random() -> CloudWisp {
        CloudWisp(
            normalizedX: Double.random(in: 0...1),
            normalizedY: Double.random(in: 0.08...0.92),
            width: Double.random(in: 120...260),
            height: Double.random(in: 80...180),
            driftAmplitudeX: Double.random(in: 10...28),
            driftAmplitudeY: Double.random(in: 6...18),
            driftPeriodX: Double.random(in: 360...840),
            driftPeriodY: Double.random(in: 420...960),
            phaseX: Double.random(in: 0...(.pi * 2)),
            phaseY: Double.random(in: 0...(.pi * 2)),
            opacity: Double.random(in: 0.02...0.06),
            blurRadius: Double.random(in: 20...40)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "060B18").ignoresSafeArea()
        StarFieldView(isDaytime: false, timePeriod: .night)
            .ignoresSafeArea()
    }
}

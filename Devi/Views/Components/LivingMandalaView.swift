// MARK: - Views/Components/LivingMandalaView.swift
// Geometric mandala that reveals in three 7-day rings.

import SwiftUI

enum LivingMandalaEmphasis {
    case teaser
    case ritual
    case poster

    var glowScale: CGFloat {
        switch self {
        case .teaser:
            return 0.9
        case .ritual:
            return 1.0
        case .poster:
            return 1.15
        }
    }
}

struct LivingMandalaView: View {
    let snapshot: MantraRitualSnapshot
    let theme: DeviTheme
    let diameter: CGFloat
    let motionGate: RitualMotionGate
    var bloomTrigger: Int = 0
    var emphasis: LivingMandalaEmphasis = .teaser

    @State private var ambientBreathing = false
    @State private var bloomScale: CGFloat = 1.0

    private var activeOpacity: Double {
        switch snapshot.status {
        case .archived:
            return 0.28
        case .paused:
            return 0.58
        default:
            return 0.96
        }
    }

    private var haloOpacity: Double {
        switch snapshot.status {
        case .archived:
            return 0.05
        case .paused:
            return 0.10
        case .ceremonialCompletion:
            return 0.22
        default:
            return 0.16
        }
    }

    private var completionRatio: CGFloat {
        CGFloat(snapshot.completedCount) / CGFloat(MantraRitualState.cycleLength)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.accentColor.opacity(haloOpacity),
                            theme.accentColor.opacity(0.01),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.55 * emphasis.glowScale
                    )
                )
                .frame(width: diameter * 1.05, height: diameter * 1.05)
                .scaleEffect(ambientBreathing ? 1.02 : 0.97)

            mandalaScaffold

            petalsLayer(ringIndex: 0, revealedCount: min(snapshot.completedCount, 7), radius: diameter * 0.18, petalLength: diameter * 0.18, petalWidth: diameter * 0.034, rotationOffset: -90)
            petalsLayer(ringIndex: 1, revealedCount: min(max(snapshot.completedCount - 7, 0), 7), radius: diameter * 0.29, petalLength: diameter * 0.20, petalWidth: diameter * 0.03, rotationOffset: -64)
            petalsLayer(ringIndex: 2, revealedCount: min(max(snapshot.completedCount - 14, 0), 7), radius: diameter * 0.41, petalLength: diameter * 0.22, petalWidth: diameter * 0.027, rotationOffset: -90)

            centerRosette
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(bloomScale)
        .accessibilityHidden(true)
        .onAppear {
            syncAmbientMotion()
        }
        .onChange(of: motionGate) { _, _ in
            syncAmbientMotion()
        }
        .onChange(of: bloomTrigger) { _, _ in
            triggerBloom()
        }
    }

    private var mandalaScaffold: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(theme.primaryText.opacity(0.06))
                    .frame(width: 1, height: diameter * 0.62)
                    .rotationEffect(.degrees(Double(index) * 45))
            }

            ForEach([0.18, 0.29, 0.41], id: \.self) { ratio in
                Circle()
                    .stroke(
                        theme.primaryText.opacity(0.09),
                        lineWidth: ratio == 0.41 ? 1.1 : 0.8
                    )
                    .frame(width: diameter * ratio * 2, height: diameter * ratio * 2)
            }
        }
        .opacity(snapshot.status == .archived ? 0.5 : 1.0)
    }

    private var centerRosette: some View {
        ZStack {
            Circle()
                .stroke(theme.accentColor.opacity(0.55 * activeOpacity), lineWidth: 1.3)
                .frame(width: diameter * 0.16, height: diameter * 0.16)

            Circle()
                .fill(theme.accentColor.opacity(0.14 * activeOpacity))
                .frame(width: diameter * 0.10, height: diameter * 0.10)

            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: diameter * 0.01, style: .continuous)
                    .fill(theme.accentColor.opacity(0.35 * activeOpacity))
                    .frame(width: diameter * 0.025, height: diameter * 0.10)
                    .offset(y: -diameter * 0.07)
                    .rotationEffect(.degrees(Double(index) * 90))
            }
        }
        .scaleEffect(0.92 + (completionRatio * 0.12))
    }

    @ViewBuilder
    private func petalsLayer(
        ringIndex: Int,
        revealedCount: Int,
        radius: CGFloat,
        petalLength: CGFloat,
        petalWidth: CGFloat,
        rotationOffset: Double
    ) -> some View {
        ForEach(0..<7, id: \.self) { index in
            let isActive = index < revealedCount
            let baseRotation = Double(index) * (360.0 / 7.0) + rotationOffset

            ZStack {
                RoundedRectangle(cornerRadius: petalWidth * 1.4, style: .continuous)
                    .stroke(
                        theme.primaryText.opacity(isActive ? 0.10 : 0.07),
                        lineWidth: ringIndex == 0 ? 0.9 : 0.75
                    )
                    .frame(width: petalWidth, height: petalLength)

                RoundedRectangle(cornerRadius: petalWidth * 1.4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accentColor.opacity(isActive ? activeOpacity : 0.03),
                                theme.primaryText.opacity(isActive ? 0.18 : 0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: petalWidth, height: petalLength)
                    .overlay {
                        RoundedRectangle(cornerRadius: petalWidth * 1.4, style: .continuous)
                            .stroke(
                                theme.accentColor.opacity(isActive ? 0.65 * activeOpacity : 0.06),
                                lineWidth: isActive ? 1.0 : 0.5
                            )
                    }
            }
            .offset(y: -radius)
            .rotationEffect(.degrees(baseRotation))
            .scaleEffect(isActive ? 1.0 : 0.92)
            .opacity(isActive ? 1.0 : 0.72)
        }
    }

    private func syncAmbientMotion() {
        guard motionGate.allowsAmbientMotion else {
            ambientBreathing = false
            return
        }

        withAnimation(.easeInOut(duration: 4.6).repeatForever(autoreverses: true)) {
            ambientBreathing = true
        }
    }

    private func triggerBloom() {
        let grow = motionGate.prefersReducedMotion ? 1.015 : 1.05
        let settleAnimation = motionGate.prefersReducedMotion
            ? Animation.easeOut(duration: 0.18)
            : Animation.spring(response: 0.48, dampingFraction: 0.76)

        bloomScale = grow
        withAnimation(settleAnimation) {
            bloomScale = 1.0
        }
    }
}

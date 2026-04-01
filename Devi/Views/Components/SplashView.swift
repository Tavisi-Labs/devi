// MARK: - Views/Components/SplashView.swift
// Animated splash screen — atmospheric brand reveal with star field

import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool

    // MARK: - Animation State
    @State private var showOM = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showBadge = false
    @State private var showVersion = false
    @State private var exitSplash = false

    // MARK: - Star Field
    @State private var stars: [SplashStar] = []

    var body: some View {
        ZStack {
            // 1. Background gradient — matches night palette to avoid pop from launch screen
            LinearGradient(
                colors: [
                    Color(hex: "0A0E1C"),
                    Color(hex: "121A2C"),
                    Color(hex: "1C2438")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 2. Simplified star field — 30 stars, no wisps
            TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    for star in stars {
                        let driftX = sin(time / star.driftPeriodX + star.phaseX) * star.driftAmplitude
                        let driftY = cos(time / star.driftPeriodY + star.phaseY) * star.driftAmplitude * 0.6

                        let x = star.normalizedX * size.width + driftX
                        let y = star.normalizedY * size.height + driftY

                        let twinkle = (sin(time * star.twinkleSpeed + star.twinklePhase) + 1) / 2
                        let brightness = star.baseBrightness * (0.5 + 0.5 * twinkle)

                        let rect = CGRect(
                            x: x - star.size / 2,
                            y: y - star.size / 2,
                            width: star.size,
                            height: star.size
                        )

                        context.opacity = brightness * 0.55
                        context.fill(
                            Ellipse().path(in: rect),
                            with: .color(star.isWarm ? Color(hex: "FFE4C4") : .white)
                        )
                    }
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // 3. Center content
            VStack(spacing: 12) {
                // OM symbol
                Text("\u{0950}")
                    .font(.system(size: 28, design: .serif))
                    .foregroundColor(Color(hex: "D4A857").opacity(0.4))
                    .opacity(showOM ? 1 : 0)

                // "Devi" title with gold gradient
                Text("Devi")
                    .font(.system(size: 48, weight: .light, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "D4A857"), Color(hex: "C9A96E")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(showTitle ? 1.0 : 0.8)
                    .opacity(showTitle ? 1 : 0)

                // "Hindu Panchang" subtitle
                Text("HINDU PANCHANG")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(2.0)
                    .foregroundColor(.white.opacity(0.5))
                    .opacity(showSubtitle ? 1 : 0)

                // "Early Access" capsule badge
                Text("EARLY ACCESS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: "D4A857"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .stroke(Color(hex: "D4A857").opacity(0.4), lineWidth: 0.5)
                    )
                    .opacity(showBadge ? 1 : 0)
                    .padding(.top, 4)

                // Version
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.9.0")")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .opacity(showVersion ? 1 : 0)
                    .padding(.top, 2)
            }
        }
        .opacity(exitSplash ? 0 : 1)
        .offset(y: exitSplash ? -40 : 0)
        .onAppear {
            // Generate stars once
            stars = (0..<30).map { _ in SplashStar.random() }

            // Animation sequence (~1.8s total)
            // T=0ms: OM fades in
            withAnimation(.easeIn(duration: 0.3)) {
                showOM = true
            }

            // T=50ms: "Devi" spring scale-up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showTitle = true
                }
            }

            // T=250ms: "Hindu Panchang" fades in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showSubtitle = true
                }
            }

            // T=450ms: "Early Access" badge fades in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showBadge = true
                }
            }

            // T=550ms: Version fades in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showVersion = true
                }
            }

            // T=1300ms: Exit — curtain rise
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    exitSplash = true
                }
            }

            // T=1850ms: Remove from view tree
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
                isFinished = true
            }
        }
    }
}

// MARK: - Splash Star Model (self-contained, no dependency on StarFieldView)

private struct SplashStar {
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
    let isWarm: Bool

    static func random() -> SplashStar {
        SplashStar(
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
            isWarm: Double.random(in: 0...1) < 0.10
        )
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}

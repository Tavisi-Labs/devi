// MARK: - Views/Components/LivingMandalaView.swift
// Parametric lotus-petal mandala. 21 petals across 3 rings, each drawing
// itself in via a .trim() stroke reveal. Single gold, no scaffolding —
// depth comes from geometry and line weight, not color diversity.

import SwiftUI

enum LivingMandalaEmphasis {
    case teaser
    case ritual
    case poster

    var glowScale: CGFloat {
        switch self {
        case .teaser: return 0.9
        case .ritual: return 1.0
        case .poster: return 1.15
        }
    }
}

// MARK: - LotusPetalShape

/// A parametric lotus petal drawn with mirrored cubic Bezier curves.
/// Symmetric across the vertical axis: pointed at the tip (top),
/// broad through the body, softly rounded at the root (bottom).
///
/// The path begins at the LEFT ROOT and traces counter-clockwise:
/// left edge up to the tip, right edge down to the right root, then a
/// gentle curve across the root to close. This ordering means a
/// `.trim(from: 0, to: progress)` reveal looks like the petal unfurling
/// from its base up and over rather than drawing a stray C-shape.
///
/// `tipSharpness` is animatable via `animatableData` so outer-ring petals
/// can gently breathe without re-creating the Shape each frame.
struct LotusPetalShape: Shape {
    var tipSharpness: CGFloat
    var rootWidth: CGFloat

    var animatableData: CGFloat {
        get { tipSharpness }
        set { tipSharpness = newValue }
    }

    init(tipSharpness: CGFloat = 0.15, rootWidth: CGFloat = 0.42) {
        self.tipSharpness = tipSharpness
        self.rootWidth = rootWidth
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let mid = w / 2
        let halfRoot = w * rootWidth / 2

        // Start at the LEFT root — the reveal climbs outward first.
        path.move(to: CGPoint(x: mid - halfRoot, y: h))

        // Left edge: left root → tip
        path.addCurve(
            to: CGPoint(x: mid, y: 0),
            control1: CGPoint(x: mid - halfRoot * 1.4, y: h * 0.62),
            control2: CGPoint(x: mid - w * tipSharpness, y: h * 0.22)
        )

        // Right edge: tip → right root
        path.addCurve(
            to: CGPoint(x: mid + halfRoot, y: h),
            control1: CGPoint(x: mid + w * tipSharpness, y: h * 0.22),
            control2: CGPoint(x: mid + halfRoot * 1.4, y: h * 0.62)
        )

        // Gentle root curve: right root → left root (softly rounded base)
        path.addQuadCurve(
            to: CGPoint(x: mid - halfRoot, y: h),
            control: CGPoint(x: mid, y: h * 1.05)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - LivingMandalaView

struct LivingMandalaView: View {
    let snapshot: MantraRitualSnapshot
    let theme: DeviTheme
    let diameter: CGFloat
    let motionGate: RitualMotionGate
    var bloomTrigger: Int = 0
    var emphasis: LivingMandalaEmphasis = .teaser

    /// Optional override for the single gold accent. When nil, the teaser tints
    /// with the current time-of-day theme; the ritual screen passes an explicit
    /// vivid gold so the sacred geometry reads against the forced-dark night sky.
    var goldColor: Color? = nil

    @State private var bloomScale: CGFloat = 1.0
    @State private var outerRotation: Double = 0
    @State private var outerBreathing: Bool = false
    @State private var haloBreath: CGFloat = 0.98

    private var gold: Color {
        goldColor ?? theme.accentColor
    }

    /// Ring status → overall brightness. Archived fades to a respectful ghost;
    /// paused holds ~half brightness so the user sees the geometry is waiting.
    private var statusOpacity: Double {
        switch snapshot.status {
        case .archived: return 0.25
        case .paused: return 0.55
        default: return 1.0
        }
    }

    private var haloOpacity: Double {
        switch snapshot.status {
        case .archived: return 0.05
        case .paused: return 0.11
        case .ceremonialCompletion: return 0.26
        default: return 0.17
        }
    }

    private var completionRatio: CGFloat {
        CGFloat(snapshot.completedCount) / CGFloat(MantraRitualState.cycleLength)
    }

    /// Teaser size skips the expensive glow overlays and keeps strokes only.
    private var showGlowDetail: Bool { emphasis != .teaser }

    private var isCycleComplete: Bool {
        snapshot.completedCount >= MantraRitualState.cycleLength
    }

    // MARK: Body

    var body: some View {
        ZStack {
            haloLayer

            petalsLayer(
                ringIndex: 0,
                revealedCount: min(snapshot.completedCount, 7),
                radius: diameter * 0.18,
                petalLength: diameter * 0.20,
                petalWidth: diameter * 0.08,
                lineWeight: ringLineWeight(0),
                ringBrightness: 0.88,
                rotationOffset: 0,
                breathingRing: false
            )

            petalsLayer(
                ringIndex: 1,
                revealedCount: min(max(snapshot.completedCount - 7, 0), 7),
                radius: diameter * 0.30,
                petalLength: diameter * 0.22,
                petalWidth: diameter * 0.07,
                lineWeight: ringLineWeight(1),
                ringBrightness: 0.72,
                rotationOffset: 25.7,
                breathingRing: false
            )

            petalsLayer(
                ringIndex: 2,
                revealedCount: min(max(snapshot.completedCount - 14, 0), 7),
                radius: diameter * 0.42,
                petalLength: diameter * 0.24,
                petalWidth: diameter * 0.06,
                lineWeight: ringLineWeight(2),
                ringBrightness: 0.56,
                rotationOffset: 34.3,
                breathingRing: true
            )
            .rotationEffect(.degrees(outerRotation))

            seedOfLifeCenter
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(bloomScale)
        .accessibilityHidden(true)
        .onAppear { syncAmbientMotion() }
        .onChange(of: motionGate) { _, _ in syncAmbientMotion() }
        .onChange(of: bloomTrigger) { _, _ in triggerBloom() }
    }

    // MARK: Halo

    private var haloLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        gold.opacity(haloOpacity * statusOpacity),
                        gold.opacity(haloOpacity * 0.22 * statusOpacity),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * 0.55 * emphasis.glowScale
                )
            )
            .frame(width: diameter * 1.08, height: diameter * 1.08)
            .scaleEffect(haloBreath)
            .blendMode(showGlowDetail ? .plusLighter : .normal)
    }

    // MARK: Seed of Life Center

    /// Six overlapping circles revealing with completion. No center dot —
    /// the intersecting geometry IS the anchor.
    private var seedOfLifeCenter: some View {
        let revealed = max(1, Int((completionRatio * 6.0).rounded()))
        let scale = 0.88 + (completionRatio * 0.14)

        return Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = size.width * 0.28
            let strokeOpacity = 0.80 * statusOpacity

            let centralPath = Path(ellipseIn: CGRect(
                x: center.x - r, y: center.y - r,
                width: r * 2, height: r * 2
            ))
            context.stroke(
                centralPath,
                with: .color(gold.opacity(strokeOpacity)),
                lineWidth: 1.0
            )

            let shown = min(revealed, 6)
            for i in 0..<shown {
                let angle = Double(i) * (2 * .pi / 6) - .pi / 2
                let cx = center.x + r * cos(angle)
                let cy = center.y + r * sin(angle)
                let petalPath = Path(ellipseIn: CGRect(
                    x: cx - r, y: cy - r,
                    width: r * 2, height: r * 2
                ))
                context.stroke(
                    petalPath,
                    with: .color(gold.opacity(strokeOpacity * 0.72)),
                    lineWidth: 0.9
                )
            }
        }
        .frame(width: diameter * 0.22, height: diameter * 0.22)
        .scaleEffect(scale)
    }

    // MARK: Petals Layer

    private func ringLineWeight(_ ring: Int) -> CGFloat {
        let base: CGFloat
        switch ring {
        case 0: base = 1.5
        case 1: base = 1.2
        default: base = 1.0
        }
        // Teaser renders smaller; scale strokes down so they don't clog.
        return emphasis == .teaser ? max(0.6, base * 0.7) : base
    }

    @ViewBuilder
    private func petalsLayer(
        ringIndex: Int,
        revealedCount: Int,
        radius: CGFloat,
        petalLength: CGFloat,
        petalWidth: CGFloat,
        lineWeight: CGFloat,
        ringBrightness: Double,
        rotationOffset: Double,
        breathingRing: Bool
    ) -> some View {
        ForEach(0..<7, id: \.self) { index in
            let isActive = index < revealedCount
            let baseAngle = Double(index) * (360.0 / 7.0) + rotationOffset

            // Outer ring inhales/exhales via tipSharpness — needs animatableData.
            let ringTipSharpness: CGFloat = breathingRing
                ? (outerBreathing ? 0.22 : 0.12)
                : 0.15
            let petal = LotusPetalShape(tipSharpness: ringTipSharpness, rootWidth: 0.42)

            let strokeAlpha = ringBrightness * statusOpacity
            let fillAlpha = ringBrightness * statusOpacity * 0.30

            ZStack {
                // Stroke — draws itself in via .trim() when this day becomes active.
                petal
                    .trim(from: 0, to: isActive ? 1.0 : 0.0)
                    .stroke(
                        gold.opacity(strokeAlpha),
                        style: StrokeStyle(
                            lineWidth: lineWeight,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .animation(
                        .spring(response: 0.85, dampingFraction: 0.74),
                        value: isActive
                    )

                // Fill — fades in slightly after the stroke leads so the outline
                // inscribes first, then the petal "fills with light."
                petal
                    .fill(
                        LinearGradient(
                            colors: [
                                gold.opacity(fillAlpha),
                                gold.opacity(fillAlpha * 0.22)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(isActive ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.82).delay(0.28),
                        value: isActive
                    )

                // Soft radial bloom on active petals — skipped at teaser size
                // where the extra layers would just muddy the silhouette.
                if showGlowDetail {
                    petal
                        .fill(
                            RadialGradient(
                                colors: [
                                    gold.opacity(0.60 * statusOpacity),
                                    gold.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: petalLength * 0.55
                            )
                        )
                        .blendMode(.plusLighter)
                        .opacity(isActive ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.82).delay(0.42),
                            value: isActive
                        )
                }
            }
            .frame(width: petalWidth, height: petalLength)
            .offset(y: -radius)
            .rotationEffect(.degrees(baseAngle))
        }
    }

    // MARK: Ambient Motion

    private func syncAmbientMotion() {
        guard motionGate.allowsAmbientMotion else {
            outerBreathing = false
            haloBreath = 0.98
            return
        }

        // Slow outer ring rotation — 120s full cycle.
        withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
            outerRotation = 360
        }

        // Outer-ring petals gently inhale/exhale via tipSharpness.
        withAnimation(.easeInOut(duration: 5.4).repeatForever(autoreverses: true)) {
            outerBreathing = true
        }

        // Halo breathes in sync so the whole mandala feels alive.
        withAnimation(.easeInOut(duration: 5.4).repeatForever(autoreverses: true)) {
            haloBreath = 1.03
        }
    }

    // MARK: Bloom on completion

    private func triggerBloom() {
        guard !motionGate.prefersReducedMotion else {
            bloomScale = 1.012
            withAnimation(.easeOut(duration: 0.2)) { bloomScale = 1.0 }
            return
        }

        // Day 21 gets a slightly bigger, more ceremonial settle.
        let peakScale: CGFloat = isCycleComplete ? 1.05 : 1.03

        withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) {
            bloomScale = peakScale
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.74)) {
                bloomScale = 1.0
            }
        }
    }
}

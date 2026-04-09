// MARK: - Views/Components/MantraRitualView.swift
// Consolidated full-screen ritual flow for the Living Mandala.

import SwiftUI
import UIKit

struct MantraRitualView: View {
    @ObservedObject var vm: PanchangViewModel

    // Forced-dark theme for the ritual screen
    private var ritualTheme: DeviTheme {
        DeviTheme.forPeriod(.night, style: vm.themeStyle, appearance: .alwaysDark)
    }

    // One gold for the entire ritual — the mandala gains depth from geometry
    // and line weight, not color diversity. Theme accents are too muted on the
    // forced-dark night sky, so we pin a warm, vivid gold here.
    private let ritualGold = Color(hex: "E8B252")

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    @State private var holdProgress: CGFloat = 0
    @State private var bloomTrigger = 0
    @State private var replayTrigger = 0
    @State private var completionFeedbackTrigger = 0
    @State private var shareCardImage: ShareableCardImage?
    @State private var isRenderingShare = false
    @State private var activeMilestone: MantraRitualMilestone?
    @State private var completionFlash: Double = 0
    @State private var breathingGlowOpacity: Double = 0.5

    // Fix 1b: Pass isVisible so motionGate pauses all mandala animations
    // when the ritual tab is off-screen during a page swipe.
    private var motionGate: RitualMotionGate {
        RitualMotionGate.resolve(scenePhase: scenePhase, reduceMotion: reduceMotion, isVisible: vm.activeTab == 1)
    }

    private var snapshot: MantraRitualSnapshot {
        vm.ritualSnapshot
    }

    private var activeMantra: DailyMantra? {
        vm.currentRitualMantra
    }

    private var prefersDirectCompletionAction: Bool {
        voiceOverEnabled || UIAccessibility.isSwitchControlRunning
    }

    var body: some View {
        ZStack {
            ritualTheme.backgroundGradient
                .ignoresSafeArea()

            // Fix 1b: Explicitly pause StarField when ritual tab not visible
            StarFieldView(
                isDaytime: false,
                timePeriod: .night,
                isPaused: !motionGate.allowsAmbientMotion || vm.activeTab != 1
            )
            .ignoresSafeArea()

            if let activeMantra {
                // Fix 4: Wrap in ScrollView so meaning text is fully readable
                // on shorter devices. Spacers become fixed heights (required
                // because ScrollView has infinite proposed height).
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                            .deviReveal(delay: 0.0, direction: .fadeUp)

                        Spacer().frame(height: 16)

                        // Mandala with ambient celestial glow backdrop
                        ZStack {
                            // Large ambient aura — single warm gold so the mandala
                            // feels like it's radiating one unified light source.
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            ritualGold.opacity(0.14),
                                            ritualGold.opacity(0.05),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 220
                                    )
                                )
                                .frame(width: 440, height: 440)
                                .blur(radius: 30)

                            LivingMandalaView(
                                snapshot: snapshot,
                                theme: ritualTheme,
                                diameter: 320,
                                motionGate: motionGate,
                                bloomTrigger: bloomTrigger,
                                replayTrigger: replayTrigger,
                                emphasis: .ritual,
                                goldColor: ritualGold
                            )
                        }
                        // Fix 3: Tap mandala to replay bloom sequence
                        .onTapGesture { replayTrigger += 1 }
                        .deviReveal(delay: 0.3, direction: .scale)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(snapshot.accessibilitySummary)
                        .accessibilityAction(named: "Replay mandala bloom") { replayTrigger += 1 }

                        Spacer().frame(height: 20)

                        mantraTextSection(activeMantra)
                            .deviEntrance(delay: 1.0)

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
            } else {
                VStack {
                    header
                    Spacer()
                    ProgressView()
                        .tint(ritualTheme.secondaryText)
                    Spacer()
                }
            }

            // Golden completion flash overlay
            ritualGold.opacity(completionFlash)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if let milestone = activeMilestone ?? (snapshot.shouldElevateSharePrompt ? snapshot.milestone : nil) {
                    milestoneRow(milestone)
                }
                completionWell
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(
                LinearGradient(
                    colors: [
                        Color.clear,
                        ritualTheme.deepBackground.opacity(0.88),
                        ritualTheme.deepBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .deviEntrance(delay: 1.2)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: completionFeedbackTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: replayTrigger)
        .onAppear {
            if let milestone = snapshot.shouldElevateSharePrompt ? snapshot.milestone : nil {
                activeMilestone = milestone
                vm.markRitualMilestoneSeen(milestone)
            }
            startBreathingGlow()
        }
        .onChange(of: vm.activeTab) { _, newTab in
            if newTab == 1 { startBreathingGlow() }
        }
    }

    // MARK: - Header

    // Fix 2: Replace .ultraThinMaterial with solid dark background to
    // eliminate frosted-glass bleeding at device corners.
    private var header: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { vm.activeTab = 0 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ritualTheme.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(ritualTheme.deepBackground.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("ritual.close")

            Spacer()

            Text("RITUAL")
                .deviLabel(.caption, theme: ritualTheme)

            Spacer()

            // Share button
            if let shareCardImage {
                ShareLink(
                    item: shareCardImage,
                    preview: SharePreview("Devi Living Mandala")
                ) {
                    headerShareIcon
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ritual.shareAction")
            } else {
                Button {
                    renderShareCard()
                } label: {
                    headerShareIcon
                }
                .buttonStyle(.plain)
                .disabled(isRenderingShare)
                .accessibilityIdentifier("ritual.shareAction")
            }
        }
    }

    private var headerShareIcon: some View {
        Image(systemName: isRenderingShare ? "hourglass" : "square.and.arrow.up")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(ritualTheme.secondaryText)
            .frame(width: 44, height: 44)
            .background(ritualTheme.deepBackground.opacity(0.6))
            .clipShape(Circle())
    }

    // MARK: - Sacred Mantra Text

    @ViewBuilder
    private func mantraTextSection(_ mantra: DailyMantra) -> some View {
        VStack(spacing: 14) {
            // Day label
            if let dayLabel = snapshot.dayLabel {
                Text(dayLabel)
                    .deviLabel(.sacredTitle, theme: ritualTheme)
            }

            // Deity context banner
            deityContextBanner(mantra)

            // Devanagari with breathing gold glow
            ZStack {
                // Wide glow halo (blurred duplicate) — actually visible
                Text(mantra.devanagari)
                    .scaledFont(size: 38, design: .serif)
                    .foregroundColor(ritualGold.opacity(breathingGlowOpacity * 0.4))
                    .blur(radius: 20)
                    .allowsHitTesting(false)

                // Main text
                Text(mantra.devanagari)
                    .scaledFont(size: 38, design: .serif)
                    .foregroundColor(ritualTheme.primaryText)
            }
            .multilineTextAlignment(.center)
            .lineSpacing(5)

            // Transliteration
            Text(mantra.transliteration)
                .scaledFont(size: 17, weight: .regular, design: .serif)
                .italic()
                .foregroundColor(ritualTheme.secondaryText.opacity(0.7))
                .tracking(0.5)
                .multilineTextAlignment(.center)

            // Meaning
            Text(mantra.meaning)
                .deviLabel(.sacredBody, theme: ritualTheme)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 4)
        }
        .padding(.horizontal, 30)
    }

    private func deityContextBanner(_ mantra: DailyMantra) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ritualGold)
                .frame(width: 5, height: 5)

            Text(mantra.deity.uppercased())
                .deviLabel(.caption, theme: ritualTheme)

            if let milestone = activeMilestone ?? snapshot.milestone,
               snapshot.shareStyle == .invited {
                Text("\u{00B7}")
                    .foregroundColor(ritualTheme.secondaryText)
                Text(milestone.title)
                    .scaledFont(size: 12, weight: .semibold, design: .serif)
                    .foregroundColor(ritualTheme.accentColor.opacity(0.9))
            }
        }
    }

    // MARK: - Breathing Glow

    private func startBreathingGlow() {
        guard !motionGate.prefersReducedMotion else {
            breathingGlowOpacity = 0.5  // Static
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathingGlowOpacity = 1.0
            }
        }
    }

    // MARK: - Completion Well

    private var completionWell: some View {
        VStack(spacing: 10) {
            if prefersDirectCompletionAction {
                Button {
                    completeRitual()
                } label: {
                    actionWellLabel(icon: snapshot.completedToday ? "checkmark.circle.fill" : "sparkles")
                }
                .buttonStyle(.plain)
                .disabled(!snapshot.canCompleteToday)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("ritual.completionWell")
            } else {
                actionWellLabel(icon: snapshot.completedToday ? "checkmark.circle.fill" : "sparkles")
                .overlay {
                    RitualLongPressCaptureView(
                        minimumDuration: 0.9,
                        maximumDistance: 36,
                        isEnabled: snapshot.canCompleteToday,
                        accessibilityLabel: snapshot.actionTitle,
                        accessibilityHint: "Press and hold to seal today\u{2019}s ritual."
                    ) { isPressing in
                        updateHoldProgress(isPressing)
                    } onCompleted: {
                        completeRitual()
                    }
                }
                .opacity(snapshot.canCompleteToday ? 1.0 : 0.92)
            }

            if snapshot.status == .paused {
                Text("The geometry stays with you. One chant resumes the same mandala.")
                    .deviLabel(.detail, theme: ritualTheme)
                    .multilineTextAlignment(.center)
            } else if snapshot.status == .archived {
                Text("The previous mandala has settled. Begin again when you are ready.")
                    .deviLabel(.detail, theme: ritualTheme)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // Fix 5: Redesigned action well — centered VStack, gold gradient border,
    // layered background, shadow aura. Sacred aesthetic.
    private func actionWellLabel(icon: String) -> some View {
        VStack(spacing: 12) {
            // Progress ring (smaller 56pt, angular gradient sweep)
            ZStack {
                Circle()
                    .stroke(ritualTheme.primaryText.opacity(0.10), lineWidth: 2)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        AngularGradient(
                            colors: [ritualGold.opacity(0.6), ritualGold, ritualGold.opacity(0.6)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)

                // Golden halo during hold
                if holdProgress > 0 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ritualGold.opacity(0.45 * holdProgress),
                                    ritualGold.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 16,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                }

                // Icon with gold glow when completed
                ZStack {
                    if snapshot.completedToday {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ritualGold.opacity(0.5))
                            .blur(radius: 8)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(snapshot.canCompleteToday ? ritualGold :
                                         snapshot.completedToday ? ritualGold :
                                         ritualTheme.primaryText.opacity(0.65))
                }
            }

            // Title
            Text(snapshot.actionTitle)
                .scaledFont(size: 16, weight: .semibold, design: .serif)
                .foregroundColor(ritualTheme.primaryText)

            // Subtitle — sacred language
            Text(snapshot.completedToday ? "The day\u{2019}s light is sealed" :
                 prefersDirectCompletionAction ? "Accessible direct action" :
                 "Press and hold to seal")
                .scaledFont(size: 12, weight: .medium)
                .foregroundColor(ritualTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        ritualGold.opacity(snapshot.canCompleteToday ? 0.10 : 0.05),
                        ritualGold.opacity(snapshot.canCompleteToday ? 0.04 : 0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                // Radial warmth from top center
                RadialGradient(
                    colors: [
                        ritualGold.opacity(0.06),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 200
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [ritualGold.opacity(0.35), ritualGold.opacity(0.10)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: ritualGold.opacity(0.12), radius: 12, x: 0, y: 4)
    }

    // MARK: - Milestone

    private func milestoneRow(_ milestone: MantraRitualMilestone) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ritualTheme.accentColor)
            Text(milestone.title)
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundColor(ritualTheme.primaryText)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ritualTheme.accentColor.opacity(0.09))
        .deviCard(theme: ritualTheme, elevation: .flat, cornerRadius: 16)
    }

    // MARK: - Actions

    private func updateHoldProgress(_ isPressing: Bool) {
        guard snapshot.canCompleteToday, !prefersDirectCompletionAction else {
            holdProgress = 0
            return
        }

        if isPressing {
            holdProgress = 0
            withAnimation(.linear(duration: 0.9)) {
                holdProgress = 1
            }
        } else if holdProgress < 1 {
            withAnimation(.easeOut(duration: 0.16)) {
                holdProgress = 0
            }
        }
    }

    private func completeRitual() {
        guard snapshot.canCompleteToday else { return }

        let result = vm.completeTodayRitual()
        guard result.completedNewDay else {
            holdProgress = 0
            return
        }

        holdProgress = 0
        bloomTrigger += 1
        completionFeedbackTrigger += 1

        // Golden flash (skip if reduced motion)
        if !motionGate.prefersReducedMotion {
            completionFlash = 0.25
            withAnimation(.easeOut(duration: 0.6)) {
                completionFlash = 0
            }
        }

        if let milestone = result.milestone {
            activeMilestone = milestone
            vm.markRitualMilestoneSeen(milestone)
        }
    }

    private func renderShareCard() {
        guard let panchang = vm.todayPanchang, let mantra = activeMantra else { return }
        isRenderingShare = true

        Task { @MainActor in
            shareCardImage = ShareCardRenderer.renderRitualCardAsTransferable(
                panchang: panchang,
                city: vm.currentCity,
                mantra: mantra,
                ritualSnapshot: vm.ritualSnapshot,
                theme: vm.theme
            )
            isRenderingShare = false
        }
    }
}

// MARK: - RitualLongPressCaptureView (UIViewRepresentable)

private struct RitualLongPressCaptureView: UIViewRepresentable {
    let minimumDuration: TimeInterval
    let maximumDistance: CGFloat
    let isEnabled: Bool
    let accessibilityLabel: String
    let accessibilityHint: String
    let onPressingChanged: (Bool) -> Void
    let onCompleted: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isAccessibilityElement = true

        let gesture = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePress(_:))
        )
        gesture.minimumPressDuration = 0
        gesture.allowableMovement = maximumDistance
        view.addGestureRecognizer(gesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        uiView.isUserInteractionEnabled = isEnabled
        uiView.accessibilityIdentifier = "ritual.completionWell"
        uiView.accessibilityLabel = accessibilityLabel
        uiView.accessibilityHint = accessibilityHint
        uiView.accessibilityTraits = isEnabled ? [.button] : [.button, .notEnabled]
    }

    final class Coordinator: NSObject {
        var parent: RitualLongPressCaptureView
        private var completionWorkItem: DispatchWorkItem?

        init(parent: RitualLongPressCaptureView) {
            self.parent = parent
        }

        @objc func handlePress(_ gesture: UILongPressGestureRecognizer) {
            guard parent.isEnabled else { return }

            switch gesture.state {
            case .began:
                completionWorkItem?.cancel()
                parent.onPressingChanged(true)

                let workItem = DispatchWorkItem { [weak self] in
                    self?.parent.onCompleted()
                }
                completionWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + parent.minimumDuration, execute: workItem)

            case .ended, .cancelled, .failed:
                completionWorkItem?.cancel()
                completionWorkItem = nil
                parent.onPressingChanged(false)

            default:
                break
            }
        }
    }
}

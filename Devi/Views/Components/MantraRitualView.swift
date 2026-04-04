// MARK: - Views/Components/MantraRitualView.swift
// Consolidated full-screen ritual flow for the Living Mandala.

import SwiftUI
import UIKit

struct MantraRitualView: View {
    @ObservedObject var vm: PanchangViewModel
    let mantra: DailyMantra
    let theme: DeviTheme

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    @State private var holdProgress: CGFloat = 0
    @State private var bloomTrigger = 0
    @State private var completionFeedbackTrigger = 0
    @State private var shareCardImage: ShareableCardImage?
    @State private var isRenderingShare = false
    @State private var activeMilestone: MantraRitualMilestone?

    private var motionGate: RitualMotionGate {
        RitualMotionGate.resolve(scenePhase: scenePhase, reduceMotion: reduceMotion)
    }

    private var snapshot: MantraRitualSnapshot {
        vm.ritualSnapshot
    }

    private var activeMantra: DailyMantra {
        vm.currentRitualMantra ?? mantra
    }

    private var prefersDirectCompletionAction: Bool {
        voiceOverEnabled || UIAccessibility.isSwitchControlRunning
    }

    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()

            StarFieldView(
                isDaytime: vm.isDaytime,
                timePeriod: vm.timePeriod,
                isPaused: !motionGate.allowsAmbientMotion
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    header

                    LivingMandalaView(
                        snapshot: snapshot,
                        theme: theme,
                        diameter: 286,
                        motionGate: motionGate,
                        bloomTrigger: bloomTrigger,
                        emphasis: .ritual
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(snapshot.accessibilitySummary)

                    VStack(spacing: 10) {
                        if let dayLabel = snapshot.dayLabel {
                            Text(dayLabel)
                                .deviLabel(.caption, theme: theme)
                        }

                        Text(snapshot.continuityText)
                            .scaledFont(size: 15, weight: .medium, design: .serif)
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)

                        if let milestone = activeMilestone ?? snapshot.milestone,
                           snapshot.shareStyle == .invited {
                            Text(milestone.title)
                                .scaledFont(size: 13, weight: .semibold, design: .serif)
                                .foregroundColor(theme.accentColor.opacity(0.9))
                        }
                    }

                    VStack(spacing: 14) {
                        Text(activeMantra.devanagari)
                            .scaledFont(size: 34, design: .serif)
                            .foregroundColor(theme.primaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)

                        Text(activeMantra.transliteration)
                            .scaledFont(size: 18, weight: .regular, design: .serif)
                            .foregroundColor(theme.secondaryText)
                            .italic()
                            .multilineTextAlignment(.center)

                        Text(activeMantra.meaning)
                            .deviLabel(.detail, theme: theme)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 30)

                    mantraDetailStrip
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 220)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if let milestone = activeMilestone ?? (snapshot.shouldElevateSharePrompt ? snapshot.milestone : nil) {
                    milestoneRow(milestone)
                }

                completionWell
                shareRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(
                LinearGradient(
                    colors: [
                        Color.clear,
                        theme.deepBackground.opacity(0.78),
                        theme.deepBackground.opacity(0.94)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: completionFeedbackTrigger)
        .onAppear {
            if let milestone = snapshot.shouldElevateSharePrompt ? snapshot.milestone : nil {
                activeMilestone = milestone
                vm.markRitualMilestoneSeen(milestone)
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("ritual.close")

            Spacer()

            Text("RITUAL")
                .deviLabel(.caption, theme: theme)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private var mantraDetailStrip: some View {
        HStack(spacing: 12) {
            ritualFact(title: "DEITY", value: activeMantra.deity)
            ritualFact(title: "REPETITIONS", value: "\(activeMantra.repetitions)")
            ritualFact(title: "BEST TIME", value: activeMantra.bestTimeToChant)
        }
    }

    private func ritualFact(title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .deviLabel(.caption, theme: theme)
            Text(value)
                .scaledFont(size: 13, weight: .medium, design: .serif)
                .foregroundColor(theme.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 74)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .deviCard(theme: theme, elevation: .flat, cornerRadius: 14)
    }

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
                        accessibilityHint: "Press and hold to complete today's ritual."
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
                    .deviLabel(.detail, theme: theme)
                    .multilineTextAlignment(.center)
            } else if snapshot.status == .archived {
                Text("The previous mandala has settled. Begin again when you are ready.")
                    .deviLabel(.detail, theme: theme)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func actionWellLabel(icon: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(theme.primaryText.opacity(0.10), lineWidth: 2)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        theme.accentColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(snapshot.canCompleteToday ? theme.accentColor : theme.primaryText.opacity(0.65))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.actionTitle)
                    .scaledFont(size: 16, weight: .semibold, design: .serif)
                    .foregroundColor(theme.primaryText)

                Text(prefersDirectCompletionAction ? "Accessible direct action" : "Press and hold to complete")
                    .scaledFont(size: 12, weight: .medium)
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(theme.accentColor.opacity(snapshot.canCompleteToday ? 0.08 : 0.05))
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 24)
    }

    private func milestoneRow(_ milestone: MantraRitualMilestone) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.accentColor)
            Text(milestone.title)
                .scaledFont(size: 13, weight: .semibold, design: .serif)
                .foregroundColor(theme.primaryText)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.accentColor.opacity(0.09))
        .deviCard(theme: theme, elevation: .flat, cornerRadius: 16)
    }

    @ViewBuilder
    private var shareRow: some View {
        let invited = snapshot.shareStyle == .invited

        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(invited ? "Share this mandala" : "Quiet share")
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(theme.primaryText)

                Text(invited ? "A poster version is ready." : "Available whenever you want it.")
                    .scaledFont(size: 12)
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            if let shareCardImage {
                ShareLink(
                    item: shareCardImage,
                    preview: SharePreview("Devi Living Mandala")
                ) {
                    shareActionLabel(invited: invited, isLoading: false)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ritual.shareAction")
            } else {
                Button {
                    renderShareCard()
                } label: {
                    shareActionLabel(invited: invited, isLoading: isRenderingShare)
                }
                .buttonStyle(.plain)
                .disabled(isRenderingShare)
                .accessibilityIdentifier("ritual.shareAction")
            }
        }
        .padding(.horizontal, 2)
    }

    private func shareActionLabel(invited: Bool, isLoading: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isLoading ? "hourglass" : "square.and.arrow.up")
                .font(.system(size: 12, weight: .semibold))
            Text(invited ? "Share" : "Export")
                .scaledFont(size: 12, weight: .semibold)
        }
        .foregroundColor(invited ? theme.accentColor : theme.secondaryText)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background((invited ? theme.accentColor.opacity(0.11) : .clear))
        .overlay {
            Capsule()
                .stroke(invited ? theme.accentColor.opacity(0.26) : theme.primaryText.opacity(0.12), lineWidth: 1)
        }
        .clipShape(Capsule())
    }

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

        if let milestone = result.milestone {
            activeMilestone = milestone
            vm.markRitualMilestoneSeen(milestone)
        }
    }

    private func renderShareCard() {
        guard let panchang = vm.todayPanchang else { return }
        isRenderingShare = true

        Task { @MainActor in
            shareCardImage = ShareCardRenderer.renderRitualCardAsTransferable(
                panchang: panchang,
                city: vm.currentCity,
                mantra: activeMantra,
                ritualSnapshot: vm.ritualSnapshot,
                theme: theme
            )
            isRenderingShare = false
        }
    }
}

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

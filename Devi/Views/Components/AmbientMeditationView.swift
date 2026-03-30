// MARK: - Views/Components/AmbientMeditationView.swift
// Full-screen meditation mode with breathing circle, mantra, and live sky

import SwiftUI

struct AmbientMeditationView: View {
    @ObservedObject var vm: PanchangViewModel
    @Environment(\.dismiss) private var dismiss

    /// Breathing phase: inhale 4s → hold 2s → exhale 4s → hold 2s (= 12s cycle)
    enum BreathPhase: CaseIterable {
        case inhale, holdIn, exhale, holdOut

        var label: String {
            switch self {
            case .inhale:  return "Breathe In"
            case .holdIn:  return "Hold"
            case .exhale:  return "Breathe Out"
            case .holdOut: return "Hold"
            }
        }

        var circleScale: CGFloat {
            switch self {
            case .inhale:  return 1.0
            case .holdIn:  return 1.0
            case .exhale:  return 0.6
            case .holdOut: return 0.6
            }
        }

        var circleOpacity: Double {
            switch self {
            case .inhale:  return 0.5
            case .holdIn:  return 0.5
            case .exhale:  return 0.25
            case .holdOut: return 0.25
            }
        }

        /// Unique index per phase so `.onChange` can detect every transition
        var index: Int {
            switch self {
            case .inhale:  return 0
            case .holdIn:  return 1
            case .exhale:  return 2
            case .holdOut: return 3
            }
        }
    }

    /// Incremented at each breath phase transition for haptic feedback
    @State private var breathTrigger: Int = 0

    var body: some View {
        ZStack {
            // Background: same theme gradient for seamless feel
            vm.theme.backgroundGradient
                .ignoresSafeArea()

            // Elevated star field
            StarFieldView(isDaytime: false, timePeriod: .night)
                .ignoresSafeArea()
                .opacity(0.7)

            // Main content
            VStack(spacing: 40) {
                Spacer()

                // Current time (large)
                Text(vm.currentTimeText)
                    .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                    .foregroundColor(vm.theme.primaryText)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                // Breathing circle
                PhaseAnimator(BreathPhase.allCases) { phase in
                    VStack(spacing: 16) {
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(vm.theme.accentColor.opacity(phase.circleOpacity * 0.3))
                                .frame(width: 200, height: 200)
                                .scaleEffect(phase.circleScale * 1.2)
                                .blur(radius: 20)

                            // Main circle
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            vm.theme.accentColor.opacity(phase.circleOpacity),
                                            vm.theme.accentColor.opacity(phase.circleOpacity * 0.3)
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 160, height: 160)
                                .scaleEffect(phase.circleScale)

                            // Inner ring
                            Circle()
                                .stroke(vm.theme.accentColor.opacity(0.4), lineWidth: 1)
                                .frame(width: 120, height: 120)
                                .scaleEffect(phase.circleScale)
                        }

                        Text(phase.label.uppercased())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(vm.theme.secondaryText)
                            .tracking(4)
                            .contentTransition(.interpolate)
                    }
                    .onChange(of: phase.index) { _, _ in
                        breathTrigger += 1
                    }
                } animation: { phase in
                    switch phase {
                    case .inhale:  .easeInOut(duration: 4.0)
                    case .holdIn:  .easeInOut(duration: 2.0)
                    case .exhale:  .easeInOut(duration: 4.0)
                    case .holdOut: .easeInOut(duration: 2.0)
                    }
                }

                Spacer()

                // Day's mantra
                if let mantra = PanchangDescriptions.dailyMantra(
                    for: Calendar.current.component(.weekday, from: Date())
                ) {
                    VStack(spacing: 8) {
                        Text(mantra.devanagari)
                            .font(.system(size: 34, weight: .regular, design: .serif))
                            .foregroundColor(vm.theme.primaryText)
                            .multilineTextAlignment(.center)

                        Text(mantra.transliteration)
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundColor(vm.theme.secondaryText)
                            .italic()
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()

                // Compact sun arc (if daytime)
                if let solar = vm.todayPanchang?.solar, vm.isDaytime {
                    SunArcView(
                        progress: vm.sunProgress,
                        isDaytime: true,
                        sunrise: solar.sunrise,
                        sunset: solar.sunset,
                        moonrise: nil,
                        moonset: nil,
                        currentTime: "",
                        countdownText: vm.countdownText,
                        countdownLabel: vm.countdownLabel,
                        theme: vm.theme,
                        timePeriod: vm.timePeriod,
                        themeStyle: vm.themeStyle,
                        timezoneIdentifier: vm.currentCity.timezoneIdentifier
                    )
                    .scaleEffect(0.6)
                    .frame(height: 100)
                    .opacity(0.5)
                }

                // Dismiss hint
                Text("Tap anywhere to return")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(vm.theme.secondaryText.opacity(0.4))
                    .padding(.bottom, 32)
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.3), trigger: breathTrigger)
        .onTapGesture {
            dismiss()
        }
        .statusBarHidden()
    }
}

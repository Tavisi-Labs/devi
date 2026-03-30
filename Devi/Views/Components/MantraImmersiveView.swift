// MARK: - Views/Components/MantraImmersiveView.swift
// Full-screen meditation focus — immersive mantra experience

import SwiftUI

struct MantraImmersiveView: View {
    let mantra: DailyMantra
    let theme: DeviTheme

    @Environment(\.dismiss) private var dismiss
    @State private var appeared: Bool = false
    @State private var breatheIn: Bool = false
    @State private var breathLabel: String = ""
    @State private var breathingActive: Bool = true

    var body: some View {
        ZStack {
            // Calming dark atmosphere
            theme.backgroundGradient.ignoresSafeArea()
            StarFieldView(isDaytime: false, timePeriod: .night)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Dismiss button (top-left)
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.secondaryText)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                // Centered mantra content
                VStack(spacing: 28) {
                    // Devanagari (large, centered)
                    Text(mantra.devanagari)
                        .font(.system(size: 30, weight: .regular))
                        .foregroundColor(theme.primaryText)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 1.5), value: appeared)

                    // Transliteration
                    Text(mantra.transliteration)
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundColor(theme.secondaryText)
                        .italic()
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 1.5).delay(0.5), value: appeared)

                    // Meaning
                    Text(mantra.meaning)
                        .deviLabel(.insight, theme: theme)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 1.0).delay(0.8), value: appeared)

                    // Breathing guide circle
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(theme.primaryText.opacity(0.08), lineWidth: 1)
                                .frame(width: 100, height: 100)

                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [theme.accentColor.opacity(0.15), .clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: breatheIn ? 45 : 20
                                    )
                                )
                                .frame(width: breatheIn ? 90 : 40, height: breatheIn ? 90 : 40)
                                .animation(.easeInOut(duration: 4), value: breatheIn)

                            Circle()
                                .fill(theme.accentColor.opacity(0.25))
                                .frame(width: breatheIn ? 30 : 12, height: breatheIn ? 30 : 12)
                                .animation(.easeInOut(duration: 4), value: breatheIn)
                        }

                        Text(breathLabel)
                            .scaledFont(size: 12, weight: .medium)
                            .foregroundColor(theme.secondaryText.opacity(0.6))
                            .animation(.easeInOut(duration: 0.5), value: breathLabel)
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 1.0).delay(1.5), value: appeared)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Bottom info cards
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Deity + Day
                        HStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Text(mantra.deity)
                                    .scaledFont(size: 16, weight: .medium, design: .serif)
                                    .foregroundColor(theme.primaryText)
                                Text("DEITY")
                                    .deviLabel(.caption, theme: theme)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)

                            VStack(spacing: 4) {
                                Text(weekdayName(for: mantra.weekday))
                                    .scaledFont(size: 16, weight: .medium)
                                    .foregroundColor(theme.primaryText)
                                Text("DAY")
                                    .deviLabel(.caption, theme: theme)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
                        }

                        // Practice details
                        HStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Text("\(mantra.repetitions)")
                                    .scaledFont(size: 16, weight: .semibold, design: .monospaced)
                                    .foregroundColor(theme.primaryText)
                                Text("REPETITIONS")
                                    .deviLabel(.caption, theme: theme)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)

                            VStack(spacing: 4) {
                                Text(mantra.bestTimeToChant)
                                    .scaledFont(size: 13, weight: .medium)
                                    .foregroundColor(theme.primaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("BEST TIME")
                                    .deviLabel(.caption, theme: theme)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
                        }

                        // Significance
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SIGNIFICANCE")
                                .deviLabel(.caption, theme: theme)
                            Text(mantra.significance)
                                .deviLabel(.detail, theme: theme)
                                .lineSpacing(3)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .deviCard(theme: theme, elevation: .raised, cornerRadius: 14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .frame(maxHeight: 300)
                .deviReveal(delay: 0.5, direction: .fadeUp)
            }
        }
        .onAppear {
            appeared = true
            startBreathingCycle()
        }
        .onDisappear {
            breathingActive = false
        }
    }

    // MARK: - Breathing Cycle

    private func startBreathingCycle() {
        // Start first cycle after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard breathingActive else { return }
            breatheInCycle()
        }
    }

    private func breatheInCycle() {
        guard breathingActive else { return }
        breathLabel = "Breathe in..."
        withAnimation { breatheIn = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            guard breathingActive else { return }
            breathLabel = "Breathe out..."
            withAnimation { breatheIn = false }

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                breatheInCycle()
            }
        }
    }

    // MARK: - Helpers

    private func weekdayName(for weekday: Int) -> String {
        switch weekday {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return ""
        }
    }
}

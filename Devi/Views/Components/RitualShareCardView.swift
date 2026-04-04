// MARK: - Views/Components/RitualShareCardView.swift
// Static poster renderer for the Living Mandala share flow.

import SwiftUI

struct RitualShareCardView: View {
    let panchang: DailyPanchang
    let city: UserCity
    let mantra: DailyMantra
    let ritualSnapshot: MantraRitualSnapshot
    let theme: DeviTheme

    private let posterMotionGate = RitualMotionGate(
        allowsAmbientMotion: false,
        prefersReducedMotion: true
    )

    var body: some View {
        ZStack {
            theme.backgroundGradient

            VStack(spacing: 0) {
                Spacer().frame(height: 90)

                Text("DEVI")
                    .font(.system(size: 48, weight: .light, design: .serif))
                    .foregroundColor(theme.primaryText)
                    .tracking(12)

                Spacer().frame(height: 14)

                Text(ritualSnapshot.continuityText.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                    .tracking(3)

                Spacer().frame(height: 34)

                if let dayLabel = ritualSnapshot.dayLabel {
                    Text(dayLabel)
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundColor(theme.accentColor)
                }

                if let milestone = ritualSnapshot.milestone,
                   ritualSnapshot.shareStyle == .invited {
                    Spacer().frame(height: 6)

                    Text(milestone.title)
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundColor(theme.secondaryText)
                }

                Spacer().frame(height: 52)

                LivingMandalaView(
                    snapshot: ritualSnapshot,
                    theme: theme,
                    diameter: 400,
                    motionGate: posterMotionGate,
                    emphasis: .poster
                )

                Spacer().frame(height: 56)

                Text(mantra.devanagari)
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 120)

                Spacer().frame(height: 10)

                Text(mantra.transliteration)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(theme.secondaryText)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 120)

                Spacer().frame(height: 34)

                Text(formattedDateLine)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.secondaryText)

                Spacer()

                Rectangle()
                    .fill(theme.accentColor.opacity(0.24))
                    .frame(height: 1)
                    .padding(.horizontal, 80)

                Spacer().frame(height: 22)

                Text("deviapp.com")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(theme.secondaryText.opacity(0.55))
                    .tracking(2)

                Spacer().frame(height: 42)
            }

            RoundedRectangle(cornerRadius: 0)
                .stroke(theme.accentColor.opacity(0.18), lineWidth: 2)
                .padding(20)
        }
        .frame(width: 1080, height: 1920)
    }

    private var formattedDateLine: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = TimeZone(identifier: city.timezoneIdentifier) ?? .current
        return "\(formatter.string(from: panchang.solar.sunrise)) · \(city.name)"
    }
}

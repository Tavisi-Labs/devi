// MARK: - Views/Components/DailyHoroscopeCard.swift
// Home screen horoscope card — theme statement, do/don't, category capsules, mantra

import SwiftUI

struct DailyHoroscopeCard: View {
    let horoscope: DailyHoroscope
    let theme: DeviTheme
    let onTapWhy: () -> Void

    @State private var expandedCategory: HoroscopeCategory? = nil
    @State private var isTextExpanded = false
    @State private var isDosDontsExpanded = false
    @State private var dosDontsGlowPhase: Bool = false

    // MARK: - Constants

    private let goldAccent = Color(hex: "D4A040")
    private let intensityDotSize: CGFloat = 4
    private let maxIntensity = 5
    private let colorSwatchSize: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            themeStatementSection
            supportingTextSection
            doAndDontSection
            thinDivider
            categoryCapsuleSection
            mantraAndColorRow
            whyButton
        }
        .padding(20)
        .deviCard(theme: theme, elevation: .prominent)
        .deviReveal(delay: 0.1, direction: .fadeUp)
    }

    // MARK: - 1. Header

    private var headerSection: some View {
        Text("YOUR DAY")
            .scaledFont(size: 11, weight: .bold)
            .foregroundColor(theme.secondaryText)
            .tracking(2)
    }

    // MARK: - 2. Theme Statement

    private var themeStatementSection: some View {
        Text(horoscope.themeStatement)
            .scaledFont(size: 26, weight: .regular, design: .serif)
            .foregroundColor(theme.accentColor)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - 3. Supporting Text

    private var supportingTextSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(horoscope.supportingText)
                .scaledFont(size: 15, weight: .regular)
                .foregroundColor(theme.secondaryText)
                .lineSpacing(3)
                .lineLimit(isTextExpanded ? nil : 4)
                .animation(.easeInOut(duration: 0.25), value: isTextExpanded)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isTextExpanded.toggle()
                }
            } label: {
                Text(isTextExpanded ? "Show less" : "Read more")
                    .scaledFont(size: 12, weight: .medium)
                    .foregroundColor(goldAccent)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 4. Do / Don't — Sacred Duality Tablet

    private var doAndDontSection: some View {
        VStack(spacing: 0) {
            dualTintedHeader

            if isDosDontsExpanded {
                expandedGuidanceContent
            }
        }
        .background(splitGradientBackground)
        .overlay(dualAccentBars)
        .overlay(expandedRadialGlow)
        .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
    }

    // MARK: Collapsed Header — Dual-Tinted

    private var dualTintedHeader: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                isDosDontsExpanded.toggle()
            }
            if !isDosDontsExpanded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    dosDontsGlowPhase = false
                }
            }
        } label: {
            HStack(spacing: 0) {
                // Do side — icon then label
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13))
                        .foregroundColor(theme.auspiciousColor)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("DO")
                            .scaledFont(size: 12, weight: .bold)
                            .tracking(1.5)
                            .foregroundColor(theme.auspiciousColor)
                        Text("\(horoscope.doList.count) guidelines")
                            .scaledFont(size: 10, weight: .regular)
                            .foregroundColor(theme.secondaryText.opacity(0.6))
                    }
                }

                Spacer()

                // Center diamond fulcrum
                Image(systemName: "diamond.fill")
                    .font(.system(size: 5))
                    .foregroundColor(goldAccent.opacity(0.4))

                Spacer()

                // Don't side — label then icon (mirrored)
                HStack(spacing: 5) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("DON\u{2019}T")
                            .scaledFont(size: 12, weight: .bold)
                            .tracking(1.5)
                            .foregroundColor(theme.inauspiciousColor)
                        Text("\(horoscope.dontList.count) cautions")
                            .scaledFont(size: 10, weight: .regular)
                            .foregroundColor(theme.secondaryText.opacity(0.6))
                    }
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 13))
                        .foregroundColor(theme.inauspiciousColor)
                }

                // Chevron
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.secondaryText.opacity(0.5))
                    .rotationEffect(.degrees(isDosDontsExpanded ? 180 : 0))
                    .padding(.leading, 8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: Split Gradient Background

    private var splitGradientBackground: some View {
        let tint: Double = isDosDontsExpanded ? 0.08 : 0.04
        return GeometryReader { geo in
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [theme.auspiciousColor.opacity(tint), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width / 2)

                LinearGradient(
                    colors: [.clear, theme.inauspiciousColor.opacity(tint)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width / 2)
            }
        }
    }

    // MARK: Vertical Accent Bars

    private var dualAccentBars: some View {
        HStack {
            RoundedRectangle(cornerRadius: 1)
                .fill(theme.auspiciousColor.opacity(0.5))
                .frame(width: 2)
            Spacer()
            RoundedRectangle(cornerRadius: 1)
                .fill(theme.inauspiciousColor.opacity(0.5))
                .frame(width: 2)
        }
        .allowsHitTesting(false)
    }

    // MARK: Radial Glow Overlay

    @ViewBuilder
    private var expandedRadialGlow: some View {
        if isDosDontsExpanded {
            ZStack {
                RadialGradient(
                    colors: [theme.auspiciousColor.opacity(dosDontsGlowPhase ? 0.06 : 0.02), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 150
                )
                RadialGradient(
                    colors: [theme.inauspiciousColor.opacity(dosDontsGlowPhase ? 0.06 : 0.02), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 150
                )
            }
            .allowsHitTesting(false)
            .transition(.opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    dosDontsGlowPhase = true
                }
            }
        }
    }

    // MARK: Expanded Guidance Content

    private var expandedGuidanceContent: some View {
        VStack(spacing: 12) {
            OrnamentalDivider("GUIDANCE", theme: theme)
                .deviReveal(delay: 0.05, direction: .fadeUp)

            HStack(alignment: .top, spacing: 0) {
                // Do column
                VStack(spacing: 8) {
                    ForEach(Array(horoscope.doList.enumerated()), id: \.offset) { index, item in
                        doItemCard(item, index: index)
                            .deviReveal(delay: 0.15 + Double(index) * 0.08, direction: .fadeLeft)
                    }
                }
                .frame(maxWidth: .infinity)

                // Center spine
                guidanceSpine(itemCount: max(horoscope.doList.count, horoscope.dontList.count))

                // Don't column
                VStack(spacing: 8) {
                    ForEach(Array(horoscope.dontList.enumerated()), id: \.offset) { index, item in
                        dontItemCard(item, index: index)
                            .deviReveal(delay: 0.15 + Double(index) * 0.08, direction: .fadeRight)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 14)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: Do Item Card

    private func doItemCard(_ text: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle()
                    .fill(theme.auspiciousColor.opacity(0.12))
                Text("\(index + 1)")
                    .scaledFont(size: 11, weight: .semibold)
                    .foregroundColor(theme.auspiciousColor)
            }
            .frame(width: 20, height: 20)

            Text(text)
                .scaledFont(size: 13, weight: .regular)
                .foregroundColor(theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(theme.auspiciousColor.opacity(0.03))
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1)
                .fill(theme.auspiciousColor.opacity(0.3))
                .frame(width: 2)
        }
    }

    // MARK: Don't Item Card (Mirrored)

    private func dontItemCard(_ text: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(text)
                .scaledFont(size: 13, weight: .regular)
                .foregroundColor(theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)

            ZStack {
                Circle()
                    .fill(theme.inauspiciousColor.opacity(0.12))
                Text("\(index + 1)")
                    .scaledFont(size: 11, weight: .semibold)
                    .foregroundColor(theme.inauspiciousColor)
            }
            .frame(width: 20, height: 20)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(theme.inauspiciousColor.opacity(0.03))
        )
        .overlay(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 1)
                .fill(theme.inauspiciousColor.opacity(0.3))
                .frame(width: 2)
        }
    }

    // MARK: Center Spine

    private func guidanceSpine(itemCount: Int) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<itemCount, id: \.self) { index in
                Circle()
                    .fill(goldAccent.opacity(0.4))
                    .frame(width: 3, height: 3)
                if index < itemCount - 1 {
                    Rectangle()
                        .fill(theme.primaryText.opacity(0.08))
                        .frame(width: 0.5)
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(width: 16)
    }

    // MARK: - 5. Thin Divider

    private var thinDivider: some View {
        Rectangle()
            .fill(theme.primaryText.opacity(0.10))
            .frame(height: 0.5)
    }

    // MARK: - 6. Category Capsules + Expansion

    private var categoryCapsuleSection: some View {
        VStack(spacing: 12) {
            // Capsule pills row — horizontally scrollable on narrow devices
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HoroscopeCategory.allCases, id: \.rawValue) { category in
                        categoryCapsule(category)
                    }
                }
            }

            // Expanded detail (shown below capsules when one is selected)
            if let expanded = expandedCategory,
               let reading = horoscope.categories.first(where: { $0.category == expanded }) {
                expandedCategoryDetail(reading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func categoryCapsule(_ category: HoroscopeCategory) -> some View {
        let isSelected = expandedCategory == category

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                if expandedCategory == category {
                    expandedCategory = nil
                } else {
                    expandedCategory = category
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: category.icon)
                    .font(.system(size: 11))
                Text(category.displayName)
                    .scaledFont(size: 12, weight: .medium)
            }
            .foregroundColor(isSelected ? goldAccent : theme.primaryText.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected
                          ? goldAccent.opacity(0.15)
                          : theme.primaryText.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? goldAccent.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func expandedCategoryDetail(_ reading: CategoryReading) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reading.summary)
                .scaledFont(size: 14, weight: .regular)
                .foregroundColor(theme.primaryText.opacity(0.9))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            intensityDots(reading.intensity)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
    }

    // MARK: - 7. Intensity Dots

    private func intensityDots(_ filled: Int) -> some View {
        HStack(spacing: 4) {
            Text("Intensity")
                .scaledFont(size: 11, weight: .medium)
                .foregroundColor(theme.secondaryText)

            HStack(spacing: 3) {
                ForEach(1...maxIntensity, id: \.self) { index in
                    Circle()
                        .fill(index <= filled ? goldAccent : theme.primaryText.opacity(0.15))
                        .frame(width: intensityDotSize, height: intensityDotSize)
                }
            }
        }
    }

    // MARK: - 8. Mantra + Color Swatch Row

    private var mantraAndColorRow: some View {
        HStack(spacing: 0) {
            // Mantra
            VStack(alignment: .leading, spacing: 3) {
                Text(horoscope.mantra.sanskrit)
                    .scaledFont(size: 14, weight: .regular, design: .serif)
                    .foregroundColor(theme.primaryText)
                    .italic()

                Text(horoscope.mantra.translation)
                    .scaledFont(size: 11, weight: .regular)
                    .foregroundColor(theme.secondaryText)
            }

            Spacer(minLength: 12)

            // Color swatch + name
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(hex: horoscope.auspiciousColor.hex))
                    .frame(width: colorSwatchSize, height: colorSwatchSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(theme.primaryText.opacity(0.2), lineWidth: 0.5)
                    )

                Text(horoscope.auspiciousColor.name)
                    .scaledFont(size: 12, weight: .medium)
                    .foregroundColor(theme.secondaryText)
            }
        }
    }

    // MARK: - 9. "Why this reading?" Button

    private var whyButton: some View {
        HStack {
            Spacer()
            Button(action: onTapWhy) {
                HStack(spacing: 4) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 12))
                    Text("Why this reading?")
                        .scaledFont(size: 12, weight: .medium)
                }
                .foregroundColor(goldAccent.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleHoroscope = DailyHoroscope(
        date: Date(),
        themeStatement: "A day of quiet strength and unexpected clarity",
        supportingText: "The Moon\u{2019}s transit through your fifth house invites creative expression. Trust the impulses that arise in stillness. Relationships deepen through honest conversation.",
        doList: [
            "Begin a creative project",
            "Speak from the heart",
            "Offer gratitude at sunrise"
        ],
        dontList: [
            "Sign major contracts",
            "Travel after sunset",
            "Lend money today"
        ],
        categories: [
            CategoryReading(category: .love, summary: "Venus aspects your seventh house, softening communication with partners. An honest conversation today plants seeds for deeper trust.", intensity: 4),
            CategoryReading(category: .work, summary: "Saturn\u{2019}s steady gaze on your tenth house rewards disciplined effort. Avoid shortcuts \u{2014} thorough work earns recognition.", intensity: 3),
            CategoryReading(category: .spirituality, summary: "Jupiter\u{2019}s blessing on your ninth house opens channels for devotion. Morning meditation yields unusual clarity and peace.", intensity: 5),
            CategoryReading(category: .health, summary: "Mars energizes your first house. Channel this vitality into movement rather than restlessness. Warm foods are favored.", intensity: 3)
        ],
        mantra: MantraReading(
            sanskrit: "Om Somaya Namaha",
            translation: "Salutations to the Moon",
            deity: "Chandra"
        ),
        auspiciousColor: AuspiciousColor(name: "Silver", hex: "C0C0C0"),
        transitContext: TransitContext(
            moonHouse: 5,
            moonHouseVedicName: "Putra",
            moonNakshatra: "Pushya",
            significantAspects: ["Jupiter transits your 9th house", "Venus aspects your 7th house"],
            birthRashi: .karka,
            birthTimeKnown: true
        )
    )

    ScrollView {
        DailyHoroscopeCard(
            horoscope: sampleHoroscope,
            theme: DeviTheme.forPeriod(.evening),
            onTapWhy: {}
        )
        .padding(.horizontal)
    }
    .background(Color(hex: "0F1B33").ignoresSafeArea())
}

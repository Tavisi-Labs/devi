// MARK: - Views/Components/DailyHoroscopeCard.swift
// Home screen horoscope card — theme statement, do/don't, category capsules, mantra

import SwiftUI

struct DailyHoroscopeCard: View {
    let horoscope: DailyHoroscope
    let theme: DeviTheme
    let onTapWhy: () -> Void
    let onTapArchive: () -> Void

    @State private var expandedCategory: HoroscopeCategory? = nil
    @State private var isTextExpanded = false
    @State private var isDosDontsExpanded = false

    // MARK: - Constants

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
        HStack(spacing: 10) {
            Text("YOUR DAY")
                .scaledFont(size: 11, weight: .bold)
                .foregroundColor(theme.secondaryText)
                .tracking(2)

            Spacer(minLength: 8)

            Button(action: onTapArchive) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Your day archive")
            .accessibilityHint("Browse past daily readings")
        }
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
                    .foregroundColor(theme.accentColor)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 4. Yama / Niyama — Manuscript Section
    //
    // Vedic framing: Niyama = positive observances (the day's "do" practices),
    // Yama = restraints (the day's cautions). Stacked vertically as a single
    // manuscript page, no green/red color blocking, no symmetric two-column
    // layout. Roman numeral markers in serif italic, gold accent. The entire
    // section is collapsed by default behind a quiet header.

    private var doAndDontSection: some View {
        VStack(spacing: 0) {
            yamaNiyamaHeader

            if isDosDontsExpanded {
                manuscriptContent
            }
        }
        .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
    }

    // MARK: Header (collapsed + tap target)

    private var yamaNiyamaHeader: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                isDosDontsExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Text("Yama · Niyama")
                    .scaledFont(size: 14, weight: .regular, design: .serif)
                    .italic()
                    .foregroundColor(theme.accentColor.opacity(0.85))

                Text("today\u{2019}s practice")
                    .scaledFont(size: 11, weight: .regular)
                    .tracking(0.5)
                    .foregroundColor(theme.secondaryText.opacity(0.6))

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.secondaryText.opacity(0.5))
                    .rotationEffect(.degrees(isDosDontsExpanded ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Manuscript Content (Niyama → separator → Yama)

    private var manuscriptContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            manuscriptSection(
                label: "Niyama",
                subtitle: "observances",
                items: horoscope.doList,
                revealDirection: .fadeUp
            )

            manuscriptSeparator

            manuscriptSection(
                label: "Yama",
                subtitle: "restraints",
                items: horoscope.dontList,
                revealDirection: .fadeUp
            )
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: Section (label + items)

    private func manuscriptSection(
        label: String,
        subtitle: String,
        items: [String],
        revealDirection: DeviRevealDirection
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label)
                    .scaledFont(size: 15, weight: .regular, design: .serif)
                    .italic()
                    .foregroundColor(theme.accentColor)

                Text("·")
                    .scaledFont(size: 11, weight: .regular)
                    .foregroundColor(theme.secondaryText.opacity(0.5))

                Text(subtitle)
                    .scaledFont(size: 11, weight: .regular)
                    .tracking(0.6)
                    .foregroundColor(theme.secondaryText.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    manuscriptItem(item, numeral: Self.romanNumeral(for: index + 1))
                        .deviReveal(
                            delay: 0.08 + Double(index) * 0.05,
                            direction: revealDirection
                        )
                }
            }
        }
    }

    // MARK: Single Manuscript Item

    private func manuscriptItem(_ text: String, numeral: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(numeral)
                .scaledFont(size: 13, weight: .regular, design: .serif)
                .italic()
                .foregroundColor(theme.accentColor.opacity(0.7))
                .frame(width: 26, alignment: .trailing)

            Text(text)
                .scaledFont(size: 14, weight: .regular)
                .foregroundColor(theme.primaryText)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Separator (three small dots, gold accent)

    private var manuscriptSeparator: some View {
        HStack(spacing: 6) {
            Spacer()
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(theme.accentColor.opacity(0.35))
                    .frame(width: 3, height: 3)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    // Lowercase roman numeral up to xii. Falls back to decimal beyond xii so
    // longer guidance lists still render rather than crashing.
    private static func romanNumeral(for n: Int) -> String {
        let map = [
            "i.", "ii.", "iii.", "iv.", "v.", "vi.",
            "vii.", "viii.", "ix.", "x.", "xi.", "xii.",
        ]
        return (1...12).contains(n) ? map[n - 1] : "\(n)."
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
            .foregroundColor(isSelected ? theme.accentColor : theme.primaryText.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected
                          ? theme.accentColor.opacity(0.15)
                          : theme.primaryText.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? theme.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
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
                        .fill(index <= filled ? theme.accentColor : theme.primaryText.opacity(0.15))
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
                .foregroundColor(theme.accentColor.opacity(0.8))
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
            onTapWhy: {},
            onTapArchive: {}
        )
        .padding(.horizontal)
    }
    .background(Color(hex: "0F1B33").ignoresSafeArea())
}

// MARK: - Views/Components/PanchangDetailSheet.swift
// Bottom sheet with educational details for tapped panchang elements

import SwiftUI

struct PanchangDetailSheet: View {
    let element: PanchangElement
    let theme: DeviTheme
    let timezoneIdentifier: String
    let cityName: String

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Category label
                Text(element.categoryLabel)
                    .deviLabel(.section, theme: theme)
                    .padding(.top, 8)

                // Element name
                Text(element.displayName)
                    .deviLabel(.sacredTitle, theme: theme)
                    .tracking(1)

                // Share button
                HStack {
                    Spacer()
                    ShareLink(item: ShareTextBuilder.panchangElement(
                        element,
                        timezoneIdentifier: timezoneIdentifier
                    )) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12))
                            Text("Share")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(theme.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.primaryText.opacity(0.06))
                        .clipShape(Capsule())
                    }
                }

                // Subtitle / meaning
                if let subtitle = subtitleText {
                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundColor(theme.secondaryText)
                }

                // Timing bar (if applicable)
                timingSection

                // Description card
                if let desc = descriptionText {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(desc)
                            .deviLabel(.body, theme: theme)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
                }

                // Eclipse mythology card (separate from description)
                if case .eclipse = element {
                    mythologySection
                }

                // Key attributes grid
                if !attributes.isEmpty {
                    attributesGrid
                }

                // Good for / Avoid section
                if !goodForItems.isEmpty || !avoidItems.isEmpty {
                    recommendationsSection
                }

                // Eclipse mantras section
                if case .eclipse = element {
                    mantrasSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(theme.backgroundGradient.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Subtitle

    private var subtitleText: String? {
        switch element {
        case .tithi(let t):
            if let info = PanchangDescriptions.tithiInfo(for: t.name) {
                return info.meaning
            }
            return "\(t.paksha.rawValue) Paksha"
        case .nakshatra(let n):
            if let info = PanchangDescriptions.nakshatraInfo(for: n.name) {
                return info.meaning
            }
            return "Ruled by \(n.ruler)"
        case .yoga(let y):
            if let info = PanchangDescriptions.yogaInfo(for: y.number) {
                return info.meaning
            }
            return nil
        case .karana(let k):
            if let info = PanchangDescriptions.karanaInfo(for: k.name) {
                return info.type
            }
            return nil
        case .vara(let v):
            if let info = PanchangDescriptions.varaInfo(for: varaWeekday(from: v)) {
                return "\(info.planet) — \(info.deity)"
            }
            return v
        case .timeWindow(let tw):
            if let info = PanchangDescriptions.timeWindowInfo(for: timeWindowKey(tw.type)) {
                return info.meaning
            }
            return nil
        case .eclipse(let e):
            return "\(e.body.devanagari) — \(e.type.rawValue)"
        }
    }

    // MARK: - Timing

    @ViewBuilder
    private var timingSection: some View {
        switch element {
        case .tithi(let t):
            timingBar(label: "Ends at", time: t.endTime)
        case .nakshatra(let n):
            timingBar(label: "Ends at", time: n.endTime)
        case .yoga(let y):
            timingBar(label: "Ends at", time: y.endTime)
        case .karana(let k):
            timingBar(label: "Ends at", time: k.endTime)
        case .timeWindow(let tw):
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("START")
                        .deviLabel(.caption, theme: theme)
                    Text(deviFormatTime(tw.start, timezoneIdentifier: timezoneIdentifier))
                        .deviLabel(.body, theme: theme)
                }
                Rectangle()
                    .fill(theme.primaryText.opacity(0.15))
                    .frame(height: 1)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("END")
                        .deviLabel(.caption, theme: theme)
                    Text(deviFormatTime(tw.end, timezoneIdentifier: timezoneIdentifier))
                        .deviLabel(.body, theme: theme)
                }
            }
            .padding(12)
            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
        case .eclipse(let e):
            VStack(alignment: .leading, spacing: 8) {
                Text("CONTACT TIMES")
                    .deviLabel(.caption, theme: theme)

                VStack(spacing: 4) {
                    ForEach(e.contactTimeline, id: \.label) { contact in
                        HStack {
                            Circle()
                                .fill(contact.label == "Maximum"
                                      ? Color(hex: "7B8EC4")
                                      : theme.secondaryText.opacity(0.4))
                                .frame(width: contact.label == "Maximum" ? 8 : 5,
                                       height: contact.label == "Maximum" ? 8 : 5)
                            Text(contact.label)
                                .font(.system(size: 13, weight: contact.label == "Maximum" ? .semibold : .regular))
                                .foregroundColor(contact.label == "Maximum" ? theme.primaryText : theme.secondaryText)
                            Spacer()
                            Text(deviFormatTime(contact.time, timezoneIdentifier: timezoneIdentifier))
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(theme.primaryText)
                        }
                    }
                }
                .padding(12)
                .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
            }
        default:
            EmptyView()
        }
    }

    private func timingBar(label: String, time: Date) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryText)
            Text(label)
                .deviLabel(.detail, theme: theme)
            Spacer()
            Text(deviFormatTime(time, timezoneIdentifier: timezoneIdentifier))
                .deviLabel(.body, theme: theme)
        }
        .padding(12)
        .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
    }

    // MARK: - Description

    private var descriptionText: String? {
        switch element {
        case .tithi(let t):
            return PanchangDescriptions.tithiInfo(for: t.name)?.description
        case .nakshatra(let n):
            return PanchangDescriptions.nakshatraInfo(for: n.name)?.description
        case .yoga(let y):
            return PanchangDescriptions.yogaInfo(for: y.number)?.description
        case .karana(let k):
            return PanchangDescriptions.karanaInfo(for: k.name)?.description
        case .vara(let v):
            return PanchangDescriptions.varaInfo(for: varaWeekday(from: v))?.description
        case .timeWindow(let tw):
            return PanchangDescriptions.timeWindowInfo(for: timeWindowKey(tw.type))?.description
        case .eclipse:
            return PanchangDescriptions.eclipseInfo.description
        }
    }

    // MARK: - Attributes Grid

    private var attributes: [(String, String)] {
        switch element {
        case .tithi(let t):
            guard let info = PanchangDescriptions.tithiInfo(for: t.name) else { return [] }
            return [
                ("Ruling Deity", info.rulingDeity),
                ("Paksha", t.paksha.rawValue),
                ("Significance", info.significance)
            ]
        case .nakshatra(let n):
            guard let info = PanchangDescriptions.nakshatraInfo(for: n.name) else { return [] }
            return [
                ("Ruling Planet", info.rulingPlanet),
                ("Deity", info.presidingDeity),
                ("Symbol", info.symbol),
                ("Quality", info.quality)
            ]
        case .yoga(let y):
            guard let info = PanchangDescriptions.yogaInfo(for: y.number) else { return [] }
            return [
                ("Quality", info.quality),
                ("Number", "\(y.number) of 27")
            ]
        case .karana(let k):
            guard let info = PanchangDescriptions.karanaInfo(for: k.name) else { return [] }
            return [
                ("Type", info.type),
                ("Suitability", info.suitability)
            ]
        case .vara(let v):
            guard let info = PanchangDescriptions.varaInfo(for: varaWeekday(from: v)) else { return [] }
            return [
                ("Deity", info.deity),
                ("Planet", info.planet),
                ("Color", info.associatedColor)
            ]
        case .timeWindow(let tw):
            guard let info = PanchangDescriptions.timeWindowInfo(for: timeWindowKey(tw.type)) else { return [] }
            return [
                ("Origin", info.origin),
                ("Recommendation", info.recommendation)
            ]
        case .eclipse(let e):
            var attrs: [(String, String)] = [
                ("Body", e.body.rawValue),
                ("Type", e.type.rawValue),
                ("Magnitude", String(format: "%.3f", e.magnitude))
            ]
            if e.moonBelowHorizon {
                attrs.append(("Visibility", "Moon below horizon — partial visibility only"))
            }
            return attrs
        }
    }

    private var attributesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(attributes, id: \.0) { attr in
                VStack(alignment: .leading, spacing: 4) {
                    Text(attr.0.uppercased())
                        .deviLabel(.caption, theme: theme)
                    Text(attr.1)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
            }
        }
    }

    // MARK: - Recommendations

    private var goodForItems: [String] {
        switch element {
        case .tithi(let t):
            return PanchangDescriptions.tithiInfo(for: t.name)?.auspiciousActivities ?? []
        case .nakshatra(let n):
            return PanchangDescriptions.nakshatraInfo(for: n.name)?.auspiciousActivities ?? []
        case .vara(let v):
            return PanchangDescriptions.varaInfo(for: varaWeekday(from: v))?.auspiciousActivities ?? []
        case .eclipse:
            return PanchangDescriptions.eclipseInfo.dosAndDonts.doItems
        default:
            return []
        }
    }

    private var avoidItems: [String] {
        switch element {
        case .timeWindow(let tw) where !tw.isAuspicious:
            return ["Starting new ventures", "Important decisions", "Travel"]
        case .eclipse:
            return PanchangDescriptions.eclipseInfo.dosAndDonts.dontItems
        default:
            return []
        }
    }

    @ViewBuilder
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !goodForItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.auspiciousColor)
                        Text("Good for")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.primaryText)
                    }

                    ForEach(goodForItems.prefix(5), id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(theme.secondaryText)
                            Text(item)
                                .deviLabel(.detail, theme: theme)
                        }
                    }
                }
            }

            if !avoidItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.inauspiciousColor)
                        Text("Avoid")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.primaryText)
                    }

                    ForEach(avoidItems, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(theme.secondaryText)
                            Text(item)
                                .deviLabel(.detail, theme: theme)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Eclipse Mythology

    @ViewBuilder
    private var mythologySection: some View {
        let info = PanchangDescriptions.eclipseInfo
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "7B8EC4"))
                Text("Samudra Manthan")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primaryText)
            }

            Text(info.mythology)
                .deviLabel(.detail, theme: theme)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "7B8EC4"))
                Text("Spiritual Significance")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primaryText)
            }

            Text(info.spiritualSignificance)
                .deviLabel(.detail, theme: theme)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Eclipse Mantras

    @ViewBuilder
    private var mantrasSection: some View {
        let info = PanchangDescriptions.eclipseInfo
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "7B8EC4"))
                Text("Mantras for Eclipse")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primaryText)
            }

            ForEach(info.mantras, id: \.transliteration) { mantra in
                VStack(alignment: .leading, spacing: 6) {
                    Text(mantra.devanagari)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(theme.primaryText.opacity(0.9))
                        .lineSpacing(4)

                    Text(mantra.transliteration)
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .foregroundColor(theme.secondaryText)
                        .italic()

                    Text(mantra.purpose)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(theme.secondaryText.opacity(0.7))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Helpers

    /// Extracts weekday name from vara string like "Surya (Sun)"
    private func varaWeekday(from varaDeity: String) -> String {
        let deityName = varaDeity.components(separatedBy: " (").first ?? varaDeity
        switch deityName {
        case "Surya": return "Sunday"
        case "Chandra": return "Monday"
        case "Mangala": return "Tuesday"
        case "Budha": return "Wednesday"
        case "Guru": return "Thursday"
        case "Shukra": return "Friday"
        case "Shani": return "Saturday"
        default: return deityName
        }
    }

    /// Converts WindowType to lookup key for PanchangDescriptions
    private func timeWindowKey(_ type: TimeWindow.WindowType) -> String {
        switch type {
        case .brahmaMuhurta: return "brahmaMuhurta"
        case .abhijitMuhurta: return "abhijitMuhurta"
        case .rahuKalam: return "rahuKalam"
        case .gulikaKalam: return "gulikaKalam"
        case .yamaganda: return "yamaganda"
        }
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PanchangDetailSheet(
                element: .tithi(Tithi(
                    number: 5,
                    name: "Panchami",
                    paksha: .shukla,
                    endTime: Date().addingTimeInterval(3600 * 4)
                )),
                theme: DeviTheme.forPeriod(.brahmaMuhurta),
                timezoneIdentifier: "America/New_York",
                cityName: "New York"
            )
        }
}

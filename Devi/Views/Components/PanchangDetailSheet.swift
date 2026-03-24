// MARK: - Views/Components/PanchangDetailSheet.swift
// Bottom sheet with educational details for tapped panchang elements

import SwiftUI

struct PanchangDetailSheet: View {
    let element: PanchangElement
    let theme: DeviTheme
    let timezoneIdentifier: String
    let cityName: String
    var panchangContext: DailyPanchang?  // Optional — used for fasting day enrichment

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
                                .scaledFont(size: 13, weight: .medium)
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
                        .scaledFont(size: 16, weight: .regular, design: .serif)
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

                // Navratri mantra section
                if case .navratriDay(let day) = element {
                    navratriMantraSection(day: day)
                }

                // Fasting day mantra section
                if case .fastingDay(let name) = element,
                   let info = PanchangDescriptions.fastingDayInfo(for: name),
                   let mantra = info.mantra {
                    fastingMantraSection(mantra: mantra, deity: info.associatedDeity)
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
        case .karana(let ks):
            guard let k = ks.first else { return nil }
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
        case .festival(let name):
            return PanchangDescriptions.festivalInfo(for: name)?.meaning
        case .fastingDay(let name):
            // Show enriched subtitle for Ekadashi with specific name
            if name == "Ekadashi", let ctx = panchangContext,
               let ekadashi = PanchangDescriptions.ekadashiName(
                   lunarMonth: ctx.lunarMonth, paksha: ctx.tithi.paksha
               ) {
                return "\(ekadashi.name) — \(ekadashi.meaning)"
            }
            // Show enriched subtitle for Pradosh with weekday type
            if name == "Pradosh Vrat", let ctx = panchangContext,
               let pradosh = PanchangDescriptions.pradoshTypeInfo(for: ctx.varaDeity) {
                return "\(pradosh.typeName) — \(pradosh.weekday)"
            }
            return PanchangDescriptions.fastingDayInfo(for: name)?.meaning
        case .navratriDay(let day):
            return day.goddessEpithet
        case .hora(let h):
            if let info = PanchangDescriptions.horaInfo(for: h.planetName) {
                return "\(info.deity) — \(info.nature)"
            }
            return "\(h.planetSanskrit) (\(h.planetName))"
        case .choghadiya(let c):
            if let info = PanchangDescriptions.choghadiyaInfo(for: c.name) {
                return "\"\(info.meaning)\" — \(c.quality.rawValue)"
            }
            return c.quality.rawValue
        case .mantra(let m):
            return "\(m.deity) — \(weekdayName(for: m.weekday))"
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
        case .karana(let ks):
            // Show all karana transitions for the day
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY'S KARANAS")
                    .deviLabel(.caption, theme: theme)

                VStack(spacing: 4) {
                    ForEach(Array(ks.enumerated()), id: \.offset) { idx, k in
                        HStack {
                            Circle()
                                .fill(idx == 0 ? theme.accentColor : theme.secondaryText.opacity(0.4))
                                .frame(width: idx == 0 ? 8 : 5, height: idx == 0 ? 8 : 5)
                            Text(k.name)
                                .scaledFont(size: 14, weight: idx == 0 ? .semibold : .regular, design: .serif)
                                .foregroundColor(idx == 0 ? theme.primaryText : theme.secondaryText)
                            Spacer()
                            Text("until \(deviFormatTime(k.endTime, timezoneIdentifier: timezoneIdentifier))")
                                .scaledFont(size: 13, weight: .medium, design: .monospaced)
                                .foregroundColor(theme.primaryText)
                        }
                    }
                }
                .padding(12)
                .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
            }
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
                                .scaledFont(size: 13, weight: contact.label == "Maximum" ? .semibold : .regular)
                                .foregroundColor(contact.label == "Maximum" ? theme.primaryText : theme.secondaryText)
                            Spacer()
                            Text(deviFormatTime(contact.time, timezoneIdentifier: timezoneIdentifier))
                                .scaledFont(size: 13, weight: .medium, design: .monospaced)
                                .foregroundColor(theme.primaryText)
                        }
                    }
                }
                .padding(12)
                .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
            }
        case .fastingDay(let name):
            if name == "Pradosh Vrat", let sunset = panchangContext?.solar.sunset {
                let pradoshEnd = sunset.addingTimeInterval(150 * 60)  // sunset + 2h30m
                VStack(alignment: .leading, spacing: 8) {
                    Text("PRADOSH KAAL")
                        .deviLabel(.caption, theme: theme)

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("START")
                                .deviLabel(.caption, theme: theme)
                            Text(deviFormatTime(sunset, timezoneIdentifier: timezoneIdentifier))
                                .deviLabel(.body, theme: theme)
                        }
                        Rectangle()
                            .fill(theme.primaryText.opacity(0.15))
                            .frame(height: 1)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("END")
                                .deviLabel(.caption, theme: theme)
                            Text(deviFormatTime(pradoshEnd, timezoneIdentifier: timezoneIdentifier))
                                .deviLabel(.body, theme: theme)
                        }
                    }
                    .padding(12)
                    .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
                }
            } else {
                EmptyView()
            }
        case .hora(let h):
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("START")
                        .deviLabel(.caption, theme: theme)
                    Text(deviFormatTime(h.startTime, timezoneIdentifier: timezoneIdentifier))
                        .deviLabel(.body, theme: theme)
                }
                Rectangle()
                    .fill(theme.primaryText.opacity(0.15))
                    .frame(height: 1)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("END")
                        .deviLabel(.caption, theme: theme)
                    Text(deviFormatTime(h.endTime, timezoneIdentifier: timezoneIdentifier))
                        .deviLabel(.body, theme: theme)
                }
            }
            .padding(12)
            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
        case .choghadiya(let c):
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("START")
                        .deviLabel(.caption, theme: theme)
                    Text(deviFormatTime(c.startTime, timezoneIdentifier: timezoneIdentifier))
                        .deviLabel(.body, theme: theme)
                }
                Rectangle()
                    .fill(theme.primaryText.opacity(0.15))
                    .frame(height: 1)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("END")
                        .deviLabel(.caption, theme: theme)
                    Text(deviFormatTime(c.endTime, timezoneIdentifier: timezoneIdentifier))
                        .deviLabel(.body, theme: theme)
                }
            }
            .padding(12)
            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
        case .mantra(let m):
            VStack(spacing: 12) {
                Text(m.devanagari)
                    .scaledFont(size: 22, weight: .regular)
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(m.transliteration)
                    .scaledFont(size: 14, weight: .regular, design: .serif)
                    .foregroundColor(theme.secondaryText)
                    .italic()
            }
            .padding(16)
            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
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
        case .karana(let ks):
            guard let k = ks.first else { return nil }
            return PanchangDescriptions.karanaInfo(for: k.name)?.description
        case .vara(let v):
            return PanchangDescriptions.varaInfo(for: varaWeekday(from: v))?.description
        case .timeWindow(let tw):
            return PanchangDescriptions.timeWindowInfo(for: timeWindowKey(tw.type))?.description
        case .eclipse:
            return PanchangDescriptions.eclipseInfo.description
        case .festival(let name):
            return PanchangDescriptions.festivalInfo(for: name)?.description
        case .fastingDay(let name):
            return PanchangDescriptions.fastingDayInfo(for: name)?.description
        case .navratriDay(let day):
            return "Day \(day.dayNumber) of Navratri is dedicated to Goddess \(day.goddessName) — \(day.goddessEpithet). Wear \(day.colorName) and offer \(day.offering) to receive her blessings."
        case .hora(let h):
            return PanchangDescriptions.horaInfo(for: h.planetName)?.description
        case .choghadiya(let c):
            return PanchangDescriptions.choghadiyaInfo(for: c.name)?.description
        case .mantra(let m):
            return m.significance
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
        case .karana(let ks):
            guard let k = ks.first, let info = PanchangDescriptions.karanaInfo(for: k.name) else { return [] }
            var attrs: [(String, String)] = [
                ("Type", info.type),
                ("Suitability", info.suitability),
            ]
            if ks.count > 1 {
                attrs.append(("Transitions", "\(ks.count) karanas today"))
            }
            return attrs
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
        case .festival(let name):
            guard let info = PanchangDescriptions.festivalInfo(for: name) else { return [] }
            return [
                ("Associated Deity", info.associatedDeity),
                ("Significance", info.significance)
            ]
        case .fastingDay(let name):
            guard let info = PanchangDescriptions.fastingDayInfo(for: name) else { return [] }
            var attrs: [(String, String)] = [
                ("Associated Deity", info.associatedDeity),
            ]
            // Add weekday-specific Pradosh type
            if name == "Pradosh Vrat", let ctx = panchangContext,
               let pradosh = PanchangDescriptions.pradoshTypeInfo(for: ctx.varaDeity) {
                attrs.append(("Type", pradosh.typeName))
                attrs.append(("Significance", pradosh.significance))
            }
            // Add named Ekadashi variant
            if name == "Ekadashi", let ctx = panchangContext,
               let ekadashi = PanchangDescriptions.ekadashiName(
                   lunarMonth: ctx.lunarMonth, paksha: ctx.tithi.paksha
               ) {
                attrs.append(("This Ekadashi", "\(ekadashi.name) — \(ekadashi.meaning)"))
            }
            attrs.append(("Why Fast", info.whyFast))
            return attrs
        case .navratriDay(let day):
            return [
                ("Day", "\(day.dayNumber) of 9"),
                ("Goddess", day.goddessName),
                ("Color", day.colorName),
                ("Offering", day.offering)
            ]
        case .hora(let h):
            guard let info = PanchangDescriptions.horaInfo(for: h.planetName) else { return [] }
            return [
                ("Planet", "\(info.planetSanskrit) (\(info.planetName))"),
                ("Nature", info.nature),
                ("Quality", info.quality),
                ("Period", h.isDaytime ? "Daytime" : "Nighttime")
            ]
        case .choghadiya(let c):
            guard let info = PanchangDescriptions.choghadiyaInfo(for: c.name) else { return [] }
            return [
                ("Meaning", info.meaning),
                ("Quality", c.quality.rawValue),
                ("Period", c.isDaytime ? "Daytime" : "Nighttime")
            ]
        case .mantra(let m):
            return [
                ("Deity", m.deity),
                ("Best Time", m.bestTimeToChant),
                ("Repetitions", "\(m.repetitions) times"),
                ("Day", weekdayName(for: m.weekday))
            ]
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
                        .scaledFont(size: 14, weight: .medium)
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
        case .festival(let name):
            return PanchangDescriptions.festivalInfo(for: name)?.observances ?? []
        case .fastingDay(let name):
            return PanchangDescriptions.fastingDayInfo(for: name)?.howToObserve ?? []
        case .navratriDay(let day):
            return [
                "Worship Goddess \(day.goddessName)",
                "Wear \(day.colorName) clothing",
                "Offer \(day.offering) to the Goddess",
                "Chant the daily Navratri mantra",
                "Observe the Navratri fast (phalahar)"
            ]
        case .hora(let h):
            return PanchangDescriptions.horaInfo(for: h.planetName)?.auspiciousActivities ?? []
        case .choghadiya(let c):
            return PanchangDescriptions.choghadiyaInfo(for: c.name)?.auspiciousActivities ?? []
        case .mantra:
            return []
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
        case .hora(let h):
            return PanchangDescriptions.horaInfo(for: h.planetName)?.avoidActivities ?? []
        case .choghadiya(let c):
            if c.quality == .inauspicious {
                return ["Starting new ventures", "Important decisions", "Travel", "Ceremonies"]
            }
            return []
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
                            .scaledFont(size: 14, weight: .semibold)
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
                            .scaledFont(size: 14, weight: .semibold)
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
                    .scaledFont(size: 14, weight: .semibold)
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
                    .scaledFont(size: 14, weight: .semibold)
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
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.primaryText)
            }

            ForEach(info.mantras, id: \.transliteration) { mantra in
                VStack(alignment: .leading, spacing: 6) {
                    Text(mantra.devanagari)
                        .scaledFont(size: 17, weight: .regular)
                        .foregroundColor(theme.primaryText.opacity(0.9))
                        .lineSpacing(4)

                    Text(mantra.transliteration)
                        .scaledFont(size: 13, weight: .regular, design: .serif)
                        .foregroundColor(theme.secondaryText)
                        .italic()

                    Text(mantra.purpose)
                        .scaledFont(size: 12, weight: .regular)
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

    // MARK: - Navratri Mantra

    private func navratriMantraSection(day: NavratriDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 12))
                    .foregroundColor(theme.accentColor)
                Text("Mantra for \(day.goddessName)")
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.primaryText)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(day.mantra)
                    .scaledFont(size: 17, weight: .regular)
                    .foregroundColor(theme.primaryText.opacity(0.9))
                    .lineSpacing(4)

                Text(day.mantraTranslit)
                    .scaledFont(size: 13, weight: .regular, design: .serif)
                    .foregroundColor(theme.secondaryText)
                    .italic()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Fasting Day Mantra

    private func fastingMantraSection(mantra: (devanagari: String, transliteration: String), deity: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "c54b2a"))
                Text("Mantra for \(deity)")
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.primaryText)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(mantra.devanagari)
                    .scaledFont(size: 17, weight: .regular)
                    .foregroundColor(theme.primaryText.opacity(0.9))
                    .lineSpacing(4)

                Text(mantra.transliteration)
                    .scaledFont(size: 13, weight: .regular, design: .serif)
                    .foregroundColor(theme.secondaryText)
                    .italic()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
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

    /// Converts Calendar weekday (1-7) to name
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
                cityName: "New York",
                panchangContext: nil
            )
        }
}

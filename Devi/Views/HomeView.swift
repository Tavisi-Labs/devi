// MARK: - Views/HomeView.swift
// The single main screen of the app

import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: PanchangViewModel
    @State private var showSettings = false
    @State private var selectedElement: PanchangElement?
    @State private var shareCardImage: ShareableCardImage?
    @State private var isRenderingCard = false

    var body: some View {
        ZStack {
            // Full-screen adaptive gradient + star field background
            // ZStack siblings with .ignoresSafeArea() are more reliable than .background { }
            vm.theme.backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 8), value: vm.timePeriod)

            StarFieldView(isDaytime: vm.isDaytime, timePeriod: vm.timePeriod)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 5), value: vm.timePeriod)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 40) {

                    // MARK: - Header (date + location + settings)
                    headerSection

                    // MARK: - Tithi & Nakshatra
                    tithiSection

                    // MARK: - Sun Arc Timer (hero)
                    if let solar = vm.todayPanchang?.solar {
                        SunArcView(
                            progress: vm.sunProgress,
                            isDaytime: vm.isDaytime,
                            sunrise: solar.sunrise,
                            sunset: solar.sunset,
                            moonrise: solar.moonrise,
                            moonset: solar.moonset,
                            currentTime: vm.currentTimeText,
                            countdownText: vm.countdownText,
                            countdownLabel: vm.countdownLabel,
                            theme: vm.theme,
                            timePeriod: vm.timePeriod,
                            timezoneIdentifier: vm.currentCity.timezoneIdentifier
                        )
                        .padding(.top, 12)
                    }

                    // MARK: - Three-fact info bar
                    if let panchang = vm.todayPanchang {
                        infoBar(panchang: panchang)
                    }

                    // MARK: - Today's Details
                    todayDetails

                    // MARK: - Today's Festival Banner
                    ForEach(vm.todayFestivals, id: \.self) { festival in
                        Button {
                            selectedElement = .festival(festival)
                        } label: {
                            festivalBanner(festival)
                        }
                        .buttonStyle(.plain)
                        .deviEntrance()
                    }

                    // MARK: - Fasting indicator (if applicable)
                    if let panchang = vm.todayPanchang, let fastType = panchang.tithi.fastingType {
                        let enrichedName = enrichedFastingName(fastType, panchang: panchang)
                        Button {
                            selectedElement = .fastingDay(fastType)
                        } label: {
                            fastingBanner(enrichedName)
                        }
                        .buttonStyle(.plain)
                        .deviEntrance()
                    }

                    // MARK: - Eclipse Card (imminent or today)
                    if let eclipse = vm.imminentEclipse {
                        EclipseCard(
                            eclipse: eclipse,
                            todayDateString: todayDateString,
                            theme: vm.theme,
                            timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                            cityName: vm.currentCity.name,
                            onTap: {
                                selectedElement = .eclipse(eclipse)
                            }
                        )
                        .padding(.horizontal)
                    }

                    // MARK: - Time Windows
                    if !vm.activeTimeWindows.isEmpty {
                        TimeWindowsCard(
                            windows: vm.activeTimeWindows,
                            theme: vm.theme,
                            timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                            onTapWindow: { window in
                                selectedElement = .timeWindow(window)
                            }
                        )
                        .padding(.horizontal)
                    }

                    // MARK: - Hora Card (planetary hours)
                    if let panchang = vm.todayPanchang {
                        HoraCard(
                            horas: panchang.horas,
                            theme: vm.theme,
                            timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                            onTapHora: { hora in
                                selectedElement = .hora(hora)
                            }
                        )
                        .padding(.horizontal)
                    }

                    // MARK: - Choghadiya Card (auspicious periods)
                    if let panchang = vm.todayPanchang {
                        ChoghadiyaCard(
                            choghadiyas: panchang.choghadiyas,
                            theme: vm.theme,
                            timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                            onTapChoghadiya: { chog in
                                selectedElement = .choghadiya(chog)
                            }
                        )
                        .padding(.horizontal)
                    }

                    // MARK: - Navratri Card (conditional)
                    if let navDay = vm.currentNavratriDay {
                        NavratriCard(day: navDay, theme: vm.theme)
                            .padding(.horizontal)
                    }

                    // MARK: - Upcoming
                    upcomingSection

                }
                .padding(.bottom, 80)
                .padding(.top, 8)
            }
        }
        .onAppear {
            vm.loadData()
            vm.startTimer()
        }
        .onDisappear {
            vm.stopTimer()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(vm: vm)
                .presentationBackground(.background)
        }
        .sheet(item: $selectedElement) { element in
            PanchangDetailSheet(
                element: element,
                theme: vm.theme,
                timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                cityName: vm.currentCity.name,
                panchangContext: vm.todayPanchang
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            // Icon bar: share left, settings right
            HStack {
                if let panchang = vm.todayPanchang {
                    ShareLink(item: ShareTextBuilder.dailySummary(
                        panchang: panchang,
                        city: vm.currentCity,
                        navratriDay: vm.currentNavratriDay
                    )) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(vm.theme.secondaryText)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    // Image share button
                    if let cardImage = shareCardImage {
                        ShareLink(item: cardImage, preview: SharePreview("Devi Daily Panchang")) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(vm.theme.secondaryText)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            renderShareCard()
                        } label: {
                            Image(systemName: isRenderingCard ? "hourglass" : "camera")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(vm.theme.secondaryText)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(isRenderingCard)
                    }
                } else {
                    Spacer().frame(width: 44, height: 44)
                }

                Spacer()

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(vm.theme.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // Centered city name
            Text(vm.currentCity.name)
                .scaledFont(size: 16, weight: .medium)
                .foregroundColor(vm.theme.primaryText)

            // Centered Vedic date + Gregorian date
            if let panchang = vm.todayPanchang {
                Text("\(panchang.lunarMonth) \u{00B7} \(panchang.tithi.paksha.rawValue) Paksha")
                    .scaledFont(size: 13, weight: .regular)
                    .foregroundColor(vm.theme.secondaryText)
            }

            // Samvathsara year name
            if !vm.samvathsaraName.isEmpty, let panchang = vm.todayPanchang {
                Text("\(vm.samvathsaraName) Samvathsara \u{00B7} \(panchang.lunarMonth) M\u{0101}sa")
                    .scaledFont(size: 12, weight: .regular, design: .serif)
                    .foregroundColor(vm.theme.secondaryText.opacity(0.7))
            }

            Text(formattedDate)
                .scaledFont(size: 12, weight: .regular)
                .foregroundColor(vm.theme.secondaryText.opacity(0.7))
        }
    }

    // MARK: - Tithi Display (tappable)

    private var tithiSection: some View {
        VStack(spacing: 10) {
            if let panchang = vm.todayPanchang {
                Button {
                    selectedElement = .tithi(panchang.tithi)
                } label: {
                    HStack(spacing: 6) {
                        Text(panchang.tithi.name.uppercased())
                            .deviLabel(.sacredTitle, theme: vm.theme)
                            .tracking(2)

                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(vm.theme.secondaryText.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)

                Button {
                    selectedElement = .nakshatra(panchang.nakshatra)
                } label: {
                    Text("\(panchang.nakshatra.name) Nakshatra")
                        .scaledFont(size: 15, weight: .regular, design: .serif)
                        .foregroundColor(vm.theme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Three-Fact Info Bar

    private func infoBar(panchang: DailyPanchang) -> some View {
        HStack(spacing: 0) {
            // Left: Tithi ends
            VStack(spacing: 3) {
                Text("TITHI ENDS")
                    .scaledFont(size: 10, weight: .medium)
                    .foregroundColor(vm.theme.secondaryText)
                    .tracking(0.5)
                Text(formatTime(panchang.tithi.endTime))
                    .scaledFont(size: 14, weight: .medium)
                    .foregroundColor(vm.theme.primaryText)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(vm.theme.primaryText.opacity(0.10))
                .frame(width: 0.5, height: 28)

            // Center: Nakshatra
            VStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(vm.theme.secondaryText)
                Text(panchang.nakshatra.name)
                    .scaledFont(size: 14, weight: .medium, design: .serif)
                    .foregroundColor(vm.theme.primaryText)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(vm.theme.primaryText.opacity(0.10))
                .frame(width: 0.5, height: 28)

            // Right: Sunset/Sunrise time
            VStack(spacing: 3) {
                Text(vm.isDaytime ? "SUNSET" : "SUNRISE")
                    .scaledFont(size: 10, weight: .medium)
                    .foregroundColor(vm.theme.secondaryText)
                    .tracking(0.5)
                Text(formatTime(vm.isDaytime ? panchang.solar.sunset : panchang.solar.sunrise))
                    .scaledFont(size: 14, weight: .medium)
                    .foregroundColor(vm.theme.primaryText)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
    }

    // MARK: - Fasting Banner

    private func fastingBanner(_ displayName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "c54b2a"))

            Text("Today is \(displayName)")
                .scaledFont(size: 14, weight: .medium)
                .foregroundColor(vm.theme.primaryText)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(vm.theme.secondaryText.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "c54b2a").opacity(0.15))
        .deviCard(theme: vm.theme, elevation: .raised, cornerRadius: 12)
        .padding(.horizontal)
    }

    // MARK: - Festival Banner

    private func festivalBanner(_ name: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "d4a857"))

            Text("Today: \(name)")
                .scaledFont(size: 14, weight: .medium)
                .foregroundColor(vm.theme.primaryText)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(vm.theme.secondaryText.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "d4a857").opacity(0.15))
        .deviCard(theme: vm.theme, elevation: .raised, cornerRadius: 12)
        .padding(.horizontal)
    }

    // MARK: - Today's Additional Details (tappable)

    private var todayDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            OrnamentalDivider("TODAY", theme: vm.theme)

            // Mantra card — lives under the TODAY heading
            if let mantra = PanchangDescriptions.dailyMantra(
                for: Calendar.current.component(.weekday, from: Date())
            ) {
                MantraCard(mantra: mantra, theme: vm.theme) {
                    selectedElement = .mantra(mantra)
                }
                .padding(.horizontal)
            }

            if let panchang = vm.todayPanchang {
                VStack(spacing: 0) {
                    tappableDetailRow("Yoga", value: panchang.yoga.name, sacredValue: true) {
                        selectedElement = .yoga(panchang.yoga)
                    }
                    Divider().background(vm.theme.primaryText.opacity(0.08))

                    tappableDetailRow("Karana", value: karanaDisplayValue(panchang), sacredValue: true) {
                        selectedElement = .karana(panchang.karanas)
                    }
                    Divider().background(vm.theme.primaryText.opacity(0.08))

                    if let moonrise = panchang.solar.moonrise {
                        detailRow("Moonrise", value: formatTime(moonrise))
                        Divider().background(vm.theme.primaryText.opacity(0.08))
                    }
                    if let moonset = panchang.solar.moonset {
                        detailRow("Moonset", value: formatTime(moonset))
                        Divider().background(vm.theme.primaryText.opacity(0.08))
                    }

                    tappableDetailRow("Vara", value: panchang.varaDeity, sacredValue: true) {
                        selectedElement = .vara(panchang.varaDeity)
                    }
                }
                .padding(.vertical, 4)
                .deviCard(theme: vm.theme, elevation: .raised)
                .padding(.horizontal)
            }
        }
        .deviEntrance(delay: 0.16)
    }

    private func tappableDetailRow(_ label: String, value: String, sacredValue: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .scaledFont(size: 15, weight: .regular)
                    .foregroundColor(vm.theme.secondaryText)

                Spacer()

                Text(value)
                    .scaledFont(size: 15, weight: .medium, design: sacredValue ? .serif : .default)
                    .foregroundColor(vm.theme.primaryText)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(vm.theme.secondaryText.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .scaledFont(size: 15, weight: .regular)
                .foregroundColor(vm.theme.secondaryText)

            Spacer()

            Text(value)
                .scaledFont(size: 15, weight: .medium)
                .foregroundColor(vm.theme.primaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Upcoming Events

    private var thisWeekEvents: [UpcomingEvent] {
        vm.upcomingEvents.filter { $0.daysAway <= 7 }
    }

    private var comingUpEvents: [UpcomingEvent] {
        vm.upcomingEvents.filter { $0.daysAway > 7 }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            OrnamentalDivider("UPCOMING", theme: vm.theme)

            if !thisWeekEvents.isEmpty {
                Text("THIS WEEK")
                    .deviLabel(.section, theme: vm.theme)
                    .padding(.horizontal, 20)

                VStack(spacing: 0) {
                    ForEach(thisWeekEvents) { event in
                        upcomingEventRow(event)
                    }
                }
                .deviCard(theme: vm.theme, elevation: .raised)
                .padding(.horizontal)
            }

            if !comingUpEvents.isEmpty {
                Text("COMING UP")
                    .deviLabel(.section, theme: vm.theme)
                    .padding(.horizontal, 20)
                    .padding(.top, thisWeekEvents.isEmpty ? 0 : 8)

                VStack(spacing: 0) {
                    ForEach(comingUpEvents) { event in
                        upcomingEventRow(event)
                    }
                }
                .deviCard(theme: vm.theme, elevation: .flat)
                .padding(.horizontal)
            }
        }
        .deviEntrance(delay: 0.24)
    }

    private func upcomingEventRow(_ event: UpcomingEvent) -> some View {
        Button {
            selectedElement = panchangElement(for: event)
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(eventDotColor(event.type))
                    .frame(width: 6, height: 6)

                Text(event.name)
                    .scaledFont(size: 15, weight: .medium)
                    .foregroundColor(vm.theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                // Relative time badge
                Text("\(event.daysAway)d")
                    .scaledFont(size: 11, weight: .semibold)
                    .foregroundColor(vm.theme.secondaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(vm.theme.primaryText.opacity(0.06))
                    .clipShape(Capsule())

                Text(event.formattedDate)
                    .scaledFont(size: 13, weight: .regular)
                    .foregroundColor(vm.theme.secondaryText)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(vm.theme.secondaryText.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    // MARK: - Event → PanchangElement Resolver

    private func panchangElement(for event: UpcomingEvent) -> PanchangElement {
        switch event.type {
        case .festival:
            if let navDay = navratriDay(from: event.name) {
                return .navratriDay(navDay)
            }
            return .festival(event.name)
        case .fasting:
            return .fastingDay(event.name)
        case .eclipse:
            if let eclipse = vm.eclipseEvents.first(where: { $0.dateString == event.dateString }) {
                return .eclipse(eclipse)
            }
            return .festival(event.name)
        }
    }

    /// Parses Navratri event names into NavratriDay structs.
    /// "Chaitra Navratri Begins" → Day 1, "Chaitra Navratri Day 3" → Day 3, etc.
    private func navratriDay(from eventName: String) -> NavratriDay? {
        let days = NavratriDay.goddesses  // Same goddess data for both Chaitra and Sharad

        if eventName.contains("Navratri Begins") {
            return days.first
        }

        // Match "Chaitra Navratri Day N" or "Sharad Navratri Day N"
        if eventName.contains("Navratri Day") {
            let components = eventName.components(separatedBy: " ")
            if let lastComponent = components.last, let dayNum = Int(lastComponent),
               dayNum >= 1, dayNum <= 9 {
                return days[dayNum - 1]
            }
        }

        return nil
    }

    private func eventDotColor(_ type: UpcomingEvent.EventType) -> Color {
        switch type {
        case .fasting: return Color(hex: "c54b2a")
        case .eclipse: return Color(hex: "7B8EC4")
        case .festival: return vm.theme.accentColor
        }
    }

    /// Format karana transitions: "Vanija → Vishti" or just "Bava" if only one
    private func karanaDisplayValue(_ panchang: DailyPanchang) -> String {
        if panchang.karanas.count <= 1 {
            return panchang.karana.name
        }
        return panchang.karanas.map(\.name).joined(separator: " → ")
    }

    /// Computes a weekday-specific Pradosh name or named Ekadashi variant.
    /// "Pradosh Vrat" + Monday → "Soma Pradosh Vrat"
    /// "Ekadashi" + Chaitra + Shukla → "Kamada Ekadashi"
    /// "Purnima" / "Amavasya" → unchanged (no named variants)
    private func enrichedFastingName(_ baseType: String, panchang: DailyPanchang) -> String {
        switch baseType {
        case "Pradosh Vrat":
            if let info = PanchangDescriptions.pradoshTypeInfo(for: panchang.varaDeity) {
                return info.typeName
            }
            return baseType
        case "Ekadashi":
            if let ekadashi = PanchangDescriptions.ekadashiName(
                lunarMonth: panchang.lunarMonth,
                paksha: panchang.tithi.paksha
            ) {
                return "\(ekadashi.name) Ekadashi"
            }
            return baseType
        default:
            return baseType
        }
    }

    private func renderShareCard() {
        guard let panchang = vm.todayPanchang else { return }
        isRenderingCard = true
        // Render off the next run loop to avoid blocking the UI
        Task { @MainActor in
            shareCardImage = ShareCardRenderer.renderAsTransferable(
                panchang: panchang,
                city: vm.currentCity,
                navratriDay: vm.currentNavratriDay,
                theme: vm.theme
            )
            isRenderingCard = false
        }
    }

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: vm.currentCity.timezoneIdentifier)
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = TimeZone(identifier: vm.currentCity.timezoneIdentifier) ?? .current
        return formatter.string(from: Date())
    }
}

// MARK: - Preview

#Preview {
    HomeView(vm: PanchangViewModel())
}

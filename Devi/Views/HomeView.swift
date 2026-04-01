// MARK: - Views/HomeView.swift
// The single main screen of the app — dashboard layout

import SwiftUI
import StoreKit

struct HomeView: View {
    @ObservedObject var vm: PanchangViewModel
    @Environment(\.requestReview) private var requestReview
    @State private var showSettings = false
    @State private var selectedElement: PanchangElement?
    @State private var shareCardImage: ShareableCardImage?
    @State private var isRenderingCard = false
    @State private var showAllUpcoming = false
    @State private var showMeditationMode = false
    @State private var settingsRotation = false
    @State private var dayNavDragOffset: CGFloat = 0
    @State private var cardTapCount: Int = 0
    @State private var immersiveElement: PanchangElement?
    @State private var sheetElement: PanchangElement?
    @State private var isTransitioning = false
    @State private var sheetSwitchTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Full-screen adaptive gradient + star field background
            vm.theme.backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 8), value: vm.timePeriod)

            StarFieldView(isDaytime: vm.isDaytime, timePeriod: vm.timePeriod, isPaused: immersiveElement != nil || showMeditationMode)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 5), value: vm.timePeriod)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // MARK: - 1. Header (swipeable for day navigation)
                    headerSection
                        .padding(.top, 8)
                        .offset(x: dayNavDragOffset * 0.3) // Subtle parallax during drag
                        .gesture(dayNavigationGesture)

                    // "Return to Today" pill (visible when viewing past/future)
                    if !vm.isViewingToday {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                vm.returnToToday()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Today")
                                    .scaledFont(size: 13, weight: .semibold)
                            }
                            .foregroundColor(vm.theme.accentColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                        .sensoryFeedback(.impact(weight: .medium), trigger: vm.dayOffset)
                        .padding(.top, 8)
                    }

                    // MARK: - 2. Celestial Observatory
                    if let solar = vm.todayPanchang?.solar {
                        CelestialHeroView(
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
                            themeStyle: vm.themeStyle,
                            timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                            tithi: vm.todayPanchang?.tithi,
                            nakshatra: vm.todayPanchang?.nakshatra,
                            cosmicSignature: vm.cosmicSignature,
                            isLoadingSignature: vm.isLoadingSignature,
                            onScrub: { scrubbedProgress in
                                let total = solar.sunset.timeIntervalSince(solar.sunrise)
                                let scrubbedDate = solar.sunrise.addingTimeInterval(total * scrubbedProgress)
                                vm.virtualTimeOffset = scrubbedDate.timeIntervalSince(Date())
                            },
                            onScrubEnd: {
                                vm.virtualTimeOffset = nil
                            },
                            onTapTithi: { if let t = vm.todayPanchang?.tithi { selectedElement = .tithi(t) } },
                            onTapNakshatra: { if let n = vm.todayPanchang?.nakshatra { selectedElement = .nakshatra(n) } },
                            onTapVedicSky: { selectedElement = .vedicSky }
                        )
                        .sensoryFeedback(.selection, trigger: vm.virtualTimeOffset != nil)
                        .padding(.top, vm.isViewingToday ? 24 : 12)
                    }

                    // MARK: - 4. Right Now Card
                    if !vm.rightNowItems.isEmpty {
                        RightNowCard(
                            items: vm.rightNowItems,
                            theme: vm.theme,
                            timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                            onTapItem: { element in
                                selectedElement = element
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }

                    // MARK: - 5. Three-fact info bar
                    if let panchang = vm.todayPanchang {
                        infoBar(panchang: panchang)
                            .padding(.top, 24)
                    }

                    // MARK: - 6. Today's Details
                    todayDetails
                        .padding(.top, 24)

                    // MARK: - 7. Festival / Fasting / Eclipse banners (grouped)
                    bannersSection
                        .padding(.top, 24)

                    // MARK: - 8. Time Windows (2-col grid)
                    if !vm.activeTimeWindows.isEmpty {
                        TimeWindowsCard(
                            windows: vm.activeTimeWindows,
                            theme: vm.theme,
                            timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                            effectiveNow: vm.effectiveNow,
                            onTapWindow: { window in
                                selectedElement = .timeWindow(window)
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 32)
                    }

                    // MARK: - 9. Hora (horizontal strip)
                    if let panchang = vm.todayPanchang {
                        HoraCard(
                            horas: panchang.horas,
                            theme: vm.theme,
                            timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                            effectiveNow: vm.effectiveNow,
                            onTapHora: { hora in
                                selectedElement = .hora(hora)
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 32)
                    }

                    // MARK: - 10. Choghadiya (dual horizontal strips)
                    if let panchang = vm.todayPanchang {
                        ChoghadiyaCard(
                            choghadiyas: panchang.choghadiyas,
                            theme: vm.theme,
                            timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                            effectiveNow: vm.effectiveNow,
                            onTapChoghadiya: { chog in
                                selectedElement = .choghadiya(chog)
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 32)
                    }

                    // MARK: - 11. Navratri Card (conditional)
                    if let navDay = vm.currentNavratriDay {
                        Button {
                            selectedElement = .navratriDay(navDay)
                        } label: {
                            NavratriCard(day: navDay, theme: vm.theme)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .padding(.top, 32)
                    }

                    // MARK: - 12. Upcoming (capped + "Show All")
                    upcomingSection
                        .padding(.top, 40)

                }
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            vm.loadData()
            vm.startTimer()
            vm.recordUsageDay()
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            if vm.shouldRequestReview {
                requestReview()
                vm.markReviewRequested()
            }
        }
        .onDisappear {
            vm.stopTimer()
            sheetSwitchTask?.cancel()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(vm: vm)
                .presentationBackground(.background)
        }
        .sheet(item: $sheetElement) { element in
            PanchangDetailSheet(
                element: element,
                theme: vm.theme,
                timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                cityName: vm.currentCity.name,
                panchangContext: vm.todayPanchang
            )
        }
        .sheet(isPresented: $showAllUpcoming) {
            UpcomingEventsSheet(
                eventsByMonth: vm.upcomingEventsByMonth,
                theme: vm.theme,
                onSelectEvent: { event in
                    showAllUpcoming = false
                    selectedElement = panchangElement(for: event)
                }
            )
            .environment(\.deviFontScale, vm.fontScale)
        }
        // MARK: - Haptic Choreography
        .sensoryFeedback(.impact(weight: .light), trigger: cardTapCount)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: vm.timePeriod)
        .sensoryFeedback(.impact(weight: .heavy), trigger: vm.countdownZeroTrigger)
        .onChange(of: selectedElement?.id) { _, _ in
            guard let el = selectedElement, !isTransitioning else { return }
            cardTapCount += 1
            isTransitioning = true
            // Clear first so SwiftUI doesn't fight dismiss/present
            selectedElement = nil
            // Small delay to let any open sheet dismiss first
            sheetSwitchTask?.cancel()
            sheetSwitchTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.4))
                guard !Task.isCancelled else { return }
                switch el {
                case .tithi, .nakshatra, .eclipse, .navratriDay, .hora, .mantra, .vedicSky:
                    immersiveElement = el
                default:
                    sheetElement = el
                }
                isTransitioning = false
            }
        }
        // Meditation mode
        .fullScreenCover(item: $immersiveElement) { element in
            ImmersiveDetailRouter(
                element: element,
                theme: vm.theme,
                timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                cityName: vm.currentCity.name,
                panchangContext: vm.todayPanchang
            )
        }
        .fullScreenCover(isPresented: $showMeditationMode) {
            AmbientMeditationView(vm: vm)
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
                    settingsRotation.toggle()
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(vm.theme.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .symbolEffect(.bounce, value: settingsRotation)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // Centered city name
            Text(vm.currentCity.name)
                .scaledFont(size: 16, weight: .medium)
                .foregroundColor(vm.theme.primaryText)

            if let panchang = vm.todayPanchang {
                HStack(spacing: 4) {
                    Image(systemName: panchang.tithi.paksha == .shukla ? "moon.fill" : "moon")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "B8C4D8"))
                    Text("\(panchang.lunarMonth) \u{00B7} \(panchang.tithi.paksha.rawValue) Paksha \u{00B7} \(formattedDate)")
                        .scaledFont(size: 12, weight: .regular, design: .serif)
                        .foregroundColor(vm.theme.secondaryText)
                        .contentTransition(.interpolate)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.dayOffset)
    }

    // MARK: - Three-Fact Info Bar (Crystalline Capsules)

    private func infoBar(panchang: DailyPanchang) -> some View {
        HStack(spacing: 8) {
            // Capsule 1: Tithi end time
            Button {
                selectedElement = .tithi(panchang.tithi)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "D4A040"))
                        .symbolEffect(.pulse, options: .speed(0.3), isActive: true)
                    Text(formatTime(panchang.tithi.endTime))
                        .scaledFont(size: 14, weight: .medium)
                        .foregroundColor(vm.theme.primaryText)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .deviCard(theme: vm.theme, elevation: .flat, cornerRadius: 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .deviReveal(delay: 0.0, direction: .fadeUp)

            // Capsule 2: Nakshatra name
            Button {
                selectedElement = .nakshatra(panchang.nakshatra)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "B8C4D8"))
                        .symbolEffect(.pulse, isActive: true)
                    Text(panchang.nakshatra.name)
                        .scaledFont(size: 13, weight: .medium, design: .serif)
                        .foregroundColor(vm.theme.primaryText)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .deviCard(theme: vm.theme, elevation: .flat, cornerRadius: 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .deviReveal(delay: 0.08, direction: .fadeUp)

            // Capsule 3: Sunset/Sunrise time
            HStack(spacing: 6) {
                Image(systemName: vm.isDaytime ? "sunset.fill" : "sunrise.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "D4A040"))
                Text(formatTime(vm.isDaytime ? panchang.solar.sunset : panchang.solar.sunrise))
                    .scaledFont(size: 14, weight: .medium)
                    .foregroundColor(vm.theme.primaryText)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .deviCard(theme: vm.theme, elevation: .flat, cornerRadius: 14)
            .deviReveal(delay: 0.16, direction: .fadeUp)
        }
        .padding(.horizontal)
    }

    // MARK: - Banners (grouped: festivals + fasting + eclipse)

    @ViewBuilder
    private var bannersSection: some View {
        let hasBanners = !vm.todayFestivals.isEmpty
            || (vm.todayPanchang?.tithi.fastingType != nil)
            || vm.imminentEclipse != nil

        if hasBanners {
            VStack(spacing: 8) {
                ForEach(vm.todayFestivals, id: \.self) { festival in
                    Button {
                        selectedElement = .festival(festival)
                    } label: {
                        festivalBanner(festival)
                    }
                    .buttonStyle(.plain)
                }

                if let panchang = vm.todayPanchang, let fastType = panchang.tithi.fastingType {
                    let enrichedName = enrichedFastingName(fastType, panchang: panchang)
                    Button {
                        selectedElement = .fastingDay(fastType)
                    } label: {
                        fastingBanner(enrichedName)
                    }
                    .buttonStyle(.plain)
                }

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
            }
            .deviEntrance()
        }
    }

    // MARK: - Fasting Banner

    private func fastingBanner(_ displayName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "c54b2a"))
                .symbolEffect(.variableColor.iterative, options: .speed(0.3), isActive: true)

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
            sparklesIcon

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

    private var sparklesIcon: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "d4a857"))
            .symbolEffect(.pulse, options: .speed(0.5), isActive: true)
    }

    // MARK: - Today's Additional Details (visually distinct groups)

    private var todayDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            OrnamentalDivider("TODAY", theme: vm.theme)

            // Mantra card (long-press → meditation mode)
            if let mantra = PanchangDescriptions.dailyMantra(
                for: Calendar.current.component(.weekday, from: Date())
            ) {
                MantraCard(mantra: mantra, theme: vm.theme) {
                    selectedElement = .mantra(mantra)
                }
                .onLongPressGesture(minimumDuration: 1) {
                    showMeditationMode = true
                }
                .padding(.horizontal)
            }

            // Three distinct visual groups: Vara, Yoga+Karana, Moon arc
            if let panchang = vm.todayPanchang {
                TodayDetailsSection(
                    panchang: panchang,
                    theme: vm.theme,
                    timezoneIdentifier: vm.currentCity.timezoneIdentifier,
                    onTapYoga: { selectedElement = .yoga(panchang.yoga) },
                    onTapKarana: { selectedElement = .karana(panchang.karanas) },
                    onTapVara: { selectedElement = .vara(panchang.varaDeity) }
                )
            }
        }
        .deviEntrance(delay: 0.16)
    }

    // MARK: - Upcoming Events (capped + "Show All")

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            OrnamentalDivider("UPCOMING", theme: vm.theme)

            if !vm.cappedUpcomingEvents.isEmpty {
                VStack(spacing: 0) {
                    ForEach(vm.cappedUpcomingEvents) { event in
                        upcomingEventRow(event)
                    }
                }
                .deviCard(theme: vm.theme, elevation: .raised)
                .padding(.horizontal)

                // "Show All" button
                if vm.upcomingEvents.count > 5 {
                    Button {
                        showAllUpcoming = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Show All \(vm.upcomingEvents.count) Events")
                                .scaledFont(size: 14, weight: .medium)
                                .foregroundColor(vm.theme.accentColor)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(vm.theme.accentColor.opacity(0.6))
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
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

    private func navratriDay(from eventName: String) -> NavratriDay? {
        let days = NavratriDay.goddesses

        if eventName.contains("Navratri Begins") {
            return days.first
        }

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

    /// Always actual today — used for eclipse proximity comparison (not day-navigated)
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = TimeZone(identifier: vm.currentCity.timezoneIdentifier) ?? .current
        return formatter.string(from: vm.displayDate)
    }

    // MARK: - Day Navigation Gesture

    private var dayNavigationGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                dayNavDragOffset = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 60
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    dayNavDragOffset = 0
                    if value.translation.width < -threshold {
                        vm.navigateDay(by: 1)  // Swipe left → next day
                    } else if value.translation.width > threshold {
                        vm.navigateDay(by: -1) // Swipe right → prev day
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    HomeView(vm: PanchangViewModel())
}

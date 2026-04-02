// MARK: - Views/OnboardingView.swift
// 3-page onboarding: Welcome → City (live tithi preview) → Notification presets

import SwiftUI

// MARK: - Notification Preset

private enum NotificationPreset: String, CaseIterable {
    case essential, sacredTimes, minimal

    var title: String {
        switch self {
        case .essential:   return "Essential"
        case .sacredTimes: return "Sacred Times"
        case .minimal:     return "Minimal"
        }
    }

    var description: String {
        switch self {
        case .essential:   return "Sunrise, sunset & daily summary"
        case .sacredTimes: return "All auspicious windows, festivals & eclipses"
        case .minimal:     return "Just a daily morning brief"
        }
    }

    var icon: String {
        switch self {
        case .essential:   return "sunrise.fill"
        case .sacredTimes: return "sparkles"
        case .minimal:     return "bell"
        }
    }

    var dailySummary: Bool { true }
    var sunrise: Bool { self != .minimal }
    var sunset: Bool { self != .minimal }
    var rahuKalam: Bool { self == .sacredTimes }
    var abhijit: Bool { self == .sacredTimes }
    var brahma: Bool { self == .sacredTimes }
    var navratri: Bool { self == .sacredTimes }
    var eclipse: Bool { self == .sacredTimes }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @ObservedObject var vm: PanchangViewModel

    // Page navigation
    @State private var currentPage = 0
    @State private var showCityPicker = false

    // Notification preset
    @State private var selectedPreset: NotificationPreset = .essential

    // City selection state
    @State private var citySelected = false

    // Birth data (optional onboarding step)
    @State private var showBirthDataStep = false
    @State private var birthDataAppeared = false

    // Per-page entrance animation triggers
    @State private var welcomeAppeared = false
    @State private var cityPageAppeared = false
    @State private var previewAppeared = false
    @State private var notifPageAppeared = false

    // Moon glow animation
    @State private var glowPhase = false

    private var theme: DeviTheme { vm.theme }
    private var isDaytime: Bool {
        vm.timePeriod == .morning || vm.timePeriod == .afternoon
    }

    var body: some View {
        ZStack {
            // Background — theme-adaptive
            theme.backgroundGradient
                .ignoresSafeArea()
            StarFieldView(isDaytime: isDaytime, timePeriod: vm.timePeriod)
                .ignoresSafeArea()

            // Page content — button-driven, no swipe
            Group {
                switch currentPage {
                case 0:  welcomePage
                case 1:  cityPage
                case 2:  birthDataPage
                default: notificationPage
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            // Location resolving overlay
            if vm.isResolvingLocation {
                Color.black.opacity(0.20)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    ProgressView()
                        .tint(theme.accentColor)

                    Text("Finding your location…")
                        .scaledFont(size: 14, weight: .medium)
                        .foregroundColor(theme.primaryText)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .deviCard(theme: theme, elevation: .raised, cornerRadius: 16)
                .padding(.horizontal, 40)
            }
        }
        .onChange(of: vm.isResolvingLocation) { _, isResolving in
            if !isResolving && currentPage == 1 && !citySelected {
                // Location resolved — show preview
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    citySelected = true
                }
                triggerPreviewAnimation()
            }
        }
        .sheet(isPresented: $showCityPicker) {
            CityPickerView(selectedCity: vm.currentCity) { city in
                vm.selectCity(city)
                showCityPicker = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    citySelected = true
                }
                triggerPreviewAnimation()
            }
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                // Hero moon — decorative half moon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "B8C4D8").opacity(glowPhase ? 0.25 : 0.12),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Canvas { context, size in
                        drawMoon(
                            context: context,
                            size: size,
                            illumination: 0.5,
                            isWaxing: true
                        )
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                }
                .scaleEffect(welcomeAppeared ? 1 : 0.7)
                .opacity(welcomeAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: welcomeAppeared)

                // App name
                Text("Devi")
                    .scaledFont(size: 36, weight: .regular, design: .serif)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "d4a857"), Color(hex: "c49a4a")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(welcomeAppeared ? 1 : 0)
                    .offset(y: welcomeAppeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.5).delay(0.25), value: welcomeAppeared)

                // Tagline
                Text("Your Daily Vedic Companion")
                    .scaledFont(size: 17, weight: .regular)
                    .foregroundColor(theme.secondaryText)
                    .opacity(welcomeAppeared ? 1 : 0)
                    .offset(y: welcomeAppeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: welcomeAppeared)

                // Verse — poetic, not a feature list
                VStack(spacing: 16) {
                    verseLine("Know the moon's phase", delay: 0.55)
                    verseLine("Observe sacred hours", delay: 0.65)
                    verseLine("Celebrate each festival", delay: 0.75)
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            // Continue button
            Button {
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentPage = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    cityPageAppeared = true
                }
            } label: {
                Text("Continue")
            }
            .deviButton(.primary)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .opacity(welcomeAppeared ? 1 : 0)
            .offset(y: welcomeAppeared ? 0 : 16)
            .animation(.easeOut(duration: 0.5).delay(0.9), value: welcomeAppeared)
        }
        .onAppear {
            withAnimation {
                welcomeAppeared = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
        }
    }

    // MARK: - Page 2: City Selection

    private var cityPage: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 48)

                    if !citySelected {
                        // State A: Before city selection
                        citySelectionContent
                    } else {
                        // State B: After city selection — show preview
                        cityPreviewContent
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            // Continue button (visible only after city selected)
            if citySelected {
                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentPage = 2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        birthDataAppeared = true
                    }
                } label: {
                    Text("Continue")
                }
                .deviButton(.primary)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(previewAppeared ? 1 : 0)
                .offset(y: previewAppeared ? 0 : 12)
                .animation(.easeOut(duration: 0.4).delay(0.7), value: previewAppeared)
            }
        }
    }

    // State A: City selection UI
    private var citySelectionContent: some View {
        VStack(spacing: 24) {
            // Title
            Text("Where will you observe?")
                .scaledFont(size: 22, weight: .regular, design: .serif)
                .foregroundColor(theme.primaryText)
                .opacity(cityPageAppeared ? 1 : 0)
                .offset(y: cityPageAppeared ? 0 : 12)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: cityPageAppeared)

            Text("Panchang times are calculated for your city")
                .scaledFont(size: 14, weight: .regular)
                .foregroundColor(theme.secondaryText)
                .opacity(cityPageAppeared ? 1 : 0)
                .offset(y: cityPageAppeared ? 0 : 12)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: cityPageAppeared)

            // Use My Location
            Button {
                vm.requestLocation()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                    Text("Use My Location")
                }
            }
            .deviButton(.primary)
            .padding(.horizontal, 32)
            .disabled(vm.isResolvingLocation)
            .opacity(cityPageAppeared ? 1 : 0)
            .offset(y: cityPageAppeared ? 0 : 12)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: cityPageAppeared)

            // Separator
            Text("or choose your city")
                .scaledFont(size: 14, weight: .regular)
                .foregroundColor(theme.secondaryText.opacity(0.6))
                .opacity(cityPageAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: cityPageAppeared)

            // City chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(UserCity.popularCities.prefix(12))) { city in
                        Button {
                            vm.selectCity(city)
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                citySelected = true
                            }
                            triggerPreviewAnimation()
                        } label: {
                            Text(city.name)
                                .scaledFont(size: 14, weight: .medium)
                                .foregroundColor(theme.primaryText)
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(theme.primaryText.opacity(0.08))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(theme.primaryText.opacity(0.10), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            .opacity(cityPageAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.45), value: cityPageAppeared)

            // Search link
            Button {
                if !vm.isResolvingLocation {
                    showCityPicker = true
                }
            } label: {
                Text("Search all cities")
                    .scaledFont(size: 14, weight: .medium)
                    .foregroundColor(theme.accentColor.opacity(0.7))
            }
            .opacity(cityPageAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: cityPageAppeared)

            Spacer().frame(height: 32)
        }
    }

    // State B: Live tithi preview after city selection
    private var cityPreviewContent: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 24)

            // City name with checkmark
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.auspiciousColor)

                Text(vm.currentCity.name)
                    .scaledFont(size: 17, weight: .semibold)
                    .foregroundColor(theme.primaryText)
            }
            .opacity(previewAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4), value: previewAppeared)

            // Moon medallion — actual phase for user's city
            if let panchang = vm.todayPanchang {
                let illum = moonIllumination(
                    number: panchang.tithi.number,
                    paksha: panchang.tithi.paksha
                )
                let isWaxing = panchang.tithi.paksha == .shukla

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "B8C4D8").opacity(glowPhase ? 0.25 : 0.12),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 25,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)

                    Canvas { context, size in
                        drawMoon(
                            context: context,
                            size: size,
                            illumination: illum,
                            isWaxing: isWaxing
                        )
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                }
                .scaleEffect(previewAppeared ? 1 : 0.5)
                .opacity(previewAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.1), value: previewAppeared)

                // Tithi name
                Text(panchang.tithi.name.uppercased())
                    .scaledFont(size: 24, weight: .regular, design: .serif)
                    .tracking(3)
                    .foregroundColor(theme.primaryText)
                    .opacity(previewAppeared ? 1 : 0)
                    .offset(y: previewAppeared ? 0 : 8)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: previewAppeared)

                // Paksha + Nakshatra
                Text("\(panchang.tithi.paksha == .shukla ? "Shukla" : "Krishna") Paksha · \(panchang.nakshatra.name)")
                    .scaledFont(size: 13, weight: .regular)
                    .foregroundColor(theme.secondaryText)
                    .opacity(previewAppeared ? 1 : 0)
                    .offset(y: previewAppeared ? 0 : 8)
                    .animation(.easeOut(duration: 0.4).delay(0.45), value: previewAppeared)

                // "Your panchang awaits"
                HStack(spacing: 4) {
                    Text("Your panchang awaits")
                        .scaledFont(size: 13, weight: .medium)
                        .foregroundColor(theme.accentColor)
                    Text("✦")
                        .font(.system(size: 10))
                        .foregroundColor(theme.accentColor)
                }
                .opacity(previewAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.6), value: previewAppeared)
            } else {
                // Fallback if panchang hasn't loaded yet
                ProgressView()
                    .tint(theme.accentColor)
                    .padding(.top, 24)
            }

            Spacer().frame(height: 16)
        }
    }

    // MARK: - Page 3: Birth Data (Optional)

    private var birthDataPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                // Icon
                Image(systemName: "moon.stars")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(theme.accentColor)
                    .opacity(birthDataAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: birthDataAppeared)

                // Title
                Text("Your Daily Vedic Reading")
                    .scaledFont(size: 24, weight: .regular, design: .serif)
                    .foregroundColor(theme.primaryText)
                    .opacity(birthDataAppeared ? 1 : 0)
                    .offset(y: birthDataAppeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: birthDataAppeared)

                // Description
                Text("Enter your birth details to receive a personalized daily horoscope based on your Moon rashi and planetary transits.")
                    .scaledFont(size: 15, weight: .regular)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .opacity(birthDataAppeared ? 1 : 0)
                    .offset(y: birthDataAppeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: birthDataAppeared)

                // Features
                VStack(spacing: 10) {
                    birthDataFeature(icon: "sparkle", text: "Daily theme, do's and don'ts", delay: 0.4)
                    birthDataFeature(icon: "heart.fill", text: "Love, work, health & spirituality", delay: 0.5)
                    birthDataFeature(icon: "lock.shield", text: "All data stays on your device", delay: 0.6)
                }
                .padding(.horizontal, 32)
            }
            .padding(.horizontal, 16)

            Spacer()

            VStack(spacing: 12) {
                // Set up button
                Button {
                    showBirthDataStep = true
                } label: {
                    Text("Enter Birth Details")
                }
                .deviButton(.primary)
                .padding(.horizontal, 32)
                .opacity(birthDataAppeared ? 1 : 0)
                .offset(y: birthDataAppeared ? 0 : 12)
                .animation(.easeOut(duration: 0.5).delay(0.7), value: birthDataAppeared)

                // Skip button
                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentPage = 3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        notifPageAppeared = true
                    }
                } label: {
                    Text("Skip for Now")
                        .scaledFont(size: 14, weight: .medium)
                        .foregroundColor(theme.secondaryText.opacity(0.7))
                }
                .opacity(birthDataAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.8), value: birthDataAppeared)
            }
            .padding(.bottom, 48)
        }
        .sheet(isPresented: $showBirthDataStep) {
            BirthDataInputView(
                theme: theme,
                currentCity: vm.currentCity,
                existingData: nil,
                onSave: { data in
                    vm.saveBirthData(data)
                    showBirthDataStep = false
                    // Move to notifications page
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentPage = 3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        notifPageAppeared = true
                    }
                },
                onCancel: {
                    showBirthDataStep = false
                }
            )
        }
    }

    private func birthDataFeature(icon: String, text: String, delay: Double) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(theme.accentColor)
                .frame(width: 24)

            Text(text)
                .scaledFont(size: 14, weight: .regular)
                .foregroundColor(theme.primaryText.opacity(0.8))

            Spacer()
        }
        .opacity(birthDataAppeared ? 1 : 0)
        .offset(y: birthDataAppeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(delay), value: birthDataAppeared)
    }

    // MARK: - Page 4: Notification Presets

    private var notificationPage: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 48)

                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(theme.accentColor)
                            .opacity(notifPageAppeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: notifPageAppeared)

                        Text("Stay Connected")
                            .scaledFont(size: 24, weight: .regular, design: .serif)
                            .foregroundColor(theme.primaryText)
                            .opacity(notifPageAppeared ? 1 : 0)
                            .offset(y: notifPageAppeared ? 0 : 8)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: notifPageAppeared)

                        Text("Choose how Devi keeps you in rhythm")
                            .scaledFont(size: 15, weight: .regular)
                            .foregroundColor(theme.secondaryText)
                            .opacity(notifPageAppeared ? 1 : 0)
                            .offset(y: notifPageAppeared ? 0 : 8)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: notifPageAppeared)
                    }

                    // Preset cards
                    VStack(spacing: 12) {
                        ForEach(Array(NotificationPreset.allCases.enumerated()), id: \.element) { index, preset in
                            presetCard(preset, delay: 0.4 + Double(index) * 0.1)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Reassurance
                    Text("You can change these anytime in Settings")
                        .scaledFont(size: 12, weight: .regular)
                        .foregroundColor(theme.secondaryText.opacity(0.6))
                        .opacity(notifPageAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.75), value: notifPageAppeared)
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            // Begin Your Journey button
            Button {
                completeOnboardingFlow()
            } label: {
                Text("Begin Your Journey")
            }
            .deviButton(.primary)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .opacity(notifPageAppeared ? 1 : 0)
            .offset(y: notifPageAppeared ? 0 : 12)
            .animation(.easeOut(duration: 0.5).delay(0.85), value: notifPageAppeared)
        }
    }

    // MARK: - Subviews

    private func verseLine(_ text: String, delay: Double) -> some View {
        Text(text)
            .scaledFont(size: 17, weight: .regular, design: .serif)
            .foregroundColor(theme.secondaryText)
            .opacity(welcomeAppeared ? 1 : 0)
            .offset(y: welcomeAppeared ? 0 : 10)
            .animation(.easeOut(duration: 0.6).delay(delay), value: welcomeAppeared)
    }

    private func presetCard(_ preset: NotificationPreset, delay: Double) -> some View {
        let isSelected = selectedPreset == preset

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPreset = preset
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: preset.icon)
                    .font(.system(size: 20))
                    .foregroundColor(theme.accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.title)
                        .scaledFont(size: 16, weight: .semibold)
                        .foregroundColor(theme.primaryText)

                    Text(preset.description)
                        .scaledFont(size: 13, weight: .regular)
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? theme.accentColor : theme.secondaryText.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(theme.accentColor)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.primaryText.opacity(theme.isLight ? 0.04 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? theme.accentColor.opacity(0.6) : theme.primaryText.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .opacity(notifPageAppeared ? 1 : 0)
        .offset(y: notifPageAppeared ? 0 : 12)
        .animation(.easeOut(duration: 0.5).delay(delay), value: notifPageAppeared)
    }

    // MARK: - Moon Drawing

    private func drawMoon(
        context: GraphicsContext,
        size: CGSize,
        illumination: CGFloat,
        isWaxing: Bool
    ) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2

        // Full silver disc
        let moonPath = Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.fill(moonPath, with: .color(Color(hex: "B8C4D8").opacity(0.9)))

        let darkColor = Color(hex: "0B1026").opacity(0.92)

        // Dark half
        var darkHalf = Path()
        if isWaxing {
            darkHalf.addArc(center: center, radius: radius, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
            darkHalf.closeSubpath()
        } else {
            darkHalf.addArc(center: center, radius: radius, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: false)
            darkHalf.closeSubpath()
        }
        context.fill(darkHalf, with: .color(darkColor))

        // Terminator ellipse
        let terminatorWidth = radius * 2 * abs(illumination * 2 - 1)
        let terminatorRect = CGRect(
            x: center.x - terminatorWidth / 2,
            y: center.y - radius,
            width: terminatorWidth,
            height: radius * 2
        )
        let terminatorPath = Path(ellipseIn: terminatorRect)

        if illumination > 0.5 {
            context.fill(terminatorPath, with: .color(Color(hex: "B8C4D8").opacity(0.9)))
        } else {
            context.fill(terminatorPath, with: .color(darkColor))
        }
    }

    private func moonIllumination(number: Int, paksha: Paksha) -> CGFloat {
        let num = CGFloat(number)
        if paksha == .shukla {
            return num / 15.0
        } else {
            return 1.0 - (num / 15.0)
        }
    }

    // MARK: - Actions

    private func triggerPreviewAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation {
                previewAppeared = true
            }
        }
    }

    private func completeOnboardingFlow() {
        let preset = selectedPreset
        Task {
            // Request notification authorization
            let _ = await vm.notificationService.requestAuthorization()

            // Map preset to individual booleans
            vm.saveOnboardingNotificationPreferences(
                sunrise: preset.sunrise,
                sunset: preset.sunset,
                rahuKalam: preset.rahuKalam,
                abhijit: preset.abhijit,
                brahma: preset.brahma
            )

            // Set remaining notification prefs directly
            vm.notifDailySummary = preset.dailySummary
            vm.notifNavratriMorning = preset.navratri
            vm.notifEclipseAlert = preset.eclipse

            vm.completeOnboarding()
            vm.loadData()
            await vm.checkNotificationAuthorization()
            await vm.rescheduleNotifications()
        }
    }
}

// MARK: - Panchang Education Sheet (moved from onboarding)

struct PanchangEducationSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let theme = DeviTheme.forPeriod(.brahmaMuhurta)

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Five Limbs
                        VStack(alignment: .leading, spacing: 12) {
                            Text("The Five Limbs of Time")
                                .scaledFont(size: 22, weight: .semibold, design: .serif)
                                .foregroundColor(theme.primaryText)

                            Text("Panchang means pancha (five) + anga (limb) \u{2014} the five elements that define each day in the Vedic calendar.")
                                .scaledFont(size: 15)
                                .foregroundColor(theme.secondaryText)
                                .lineSpacing(4)

                            VStack(spacing: 10) {
                                limbRow(icon: "moon.circle", name: "Tithi", desc: "The lunar day, cycling through 15 phases in each half of the lunar month.")
                                limbRow(icon: "star.circle", name: "Nakshatra", desc: "The moon's celestial mansion \u{2014} one of 27 star clusters the moon visits.")
                                limbRow(icon: "circle.grid.cross", name: "Yoga", desc: "The angular relationship between sun and moon, revealing the day's energy.")
                                limbRow(icon: "square.split.2x1", name: "Karana", desc: "Half of a tithi, governing the suitability of activities during that period.")
                                limbRow(icon: "calendar", name: "Vara", desc: "The weekday, each ruled by a celestial deity and planet.")
                            }
                        }

                        // Sacred Hours
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sacred Hours")
                                .scaledFont(size: 22, weight: .semibold, design: .serif)
                                .foregroundColor(theme.primaryText)

                            Text("Some hours are ideal for new ventures; others are best observed with caution.")
                                .scaledFont(size: 15)
                                .foregroundColor(theme.secondaryText)
                                .lineSpacing(4)

                            VStack(spacing: 10) {
                                timeRow(icon: "checkmark.circle.fill", color: theme.auspiciousColor,
                                       name: "Abhijit Muhurta", desc: "The \"unconquerable moment\" \u{2014} the most auspicious window of the day.")
                                timeRow(icon: "xmark.circle.fill", color: theme.inauspiciousColor,
                                       name: "Rahu Kalam", desc: "A daily period ruled by Rahu. Traditionally avoided for new activities.")
                                timeRow(icon: "checkmark.circle.fill", color: theme.auspiciousColor,
                                       name: "Brahma Muhurta", desc: "The \"creator's hour\" \u{2014} 96 minutes before sunrise. Ideal for meditation.")
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("About Panchang")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "d4a857"))
                }
            }
        }
    }

    private func limbRow(icon: String, name: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(theme.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .scaledFont(size: 15, weight: .semibold)
                    .foregroundColor(theme.primaryText)
                Text(desc)
                    .scaledFont(size: 13)
                    .foregroundColor(theme.secondaryText)
                    .lineSpacing(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 14)
    }

    private func timeRow(icon: String, color: Color, name: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
                .frame(width: 24)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .scaledFont(size: 15, weight: .semibold)
                    .foregroundColor(theme.primaryText)
                Text(desc)
                    .scaledFont(size: 13)
                    .foregroundColor(theme.secondaryText)
                    .lineSpacing(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: theme, elevation: .raised, cornerRadius: 14)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(vm: PanchangViewModel())
}

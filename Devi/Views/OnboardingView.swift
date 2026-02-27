// MARK: - Views/OnboardingView.swift
// 5-screen onboarding: Welcome, Five Limbs, Sacred Hours, Location, Notifications

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var vm: PanchangViewModel
    @State private var currentPage = 0
    @State private var showCityPicker = false

    // Notification toggle states
    @State private var notifSunrise = true
    @State private var notifSunset = true
    @State private var notifRahuKalam = true
    @State private var notifAbhijit = false
    @State private var notifBrahma = false

    private let onboardingTheme = DeviTheme.forPeriod(.brahmaMuhurta)

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            ZStack {
                onboardingTheme.backgroundGradient
                    .ignoresSafeArea()
                StarFieldView(isDaytime: false, timePeriod: .brahmaMuhurta)
                    .ignoresSafeArea()
            }

            // Page content
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                fiveLimbsPage.tag(1)
                sacredHoursPage.tag(2)
                locationPage.tag(3)
                notificationPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom page indicator
            if currentPage < 4 {
                pageIndicator
                    .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showCityPicker) {
            CityPickerView(selectedCity: vm.currentCity) { city in
                vm.selectCity(city)
                showCityPicker = false
                withAnimation { currentPage = 4 }
            }
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index == currentPage
                          ? onboardingTheme.accentColor
                          : onboardingTheme.primaryText.opacity(0.2))
                    .frame(width: index == currentPage ? 8 : 6,
                           height: index == currentPage ? 8 : 6)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(onboardingTheme.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "sun.max")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(onboardingTheme.accentColor)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                Text("Devi")
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundColor(onboardingTheme.primaryText)

                Text("Your Vedic Calendar Companion")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(onboardingTheme.secondaryText)
            }

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Begin")
            }
            .deviButton(.primary)
            .padding(.horizontal, 32)
            .padding(.bottom, 64)
        }
    }

    // MARK: - Page 2: The Five Limbs of Time

    private var fiveLimbsPage: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The Five Limbs of Time")
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .foregroundColor(onboardingTheme.primaryText)

                        Text("Panchang means pancha (five) + anga (limb) — the five elements that define each day in the Vedic calendar.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(onboardingTheme.secondaryText)
                            .lineSpacing(4)
                    }
                    .padding(.top, 48)

                    // Staggered list of 5 elements
                    VStack(spacing: 12) {
                        limbRow(icon: "moon.circle", name: "Tithi", desc: "The lunar day, cycling through 15 phases in each half of the lunar month.")
                        limbRow(icon: "star.circle", name: "Nakshatra", desc: "The moon's celestial mansion — one of 27 star clusters the moon visits.")
                        limbRow(icon: "circle.grid.cross", name: "Yoga", desc: "The angular relationship between sun and moon, revealing the day's energy.")
                        limbRow(icon: "square.split.2x1", name: "Karana", desc: "Half of a tithi, governing the suitability of activities during that period.")
                        limbRow(icon: "calendar", name: "Vara", desc: "The weekday, each ruled by a celestial deity and planet.")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)

            // Bottom buttons
            HStack {
                Button {
                    withAnimation { currentPage = 3 }
                } label: {
                    Text("Skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(onboardingTheme.accentColor.opacity(0.7))
                }

                Spacer()

                Button {
                    withAnimation { currentPage = 2 }
                } label: {
                    Text("Next")
                }
                .deviButton(.primary)
                .frame(width: 120)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 64)
        }
    }

    private func limbRow(icon: String, name: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(onboardingTheme.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(onboardingTheme.primaryText)

                Text(desc)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(onboardingTheme.secondaryText)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: onboardingTheme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Page 3: Sacred Hours

    private var sacredHoursPage: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sacred Hours")
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .foregroundColor(onboardingTheme.primaryText)

                        Text("Some hours are ideal for new ventures; others are best observed with caution. Devi tracks these windows for you.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(onboardingTheme.secondaryText)
                            .lineSpacing(4)
                    }
                    .padding(.top, 48)

                    VStack(spacing: 12) {
                        timeWindowExample(
                            icon: "checkmark.circle.fill",
                            color: onboardingTheme.auspiciousColor,
                            name: "Abhijit Muhurta",
                            desc: "The \"unconquerable moment\" — the most auspicious window of the day, ideal for starting important work."
                        )
                        timeWindowExample(
                            icon: "xmark.circle.fill",
                            color: onboardingTheme.inauspiciousColor,
                            name: "Rahu Kalam",
                            desc: "A daily period ruled by Rahu. Traditionally avoided for beginning new activities or journeys."
                        )
                        timeWindowExample(
                            icon: "checkmark.circle.fill",
                            color: onboardingTheme.auspiciousColor,
                            name: "Brahma Muhurta",
                            desc: "The \"creator's hour\" — 96 minutes before sunrise. Ideal for meditation, study, and spiritual practice."
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollBounceBehavior(.basedOnSize)

            HStack {
                Button {
                    withAnimation { currentPage = 3 }
                } label: {
                    Text("Skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(onboardingTheme.accentColor.opacity(0.7))
                }

                Spacer()

                Button {
                    withAnimation { currentPage = 3 }
                } label: {
                    Text("Next")
                }
                .deviButton(.primary)
                .frame(width: 120)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 64)
        }
    }

    private func timeWindowExample(icon: String, color: Color, name: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(onboardingTheme.primaryText)

                Text(desc)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(onboardingTheme.secondaryText)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deviCard(theme: onboardingTheme, elevation: .raised, cornerRadius: 16)
    }

    // MARK: - Page 4: Location

    private var locationPage: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(onboardingTheme.accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(onboardingTheme.accentColor)
            }
            .padding(.bottom, 28)

            VStack(spacing: 12) {
                Text("Your Sacred Geography")
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundColor(onboardingTheme.primaryText)

                Text("Panchang calculations depend on your\nsunrise and sunset times.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(onboardingTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    vm.requestLocation()
                    withAnimation { currentPage = 4 }
                } label: {
                    Text("Allow Location")
                }
                .deviButton(.primary)

                Button {
                    showCityPicker = true
                } label: {
                    Text("Choose city manually")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(onboardingTheme.accentColor.opacity(0.7))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 64)
        }
    }

    // MARK: - Page 5: Notifications

    private var notificationPage: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(onboardingTheme.accentColor)

                        Text("Stay Attuned")
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .foregroundColor(onboardingTheme.primaryText)

                        Text("Get notified for important daily times")
                            .font(.system(size: 15))
                            .foregroundColor(onboardingTheme.secondaryText)
                    }
                    .padding(.top, 48)

                    // Notification toggles
                    VStack(spacing: 0) {
                        notifToggle("Sunrise", icon: "sunrise.fill", isOn: $notifSunrise)
                        Divider().background(onboardingTheme.primaryText.opacity(0.08))
                        notifToggle("Sunset", icon: "sunset.fill", isOn: $notifSunset)
                        Divider().background(onboardingTheme.primaryText.opacity(0.08))
                        notifToggle("Rahu Kalam Warning", icon: "exclamationmark.circle", isOn: $notifRahuKalam)
                        Divider().background(onboardingTheme.primaryText.opacity(0.08))
                        notifToggle("Abhijit Muhurta", icon: "checkmark.circle", isOn: $notifAbhijit)
                        Divider().background(onboardingTheme.primaryText.opacity(0.08))
                        notifToggle("Brahma Muhurta", icon: "moon.stars", isOn: $notifBrahma)
                    }
                    .deviCard(theme: onboardingTheme, elevation: .raised)
                    .padding(.horizontal, 24)

                    Text("You can change these anytime in settings")
                        .font(.system(size: 13))
                        .foregroundColor(onboardingTheme.secondaryText.opacity(0.6))
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            Button {
                vm.saveOnboardingNotificationPreferences(
                    sunrise: notifSunrise,
                    sunset: notifSunset,
                    rahuKalam: notifRahuKalam,
                    abhijit: notifAbhijit,
                    brahma: notifBrahma
                )
                vm.completeOnboarding()
                vm.loadData()
            } label: {
                Text("Begin")
            }
            .deviButton(.primary)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private func notifToggle(_ label: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(onboardingTheme.accentColor)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(onboardingTheme.primaryText)

            Spacer()

            Toggle("", isOn: isOn)
                .tint(onboardingTheme.accentColor)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(vm: PanchangViewModel())
}

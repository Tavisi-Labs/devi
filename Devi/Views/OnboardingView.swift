// MARK: - Views/OnboardingView.swift
// 2-screen onboarding: Welcome + Location, then Notifications

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
        ZStack {
            // Background
            ZStack {
                onboardingTheme.backgroundGradient
                    .ignoresSafeArea()
                StarFieldView(isDaytime: false, timePeriod: .brahmaMuhurta)
                    .ignoresSafeArea()
            }

            // Page content — simple 2-page flow, no page indicator needed
            TabView(selection: $currentPage) {
                welcomeLocationPage.tag(0)
                notificationPage.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .sheet(isPresented: $showCityPicker) {
            CityPickerView(selectedCity: vm.currentCity) { city in
                vm.selectCity(city)
                showCityPicker = false
                withAnimation { currentPage = 1 }
            }
        }
    }

    // MARK: - Page 1: Welcome + Location

    private var welcomeLocationPage: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 48)

                    // App icon
                    ZStack {
                        Circle()
                            .fill(onboardingTheme.accentColor.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "sun.max")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(onboardingTheme.accentColor)
                    }

                    // Title + tagline
                    VStack(spacing: 8) {
                        Text("Devi")
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundColor(onboardingTheme.primaryText)

                        Text("Your Light Through Each Day")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(onboardingTheme.secondaryText)
                    }

                    Spacer().frame(height: 12)

                    // Location prompt
                    Text("Where will you observe today's panchang?")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(onboardingTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // Use My Location button
                    Button {
                        vm.requestLocation()
                        withAnimation { currentPage = 1 }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                            Text("Use My Location")
                        }
                    }
                    .deviButton(.primary)
                    .padding(.horizontal, 32)

                    // "or choose your city" separator
                    Text("or choose your city")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(onboardingTheme.secondaryText.opacity(0.6))

                    // Popular city chips — horizontal scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(UserCity.popularCities.prefix(12))) { city in
                                Button {
                                    vm.selectCity(city)
                                    withAnimation { currentPage = 1 }
                                } label: {
                                    Text(city.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(onboardingTheme.primaryText)
                                        .lineLimit(1)
                                        .fixedSize()
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(onboardingTheme.primaryText.opacity(0.08))
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(onboardingTheme.primaryText.opacity(0.10), lineWidth: 0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Search other cities
                    Button {
                        showCityPicker = true
                    } label: {
                        Text("Search other cities")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(onboardingTheme.accentColor.opacity(0.7))
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }

    // MARK: - Page 2: Notifications + Begin

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
                Task {
                    // Request notification permission before saving prefs
                    let _ = await vm.notificationService.requestAuthorization()
                    vm.saveOnboardingNotificationPreferences(
                        sunrise: notifSunrise,
                        sunset: notifSunset,
                        rahuKalam: notifRahuKalam,
                        abhijit: notifAbhijit,
                        brahma: notifBrahma
                    )
                    vm.completeOnboarding()
                    vm.loadData()
                    await vm.checkNotificationAuthorization()
                    await vm.rescheduleNotifications()
                }
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
                                .font(.system(size: 22, weight: .semibold, design: .serif))
                                .foregroundColor(theme.primaryText)

                            Text("Panchang means pancha (five) + anga (limb) \u{2014} the five elements that define each day in the Vedic calendar.")
                                .font(.system(size: 15))
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
                                .font(.system(size: 22, weight: .semibold, design: .serif))
                                .foregroundColor(theme.primaryText)

                            Text("Some hours are ideal for new ventures; others are best observed with caution.")
                                .font(.system(size: 15))
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                Text(desc)
                    .font(.system(size: 13))
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                Text(desc)
                    .font(.system(size: 13))
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

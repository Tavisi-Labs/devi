// MARK: - Views/OnboardingView.swift
// Simple 2-screen onboarding: location + notifications

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

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            notificationPage.tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "1a0a2e"), Color(hex: "2d1854")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                StarFieldView(isDaytime: false, timePeriod: .brahmaMuhurta)
                    .ignoresSafeArea()
            }
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

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "d4a857").opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color(hex: "d4a857"))
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                Text("Devi")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(Color(hex: "f5f0e8"))

                Text("Your daily panchang companion")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color(hex: "f5f0e8").opacity(0.6))
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Devi uses your location to calculate\naccurate sunrise and prayer times.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "f5f0e8").opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Button {
                    vm.requestLocation()
                    withAnimation { currentPage = 1 }
                } label: {
                    Text("Allow Location")
                }
                .deviButton(.primary)

                Button {
                    showCityPicker = true
                } label: {
                    Text("Choose city manually")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "d4a857").opacity(0.7))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Page 2: Notifications

    private var notificationPage: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(Color(hex: "d4a857"))

                        Text("Stay Connected")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(Color(hex: "f5f0e8"))

                        Text("Get notified for important daily times")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "f5f0e8").opacity(0.5))
                    }
                    .padding(.top, 48)

                    // Notification toggles
                    VStack(spacing: 0) {
                        notifToggle("Sunrise", icon: "sunrise.fill", isOn: $notifSunrise)
                        Divider().background(Color.white.opacity(0.1))
                        notifToggle("Sunset", icon: "sunset.fill", isOn: $notifSunset)
                        Divider().background(Color.white.opacity(0.1))
                        notifToggle("Rahu Kalam Warning", icon: "exclamationmark.circle", isOn: $notifRahuKalam)
                        Divider().background(Color.white.opacity(0.1))
                        notifToggle("Abhijit Muhurta", icon: "checkmark.circle", isOn: $notifAbhijit)
                        Divider().background(Color.white.opacity(0.1))
                        notifToggle("Brahma Muhurta", icon: "moon.stars", isOn: $notifBrahma)
                    }
                    .deviCard(theme: DeviTheme.forPeriod(.brahmaMuhurta))
                    .padding(.horizontal, 24)

                    Text("You can change these anytime in settings")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "f5f0e8").opacity(0.35))
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
                .foregroundColor(Color(hex: "d4a857"))
                .frame(width: 24)

            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(hex: "f5f0e8"))

            Spacer()

            Toggle("", isOn: isOn)
                .tint(Color(hex: "d4a857"))
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

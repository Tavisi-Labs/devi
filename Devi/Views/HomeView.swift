// MARK: - Views/HomeView.swift
// The single main screen of the app

import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: PanchangViewModel
    @State private var showSettings = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 28) {

                // MARK: - Header (location + settings)
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
                        currentTime: vm.currentTimeText,
                        countdownText: vm.countdownText,
                        countdownLabel: vm.countdownLabel,
                        theme: vm.theme,
                        timezoneIdentifier: vm.currentCity.timezoneIdentifier
                    )
                }

                // MARK: - Fasting indicator (if applicable)
                if let fastType = vm.todayPanchang?.tithi.fastingType {
                    fastingBanner(fastType)
                        .deviEntrance()
                }

                // MARK: - Time Windows
                if !vm.activeTimeWindows.isEmpty {
                    TimeWindowsCard(
                        windows: vm.activeTimeWindows,
                        theme: vm.theme,
                        timezoneIdentifier: vm.currentCity.timezoneIdentifier
                    )
                    .padding(.horizontal)
                }

                // MARK: - Navratri Card (conditional)
                if let navDay = vm.currentNavratriDay {
                    NavratriCard(day: navDay, theme: vm.theme)
                        .padding(.horizontal)
                }

                // MARK: - Today's Details
                todayDetails

                // MARK: - Upcoming
                upcomingSection

            }
            .padding(.bottom, 60)
            .padding(.top, 8)
        }
        // Full-screen adaptive gradient + star field background
        .background {
            ZStack {
                vm.theme.backgroundGradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 30), value: vm.timePeriod)

                StarFieldView(isDaytime: vm.isDaytime, timePeriod: vm.timePeriod)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 5), value: vm.timePeriod)
            }
        }
        .onAppear {
            vm.requestLocation()
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
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                    Text(vm.currentCity.name)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(vm.theme.secondaryText)
            }
            
            Spacer()
            
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(vm.theme.secondaryText)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tithi Display
    
    private var tithiSection: some View {
        VStack(spacing: 6) {
            if let panchang = vm.todayPanchang {
                Text("\(panchang.lunarMonth), \(panchang.tithi.paksha.rawValue) Paksha")
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(vm.theme.secondaryText)

                Text(panchang.tithi.name.uppercased())
                    .deviLabel(.sacredTitle, theme: vm.theme)
                    .tracking(2)

                Text("\(panchang.nakshatra.name) Nakshatra")
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(vm.theme.secondaryText)
            }
        }
    }
    
    // MARK: - Fasting Banner
    
    private func fastingBanner(_ type: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "c54b2a"))
            
            Text("Today is \(type)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(vm.theme.primaryText)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "c54b2a").opacity(0.15))
        .deviCard(theme: vm.theme, cornerRadius: 12)
        .padding(.horizontal)
    }
    
    // MARK: - Today's Additional Details
    
    private var todayDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            OrnamentalDivider("TODAY", theme: vm.theme)

            if let panchang = vm.todayPanchang {
                VStack(spacing: 12) {
                    detailRow("Yoga", value: panchang.yoga.name, sacredValue: true)
                    detailRow("Karana", value: panchang.karana.name, sacredValue: true)

                    if let moonrise = panchang.solar.moonrise {
                        detailRow("Moonrise", value: formatTime(moonrise))
                    }
                    if let moonset = panchang.solar.moonset {
                        detailRow("Moonset", value: formatTime(moonset))
                    }

                    detailRow("Vara", value: panchang.varaDeity, sacredValue: true)
                }
                .padding(.vertical, 16)
                .deviCard(theme: vm.theme)
                .padding(.horizontal)
            }
        }
        .deviEntrance(delay: 0.16)
    }
    
    private func detailRow(_ label: String, value: String, sacredValue: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(vm.theme.secondaryText)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .medium, design: sacredValue ? .serif : .default))
                .foregroundColor(vm.theme.primaryText)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Upcoming Events
    
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            OrnamentalDivider("UPCOMING", theme: vm.theme)

            VStack(spacing: 0) {
                ForEach(vm.upcomingEvents) { event in
                    HStack {
                        Circle()
                            .fill(event.type == .fasting ? 
                                  Color(hex: "c54b2a") : vm.theme.accentColor)
                            .frame(width: 6, height: 6)
                        
                        Text(event.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(vm.theme.primaryText)
                        
                        Spacer()
                        
                        Text("in \(event.daysAway) days")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(vm.theme.secondaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
            }
        }
        .deviEntrance(delay: 0.24)
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        deviFormatTime(date, timezoneIdentifier: vm.currentCity.timezoneIdentifier)
    }
}

// MARK: - Preview

#Preview {
    HomeView(vm: PanchangViewModel())
}

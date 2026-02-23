// MARK: - Views/HomeView.swift
// The single main screen of the app

import SwiftUI

struct HomeView: View {
    @ObservedObject var vm: PanchangViewModel
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // Full-screen adaptive gradient background
            vm.theme.backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 30), value: vm.timePeriod)
            
            // Content
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
                            theme: vm.theme
                        )
                    }
                    
                    // MARK: - Fasting indicator (if applicable)
                    if let fastType = vm.todayPanchang?.tithi.fastingType {
                        fastingBanner(fastType)
                    }
                    
                    // MARK: - Time Windows
                    if !vm.activeTimeWindows.isEmpty {
                        TimeWindowsCard(
                            windows: vm.activeTimeWindows,
                            theme: vm.theme
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
                    
                    // Bottom padding for scroll
                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            vm.requestLocation()
            vm.loadData()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(vm: vm)
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
                    .deviLabel(.detail, theme: vm.theme)
                
                Text(panchang.tithi.name.uppercased())
                    .deviLabel(.title, theme: vm.theme)
                    .tracking(2)
                
                Text("\(panchang.nakshatra.name) Nakshatra")
                    .deviLabel(.detail, theme: vm.theme)
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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal)
    }
    
    // MARK: - Today's Additional Details
    
    private var todayDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Rectangle()
                    .fill(vm.theme.primaryText.opacity(0.2))
                    .frame(height: 1)
                
                Text("TODAY")
                    .deviLabel(.section, theme: vm.theme)
                
                Rectangle()
                    .fill(vm.theme.primaryText.opacity(0.2))
                    .frame(height: 1)
            }
            .padding(.horizontal)
            
            if let panchang = vm.todayPanchang {
                VStack(spacing: 12) {
                    detailRow("Yoga", value: panchang.yoga.name)
                    detailRow("Karana", value: panchang.karana.name)
                    
                    if let moonrise = panchang.solar.moonrise {
                        detailRow("Moonrise", value: formatTime(moonrise))
                    }
                    if let moonset = panchang.solar.moonset {
                        detailRow("Moonset", value: formatTime(moonset))
                    }
                    
                    detailRow("Vara", value: panchang.varaDeity)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(vm.theme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(vm.theme.primaryText)
        }
    }
    
    // MARK: - Upcoming Events
    
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming")
                .deviLabel(.section, theme: vm.theme)
                .padding(.horizontal, 20)
            
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
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    HomeView(vm: PanchangViewModel())
}

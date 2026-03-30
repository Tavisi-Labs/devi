// MARK: - Views/SettingsView.swift
// Minimal settings: city selection + notification toggles

import SwiftUI
import MapKit

struct SettingsView: View {
    @ObservedObject var vm: PanchangViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCityPicker = false
    @State private var showPanchangEducation = false
    @State private var apiKey: String = ""

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Location
                Section {
                    Button {
                        showCityPicker = true
                    } label: {
                        HStack {
                            Label("City", systemImage: "location.fill")
                            Spacer()
                            Text(vm.currentCity.name)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                } header: {
                    Text("Location")
                } footer: {
                    Text("Panchang times are calculated for this city.")
                }
                
                // MARK: - Notification Permission Banner
                if !vm.notificationsAuthorized {
                    Section {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Notifications Disabled")
                                        .scaledFont(size: 15, weight: .medium)
                                        .foregroundColor(.primary)
                                    Text("Tap to open Settings")
                                        .scaledFont(size: 13)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: - Text Size
                Section {
                    Picker("Text Size", selection: $vm.fontScale) {
                        ForEach(DeviFontScale.allCases, id: \.self) { scale in
                            Text(scale.rawValue).tag(scale)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Text Size")
                } footer: {
                    Text("Default is 15% larger than Compact. Changes apply immediately.")
                }

                // MARK: - Theme
                Section {
                    ForEach(DeviThemeStyle.allCases) { style in
                        Button {
                            vm.setThemeStyle(style)
                        } label: {
                            HStack(spacing: 12) {
                                // 3 overlapping circles showing the morning palette
                                ThemeSwatchView(style: style)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(style.rawValue)
                                        .scaledFont(size: 15, weight: .medium)
                                        .foregroundColor(.primary)
                                    Text(themeSubtitle(style))
                                        .scaledFont(size: 12)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if vm.themeStyle == style {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "d4a857"))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Theme")
                } footer: {
                    Text("Changes the color palette across all time periods.")
                }

                // MARK: - Notifications
                Section {
                    Toggle(isOn: $vm.notifDailySummary) {
                        Label("Daily Summary", systemImage: "sun.and.horizon")
                    }
                    Toggle(isOn: $vm.notifSunrise) {
                        Label("Sunrise", systemImage: "sunrise.fill")
                    }
                    Toggle(isOn: $vm.notifSunset) {
                        Label("Sunset / Sandhya", systemImage: "sunset.fill")
                    }
                    Toggle(isOn: $vm.notifRahuKalamWarning) {
                        Label("Rahu Kalam Warning", systemImage: "exclamationmark.circle")
                    }
                    Toggle(isOn: $vm.notifAbhijitMuhurta) {
                        Label("Abhijit Muhurta", systemImage: "checkmark.circle")
                    }
                    Toggle(isOn: $vm.notifBrahmaMuhurta) {
                        Label("Brahma Muhurta", systemImage: "moon.stars")
                    }
                    Toggle(isOn: $vm.notifNavratriMorning) {
                        Label("Navratri Daily", systemImage: "sparkle")
                    }
                    Toggle(isOn: $vm.notifEclipseAlert) {
                        Label("Eclipse Alert", systemImage: "moon.circle")
                    }
                    Stepper(value: $vm.notifMinutesBefore, in: 5...60, step: 5) {
                        Label("\(vm.notifMinutesBefore) min before", systemImage: "clock")
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Event notifications are sent \(vm.notifMinutesBefore) minutes before. Daily summary arrives 30 minutes before sunrise.")
                }
                
                // MARK: - Learn
                Section {
                    Button {
                        showPanchangEducation = true
                    } label: {
                        HStack {
                            Label("Learn about Panchang", systemImage: "book")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                } header: {
                    Text("Learn")
                }

                // MARK: - Cosmic Signature (AI)
                Section {
                    HStack {
                        Label("API Key", systemImage: "key")
                        Spacer()
                        if apiKey.isEmpty {
                            Text("Not set")
                                .foregroundColor(.secondary)
                        } else {
                            Text("••••\(String(apiKey.suffix(4)))")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    }

                    SecureField("sk-ant-...", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 14, design: .monospaced))
                        .onChange(of: apiKey) { _, newValue in
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                KeychainHelper.save(key: "anthropic_api_key", value: trimmed)
                            }
                        }
                } header: {
                    Text("Cosmic Signature (AI)")
                } footer: {
                    Text("Optional. Paste your Anthropic API key to get AI-generated daily insights. Without a key, insights are composed from Vedic descriptions offline.")
                }

                // MARK: - About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.9.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "mailto:hello@deviapp.com")!) {
                        Label("Send Feedback", systemImage: "envelope")
                    }

                    Link(destination: URL(string: "https://hareeshnagaraj.github.io/devi/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "https://hareeshnagaraj.github.io/devi/support")!) {
                        Label("Support", systemImage: "questionmark.circle")
                    }

                    Button {
                        vm.resetOnboarding()
                        dismiss()
                    } label: {
                        Label("Restart Onboarding", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("About")
                }
            }
            .tint(Color(hex: "d4a857"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "d4a857"))
                }
            }
            .task {
                await vm.checkNotificationAuthorization()
            }
            .onAppear {
                apiKey = KeychainHelper.read(key: "anthropic_api_key") ?? ""
            }
            .sheet(isPresented: $showCityPicker) {
                CityPickerView(selectedCity: vm.currentCity) { city in
                    vm.selectCity(city)
                    showCityPicker = false
                }
            }
            .sheet(isPresented: $showPanchangEducation) {
                PanchangEducationSheet()
            }
        }
    }
}

// MARK: - City Picker

struct CityPickerView: View {
    let selectedCity: UserCity
    let onSelect: (UserCity) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = CitySearchService()
    @State private var searchText = ""
    @State private var isResolving = false
    @State private var errorMessage: String?

    // MARK: - Popular Cities (shown when search is empty)

    private var popularGrouped: [(String, [UserCity])] {
        let dict = Dictionary(grouping: UserCity.popularCities, by: { $0.country })
        let countryNames = [
            "US": "United States", "IN": "India", "UK": "United Kingdom",
            "GB": "United Kingdom", "CA": "Canada", "SG": "Singapore"
        ]
        return dict
            .sorted { countryNames[$0.key, default: $0.key] < countryNames[$1.key, default: $1.key] }
            .map { (countryNames[$0.key, default: $0.key], $0.value) }
    }

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if isSearchActive {
                    searchResultsSection
                } else {
                    popularCitiesSection
                }
            }
            .searchable(text: $searchText, prompt: "Search any city worldwide")
            .onChange(of: searchText) { _, newValue in
                searchService.updateQuery(newValue)
            }
            .navigationTitle("Choose City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isResolving {
                    resolvingOverlay
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResultsSection: some View {
        if searchService.isSearching {
            Section {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color(hex: "d4a857"))
                    Text("Searching...")
                        .foregroundColor(.secondary)
                        .scaledFont(size: 14)
                    Spacer()
                }
            }
        } else if searchService.suggestions.isEmpty {
            Section {
                Text("No results found")
                    .foregroundColor(.secondary)
            }
        } else {
            Section("Results") {
                ForEach(searchService.suggestions, id: \.self) { completion in
                    Button {
                        resolveAndSelect(completion)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.title)
                                .foregroundColor(.primary)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .scaledFont(size: 13)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Popular Cities

    private var popularCitiesSection: some View {
        ForEach(popularGrouped, id: \.0) { country, cities in
            Section(country) {
                ForEach(cities) { city in
                    Button {
                        onSelect(city)
                        dismiss()
                    } label: {
                        HStack {
                            Text(city.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if city.id == selectedCity.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "d4a857"))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Resolving Overlay

    private var resolvingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .tint(Color(hex: "d4a857"))
                    .scaleEffect(1.2)
                Text("Loading city details...")
                    .scaledFont(size: 14, weight: .medium)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Resolve Search Completion

    private func resolveAndSelect(_ completion: MKLocalSearchCompletion) {
        isResolving = true
        Task {
            do {
                let city = try await searchService.resolveCity(from: completion)
                onSelect(city)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isResolving = false
        }
    }
}

// MARK: - Theme Swatch (3 overlapping circles from morning palette)

private struct ThemeSwatchView: View {
    let style: DeviThemeStyle

    var body: some View {
        let palette = ThemePaletteRegistry.palette(for: style, period: .morning)
        ZStack {
            Circle()
                .fill(Color(hex: palette.bgBottom))
                .frame(width: 22, height: 22)
                .offset(x: 8)

            Circle()
                .fill(Color(hex: palette.bgMid))
                .frame(width: 22, height: 22)

            Circle()
                .fill(Color(hex: palette.bgTop))
                .frame(width: 22, height: 22)
                .offset(x: -8)
        }
        .frame(width: 38, height: 22)
    }
}

/// Short description for each theme style
private func themeSubtitle(_ style: DeviThemeStyle) -> String {
    switch style {
    case .classic:       return "Original dark palette"
    case .vividTemple:   return "Electric saffron & vivid indigo"
    case .sunriseGarden: return "Warm plum, teal & terracotta"
    case .cosmicJewel:   return "Deep space gemstones"
    case .goldenDawn:    return "Brightest, near light-mode"
    }
}

#Preview {
    SettingsView(vm: PanchangViewModel())
}

// MARK: - Views/SettingsView.swift
// Minimal settings: city selection + notification toggles

import SwiftUI
import MapKit
import StoreKit

struct SettingsView: View {
    @ObservedObject var vm: PanchangViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var showCityPicker = false
    @State private var showPanchangEducation = false
    @State private var showWhatsNew = false
    @State private var showBirthDataInput = false
    @State private var apiKey: String = ""

    private var theme: DeviTheme { vm.theme }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // MARK: - Card 1 — Location
                    Text("LOCATION")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 0) {
                        Button {
                            showCityPicker = true
                        } label: {
                            HStack {
                                Label {
                                    Text("City")
                                        .foregroundColor(theme.primaryText)
                                } icon: {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(theme.accentColor)
                                }
                                Spacer()
                                Text(vm.currentCity.name)
                                    .foregroundColor(theme.secondaryText)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(theme.secondaryText.opacity(0.5))
                            }
                            .padding(16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if !vm.notificationsAuthorized {
                            Divider().opacity(0.2)

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
                                            .foregroundColor(theme.primaryText)
                                        Text("Tap to open Settings")
                                            .scaledFont(size: 13)
                                            .foregroundColor(theme.secondaryText)
                                    }
                                    Spacer()
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .deviCard(theme: theme, elevation: .raised)

                    Text("Panchang times are calculated for this city.")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: - Card 1b — Birth Details
                    Text("YOUR HOROSCOPE")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    VStack(spacing: 0) {
                        if let _ = vm.birthData, let natal = vm.natalChart {
                            // Show current birth rashi
                            HStack {
                                Label {
                                    Text("Birth Rashi")
                                        .foregroundColor(theme.primaryText)
                                } icon: {
                                    Image(systemName: "moon.stars")
                                        .foregroundColor(theme.accentColor)
                                }
                                Spacer()
                                Text("\(natal.birthRashi.sanskritName) (\(natal.birthRashi.westernName))")
                                    .foregroundColor(theme.secondaryText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            settingsDivider

                            // Edit birth details
                            Button {
                                showBirthDataInput = true
                            } label: {
                                settingsRow(title: "Edit Birth Details", icon: "pencil", showChevron: true)
                            }
                            .buttonStyle(.plain)

                            settingsDivider

                            // Clear birth data
                            Button {
                                vm.clearBirthData()
                            } label: {
                                HStack {
                                    Label {
                                        Text("Clear Birth Data")
                                            .foregroundColor(.red)
                                    } icon: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red.opacity(0.7))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            // No birth data set
                            Button {
                                showBirthDataInput = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "moon.stars")
                                        .foregroundColor(theme.accentColor)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Set Up Horoscope")
                                            .scaledFont(size: 15, weight: .medium)
                                            .foregroundColor(theme.primaryText)
                                        Text("Enter your birth details for daily readings")
                                            .scaledFont(size: 13)
                                            .foregroundColor(theme.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(theme.secondaryText.opacity(0.5))
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .deviCard(theme: theme, elevation: .raised)

                    if vm.birthData != nil {
                        Text("Your birth data is stored only on this device and is never sent to any server.")
                            .deviLabel(.caption, theme: theme)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: - Card 2 — Display
                    Text("DISPLAY")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Text Size")
                                .scaledFont(size: 15, weight: .medium)
                                .foregroundColor(theme.primaryText)

                            Picker("Text Size", selection: $vm.fontScale) {
                                ForEach(DeviFontScale.allCases, id: \.self) { scale in
                                    Text(scale.rawValue).tag(scale)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Divider().opacity(0.2)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Appearance")
                                .scaledFont(size: 15, weight: .medium)
                                .foregroundColor(theme.primaryText)

                            Picker("Appearance", selection: Binding(
                                get: { vm.appearanceMode },
                                set: { vm.setAppearanceMode($0) }
                            )) {
                                ForEach(DeviAppearanceMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(16)
                    .deviCard(theme: theme, elevation: .raised)

                    Text("Default text is 15% larger than Compact. Auto switches appearance for morning and afternoon.")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: - Card 3 — Theme
                    Text("THEME")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(DeviThemeStyle.allCases.enumerated()), id: \.element.id) { index, style in
                            if index > 0 {
                                Divider().opacity(0.2).padding(.leading, 54)
                            }

                            Button {
                                vm.setThemeStyle(style)
                            } label: {
                                HStack(spacing: 12) {
                                    ThemeSwatchView(style: style)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(style.rawValue)
                                            .scaledFont(size: 15, weight: .medium)
                                            .foregroundColor(theme.primaryText)
                                        Text(themeSubtitle(style))
                                            .scaledFont(size: 12)
                                            .foregroundColor(theme.secondaryText)
                                    }

                                    Spacer()

                                    if vm.themeStyle == style {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(theme.accentColor)
                                            .font(.system(size: 18, weight: .semibold))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(theme.secondaryText.opacity(0.4))
                                            .font(.system(size: 18))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .deviCard(theme: theme, elevation: .raised)

                    Text("Changes the color palette across all time periods.")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: - Card 4 — Notifications
                    Text("NOTIFICATIONS")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    VStack(spacing: 0) {
                        settingsToggle("Daily Summary", icon: "sun.and.horizon", isOn: $vm.notifDailySummary)
                        settingsDivider
                        settingsToggle("Sunrise", icon: "sunrise.fill", isOn: $vm.notifSunrise)
                        settingsDivider
                        settingsToggle("Sunset / Sandhya", icon: "sunset.fill", isOn: $vm.notifSunset)
                        settingsDivider
                        settingsToggle("Rahu Kalam Warning", icon: "exclamationmark.circle", isOn: $vm.notifRahuKalamWarning)
                        settingsDivider
                        settingsToggle("Abhijit Muhurta", icon: "checkmark.circle", isOn: $vm.notifAbhijitMuhurta)
                        settingsDivider
                        settingsToggle("Brahma Muhurta", icon: "moon.stars", isOn: $vm.notifBrahmaMuhurta)
                        settingsDivider
                        settingsToggle("Navratri Daily", icon: "sparkle", isOn: $vm.notifNavratriMorning)
                        settingsDivider
                        settingsToggle("Eclipse Alert", icon: "moon.circle", isOn: $vm.notifEclipseAlert)
                        settingsDivider

                        HStack {
                            Label {
                                Text("\(vm.notifMinutesBefore) min before")
                                    .foregroundColor(theme.primaryText)
                            } icon: {
                                Image(systemName: "clock")
                                    .foregroundColor(theme.accentColor)
                            }
                            Spacer()
                            Stepper("", value: $vm.notifMinutesBefore, in: 5...60, step: 5)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .deviCard(theme: theme, elevation: .raised)

                    Text("Event notifications are sent \(vm.notifMinutesBefore) minutes before. Daily summary arrives 30 minutes before sunrise.")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: - Card 5 — Cosmic Signature
                    Text("COSMIC SIGNATURE (AI)")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    VStack(spacing: 12) {
                        HStack {
                            Label {
                                Text("API Key")
                                    .foregroundColor(theme.primaryText)
                            } icon: {
                                Image(systemName: "key")
                                    .foregroundColor(theme.accentColor)
                            }
                            Spacer()
                            if apiKey.isEmpty {
                                Text("Not set")
                                    .foregroundColor(theme.secondaryText)
                            } else {
                                Text("••••\(String(apiKey.suffix(4)))")
                                    .foregroundColor(theme.secondaryText)
                                    .monospacedDigit()
                            }
                        }

                        SecureField("sk-ant-...", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: 14, design: .monospaced))
                            .padding(10)
                            .background(theme.primaryText.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .onChange(of: apiKey) { _, newValue in
                                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty {
                                    KeychainHelper.save(key: "anthropic_api_key", value: trimmed)
                                }
                            }
                    }
                    .padding(16)
                    .deviCard(theme: theme, elevation: .raised)

                    Text("Optional. Paste your Anthropic API key for AI-generated daily insights. Without a key, insights use Vedic descriptions offline.")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: - Card 6 — About & Learn
                    Text("ABOUT & LEARN")
                        .deviLabel(.caption, theme: theme)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    VStack(spacing: 0) {
                        // 1. Learn about Panchang
                        Button {
                            showPanchangEducation = true
                        } label: {
                            settingsRow(title: "Learn about Panchang", icon: "book", showChevron: true)
                        }
                        .buttonStyle(.plain)

                        settingsDivider

                        // 2. What's New
                        Button {
                            showWhatsNew = true
                        } label: {
                            settingsRow(title: "What's New", icon: "sparkles", showChevron: true)
                        }
                        .buttonStyle(.plain)

                        settingsDivider

                        // 3. Rate Devi
                        Button {
                            requestReview()
                        } label: {
                            settingsRow(title: "Rate Devi", icon: "star", showChevron: false)
                        }
                        .buttonStyle(.plain)

                        settingsDivider

                        // 4. Version + EARLY ACCESS badge
                        HStack {
                            Label {
                                Text("Version")
                                    .foregroundColor(theme.primaryText)
                            } icon: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(theme.accentColor)
                            }
                            Spacer()
                            HStack(spacing: 6) {
                                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.9.0")
                                    .foregroundColor(theme.secondaryText)
                                Text("EARLY ACCESS")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(theme.accentColor)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().stroke(theme.accentColor.opacity(0.4), lineWidth: 0.5))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        settingsDivider

                        // 5. Send Feedback
                        Link(destination: URL(string: "mailto:hello@deviapp.com")!) {
                            settingsRow(title: "Send Feedback", icon: "envelope", showChevron: true)
                        }

                        settingsDivider

                        // 6. Telegram
                        Link(destination: URL(string: "https://t.me/hareeshnagaraj")!) {
                            settingsRow(title: "Telegram", icon: "paperplane", showChevron: true)
                        }

                        settingsDivider

                        // 7. Privacy Policy
                        Link(destination: URL(string: "https://hareeshnagaraj.github.io/devi/privacy")!) {
                            settingsRow(title: "Privacy Policy", icon: "hand.raised", showChevron: true)
                        }

                        settingsDivider

                        // 8. Support
                        Link(destination: URL(string: "https://hareeshnagaraj.github.io/devi/support")!) {
                            settingsRow(title: "Support", icon: "questionmark.circle", showChevron: true)
                        }

                        settingsDivider

                        // 9. Restart Onboarding
                        Button {
                            vm.resetOnboarding()
                            dismiss()
                        } label: {
                            settingsRow(title: "Restart Onboarding", icon: "arrow.counterclockwise", showChevron: false)
                        }
                        .buttonStyle(.plain)
                    }
                    .deviCard(theme: theme, elevation: .raised)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .tint(theme.accentColor)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.accentColor)
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
            .sheet(isPresented: $showWhatsNew) {
                WhatsNewSheet()
            }
            .sheet(isPresented: $showBirthDataInput) {
                BirthDataInputView(
                    theme: theme,
                    currentCity: vm.currentCity,
                    existingData: vm.birthData,
                    onSave: { data in
                        vm.saveBirthData(data)
                        showBirthDataInput = false
                    },
                    onCancel: { showBirthDataInput = false }
                )
            }
        }
    }

    // MARK: - Reusable row helpers

    private func settingsRow(title: String, icon: String, showChevron: Bool) -> some View {
        HStack {
            Label {
                Text(title)
                    .foregroundColor(theme.primaryText)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(theme.accentColor)
            }
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.secondaryText.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func settingsToggle(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label {
                Text(title)
                    .foregroundColor(theme.primaryText)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(theme.accentColor)
            }
        }
        .tint(theme.accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private var settingsDivider: some View {
        Divider().opacity(0.2).padding(.leading, 54)
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
    case .classic:       return "Mahogany library, antique gold"
    case .vividTemple:   return "Oil-lamp saffron & deep indigo"
    case .sunriseGarden: return "Organic earth tones & sage"
    case .cosmicJewel:   return "Gemstone gallery, per-period jewel"
    case .goldenDawn:    return "Golden hour warmth throughout"
    }
}

#Preview {
    SettingsView(vm: PanchangViewModel())
}

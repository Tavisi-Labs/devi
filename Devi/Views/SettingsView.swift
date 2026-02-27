// MARK: - Views/SettingsView.swift
// Minimal settings: city selection + notification toggles

import SwiftUI
import MapKit

struct SettingsView: View {
    @ObservedObject var vm: PanchangViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCityPicker = false
    
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
                    }
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
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("Tap to open Settings")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
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
                
                // MARK: - About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "mailto:hello@deviapp.com")!) {
                        Label("Send Feedback", systemImage: "envelope")
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
            .sheet(isPresented: $showCityPicker) {
                CityPickerView(selectedCity: vm.currentCity) { city in
                    vm.selectCity(city)
                    showCityPicker = false
                }
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
                        .font(.system(size: 14))
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
                                    .font(.system(size: 13))
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
                    .font(.system(size: 14, weight: .medium))
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

#Preview {
    SettingsView(vm: PanchangViewModel())
}

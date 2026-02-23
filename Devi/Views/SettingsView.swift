// MARK: - Views/SettingsView.swift
// Minimal settings: city selection + notification toggles

import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: PanchangViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCityPicker = false
    @State private var notifPrefs = NotificationPreferences()
    
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
                    Text("Panchang times are calculated for this city. Choose the nearest one to you.")
                }
                
                // MARK: - Notifications
                Section {
                    Toggle(isOn: $notifPrefs.sunrise) {
                        Label("Sunrise", systemImage: "sunrise.fill")
                    }
                    Toggle(isOn: $notifPrefs.sunset) {
                        Label("Sunset / Sandhya", systemImage: "sunset.fill")
                    }
                    Toggle(isOn: $notifPrefs.rahuKalamWarning) {
                        Label("Rahu Kalam Warning", systemImage: "exclamationmark.circle")
                    }
                    Toggle(isOn: $notifPrefs.abhijitMuhurta) {
                        Label("Abhijit Muhurta", systemImage: "checkmark.circle")
                    }
                    Toggle(isOn: $notifPrefs.brahmaMuhurta) {
                        Label("Brahma Muhurta", systemImage: "moon.stars")
                    }
                    Toggle(isOn: $notifPrefs.navratriMorning) {
                        Label("Navratri Daily", systemImage: "sparkle")
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Notifications are sent \(notifPrefs.minutesBefore) minutes before each event.")
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
    @State private var searchText = ""
    
    private var filteredCities: [UserCity] {
        if searchText.isEmpty {
            return UserCity.defaults
        }
        return UserCity.defaults.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var grouped: [(String, [UserCity])] {
        let dict = Dictionary(grouping: filteredCities, by: { $0.country })
        let countryNames = ["US": "United States", "IN": "India", "UK": "United Kingdom",
                           "CA": "Canada", "SG": "Singapore"]
        return dict.sorted { countryNames[$0.key, default: $0.key] < countryNames[$1.key, default: $1.key] }
            .map { (countryNames[$0.key, default: $0.key], $0.value) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { country, cities in
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
            .searchable(text: $searchText, prompt: "Search cities")
            .navigationTitle("Choose City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView(vm: PanchangViewModel())
}

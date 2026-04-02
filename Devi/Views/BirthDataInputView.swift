// MARK: - Views/BirthDataInputView.swift
// Birth data entry view used in onboarding and settings

import SwiftUI

struct BirthDataInputView: View {
    let theme: DeviTheme
    let currentCity: UserCity              // Pre-fill with current city
    let existingData: BirthData?          // nil for new entry, non-nil for editing
    let onSave: (BirthData) -> Void
    let onCancel: (() -> Void)?           // nil in onboarding (no cancel)

    @State private var birthDate: Date
    @State private var birthTime: Date
    @State private var birthTimeKnown: Bool
    @State private var selectedCity: UserCity
    @State private var showCityPicker: Bool = false

    // MARK: - Init

    init(
        theme: DeviTheme,
        currentCity: UserCity,
        existingData: BirthData?,
        onSave: @escaping (BirthData) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.theme = theme
        self.currentCity = currentCity
        self.existingData = existingData
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize @State from existingData or defaults
        if let data = existingData {
            _birthDate = State(initialValue: data.birthDate)
            _birthTime = State(initialValue: data.birthTime ?? BirthDataInputView.defaultNoon())
            _birthTimeKnown = State(initialValue: data.birthTimeKnown)
            _selectedCity = State(initialValue: UserCity(
                name: data.birthPlace,
                country: "",
                latitude: data.latitude,
                longitude: data.longitude,
                timezoneIdentifier: data.timezoneIdentifier
            ))
        } else {
            _birthDate = State(initialValue: Date())
            _birthTime = State(initialValue: BirthDataInputView.defaultNoon())
            _birthTimeKnown = State(initialValue: false)
            _selectedCity = State(initialValue: currentCity)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // MARK: — Intro guidance
                    Text("Three quick steps for your personalized daily reading.")
                        .deviLabel(.detail, theme: theme)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 4)

                    // MARK: Section 1 — Date of Birth
                    VStack(alignment: .leading, spacing: 12) {
                        Text("STEP 1 · DATE OF BIRTH")
                            .deviLabel(.section, theme: theme)

                        DatePicker(
                            "Birth Date",
                            selection: $birthDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(theme.accentColor)
                    }
                    .padding(16)
                    .deviCard(theme: theme, elevation: .raised)

                    // MARK: — Scroll nudge
                    HStack(spacing: 4) {
                        Text("Scroll down for steps 2 & 3")
                            .scaledFont(size: 11, weight: .medium)
                            .foregroundColor(theme.secondaryText.opacity(0.5))
                        Image(systemName: "arrow.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(theme.secondaryText.opacity(0.5))
                    }
                    .deviEntrance(delay: 0.6)

                    // MARK: Section 2 — Birth Time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("STEP 2 · BIRTH TIME (OPTIONAL)")
                            .deviLabel(.section, theme: theme)

                        Toggle(isOn: $birthTimeKnown) {
                            HStack(spacing: 10) {
                                Image(systemName: "clock")
                                    .foregroundColor(theme.accentColor)
                                Text("I know my birth time")
                                    .scaledFont(size: 16, weight: .medium)
                                    .foregroundColor(theme.primaryText)
                            }
                        }
                        .tint(theme.accentColor)

                        if birthTimeKnown {
                            DatePicker(
                                "Birth Time",
                                selection: $birthTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(16)
                    .deviCard(theme: theme, elevation: .raised)
                    .animation(.easeInOut(duration: 0.25), value: birthTimeKnown)

                    // MARK: Section 3 — Birth Place
                    VStack(alignment: .leading, spacing: 12) {
                        Text("STEP 3 · BIRTH PLACE")
                            .deviLabel(.section, theme: theme)

                        Button {
                            showCityPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(theme.accentColor)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedCity.name)
                                        .scaledFont(size: 16, weight: .medium)
                                        .foregroundColor(theme.primaryText)
                                    if !selectedCity.country.isEmpty {
                                        Text(selectedCity.country)
                                            .scaledFont(size: 13)
                                            .foregroundColor(theme.secondaryText)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(theme.secondaryText.opacity(0.5))
                            }
                            .padding(12)
                            .deviCard(theme: theme, elevation: .flat, cornerRadius: 12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .deviCard(theme: theme, elevation: .raised)

                    // MARK: — Explanatory text
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(theme.secondaryText)
                                .padding(.top, 2)

                            Text("Why does birth time matter? The Moon moves about 13 degrees per day through the zodiac. Without an exact birth time, the app defaults to noon, which could place your Moon in the wrong nakshatra or rashi. Adding your birth time gives you more accurate readings.")
                                .deviLabel(.detail, theme: theme)
                                .lineSpacing(4)
                        }
                    }
                    .padding(16)
                    .deviCard(theme: theme, elevation: .flat)

                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                        .overlay(theme.primaryText.opacity(0.1))

                    Button {
                        saveBirthData()
                    } label: {
                        Text(existingData != nil ? "Update My Reading" : "Start My Reading")
                    }
                    .deviButton(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(.ultraThinMaterial)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Birth Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if let onCancel = onCancel {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { onCancel() }
                            .foregroundColor(theme.secondaryText)
                    }
                }
            }
            .sheet(isPresented: $showCityPicker) {
                CityPickerView(selectedCity: selectedCity, theme: theme) { city in
                    selectedCity = city
                    showCityPicker = false
                }
            }
        }
    }

    // MARK: - Actions

    private func saveBirthData() {
        let data = BirthData(
            birthDate: birthDate,
            birthTime: birthTimeKnown ? birthTime : nil,
            birthPlace: selectedCity.name,
            latitude: selectedCity.latitude,
            longitude: selectedCity.longitude,
            timezoneIdentifier: selectedCity.timezoneIdentifier,
            birthTimeKnown: birthTimeKnown
        )
        data.save()
        onSave(data)
    }

    // MARK: - Helpers

    /// Returns a Date set to noon today — used as default birth time.
    private static func defaultNoon() -> Date {
        let cal = Calendar.current
        return cal.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - Preview

#Preview {
    BirthDataInputView(
        theme: DeviTheme.forPeriod(.morning),
        currentCity: UserCity.popularCities[0],
        existingData: nil,
        onSave: { _ in },
        onCancel: { }
    )
}

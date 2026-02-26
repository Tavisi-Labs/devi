# Devi

A Hindu Panchang (almanac) app for iOS, built with SwiftUI. Devi provides daily Vedic calendar information — tithi, nakshatra, yoga, karana, auspicious/inauspicious time windows, and more — localized to your city.

## Features

- **Daily Panchang** — Tithi (lunar day), Nakshatra (lunar mansion), Yoga, Karana, and Vara (weekday deity)
- **Sun Arc Visualization** — Live sunrise/sunset progress with countdown timer
- **Time Windows** — Brahma Muhurta, Abhijit Muhurta, Rahu Kalam, Gulika Kalam, and Yamaganda with color-coded auspicious/inauspicious indicators
- **Fasting Day Alerts** — Automatic detection of Ekadashi, Pradosh Vrat, Purnima, and Amavasya
- **Navratri Tracking** — Day-by-day goddess info, mantras (Devanagari + transliteration), colors, and offerings for Chaitra and Sharad Navratri
- **Multi-City Support** — Pre-configured cities across the US, India, UK, Canada, and Singapore
- **Dark Theme** — Adaptive gradient backgrounds that shift with the time of day

## Requirements

- iOS 17.0+
- Xcode 16.0+
- Swift 5.0

## Setup

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`.

```bash
# Install XcodeGen (if needed)
brew install xcodegen

# Generate the Xcode project
xcodegen generate

# Open in Xcode
open Devi.xcodeproj
```

## Panchang Data Generation

The `scripts/` directory contains a Python script that generates panchang JSON data using the Swiss Ephemeris (Lahiri ayanamsa) for sidereal calculations.

```bash
cd scripts
python3 -m venv ../.venv
source ../.venv/bin/activate
pip install -r requirements.txt
python3 generate_panchang.py
```

## Project Structure

```
Devi/
├── DeviApp.swift              # App entry point (onboarding → home routing)
├── Models/
│   ├── PanchangData.swift     # Core data models (Tithi, Nakshatra, Yoga, etc.)
│   └── PanchangViewModel.swift# Main view model
├── Views/
│   ├── HomeView.swift         # Primary single-screen UI
│   ├── OnboardingView.swift   # First-launch city selection
│   ├── SettingsView.swift     # User preferences
│   └── Components/
│       ├── SunArcView.swift   # Sunrise/sunset arc visualization
│       ├── TimeWindowsCard.swift
│       └── NavratriCard.swift
└── Utils/
    └── Theme.swift            # Adaptive color/gradient system
scripts/
├── generate_panchang.py       # Swiss Ephemeris data generator
└── requirements.txt           # pyswisseph
project.yml                    # XcodeGen project definition
```

## Dependencies

- [Solar](https://github.com/ceeK/Solar) — Sunrise/sunset calculations
- [pyswisseph](https://pypi.org/project/pyswisseph/) — Swiss Ephemeris bindings for panchang data generation

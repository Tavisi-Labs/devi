# Devi

A Hindu Panchang app for iOS. No ads, no subscriptions, no clutter — just accurate Vedic calendar information, beautifully presented.

## What It Does

Devi gives you the full Hindu panchang for today, calculated for your city using the Swiss Ephemeris with Lahiri ayanamsa. Open the app and you immediately see:

- **Tithi & Nakshatra** — today's lunar day and star, with tap-through details on ruling deities, significance, and auspicious activities
- **Sun Arc** — a live visual tracker showing sun position, countdown to sunrise/sunset, and current time
- **Today's Mantra** — a weekday-specific Sanskrit mantra in Devanagari with transliteration, meaning, and chanting guidance
- **Yoga & Karana** — the full set of daily Vedic elements with educational descriptions
- **Hora** — planetary hours showing which planet rules the current hour and what activities it favors
- **Choghadiya** — auspicious/inauspicious time periods for the day and night, color-coded by quality
- **Time Windows** — Rahu Kaal, Yamagandam, Gulika Kaal, Brahma Muhurta, Abhijit Muhurta
- **Fasting Days** — automatic detection of Ekadashi, Pradosh Vrat, Purnima, Amavasya with named variants (Soma Pradosh, Kamada Ekadashi, etc.)
- **Eclipse Alerts** — upcoming solar and lunar eclipses with visibility info and do's/don'ts
- **Navratri Tracker** — day-by-day goddess info, colors, mantras, and offerings during Chaitra and Sharad Navratri
- **Upcoming Events** — festivals, fasting days, and eclipses on the horizon

Every element is tappable. Tap any tithi, nakshatra, hora, or time window to get a rich detail sheet with Vedic context — not a paragraph from Wikipedia, but real descriptions rooted in scripture and tradition.

## Design

Dark theme only. The background gradient shifts through five periods — Brahma Muhurta, morning, midday, evening, night — so the app feels different every time you open it. Sacred terms are rendered in serif. The accent palette is gold and saffron. Stars animate softly behind everything.

The goal is an app that feels like it belongs on a temple wall, not in a startup pitch deck.

## Privacy

All panchang calculations happen on your device. No server, no API calls, no analytics, no tracking. Your location data stays on your phone.

## Setup

Requires iOS 17.0+, Xcode 16+, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen   # if needed
xcodegen generate
open Devi.xcodeproj
```

### Panchang Data Scripts

```bash
cd scripts
source ../.venv/bin/activate
pip install -r requirements.txt
python3 generate_panchang.py
```

## Dependencies

- [Solar](https://github.com/ceeK/Solar) — Sunrise/sunset calculations
- [SwissEphemeris](https://github.com/vsmithers1087/SwissEphemeris) — Vedic astronomical calculations (Lahiri ayanamsa)
- [pyswisseph](https://pypi.org/project/pyswisseph/) — Ephemeris bindings for the data generation scripts

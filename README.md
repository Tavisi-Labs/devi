# Devi — Vedic Calendar

Devi is a beautiful Vedic calendar designed for daily spiritual practice. Get accurate tithi, nakshatra, yoga, karana, and planetary positions calculated in real time using the Swiss Ephemeris with Lahiri ayanamsa — localized to your city.

## Features

- Daily panchang with tithi, nakshatra, yoga, karana, and vara
- Accurate sunrise, sunset, moonrise, and moonset times
- Auspicious time windows: Brahma Muhurta, Abhijit Muhurta, Rahu Kalam, Yama Gandam, Gulika Kalam
- Hora (planetary hour) and Choghadiya systems
- Navagraha positions on the Vedic ecliptic
- Immersive views for tithi, nakshatra, and planetary positions
- Festival and observance calendar with Navratri tracking
- Customizable notifications for key time windows
- Five beautiful themes with light and dark mode
- Fully offline — all calculations performed on device

Devi respects your privacy: no accounts, no tracking, no ads.

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

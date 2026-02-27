#!/usr/bin/env python3
"""
Panchang data generator using Swiss Ephemeris (pyswisseph).
Generates JSON files for each supported city for date range March 1 - April 30, 2026.
Uses Lahiri ayanamsa for sidereal (nirayana) calculations.
"""

import json
import math
import os
import sys
from datetime import datetime, timedelta, timezone

import swisseph as swe

# ── Constants ──────────────────────────────────────────────────────────────────

LAHIRI_AYANAMSA = swe.SIDM_LAHIRI

TITHI_NAMES = [
    "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
    "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
    "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima",  # Shukla 1-15
    "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
    "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
    "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Amavasya",  # Krishna 1-15
]

NAKSHATRA_NAMES = [
    "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira",
    "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha",
    "Purva Phalguni", "Uttara Phalguni", "Hasta", "Chitra", "Swati",
    "Vishakha", "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha",
    "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
    "Purva Bhadrapada", "Uttara Bhadrapada", "Revati",
]

NAKSHATRA_RULERS = [
    "Ketu", "Venus", "Sun", "Moon", "Mars",
    "Rahu", "Jupiter", "Saturn", "Mercury", "Ketu",
    "Venus", "Sun", "Moon", "Mars", "Rahu",
    "Jupiter", "Saturn", "Mercury", "Ketu", "Venus",
    "Sun", "Moon", "Mars", "Rahu", "Jupiter",
    "Saturn", "Mercury",
]

NAKSHATRA_DEITIES = [
    "Ashwini Kumaras", "Yama", "Agni", "Brahma", "Soma",
    "Rudra", "Aditi", "Brihaspati", "Nagas", "Pitrs",
    "Bhaga", "Aryaman", "Savitar", "Vishvakarma", "Vayu",
    "Indra-Agni", "Mitra", "Indra", "Nirriti", "Apah",
    "Vishvadevas", "Vishnu", "Vasu", "Varuna",
    "Aja Ekapada", "Ahir Budhnya", "Pushan",
]

YOGA_NAMES = [
    "Vishkambha", "Priti", "Ayushman", "Saubhagya", "Shobhana",
    "Atiganda", "Sukarma", "Dhriti", "Shula", "Ganda",
    "Vriddhi", "Dhruva", "Vyaghata", "Harshana", "Vajra",
    "Siddhi", "Vyatipata", "Variyan", "Parigha", "Shiva",
    "Siddha", "Sadhya", "Shubha", "Shukla", "Brahma",
    "Indra", "Vaidhriti",
]

KARANA_NAMES = [
    "Bava", "Balava", "Kaulava", "Taitila", "Garaja",
    "Vanija", "Vishti",  # Repeating karanas (cycle through these 7)
    "Shakuni", "Chatushpada", "Nagava", "Kimstughna",  # Fixed karanas
]

# Lunar month names (approximate mapping by Sun's sidereal longitude)
LUNAR_MONTHS = [
    "Chaitra", "Vaishakha", "Jyeshtha", "Ashadha",
    "Shravana", "Bhadrapada", "Ashwin", "Kartik",
    "Margashirsha", "Pausha", "Magha", "Phalguna",
]

# Cities matching the Swift UserCity.defaults
CITIES = [
    {"name": "New York", "country": "US", "lat": 40.7128, "lon": -74.0060, "tz": "America/New_York"},
    {"name": "Los Angeles", "country": "US", "lat": 34.0522, "lon": -118.2437, "tz": "America/Los_Angeles"},
    {"name": "Chicago", "country": "US", "lat": 41.8781, "lon": -87.6298, "tz": "America/Chicago"},
    {"name": "Houston", "country": "US", "lat": 29.7604, "lon": -95.3698, "tz": "America/Chicago"},
    {"name": "San Francisco", "country": "US", "lat": 37.7749, "lon": -122.4194, "tz": "America/Los_Angeles"},
    {"name": "Dallas", "country": "US", "lat": 32.7767, "lon": -96.7970, "tz": "America/Chicago"},
    {"name": "Edison", "country": "US", "lat": 40.5187, "lon": -74.4121, "tz": "America/New_York"},
    {"name": "Mumbai", "country": "IN", "lat": 19.0760, "lon": 72.8777, "tz": "Asia/Kolkata"},
    {"name": "Delhi", "country": "IN", "lat": 28.7041, "lon": 77.1025, "tz": "Asia/Kolkata"},
    {"name": "Bangalore", "country": "IN", "lat": 12.9716, "lon": 77.5946, "tz": "Asia/Kolkata"},
    {"name": "Chennai", "country": "IN", "lat": 13.0827, "lon": 80.2707, "tz": "Asia/Kolkata"},
    {"name": "Hyderabad", "country": "IN", "lat": 17.3850, "lon": 78.4867, "tz": "Asia/Kolkata"},
    {"name": "Kolkata", "country": "IN", "lat": 22.5726, "lon": 88.3639, "tz": "Asia/Kolkata"},
    {"name": "Kochi", "country": "IN", "lat": 9.9312, "lon": 76.2673, "tz": "Asia/Kolkata"},
    {"name": "Thiruvananthapuram", "country": "IN", "lat": 8.5241, "lon": 76.9366, "tz": "Asia/Kolkata"},
    {"name": "Kozhikode", "country": "IN", "lat": 11.2588, "lon": 75.7804, "tz": "Asia/Kolkata"},
    {"name": "Thrissur", "country": "IN", "lat": 10.5276, "lon": 76.2144, "tz": "Asia/Kolkata"},
    {"name": "London", "country": "UK", "lat": 51.5074, "lon": -0.1278, "tz": "Europe/London"},
    {"name": "Toronto", "country": "CA", "lat": 43.6532, "lon": -79.3832, "tz": "America/Toronto"},
    {"name": "Singapore", "country": "SG", "lat": 1.3521, "lon": 103.8198, "tz": "Asia/Singapore"},
]

# Festival dates (hardcoded for 2026)
FESTIVALS = {
    "2026-03-13": ["Maha Shivaratri"],
    "2026-03-14": ["Amavasya"],
    "2026-03-19": ["Chaitra Navratri Begins"],
    "2026-03-20": ["Chaitra Navratri Day 2"],
    "2026-03-21": ["Chaitra Navratri Day 3"],
    "2026-03-22": ["Chaitra Navratri Day 4"],
    "2026-03-23": ["Chaitra Navratri Day 5"],
    "2026-03-24": ["Chaitra Navratri Day 6"],
    "2026-03-25": ["Chaitra Navratri Day 7"],
    "2026-03-26": ["Chaitra Navratri Day 8", "Durga Ashtami"],
    "2026-03-27": ["Chaitra Navratri Day 9", "Ram Navami"],
    "2026-03-28": ["Ekadashi"],
    "2026-03-29": ["Hanuman Jayanti"],
    "2026-04-01": ["Chaitra Purnima"],
    "2026-04-12": ["Amavasya"],
    "2026-04-13": ["Baisakhi"],
    "2026-04-14": ["Tamil New Year"],
}

# ── Swiss Ephemeris Helpers ───────────────────────────────────────────────────

def datetime_to_jd(dt):
    """Convert datetime (UTC) to Julian Day."""
    return swe.julday(dt.year, dt.month, dt.day,
                      dt.hour + dt.minute / 60.0 + dt.second / 3600.0)


def get_sun_longitude_sidereal(jd):
    """Get Sun's sidereal (nirayana) longitude."""
    swe.set_sid_mode(LAHIRI_AYANAMSA)
    result = swe.calc_ut(jd, swe.SUN, swe.FLG_SIDEREAL)
    return result[0][0]  # longitude in degrees


def get_moon_longitude_sidereal(jd):
    """Get Moon's sidereal (nirayana) longitude."""
    swe.set_sid_mode(LAHIRI_AYANAMSA)
    result = swe.calc_ut(jd, swe.MOON, swe.FLG_SIDEREAL)
    return result[0][0]


def compute_tithi(jd):
    """
    Tithi = (Moon - Sun) / 12 degrees.
    Returns (tithi_number 1-30, tithi_name, paksha).
    """
    sun_lng = get_sun_longitude_sidereal(jd)
    moon_lng = get_moon_longitude_sidereal(jd)

    diff = (moon_lng - sun_lng) % 360.0
    tithi_num = int(diff / 12.0) + 1  # 1-30
    if tithi_num > 30:
        tithi_num = 30

    paksha = "Shukla" if tithi_num <= 15 else "Krishna"
    paksha_num = tithi_num if tithi_num <= 15 else tithi_num - 15
    name = TITHI_NAMES[tithi_num - 1]

    return tithi_num, paksha_num, name, paksha


def compute_nakshatra(jd):
    """
    Nakshatra = Moon's nirayana longitude / 13.333...
    Returns (nakshatra_number 1-27, name, ruler, deity).
    """
    moon_lng = get_moon_longitude_sidereal(jd)
    nak_num = int(moon_lng / (360.0 / 27.0)) + 1
    if nak_num > 27:
        nak_num = 27

    return (nak_num,
            NAKSHATRA_NAMES[nak_num - 1],
            NAKSHATRA_RULERS[nak_num - 1],
            NAKSHATRA_DEITIES[nak_num - 1])


def compute_yoga(jd):
    """
    Yoga = (Sun + Moon nirayana longitude) / 13.333...
    Returns (yoga_number 1-27, name).
    """
    sun_lng = get_sun_longitude_sidereal(jd)
    moon_lng = get_moon_longitude_sidereal(jd)

    total = (sun_lng + moon_lng) % 360.0
    yoga_num = int(total / (360.0 / 27.0)) + 1
    if yoga_num > 27:
        yoga_num = 27

    return yoga_num, YOGA_NAMES[yoga_num - 1]


def compute_karana(jd):
    """
    Karana = half-tithi. Each tithi has 2 karanas.
    Returns (karana_number, name).
    """
    sun_lng = get_sun_longitude_sidereal(jd)
    moon_lng = get_moon_longitude_sidereal(jd)

    diff = (moon_lng - sun_lng) % 360.0
    karana_num = int(diff / 6.0) + 1  # 1-60
    if karana_num > 60:
        karana_num = 60

    # First karana is Kimstughna (fixed), then 7 repeating, then 4 fixed at end
    if karana_num == 1:
        name = "Kimstughna"
    elif karana_num >= 58:
        fixed_idx = karana_num - 58  # 0-2 maps to Shakuni, Chatushpada, Nagava
        name = KARANA_NAMES[7 + fixed_idx]
    else:
        # Repeating cycle of 7: Bava, Balava, Kaulava, Taitila, Garaja, Vanija, Vishti
        idx = (karana_num - 2) % 7
        name = KARANA_NAMES[idx]

    return karana_num, name


def compute_lunar_month(jd):
    """
    Approximate lunar month from Sun's sidereal longitude.
    Each lunar month spans ~30 degrees of solar longitude.
    """
    sun_lng = get_sun_longitude_sidereal(jd)
    # Chaitra starts roughly when Sun is at ~0 deg sidereal (Aries)
    # Adjust: Chaitra ~ 0-30, Vaishakha ~ 30-60, etc.
    month_idx = int(sun_lng / 30.0)
    return LUNAR_MONTHS[month_idx % 12]


def find_end_time(jd_start, compute_fn, current_value, max_hours=30):
    """
    Find when a panchang element changes from current_value.
    Steps forward in 30-min increments, then refines with bisection.
    Returns ISO datetime string (UTC).
    """
    step = 0.5 / 24.0  # 30 minutes in JD
    jd = jd_start

    # Coarse search
    for _ in range(int(max_hours * 2)):
        jd += step
        result = compute_fn(jd)
        val = result[0] if isinstance(result, tuple) else result
        if val != current_value:
            # Bisect to refine
            lo, hi = jd - step, jd
            for _ in range(10):
                mid = (lo + hi) / 2.0
                result_mid = compute_fn(mid)
                val_mid = result_mid[0] if isinstance(result_mid, tuple) else result_mid
                if val_mid == current_value:
                    lo = mid
                else:
                    hi = mid
            # Convert hi (JD) to ISO datetime
            y, m, d, h = swe.revjul(hi)
            hours = int(h)
            minutes = int((h - hours) * 60)
            seconds = int(((h - hours) * 60 - minutes) * 60)
            dt = datetime(y, m, d, hours, minutes, seconds, tzinfo=timezone.utc)
            return dt.isoformat()

    # Fallback: end of day
    y, m, d, h = swe.revjul(jd_start + 1.0)
    dt = datetime(y, m, d, 23, 59, 59, tzinfo=timezone.utc)
    return dt.isoformat()


def generate_day(date, city):
    """Generate panchang data for a single day and city."""
    # Use local noon as the reference time for calculations
    # (ensures we get the tithi/nakshatra valid for most of that day)
    dt_noon = datetime(date.year, date.month, date.day, 12, 0, 0, tzinfo=timezone.utc)
    jd_noon = datetime_to_jd(dt_noon)

    # Compute panchang elements at local noon
    tithi_num, paksha_num, tithi_name, paksha = compute_tithi(jd_noon)
    nak_num, nak_name, nak_ruler, nak_deity = compute_nakshatra(jd_noon)
    yoga_num, yoga_name = compute_yoga(jd_noon)
    karana_num, karana_name = compute_karana(jd_noon)
    lunar_month = compute_lunar_month(jd_noon)

    # Find end times
    tithi_end = find_end_time(jd_noon, compute_tithi, tithi_num)
    nak_end = find_end_time(jd_noon, compute_nakshatra, nak_num)
    yoga_end = find_end_time(jd_noon, compute_yoga, yoga_num)
    karana_end = find_end_time(jd_noon, compute_karana, karana_num)

    date_str = date.strftime("%Y-%m-%d")
    festivals = FESTIVALS.get(date_str, [])

    return {
        "dateString": date_str,
        "tithi": {
            "number": paksha_num,
            "name": tithi_name,
            "paksha": paksha,
            "endTime": tithi_end,
        },
        "nakshatra": {
            "number": nak_num,
            "name": nak_name,
            "ruler": nak_ruler,
            "deity": nak_deity,
            "endTime": nak_end,
        },
        "yoga": {
            "number": yoga_num,
            "name": yoga_name,
            "endTime": yoga_end,
        },
        "karana": {
            "number": karana_num,
            "name": karana_name,
            "endTime": karana_end,
        },
        "lunarMonth": lunar_month,
        "festivals": festivals,
    }


# ── Eclipse Computation ──────────────────────────────────────────────────────

# Eclipse type flag masks from pyswisseph
LUNAR_ECLIPSE_TYPES = {
    swe.ECL_TOTAL: "Total",
    swe.ECL_PARTIAL: "Partial",
    swe.ECL_PENUMBRAL: "Penumbral",
}

SOLAR_ECLIPSE_TYPES = {
    swe.ECL_TOTAL: "Total",
    swe.ECL_PARTIAL: "Partial",
    swe.ECL_ANNULAR: "Annular",
    swe.ECL_ANNULAR_TOTAL: "Annular",  # Hybrid
}


def jd_to_iso(jd, tz_name="UTC"):
    """Convert Julian Day to ISO 8601 string in given timezone."""
    from zoneinfo import ZoneInfo
    y, m, d, h = swe.revjul(jd)
    hours = int(h)
    minutes = int((h - hours) * 60)
    seconds = int(((h - hours) * 60 - minutes) * 60)
    dt_utc = datetime(y, m, d, hours, minutes, seconds, tzinfo=timezone.utc)
    dt_local = dt_utc.astimezone(ZoneInfo(tz_name))
    return dt_local.isoformat()


def classify_eclipse_type(ecl_flags, type_map):
    """Determine eclipse type string from Swiss Ephemeris flags."""
    for flag, name in type_map.items():
        if ecl_flags & flag:
            return name
    return "Partial"  # fallback


def compute_eclipses_for_city(city, start_jd, end_jd):
    """
    Compute all lunar and solar eclipses visible from a city within the JD range.
    Uses swe.lun_eclipse_when_loc() and swe.sol_eclipse_when_loc().
    Returns a list of eclipse dicts ready for JSON serialization.
    """
    geopos = (city["lon"], city["lat"], 0.0)  # (longitude, latitude, altitude)
    tz_name = city["tz"]
    eclipses = []

    # ── Lunar eclipses ─────────────────────────────────────────────────────
    search_jd = start_jd
    while search_jd < end_jd:
        try:
            retflag, tret = swe.lun_eclipse_when_loc(search_jd, geopos)
        except Exception:
            break

        if retflag == 0 or tret[0] == 0.0:
            break

        # tret indices for lunar eclipse at location:
        # 0 = maximum, 1 = partial begin, 2 = partial end,
        # 3 = total begin, 4 = total end, 5 = penumbral begin, 6 = penumbral end
        max_jd = tret[0]

        if max_jd > end_jd:
            break

        eclipse_type = classify_eclipse_type(retflag, LUNAR_ECLIPSE_TYPES)

        # Convert JD to date string (using maximum time)
        y, m, d, h = swe.revjul(max_jd)
        date_str = f"{y:04d}-{m:02d}-{d:02d}"

        # Check if moon is below horizon (partial begin == 0 means not visible)
        moon_below = (tret[1] == 0.0 and tret[5] != 0.0)

        eclipse = {
            "body": "Lunar",
            "type": eclipse_type,
            "dateString": date_str,
            "maxEclipseTime": jd_to_iso(max_jd, tz_name),
            "magnitude": round(abs(retflag & 0xFFFF) / 1000.0, 4) if False else 0.0,
            "moonBelowHorizon": moon_below,
            "lunarContactTimes": {
                "penumbralBegin": jd_to_iso(tret[5], tz_name) if tret[5] != 0 else None,
                "partialBegin": jd_to_iso(tret[1], tz_name) if tret[1] != 0 else None,
                "totalBegin": jd_to_iso(tret[3], tz_name) if tret[3] != 0 else None,
                "maximum": jd_to_iso(max_jd, tz_name),
                "totalEnd": jd_to_iso(tret[4], tz_name) if tret[4] != 0 else None,
                "partialEnd": jd_to_iso(tret[2], tz_name) if tret[2] != 0 else None,
                "penumbralEnd": jd_to_iso(tret[6], tz_name) if tret[6] != 0 else None,
            },
            "solarContactTimes": None,
            "mythologyNote": "Rahu swallows Chandra — the shadow of the Earth envelops the Moon.",
        }

        # Compute magnitude using swe.lun_eclipse_how()
        try:
            attr_flag, attr = swe.lun_eclipse_how(max_jd, geopos)
            eclipse["magnitude"] = round(attr[0], 4)  # attr[0] = umbral magnitude
        except Exception:
            pass

        eclipses.append(eclipse)
        search_jd = max_jd + 1.0  # Move past this eclipse

    # ── Solar eclipses ─────────────────────────────────────────────────────
    search_jd = start_jd
    while search_jd < end_jd:
        try:
            retflag, tret, attr = swe.sol_eclipse_when_loc(search_jd, geopos)
        except Exception:
            break

        if retflag == 0 or tret[0] == 0.0:
            break

        # tret indices for solar eclipse at location:
        # 0 = maximum, 1 = first contact, 2 = second contact,
        # 3 = third contact, 4 = fourth contact
        max_jd = tret[0]

        if max_jd > end_jd:
            break

        eclipse_type = classify_eclipse_type(retflag, SOLAR_ECLIPSE_TYPES)

        y, m, d, h = swe.revjul(max_jd)
        date_str = f"{y:04d}-{m:02d}-{d:02d}"

        eclipse = {
            "body": "Solar",
            "type": eclipse_type,
            "dateString": date_str,
            "maxEclipseTime": jd_to_iso(max_jd, tz_name),
            "magnitude": round(attr[0], 4) if attr[0] != 0 else 0.0,  # attr[0] = magnitude
            "moonBelowHorizon": False,
            "lunarContactTimes": None,
            "solarContactTimes": {
                "firstContact": jd_to_iso(tret[1], tz_name) if tret[1] != 0 else None,
                "secondContact": jd_to_iso(tret[2], tz_name) if tret[2] != 0 else None,
                "maximum": jd_to_iso(max_jd, tz_name),
                "thirdContact": jd_to_iso(tret[3], tz_name) if tret[3] != 0 else None,
                "fourthContact": jd_to_iso(tret[4], tz_name) if tret[4] != 0 else None,
            },
            "mythologyNote": "Rahu swallows Surya — the Moon's shadow crosses the face of the Sun.",
        }

        eclipses.append(eclipse)
        search_jd = max_jd + 1.0

    return eclipses


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    swe.set_ephe_path(None)  # Use built-in ephemeris

    start_date = datetime(2026, 3, 1)
    end_date = datetime(2026, 4, 30)

    # Wider range for eclipse search (eclipses are rare, search full year)
    eclipse_start = datetime(2026, 1, 1)
    eclipse_end = datetime(2027, 1, 1)
    eclipse_start_jd = datetime_to_jd(eclipse_start.replace(tzinfo=timezone.utc))
    eclipse_end_jd = datetime_to_jd(eclipse_end.replace(tzinfo=timezone.utc))

    output_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "Devi", "Data")
    os.makedirs(output_dir, exist_ok=True)

    total_days = (end_date - start_date).days + 1

    for city in CITIES:
        city_key = city["name"].lower().replace(" ", "_")
        print(f"Generating {city['name']}...", end=" ", flush=True)

        # Generate daily panchang data
        days = []
        current = start_date
        for _ in range(total_days):
            day_data = generate_day(current, city)
            days.append(day_data)
            current += timedelta(days=1)

        output_path = os.path.join(output_dir, f"panchang_{city_key}.json")
        with open(output_path, "w") as f:
            json.dump(days, f, indent=2)

        # Generate eclipse data
        city_eclipses = compute_eclipses_for_city(city, eclipse_start_jd, eclipse_end_jd)
        eclipse_path = os.path.join(output_dir, f"eclipses_{city_key}.json")
        with open(eclipse_path, "w") as f:
            json.dump(city_eclipses, f, indent=2)

        eclipse_count = len(city_eclipses)
        print(f"done ({len(days)} days, {eclipse_count} eclipses)")

    print(f"\nGenerated {len(CITIES)} city files in {output_dir}")


if __name__ == "__main__":
    main()

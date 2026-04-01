# TODOS

## Accuracy Verification

- [ ] **Accuracy verification Phase 1 — Drik Panchang comparison**
  **Priority:** P1
  Verify tithi/nakshatra transitions match Drik Panchang within 2 minutes for 3 days x 2 cities (Delhi, New York). Sunrise within 1 minute.
  Deferred from plan: VedicSkyView design doc (2026-03-30)

- [ ] **Unit test: graha positions for a known date**
  **Priority:** P1
  Verify computeGrahaSnapshot returns correct sidereal longitudes against a known ephemeris reference.
  Deferred from plan: VedicSkyView design doc (2026-03-30)

## VedicSkyView Enhancements

- [ ] **Wire up graha card tap → PanchangDetailSheet**
  **Priority:** P2
  The `.graha(Graha, Double)` PanchangElement case exists but no UI creates it. Add onTapGesture to graha cards in VedicSkyView to open the detail sheet.

- [ ] **Add @MainActor to VedicCalculator**
  **Priority:** P3
  Swiss Ephemeris is not thread-safe. VedicCalculator is safe today (all callers are @MainActor) but should be explicitly annotated for future-proofing.

- [ ] **Defensive guard for Rahu-before-Ketu ordering**
  **Priority:** P3
  computeGrahaSnapshot assumes Graha.allCases iterates Rahu before Ketu. Add assertion or compute Rahu explicitly before the loop.

## App Store Submission

- [ ] **Capture App Store screenshots (including VedicSkyView hero shot)**
  **Priority:** P2
  Deferred from plan: VedicSkyView design doc (2026-03-30)

- [ ] **Draft App Store description and keywords**
  **Priority:** P2
  Deferred from plan: VedicSkyView design doc (2026-03-30)

## Completed

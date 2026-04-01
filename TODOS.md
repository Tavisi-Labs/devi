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
  `PanchangCalculator.computeGrahaSnapshot()` assumes `Graha.allCases` iterates Rahu before Ketu. Compute Rahu explicitly before the loop instead of relying on enum declaration order.
  File: `Devi/Models/PanchangCalculator.swift` ~line 515

## Adversarial Review Fixes (mechanical, ~15 lines total)

- [ ] **Remove redundant Task wrapper in notification observers**
  **Priority:** P3
  `VedicSkyMotionManager.swift` lines 35-37 and 47-49: notification delivered on `.main` queue, class is `@MainActor` — call `self.stopUpdates()` / `self.startUpdates()` directly instead of wrapping in `Task { @MainActor in }`.

- [ ] **Move Reduce Motion check from init() to startUpdates()**
  **Priority:** P3
  `VedicSkyMotionManager.swift` line 23: `UIAccessibility.isReduceMotionEnabled` checked only in `init()`. Move to `startUpdates()` so it's re-evaluated if user toggles setting while app is running.

- [ ] **Remove unnecessary iOS 18 availability check on sparklesIcon**
  **Priority:** P3
  `HomeView.swift` ~line 622: `if #available(iOS 18.0, *)` guard on `.symbolEffect(.bounce)` is unnecessary — API is available from iOS 17.0 and app targets iOS 17.0+. Remove the availability check.

- [ ] **Remove redundant observers.removeAll() from deinit**
  **Priority:** P3
  `VedicSkyMotionManager.swift` line 58: `observers.removeAll()` in `deinit` is redundant (array is about to be deallocated) and technically unsafe under strict concurrency since `deinit` doesn't run on `@MainActor`.

- [ ] **Extract nakshatraIndex helper to deduplicate formula**
  **Priority:** P4
  `min(Int(lon / (360.0 / 27.0)), 26)` appears in 3 places: `VedicSkyView.moonNakshatraIndex`, `VedicSkyView.grahaCard`, `PanchangDetailSheet` graha detail. Extract to a shared utility function.

## App Store Submission

- [ ] **Capture App Store screenshots (including VedicSkyView hero shot)**
  **Priority:** P2
  Deferred from plan: VedicSkyView design doc (2026-03-30)

- [ ] **Draft App Store description and keywords**
  **Priority:** P2
  Deferred from plan: VedicSkyView design doc (2026-03-30)

## Completed

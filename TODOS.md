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

- [x] **Remove redundant Task wrapper in notification observers**
  **Priority:** P3
  `VedicSkyMotionManager.swift` lines 35-37 and 47-49: notification delivered on `.main` queue, class is `@MainActor` — call `self.stopUpdates()` / `self.startUpdates()` directly instead of wrapping in `Task { @MainActor in }`.

- [x] **Move Reduce Motion check from init() to startUpdates()**
  **Priority:** P3
  `VedicSkyMotionManager.swift` line 23: `UIAccessibility.isReduceMotionEnabled` checked only in `init()`. Move to `startUpdates()` so it's re-evaluated if user toggles setting while app is running.

- [x] **Remove unnecessary iOS 18 availability check on sparklesIcon**
  **Priority:** P3
  `HomeView.swift` ~line 622: `if #available(iOS 18.0, *)` guard on `.symbolEffect(.bounce)` is unnecessary — API is available from iOS 17.0 and app targets iOS 17.0+. Remove the availability check.

- [x] **Remove redundant observers.removeAll() from deinit**
  **Priority:** P3
  `VedicSkyMotionManager.swift` line 58: `observers.removeAll()` in `deinit` is redundant (array is about to be deallocated) and technically unsafe under strict concurrency since `deinit` doesn't run on `@MainActor`.

- [x] **Extract nakshatraIndex helper to deduplicate formula**
  **Priority:** P4
  `min(Int(lon / (360.0 / 27.0)), 26)` appears in 3 places: `VedicSkyView.moonNakshatraIndex`, `VedicSkyView.grahaCard`, `PanchangDetailSheet` graha detail. Extracted to `GrahaSnapshot.nakshatraIndex(forLongitude:)` in PanchangData.swift.

## Accessibility (from Design Review 2026-04-02)

- [ ] **VoiceOver: Canvas moon phase accessibility label**
  **Priority:** P2
  `CelestialHeroView.moonPhaseCanvas()` and `OnboardingView.drawMoon()` render Canvas elements invisible to VoiceOver. Add `.accessibilityLabel("Shukla Panchami, 33% illuminated")` with dynamic tithi/paksha values.
  Files: `Devi/Views/Components/CelestialHeroView.swift`, `Devi/Views/OnboardingView.swift`

- [ ] **VoiceOver: Sun arc drag accessibility equivalent**
  **Priority:** P2
  `DragGesture` on the arc has no VoiceOver alternative. Add `.accessibilityAdjustableAction` with increment/decrement that scrubs ±30 min.
  File: `Devi/Views/Components/CelestialHeroView.swift`

- [ ] **VoiceOver: Day navigation accessibility equivalent**
  **Priority:** P2
  `dayNavigationGesture` (DragGesture on header) has no VoiceOver alternative. Add accessible "Previous Day" / "Next Day" actions.
  File: `Devi/Views/HomeView.swift`

- [ ] **VoiceOver: Add .accessibilityLabel to all interactive elements**
  **Priority:** P2
  Info bar capsules, Right Now rows, upcoming event rows, festival/fasting banners, and MantraCard lack semantic labels. VoiceOver reads "Button" without context.
  Files: `HomeView.swift`, `RightNowCard.swift`, `MantraCard.swift`, `CelestialHeroView.swift`

- [ ] **Reduce Motion: Check isReduceMotionEnabled for animations**
  **Priority:** P2
  `.breathing()` modifier, PhaseAnimator sun dot, `.symbolEffect(.pulse)` calls do NOT check `UIAccessibility.isReduceMotionEnabled`. iOS does not automatically suppress these for Reduce Motion users.
  Files: `Theme.swift` (BreathingModifier), `CelestialHeroView.swift` (SunDot), `HomeView.swift`, `RightNowCard.swift`

- [ ] **Color contrast audit for light mode**
  **Priority:** P3
  Secondary text at 55-60% opacity (`secondaryTextOpacity: 0.55`) on cream backgrounds may fail WCAG AA (4.5:1). Verify contrast ratios for all 5 light-mode palettes.
  File: `Devi/Utils/ThemePalettes.swift`

- [ ] **iPad layout consideration**
  **Priority:** P3
  HomeView renders as a narrow column on iPad with gradient filling the rest. No split view, sidebar, or multi-column layout. Consider `NavigationSplitView` for iPad.
  File: `Devi/Views/HomeView.swift`

- [ ] **Dynamic Type integration**
  **Priority:** P3
  Custom `DeviFontScale` system does not respect iOS Dynamic Type (`@ScaledMetric`). Users who set Accessibility Sizes in iOS Settings get no scaling from the system.
  File: `Devi/Utils/Theme.swift`

## App Store Submission

- [ ] **Capture App Store screenshots (including VedicSkyView hero shot)**
  **Priority:** P2
  Deferred from plan: VedicSkyView design doc (2026-03-30)

- [ ] **Draft App Store description and keywords**
  **Priority:** P2
  Deferred from plan: VedicSkyView design doc (2026-03-30)

## Completed

# Devi Design System

## Philosophy

Devi is a living celestial instrument, not a dashboard. Every design choice serves one purpose: connecting the user to the rhythm of Vedic time. The design should feel like looking at the sky, not reading a spreadsheet.

**Core principles:**
- **Atmospheric, not decorative.** Gradients mimic the real sky. Animations breathe like living things. Nothing is ornamental.
- **Sacred language has visual weight.** Tithi names, nakshatra names, deity names, and mantras use serif type. UI labels use sans-serif. This distinction is non-negotiable.
- **The celestial hero is the anchor.** The sun arc + moon phase + countdown is the soul of the app. Everything else serves it.
- **Restraint over richness.** Subtle opacity, thin strokes, quiet shadows. If something feels loud, make it quieter.

## Color System

### Semantic Tokens (DeviTheme)

These are the canonical colors. Always use theme properties, never hardcode hex values.

| Token | Purpose | Dark Mode Example | Light Mode Example |
|-------|---------|-------------------|--------------------|
| `accentColor` | Primary accent, CTAs, selected states | `#C9A96E` (classic) | `#9A7B4F` (classic) |
| `primaryText` | Headings, body text, primary labels | `#E8E4DC` | `#2A2218` |
| `secondaryText` | Captions, timestamps, supporting text | `#E8E4DC` @ 0.65 | `#2A2218` @ 0.58 |
| `auspiciousColor` | Favorable periods, success states | `#3DA66A` | `#3DA66A` |
| `inauspiciousColor` | Unfavorable periods, warnings | `#C45050` | `#C45050` |
| `cautionColor` | Neutral/mixed periods | `#D4A040` | `#D4A040` |
| `backgroundGradientTop/Mid/Bottom` | 3-stop atmospheric sky gradient | varies by period | varies by period |

### Semantic Colors (needs migration to DeviTheme)

These colors appear inline across components and should be consolidated into theme tokens:

| Color | Hex | Usage | Proposed Token |
|-------|-----|-------|----------------|
| Lunar Silver | `#B8C4D8` | Moon phase, paksha dots, moonrise/set icons | `lunarColor` |
| Sun Gold | `#f0c040` | Sun dot glow, solar emphasis | `solarGlow` |
| Fasting Ember | `#c54b2a` | Fasting banners, flame icon | `fastingColor` |
| Eclipse Blue | `#7B8EC4` | Eclipse cards, shadow events, Saturn | `eclipseColor` |
| Deep Void | `#0B1026` | Moon dark side, deep backgrounds | `deepBackground` |
| Star Warm | `#FFE4C4` | Star field warm tint | (internal to StarFieldView) |

### Planetary Colors (Navagraha Palette)

Fixed colors representing the nine Vedic planets. These do NOT change with theme style or time period.

| Graha | Hex | Notes |
|-------|-----|-------|
| Surya (Sun) | `#D4A040` | Gold, matches cautionColor |
| Chandra (Moon) | `#B8C4D8` | Silver, matches lunarColor |
| Mangala (Mars) | `#C45050` | Red, matches inauspiciousColor |
| Budha (Mercury) | `#4AAD6E` | Green |
| Guru (Jupiter) | `#C9A96E` | Warm gold |
| Shukra (Venus) | `#D47AAD` | Pink |
| Shani (Saturn) | `#7B8EC4` | Blue-silver, matches eclipseColor |
| Rahu | `#5A6A8A` | Muted blue-grey |
| Ketu | `#8A5A5A` | Muted brown-red |

### What NOT to do with color
- Never use purple/violet as a primary background. That's AI slop territory.
- Never use the accent gold at full opacity for large areas. It's an accent, not a fill.
- Never hardcode `Color(hex: "d4a857")` — use `theme.accentColor`.
- Never invent new semantic colors without adding them to the palette registry.

## Typography

### The Sacred/Secular Split

This is the most important typographic rule in Devi:

| Content Type | Font Design | Examples |
|--------------|-------------|---------|
| Sacred names, Vedic terms | `.serif` | Tithi names, nakshatra names, deity names, mantras, lunar month |
| UI labels, actions, status | `.default` (SF Pro) | "RIGHT NOW", "UPCOMING", button labels, timestamps |
| Countdown, numbers | `.rounded` or `.serif` | Sun arc countdown, time displays |
| Devanagari script | System serif | Mantras in original script |

### Type Scale (via `deviLabel` styles)

| Style | Size | Weight | Design | Use For |
|-------|------|--------|--------|---------|
| `.hero` | 48pt (capped at 1.15x scale) | Light | Rounded | Countdown timer only |
| `.sacredTitle` | 32pt | Regular | Serif | Tithi name, goddess name in immersive views |
| `.title` | 22pt | Semibold | Default | Section headers, card titles |
| `.section` | 12pt | Semibold | Default | Uppercase tracking labels ("TODAY", "UPCOMING") |
| `.body` | 16pt | Regular | Default | Primary content |
| `.sacredBody` | 16pt | Regular | Serif | Vedic descriptions, mythology text |
| `.detail` | 14pt | Regular | Default | Secondary content, supporting text |
| `.caption` | 12pt | Regular | Default | Timestamps, footnotes |
| `.insight` | 13pt | Regular | Serif @ 85% | Inline Vedic meanings, deity associations |

### Font Scale System

Users can adjust text size via Settings. Four levels:
- **Compact** (1.0x) — original sizes, for small screens
- **Standard** (1.15x) — default, 15% larger
- **Large** (1.30x) — comfortable reading
- **Extra Large** (1.45x) — accessibility

Hero text caps at 1.15x to prevent layout blowout. Icons never scale (they're fixed-size SF Symbols).

## Spacing

### Vertical Rhythm

| Context | Spacing | Notes |
|---------|---------|-------|
| Between major sections | 32pt | Hora → Choghadiya, Time Windows → Hora |
| Between related items | 16pt | Cards within a section |
| Between card content lines | 8-12pt | Within a single card |
| Section header to content | 12pt | OrnamentalDivider to first card |
| Bottom padding (scroll end) | 80pt | Breathing room below last section |
| Card internal padding | 16-20pt | Content within card border |

### Horizontal

| Context | Value |
|---------|-------|
| Screen edge padding | 16pt (cards, sections) |
| Card internal padding | 16pt (horizontal), 12-16pt (vertical) |
| Arc horizontal padding | 48pt (sunrise/sunset labels) |
| Button internal padding | 14-16pt (horizontal), 10-14pt (vertical) |

## Card Elevation System

Three tiers. Choose based on visual importance, not aesthetics.

| Elevation | When to Use | Background | Shadow |
|-----------|-------------|------------|--------|
| `.flat` | Inline elements, info capsules | Subtle gradient fill (0.02-0.06 opacity) | None |
| `.raised` | Standard cards (settings rows, upcoming events, detail sections) | ultraThinMaterial (0.30) + gradient fill | Black 0.12 @ 8r (dark) / 0.06 @ 6r (light) |
| `.prominent` | Hero-level cards (Right Now, Navratri, Eclipse) | ultraThinMaterial (0.50) + accent tint | Black 0.18 @ 12r (dark) / 0.08 @ 10r (light) |

### Rules
- Default corner radius: 14pt
- Prominent cards: minimum 18pt radius
- Never use both `.prominent` AND a colored background. Pick one.
- Light mode uses white fill (0.85-0.90) instead of material.

## Animation

### Principles
- Animations serve information, not decoration.
- If an animation doesn't communicate state change, remove it.
- Respect Reduce Motion (check `UIAccessibility.isReduceMotionEnabled`).

### Catalog

| Animation | Duration | Use | Modifier |
|-----------|----------|-----|----------|
| Entrance (fade-up) | 0.6s spring | First appear of sections | `.deviEntrance(delay:)` |
| Directional reveal | 0.6s spring | Staggered card appears | `.deviReveal(delay:direction:)` |
| Breathing pulse | 1.8s ease, repeating | Active "NOW" badges | `.breathing()` |
| Sun dot heartbeat | 4-phase (rest→inhale→peak→exhale) | Sun position dot | PhaseAnimator in SunDot |
| Content transition | .interpolate | Text that changes (tithi name, dates) | `.contentTransition(.interpolate)` |
| Numeric transition | .numericText | Countdown, times | `.contentTransition(.numericText())` |
| Time period change | 8s easeInOut | Background gradient shifts | Keyed on `vm.timePeriod` |

### Haptics

| Event | Feedback | Trigger |
|-------|----------|---------|
| Card tap | `.impact(weight: .light)` | `cardTapCount` |
| Time period transition | `.impact(flexibility: .soft, intensity: 0.5)` | `vm.timePeriod` |
| Countdown zero | `.impact(weight: .heavy)` | `vm.countdownZeroTrigger` |
| Day navigation | `.impact(weight: .medium)` | `vm.dayOffset` |
| Arc scrub start | `.selection` | `vm.virtualTimeOffset != nil` |

## Component Vocabulary

### Sacred Components (unique to Devi)
- **CelestialHeroView** — sun arc + moon phase + countdown + scrub. The soul of the app.
- **MantraCard** — daily mantra with Devanagari + transliteration. Long-press for meditation.
- **NavratriCard** — goddess-of-the-day during Navratri periods. Uses goddess-specific color.
- **EclipseCard** — blue-silver palette (#7B8EC4). Uses `.prominent` elevation.
- **OrnamentalDivider** — hairline + centered label. Simple. No Unicode ornaments.

### Structural Components
- **RightNowCard** — aggregates active hora/choghadiya/time windows. `.prominent` elevation.
- **HoraCard / ChoghadiyaCard** — horizontal scroll strips showing planetary hours.
- **TimeWindowsCard** — 2-column grid of auspicious/inauspicious windows.
- **TodayDetailsSection** — yoga, karana, vara in grouped sub-cards.

### Immersive Views (fullScreenCover)
- **TithiImmersiveView** — lunar observatory
- **NakshatraImmersiveView** — constellation theater
- **EclipseImmersiveView** — cosmic theater
- **NavratriImmersiveView** — goddess darshan
- **HoraImmersiveView** — planetary orrery
- **MantraImmersiveView** — meditation focus
- **VedicSkyView** — ecliptic strip with navagraha grid + gyroscope parallax

## Theme Styles

Five styles, each with a distinct aesthetic personality across all 5 time periods:

| Style | Personality | Accent Family |
|-------|-------------|---------------|
| Classic | Mahogany library, antique gold | Warm gold/amber |
| Vivid Temple | Oil-lamp saffron, deep indigo | Flame orange/saffron |
| Sunrise Garden | Organic earth tones, sage | Clay/earth |
| Cosmic Jewel | Gemstone gallery, per-period jewel | Changes: amethyst→topaz→sapphire→ruby→onyx |
| Golden Dawn | Golden hour warmth throughout | Persistent gold |

Each style defines: background gradient (3-stop), accent color, text colors, arc gradient (2-stop), arc shadow. All 50 combinations live in `ThemePalettes.swift`.

## Design Anti-Patterns

Things to actively avoid in Devi:

1. **Generic card grids.** Every card earns its existence with unique content.
2. **Centered-everything layouts.** Content is left-aligned. Only the celestial hero is centered.
3. **Emoji as design elements.** Use SF Symbols, not emoji. Exception: Devanagari script is text, not decoration.
4. **Decorative blobs or waves.** The star field is the only ambient element. It's deliberately subtle.
5. **Feature-list patterns.** (icon + title + subtitle) repeated 3+ times in a column. Find a more distinctive layout.
6. **Purple gradients.** The cosmic palette has indigo, not purple. There's a difference.
7. **Stock photo hero sections.** Devi's hero is computational (sun arc from real ephemeris data), not decorative.
8. **"Welcome to [App Name]" copy.** Be specific. "Your Daily Vedic Companion" not "Welcome to Devi."

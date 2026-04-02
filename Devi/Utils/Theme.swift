// MARK: - Utils/Theme.swift
// Time-of-day adaptive color system — atmospheric realism palette

import SwiftUI

// MARK: - Font Scale System

/// User-adjustable font scale. Default is `.standard` (1.15x) — 15% bigger than the original
/// "Compact" sizes. Propagated via SwiftUI Environment so all views inherit automatically.
enum DeviFontScale: String, CaseIterable {
    case compact    = "Compact"       // 1.0x  (original sizes, for small screens)
    case standard   = "Default"       // 1.15x (new default — 15% bigger)
    case large      = "Large"         // 1.30x
    case extraLarge = "Extra Large"   // 1.45x

    var multiplier: CGFloat {
        switch self {
        case .compact:    return 1.0
        case .standard:   return 1.15
        case .large:      return 1.30
        case .extraLarge: return 1.45
        }
    }

    /// Hero/countdown text caps at 1.15x to avoid blowing out the layout
    var heroMultiplier: CGFloat {
        min(multiplier, 1.15)
    }
}

// MARK: - Environment Key

private struct DeviFontScaleKey: EnvironmentKey {
    static let defaultValue: DeviFontScale = .standard
}

extension EnvironmentValues {
    var deviFontScale: DeviFontScale {
        get { self[DeviFontScaleKey.self] }
        set { self[DeviFontScaleKey.self] = newValue }
    }
}

// MARK: - Scaled Font Modifier

/// Drop-in replacement for `.font(.system(size:weight:design:))` that reads
/// the environment font scale automatically.
struct ScaledFontModifier: ViewModifier {
    @Environment(\.deviFontScale) private var scale
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        content.font(.system(size: size * scale.multiplier, weight: weight, design: design))
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFontModifier(size: size, weight: weight, design: design))
    }
}

// MARK: - Theme Style

enum DeviThemeStyle: String, CaseIterable, Identifiable {
    case classic       = "Classic"
    case vividTemple   = "Vivid Temple"
    case sunriseGarden = "Sunrise Garden"
    case cosmicJewel   = "Cosmic Jewel"
    case goldenDawn    = "Golden Dawn"
    var id: String { rawValue }
}

// MARK: - Appearance Mode

enum DeviAppearanceMode: String, CaseIterable {
    case auto        = "Auto"
    case alwaysLight = "Always Light"
    case alwaysDark  = "Always Dark"

    func isLight(for period: TimePeriod) -> Bool {
        switch self {
        case .auto:        return period == .morning || period == .afternoon
        case .alwaysLight: return true
        case .alwaysDark:  return false
        }
    }
}

// MARK: - Time Period

enum TimePeriod {
    case brahmaMuhurta  // 3:30 AM - sunrise
    case morning        // sunrise - noon
    case afternoon      // noon - sunset
    case evening        // sunset - 9 PM
    case night          // 9 PM - 3:30 AM

    static func current(sunrise: Date, sunset: Date) -> TimePeriod {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        // Brahma muhurta: ~96 min before sunrise (simplified to 3:30 AM - sunrise)
        let brahmaMuhurtaStart = calendar.date(bySettingHour: 3, minute: 30, second: 0, of: now)!

        if now >= brahmaMuhurtaStart && now < sunrise {
            return .brahmaMuhurta
        } else if now >= sunrise && hour < 12 {
            return .morning
        } else if hour >= 12 && now < sunset {
            return .afternoon
        } else if now >= sunset && hour < 21 {
            return .evening
        } else {
            return .night
        }
    }
}

// MARK: - Theme Colors

struct DeviTheme {
    let backgroundGradientTop: Color
    let backgroundGradientMid: Color
    let backgroundGradientBottom: Color
    let accentColor: Color
    let primaryText: Color
    let secondaryText: Color
    let isLight: Bool  // Whether this theme instance is a light palette

    // Consistent semantic status colors across all themes
    let auspiciousColor: Color = Color(hex: "3DA66A")
    let inauspiciousColor: Color = Color(hex: "C45050")
    let cautionColor: Color = Color(hex: "D4A040")

    // Semantic element colors (from DESIGN.md palette)
    let lunarColor: Color
    let solarGlow: Color
    let fastingColor: Color
    let eclipseColor: Color
    let deepBackground: Color

    // MARK: - Time-based themes

    static func forPeriod(_ period: TimePeriod, style: DeviThemeStyle = .classic, appearance: DeviAppearanceMode = .alwaysDark) -> DeviTheme {
        let isLight = appearance.isLight(for: period)
        let p = ThemePaletteRegistry.palette(for: style, period: period, isLight: isLight)
        return DeviTheme(
            backgroundGradientTop: Color(hex: p.bgTop),
            backgroundGradientMid: Color(hex: p.bgMid),
            backgroundGradientBottom: Color(hex: p.bgBottom),
            accentColor: Color(hex: p.accent),
            primaryText: Color(hex: p.primaryText),
            secondaryText: Color(hex: p.secondaryText).opacity(p.secondaryTextOpacity),
            isLight: isLight,
            lunarColor: Color(hex: p.lunarColor),
            solarGlow: Color(hex: p.solarGlow),
            fastingColor: Color(hex: p.fastingColor),
            eclipseColor: Color(hex: p.eclipseColor),
            deepBackground: Color(hex: p.deepBackground)
        )
    }

    // The full background gradient (3-stop atmospheric sky)
    var backgroundGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: backgroundGradientTop, location: 0.0),
                .init(color: backgroundGradientMid, location: 0.55),
                .init(color: backgroundGradientBottom, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // Arc gradient for the sun timer — adapts to time of day and style
    static func arcGradient(for period: TimePeriod, style: DeviThemeStyle = .classic, appearance: DeviAppearanceMode = .alwaysDark) -> LinearGradient {
        let isLight = appearance.isLight(for: period)
        let p = ThemePaletteRegistry.palette(for: style, period: period, isLight: isLight)
        return LinearGradient(
            colors: [Color(hex: p.arcStart), Color(hex: p.arcEnd)],
            startPoint: .leading, endPoint: .trailing
        )
    }

    // Arc shadow color — matches the gradient start for visual coherence
    static func arcShadowColor(for period: TimePeriod, style: DeviThemeStyle = .classic, appearance: DeviAppearanceMode = .alwaysDark) -> Color {
        let isLight = appearance.isLight(for: period)
        let p = ThemePaletteRegistry.palette(for: style, period: period, isLight: isLight)
        return Color(hex: p.arcShadow)
    }
}

// MARK: - Card Elevation System

enum DeviCardElevation {
    case flat
    case raised
    case prominent
}

struct DeviCardModifier: ViewModifier {
    let theme: DeviTheme
    let elevation: DeviCardElevation
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let effectiveRadius = elevation == .prominent ? max(cornerRadius, 18) : cornerRadius

        content
            .background {
                if theme.isLight {
                    lightBackground(effectiveRadius)
                } else {
                    darkBackground(effectiveRadius)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }

    // MARK: - Dark Mode Backgrounds (upgraded)
    @ViewBuilder
    private func darkBackground(_ r: CGFloat) -> some View {
        switch elevation {
        case .flat:
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [theme.primaryText.opacity(0.06), theme.primaryText.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        case .raised:
            ZStack {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.30))
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryText.opacity(0.08), theme.primaryText.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
        case .prominent:
            ZStack {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.50))
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryText.opacity(0.10), theme.primaryText.opacity(0.03)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                LinearGradient(
                    colors: [theme.accentColor.opacity(0.15), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
            }
        }
    }

    // MARK: - Light Mode Backgrounds
    @ViewBuilder
    private func lightBackground(_ r: CGFloat) -> some View {
        switch elevation {
        case .flat:
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [theme.primaryText.opacity(0.03), theme.primaryText.opacity(0.01)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        case .raised:
            ZStack {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(Color.white.opacity(0.85))
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryText.opacity(0.04), theme.primaryText.opacity(0.015)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
        case .prominent:
            ZStack {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(Color.white.opacity(0.90))
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryText.opacity(0.05), theme.primaryText.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                LinearGradient(
                    colors: [theme.accentColor.opacity(0.08), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
            }
        }
    }

    // MARK: - Shadow
    private var shadowColor: Color {
        switch elevation {
        case .flat: return .clear
        case .raised: return Color.black.opacity(theme.isLight ? 0.06 : 0.12)
        case .prominent: return Color.black.opacity(theme.isLight ? 0.08 : 0.18)
        }
    }

    private var shadowRadius: CGFloat {
        switch elevation {
        case .flat: return 0
        case .raised: return theme.isLight ? 6 : 8
        case .prominent: return theme.isLight ? 10 : 12
        }
    }

    private var shadowY: CGFloat {
        switch elevation {
        case .flat: return 0
        case .raised: return 2
        case .prominent: return 3
        }
    }
}

extension View {
    func deviCard(theme: DeviTheme, elevation: DeviCardElevation = .raised, cornerRadius: CGFloat = 14) -> some View {
        modifier(DeviCardModifier(theme: theme, elevation: elevation, cornerRadius: cornerRadius))
    }
}

// MARK: - Button Style

enum DeviButtonVariant {
    case primary
    case secondary
}

struct DeviButtonStyle: ButtonStyle {
    let variant: DeviButtonVariant
    var accentColor: Color = Color(hex: "d4a857")

    func makeBody(configuration: Configuration) -> some View {
        switch variant {
        case .primary:
            configuration.label
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(accentColor)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(0.4), lineWidth: 1)
                )
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                .opacity(configuration.isPressed ? 0.7 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        case .secondary:
            configuration.label
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(accentColor)
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(0.4), lineWidth: 1)
                )
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                .opacity(configuration.isPressed ? 0.7 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

extension View {
    func deviButton(_ variant: DeviButtonVariant) -> some View {
        self.buttonStyle(DeviButtonStyle(variant: variant))
    }
    func deviButton(_ variant: DeviButtonVariant, theme: DeviTheme) -> some View {
        self.buttonStyle(DeviButtonStyle(variant: variant, accentColor: theme.accentColor))
    }
}

// MARK: - Timezone-Aware Time Formatting

func deviFormatTime(_ date: Date, timezoneIdentifier: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    formatter.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .current
    return formatter.string(from: date)
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifier for themed text

struct ThemedLabel: ViewModifier {
    let style: LabelStyle
    let theme: DeviTheme
    @Environment(\.deviFontScale) private var scale

    enum LabelStyle {
        case hero        // 48pt countdown
        case sacredTitle // 32pt serif (tithi name, goddess)
        case title       // 22pt semibold sans (section headers)
        case section     // 12pt uppercase label, tracking 2.0
        case body        // 16pt regular
        case sacredBody  // 16pt regular serif
        case detail      // 14pt secondary
        case caption     // 12pt timestamps
        case insight     // 13pt regular serif at 70% — inline Vedic meanings/deity names
    }

    func body(content: Content) -> some View {
        let m = scale.multiplier
        let hm = scale.heroMultiplier

        switch style {
        case .hero:
            content
                .font(.system(size: 48 * hm, weight: .light, design: .rounded))
                .foregroundColor(theme.primaryText)
                .monospacedDigit()
        case .sacredTitle:
            content
                .font(.system(size: 32 * m, weight: .regular, design: .serif))
                .foregroundColor(theme.primaryText)
        case .title:
            content
                .font(.system(size: 22 * m, weight: .semibold))
                .foregroundColor(theme.primaryText)
        case .section:
            content
                .font(.system(size: 12 * m, weight: .semibold))
                .foregroundColor(theme.secondaryText)
                .textCase(.uppercase)
                .tracking(2.0)
        case .body:
            content
                .font(.system(size: 16 * m, weight: .regular))
                .foregroundColor(theme.primaryText)
        case .sacredBody:
            content
                .font(.system(size: 16 * m, weight: .regular, design: .serif))
                .foregroundColor(theme.primaryText)
        case .detail:
            content
                .font(.system(size: 14 * m, weight: .regular))
                .foregroundColor(theme.secondaryText)
        case .caption:
            content
                .font(.system(size: 12 * m, weight: .regular))
                .foregroundColor(theme.secondaryText)
        case .insight:
            content
                .font(.system(size: 13 * m, weight: .regular, design: .serif))
                .foregroundColor(theme.secondaryText.opacity(0.85))
        }
    }
}

extension View {
    func deviLabel(_ style: ThemedLabel.LabelStyle, theme: DeviTheme) -> some View {
        modifier(ThemedLabel(style: style, theme: theme))
    }
}

// MARK: - Entrance Animation Modifier

struct DeviEntranceModifier: ViewModifier {
    let delay: Double
    @State private var isAppearing = false

    func body(content: Content) -> some View {
        content
            .offset(y: isAppearing ? 0 : 20)
            .opacity(isAppearing ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    isAppearing = true
                }
            }
    }
}

extension View {
    func deviEntrance(delay: Double = 0) -> some View {
        modifier(DeviEntranceModifier(delay: delay))
    }
}

// MARK: - Directional Reveal Animation Modifier

enum DeviRevealDirection {
    case fadeUp
    case fadeLeft
    case fadeRight
    case scale
}

struct DeviRevealModifier: ViewModifier {
    let delay: Double
    let direction: DeviRevealDirection
    @State private var isAppearing = false

    func body(content: Content) -> some View {
        content
            .offset(
                x: isAppearing ? 0 : horizontalOffset,
                y: isAppearing ? 0 : verticalOffset
            )
            .scaleEffect(isAppearing ? 1 : scaleValue)
            .opacity(isAppearing ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    isAppearing = true
                }
            }
    }

    private var horizontalOffset: CGFloat {
        switch direction {
        case .fadeLeft: return -20
        case .fadeRight: return 20
        default: return 0
        }
    }

    private var verticalOffset: CGFloat {
        direction == .fadeUp ? 20 : 0
    }

    private var scaleValue: CGFloat {
        direction == .scale ? 0.85 : 1.0
    }
}

extension View {
    func deviReveal(delay: Double = 0, direction: DeviRevealDirection = .fadeUp) -> some View {
        modifier(DeviRevealModifier(delay: delay, direction: direction))
    }
}

// MARK: - Breathing Animation Modifier (for NOW badges)

/// Applies a subtle opacity oscillation (dim ↔ bright) to simulate breathing.
/// Used on all "NOW" badges across cards to make active states feel alive.
struct BreathingModifier: ViewModifier {
    @State private var isBreathing = false

    func body(content: Content) -> some View {
        content
            .opacity(isBreathing ? 1.0 : 0.5)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            }
    }
}

extension View {
    /// Makes a view "breathe" — oscillating opacity between 50% and 100%.
    func breathing() -> some View {
        modifier(BreathingModifier())
    }
}

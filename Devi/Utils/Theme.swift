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

    // Consistent semantic status colors across all themes
    let auspiciousColor: Color = Color(hex: "3DA66A")
    let inauspiciousColor: Color = Color(hex: "C45050")
    let cautionColor: Color = Color(hex: "D4A040")

    // MARK: - Time-based themes

    static func forPeriod(_ period: TimePeriod) -> DeviTheme {
        switch period {
        case .brahmaMuhurta:
            return DeviTheme(
                backgroundGradientTop: Color(hex: "0B1026"),
                backgroundGradientMid: Color(hex: "162044"),
                backgroundGradientBottom: Color(hex: "2B3A5E"),
                accentColor: Color(hex: "C9A96E"),
                primaryText: Color(hex: "E8E4DC"),
                secondaryText: Color(hex: "E8E4DC").opacity(0.6)
            )
        case .morning:
            return DeviTheme(
                backgroundGradientTop: Color(hex: "1E3A5F"),
                backgroundGradientMid: Color(hex: "D4854A"),
                backgroundGradientBottom: Color(hex: "E8A74D"),
                accentColor: Color(hex: "8B3E1C"),
                primaryText: Color(hex: "FAF3E8"),
                secondaryText: Color(hex: "FAF3E8").opacity(0.7)
            )
        case .afternoon:
            return DeviTheme(
                backgroundGradientTop: Color(hex: "1B4B7A"),
                backgroundGradientMid: Color(hex: "3B7CB8"),
                backgroundGradientBottom: Color(hex: "8FB8D4"),
                accentColor: Color(hex: "B8860B"),
                primaryText: Color(hex: "1A1A2E"),
                secondaryText: Color(hex: "1A1A2E").opacity(0.55)
            )
        case .evening:
            return DeviTheme(
                backgroundGradientTop: Color(hex: "0F1B33"),
                backgroundGradientMid: Color(hex: "3D2245"),
                backgroundGradientBottom: Color(hex: "6B3040"),
                accentColor: Color(hex: "C4813D"),
                primaryText: Color(hex: "F5EDE0"),
                secondaryText: Color(hex: "F5EDE0").opacity(0.6)
            )
        case .night:
            return DeviTheme(
                backgroundGradientTop: Color(hex: "060B18"),
                backgroundGradientMid: Color(hex: "0D1528"),
                backgroundGradientBottom: Color(hex: "141E33"),
                accentColor: Color(hex: "8A9BB8"),
                primaryText: Color(hex: "E8E4DC"),
                secondaryText: Color(hex: "E8E4DC").opacity(0.5)
            )
        }
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

    // Arc gradient for the sun timer — adapts to time of day
    static func arcGradient(for period: TimePeriod) -> LinearGradient {
        switch period {
        case .brahmaMuhurta:
            return LinearGradient(
                colors: [Color(hex: "6366f1"), Color(hex: "a855f7")],
                startPoint: .leading, endPoint: .trailing
            )
        case .morning:
            return LinearGradient(
                colors: [Color(hex: "f59e0b"), Color(hex: "ef4444")],
                startPoint: .leading, endPoint: .trailing
            )
        case .afternoon:
            return LinearGradient(
                colors: [Color(hex: "d4a857"), Color(hex: "f0c040")],
                startPoint: .leading, endPoint: .trailing
            )
        case .evening:
            return LinearGradient(
                colors: [Color(hex: "ea580c"), Color(hex: "9a3412")],
                startPoint: .leading, endPoint: .trailing
            )
        case .night:
            return LinearGradient(
                colors: [Color(hex: "94a3b8"), Color(hex: "64748b")],
                startPoint: .leading, endPoint: .trailing
            )
        }
    }

    // Arc shadow color — matches the gradient start for visual coherence
    static func arcShadowColor(for period: TimePeriod) -> Color {
        switch period {
        case .brahmaMuhurta: return Color(hex: "6366f1")
        case .morning:       return Color(hex: "f59e0b")
        case .afternoon:     return Color(hex: "f0c040")
        case .evening:       return Color(hex: "ea580c")
        case .night:         return Color(hex: "94a3b8")
        }
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
        let effectiveRadius = elevation == .prominent ? max(cornerRadius, 24) : cornerRadius

        content
            .background {
                switch elevation {
                case .flat:
                    RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
                        .fill(theme.primaryText.opacity(0.04))
                case .raised:
                    ZStack {
                        RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.25))

                        RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
                            .fill(theme.primaryText.opacity(0.03))
                    }
                case .prominent:
                    ZStack {
                        RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.6))

                        RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
                            .fill(theme.primaryText.opacity(0.08))

                        // Inner gradient for prominent cards
                        LinearGradient(
                            colors: [theme.accentColor.opacity(0.06), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous))
            .overlay(
                Group {
                    switch elevation {
                    case .flat:
                        EmptyView()
                    case .raised:
                        RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
                            .stroke(theme.primaryText.opacity(0.05), lineWidth: 0.5)
                    case .prominent:
                        RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
                            .stroke(theme.accentColor.opacity(0.15), lineWidth: 1)
                    }
                }
            )
            .shadow(
                color: {
                    switch elevation {
                    case .flat: return .clear
                    case .raised: return Color.black.opacity(0.08)
                    case .prominent: return Color.black.opacity(0.12)
                    }
                }(),
                radius: elevation == .prominent ? 8 : 4,
                x: 0,
                y: elevation == .prominent ? 3 : 2
            )
    }
}

extension View {
    func deviCard(theme: DeviTheme, elevation: DeviCardElevation = .raised, cornerRadius: CGFloat = 20) -> some View {
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

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(variant == .primary ? Color(hex: "1a0a2e") : Color(hex: "d4a857"))
            .background(
                Group {
                    if variant == .primary {
                        LinearGradient(
                            colors: [Color(hex: "d4a857"), Color(hex: "c49a4a")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                Group {
                    if variant == .secondary {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: "d4a857").opacity(0.4), lineWidth: 1)
                    }
                }
            )
            .shadow(
                color: variant == .primary ? Color(hex: "d4a857").opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func deviButton(_ variant: DeviButtonVariant) -> some View {
        self.buttonStyle(DeviButtonStyle(variant: variant))
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

// MARK: - Utils/Theme.swift
// Time-of-day adaptive color system

import SwiftUI

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
    let backgroundGradientBottom: Color
    let accentColor: Color
    let primaryText: Color
    let secondaryText: Color
    let cardBackground: Color
    let auspiciousColor: Color
    let inauspiciousColor: Color
    let cautionColor: Color
    
    // MARK: - Time-based themes
    
    static func forPeriod(_ period: TimePeriod) -> DeviTheme {
        switch period {
        case .brahmaMuhurta:
            return DeviTheme(
                backgroundGradientTop: Color(hex: "1a0a2e"),
                backgroundGradientBottom: Color(hex: "2d1854"),
                accentColor: Color(hex: "d4a857"),
                primaryText: Color(hex: "f5f0e8"),
                secondaryText: Color(hex: "f5f0e8").opacity(0.6),
                cardBackground: Color.white.opacity(0.08),
                auspiciousColor: Color(hex: "4ade80"),
                inauspiciousColor: Color(hex: "b85c5c"),
                cautionColor: Color(hex: "d4a857")
            )
        case .morning:
            return DeviTheme(
                backgroundGradientTop: Color(hex: "c54b2a"),
                backgroundGradientBottom: Color(hex: "d4862a"),
                accentColor: Color(hex: "6b1d1d"),
                primaryText: Color(hex: "faf3e8"),
                secondaryText: Color(hex: "faf3e8").opacity(0.7),
                cardBackground: Color.black.opacity(0.15),
                auspiciousColor: Color(hex: "2d8a4e"),
                inauspiciousColor: Color(hex: "8b3a3a"),
                cautionColor: Color(hex: "d4a857")
            )
        case .afternoon:
            return DeviTheme(
                backgroundGradientTop: Color(hex: "a8441a"),
                backgroundGradientBottom: Color(hex: "7a3018"),
                accentColor: Color(hex: "c9a84c"),
                primaryText: Color(hex: "f0e8d8"),
                secondaryText: Color(hex: "f0e8d8").opacity(0.65),
                cardBackground: Color.black.opacity(0.15),
                auspiciousColor: Color(hex: "4ade80"),
                inauspiciousColor: Color(hex: "b85c5c"),
                cautionColor: Color(hex: "d4a857")
            )
        case .evening:
            return DeviTheme(
                backgroundGradientTop: Color(hex: "4a1942"),
                backgroundGradientBottom: Color(hex: "2a0e22"),
                accentColor: Color(hex: "b87333"),
                primaryText: Color(hex: "f5ede0"),
                secondaryText: Color(hex: "f5ede0").opacity(0.6),
                cardBackground: Color.white.opacity(0.08),
                auspiciousColor: Color(hex: "4ade80"),
                inauspiciousColor: Color(hex: "b85c5c"),
                cautionColor: Color(hex: "d4a857")
            )
        case .night:
            return DeviTheme(
                backgroundGradientTop: Color(hex: "0a0612"),
                backgroundGradientBottom: Color(hex: "121028"),
                accentColor: Color(hex: "a8b8d4"),
                primaryText: Color(hex: "e8e4dc"),
                secondaryText: Color(hex: "e8e4dc").opacity(0.5),
                cardBackground: Color.white.opacity(0.06),
                auspiciousColor: Color(hex: "4ade80"),
                inauspiciousColor: Color(hex: "b85c5c"),
                cautionColor: Color(hex: "d4a857")
            )
        }
    }
    
    // The full background gradient (used as main view background)
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundGradientTop, backgroundGradientBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // Arc gradient for the sun timer
    var arcGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "d4a857"),   // Sunrise gold
                Color(hex: "f0c040"),   // Noon bright
                Color(hex: "b87333")    // Sunset copper
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
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
    
    enum LabelStyle {
        case hero        // 48pt countdown
        case title       // 28pt tithi name
        case section     // 13pt uppercase label
        case body        // 17pt regular
        case detail      // 15pt secondary
        case sacredTitle // 28pt medium serif
        case sacredBody  // 15pt medium serif
    }
    
    func body(content: Content) -> some View {
        switch style {
        case .hero:
            content
                .font(.system(size: 48, weight: .light, design: .rounded))
                .foregroundColor(theme.primaryText)
                .monospacedDigit()
        case .title:
            content
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(theme.primaryText)
        case .section:
            content
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.secondaryText)
                .textCase(.uppercase)
                .tracking(1.5)
        case .body:
            content
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(theme.primaryText)
        case .detail:
            content
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(theme.secondaryText)
        case .sacredTitle:
            content
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundColor(theme.primaryText)
        case .sacredBody:
            content
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(theme.primaryText)
        }
    }
}

extension View {
    func deviLabel(_ style: ThemedLabel.LabelStyle, theme: DeviTheme) -> some View {
        modifier(ThemedLabel(style: style, theme: theme))
    }
}

// MARK: - Glassmorphic Card Modifier

struct DeviCardModifier: ViewModifier {
    let theme: DeviTheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    theme.cardBackground

                    LinearGradient(
                        colors: [theme.primaryText.opacity(0.04), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.primaryText.opacity(0.12), lineWidth: 0.5)
            )
    }
}

extension View {
    func deviCard(theme: DeviTheme, cornerRadius: CGFloat = 16) -> some View {
        modifier(DeviCardModifier(theme: theme, cornerRadius: cornerRadius))
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

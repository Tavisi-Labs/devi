// MARK: - Utils/ThemePalettes.swift
// All 25 theme palette definitions (5 styles × 5 time periods)
// Data-only file — no SwiftUI views or modifiers

import SwiftUI

// MARK: - Palette Data Container

struct ThemePalette {
    let bgTop: String
    let bgMid: String
    let bgBottom: String
    let accent: String
    let primaryText: String
    let secondaryText: String
    let secondaryTextOpacity: Double
    let arcStart: String
    let arcEnd: String
    let arcShadow: String
}

// MARK: - Palette Registry

enum ThemePaletteRegistry {

    static func palette(for style: DeviThemeStyle, period: TimePeriod) -> ThemePalette {
        switch style {
        case .classic:       return classicPalette(period)
        case .vividTemple:   return vividTemplePalette(period)
        case .sunriseGarden: return sunriseGardenPalette(period)
        case .cosmicJewel:   return cosmicJewelPalette(period)
        case .goldenDawn:    return goldenDawnPalette(period)
        }
    }

    // MARK: - Classic (current palette, extracted from Theme.swift)

    private static func classicPalette(_ period: TimePeriod) -> ThemePalette {
        switch period {
        case .brahmaMuhurta:
            return ThemePalette(
                bgTop: "0B1026", bgMid: "162044", bgBottom: "2B3A5E",
                accent: "C9A96E",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.6,
                arcStart: "6366f1", arcEnd: "a855f7", arcShadow: "6366f1"
            )
        case .morning:
            return ThemePalette(
                bgTop: "1E3A5F", bgMid: "D4854A", bgBottom: "E8A74D",
                accent: "8B3E1C",
                primaryText: "FAF3E8", secondaryText: "FAF3E8", secondaryTextOpacity: 0.7,
                arcStart: "f59e0b", arcEnd: "ef4444", arcShadow: "f59e0b"
            )
        case .afternoon:
            return ThemePalette(
                bgTop: "1B4B7A", bgMid: "3B7CB8", bgBottom: "8FB8D4",
                accent: "B8860B",
                primaryText: "1A1A2E", secondaryText: "1A1A2E", secondaryTextOpacity: 0.55,
                arcStart: "d4a857", arcEnd: "f0c040", arcShadow: "f0c040"
            )
        case .evening:
            return ThemePalette(
                bgTop: "0F1B33", bgMid: "3D2245", bgBottom: "6B3040",
                accent: "C4813D",
                primaryText: "F5EDE0", secondaryText: "F5EDE0", secondaryTextOpacity: 0.6,
                arcStart: "ea580c", arcEnd: "9a3412", arcShadow: "ea580c"
            )
        case .night:
            return ThemePalette(
                bgTop: "060B18", bgMid: "0D1528", bgBottom: "141E33",
                accent: "8A9BB8",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.5,
                arcStart: "94a3b8", arcEnd: "64748b", arcShadow: "94a3b8"
            )
        }
    }

    // MARK: - Vivid Temple (saturated dark)

    private static func vividTemplePalette(_ period: TimePeriod) -> ThemePalette {
        switch period {
        case .brahmaMuhurta:
            return ThemePalette(
                bgTop: "0D0A2E", bgMid: "1E1450", bgBottom: "3A2878",
                accent: "FFB347",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.6,
                arcStart: "7C6AFF", arcEnd: "C084FC", arcShadow: "7C6AFF"
            )
        case .morning:
            return ThemePalette(
                bgTop: "1A1845", bgMid: "E06830", bgBottom: "FF9F43",
                accent: "C0392B",
                primaryText: "FAF3E8", secondaryText: "FAF3E8", secondaryTextOpacity: 0.7,
                arcStart: "FFB020", arcEnd: "FF4444", arcShadow: "FFB020"
            )
        case .afternoon:
            return ThemePalette(
                bgTop: "0E3D6B", bgMid: "2E8BC0", bgBottom: "6FC3DF",
                accent: "F1C40F",
                primaryText: "1A1A2E", secondaryText: "1A1A2E", secondaryTextOpacity: 0.55,
                arcStart: "FFD700", arcEnd: "FFA500", arcShadow: "FFD700"
            )
        case .evening:
            return ThemePalette(
                bgTop: "12082A", bgMid: "6B2047", bgBottom: "A8334A",
                accent: "E67E22",
                primaryText: "F5EDE0", secondaryText: "F5EDE0", secondaryTextOpacity: 0.6,
                arcStart: "FF6B35", arcEnd: "C0392B", arcShadow: "FF6B35"
            )
        case .night:
            return ThemePalette(
                bgTop: "070514", bgMid: "0F0D28", bgBottom: "1A1640",
                accent: "9B89D9",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.5,
                arcStart: "A8A3C7", arcEnd: "7B78A0", arcShadow: "A8A3C7"
            )
        }
    }

    // MARK: - Sunrise Garden (warm & lighter)

    private static func sunriseGardenPalette(_ period: TimePeriod) -> ThemePalette {
        switch period {
        case .brahmaMuhurta:
            return ThemePalette(
                bgTop: "1A0E2E", bgMid: "2D1B4E", bgBottom: "4A3068",
                accent: "E8B84D",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.6,
                arcStart: "8B6FD4", arcEnd: "C490E0", arcShadow: "8B6FD4"
            )
        case .morning:
            return ThemePalette(
                bgTop: "2D1810", bgMid: "C85A28", bgBottom: "F4A940",
                accent: "A0421A",
                primaryText: "FAF3E8", secondaryText: "FAF3E8", secondaryTextOpacity: 0.7,
                arcStart: "F0A030", arcEnd: "E04830", arcShadow: "F0A030"
            )
        case .afternoon:
            return ThemePalette(
                bgTop: "1A4040", bgMid: "2E8A7A", bgBottom: "70C4B0",
                accent: "D4A017",
                primaryText: "1A1A2E", secondaryText: "1A1A2E", secondaryTextOpacity: 0.55,
                arcStart: "40B090", arcEnd: "70D4B8", arcShadow: "40B090"
            )
        case .evening:
            return ThemePalette(
                bgTop: "2A1018", bgMid: "6B2038", bgBottom: "A84050",
                accent: "D4943C",
                primaryText: "F5EDE0", secondaryText: "F5EDE0", secondaryTextOpacity: 0.6,
                arcStart: "D46040", arcEnd: "8B2030", arcShadow: "D46040"
            )
        case .night:
            return ThemePalette(
                bgTop: "0E0818", bgMid: "1A1230", bgBottom: "251C42",
                accent: "A89BC8",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.5,
                arcStart: "9088B0", arcEnd: "6860A0", arcShadow: "9088B0"
            )
        }
    }

    // MARK: - Cosmic Jewel (gemstone identities)

    private static func cosmicJewelPalette(_ period: TimePeriod) -> ThemePalette {
        switch period {
        case .brahmaMuhurta: // Amethyst
            return ThemePalette(
                bgTop: "0C0620", bgMid: "1E1048", bgBottom: "3D2470",
                accent: "C9A0F0",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.6,
                arcStart: "9B59B6", arcEnd: "D4A0F0", arcShadow: "9B59B6"
            )
        case .morning: // Topaz
            return ThemePalette(
                bgTop: "1A1000", bgMid: "B07020", bgBottom: "E8A830",
                accent: "FF6B2C",
                primaryText: "FAF3E8", secondaryText: "FAF3E8", secondaryTextOpacity: 0.7,
                arcStart: "F0A030", arcEnd: "FF5722", arcShadow: "F0A030"
            )
        case .afternoon: // Sapphire
            return ThemePalette(
                bgTop: "081840", bgMid: "1848A0", bgBottom: "4080E0",
                accent: "FFD700",
                primaryText: "F0F0F8", secondaryText: "F0F0F8", secondaryTextOpacity: 0.6,
                arcStart: "3498DB", arcEnd: "5DADE2", arcShadow: "3498DB"
            )
        case .evening: // Ruby
            return ThemePalette(
                bgTop: "180818", bgMid: "601030", bgBottom: "A01840",
                accent: "F0C060",
                primaryText: "F5EDE0", secondaryText: "F5EDE0", secondaryTextOpacity: 0.6,
                arcStart: "E74C3C", arcEnd: "C0392B", arcShadow: "E74C3C"
            )
        case .night: // Onyx
            return ThemePalette(
                bgTop: "040408", bgMid: "0C0C18", bgBottom: "181828",
                accent: "70A0C0",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.5,
                arcStart: "7F8C8D", arcEnd: "566573", arcShadow: "7F8C8D"
            )
        }
    }

    // MARK: - Golden Dawn (brightest)

    private static func goldenDawnPalette(_ period: TimePeriod) -> ThemePalette {
        switch period {
        case .brahmaMuhurta:
            return ThemePalette(
                bgTop: "141030", bgMid: "282058", bgBottom: "483880",
                accent: "FFD060",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.6,
                arcStart: "7B68EE", arcEnd: "BA55D3", arcShadow: "7B68EE"
            )
        case .morning: // Light mode with dark text
            return ThemePalette(
                bgTop: "3A2A10", bgMid: "D89040", bgBottom: "FFD080",
                accent: "8B3A10",
                primaryText: "2A1A08", secondaryText: "2A1A08", secondaryTextOpacity: 0.55,
                arcStart: "FFB800", arcEnd: "FF6347", arcShadow: "FFB800"
            )
        case .afternoon: // Light mode with dark text
            return ThemePalette(
                bgTop: "184870", bgMid: "4098D0", bgBottom: "A0D4F0",
                accent: "C08808",
                primaryText: "0A1828", secondaryText: "0A1828", secondaryTextOpacity: 0.55,
                arcStart: "FFD700", arcEnd: "FFA500", arcShadow: "FFD700"
            )
        case .evening:
            return ThemePalette(
                bgTop: "1A1028", bgMid: "583048", bgBottom: "904858",
                accent: "E8A040",
                primaryText: "F5EDE0", secondaryText: "F5EDE0", secondaryTextOpacity: 0.6,
                arcStart: "FF7043", arcEnd: "B71C1C", arcShadow: "FF7043"
            )
        case .night:
            return ThemePalette(
                bgTop: "080818", bgMid: "101028", bgBottom: "1C1C38",
                accent: "A0B8D8",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.5,
                arcStart: "B0C4DE", arcEnd: "778899", arcShadow: "B0C4DE"
            )
        }
    }
}

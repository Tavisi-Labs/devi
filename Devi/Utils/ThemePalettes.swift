// MARK: - Utils/ThemePalettes.swift
// All 50 theme palette definitions (5 styles x 5 time periods x 2 modes)
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

    static func palette(for style: DeviThemeStyle, period: TimePeriod, isLight: Bool = false) -> ThemePalette {
        switch style {
        case .classic:       return classicPalette(period, isLight)
        case .vividTemple:   return vividTemplePalette(period, isLight)
        case .sunriseGarden: return sunriseGardenPalette(period, isLight)
        case .cosmicJewel:   return cosmicJewelPalette(period, isLight)
        case .goldenDawn:    return goldenDawnPalette(period, isLight)
        }
    }

    // MARK: - Classic
    // Sophisticated mahogany library. Antique gold accent. Warm neutral backgrounds.

    private static func classicPalette(_ period: TimePeriod, _ isLight: Bool) -> ThemePalette {
        if isLight {
            switch period {
            case .brahmaMuhurta:
                return ThemePalette(
                    bgTop: "F0EBE3", bgMid: "E8E0D4", bgBottom: "DED4C4",
                    accent: "9A7B4F",
                    primaryText: "2A2218", secondaryText: "2A2218", secondaryTextOpacity: 0.58,
                    arcStart: "7B6BAE", arcEnd: "A088C8", arcShadow: "7B6BAE"
                )
            case .morning:
                return ThemePalette(
                    bgTop: "F5F0E8", bgMid: "EDE5D8", bgBottom: "E3D8C8",
                    accent: "9E6830",
                    primaryText: "2A2018", secondaryText: "2A2018", secondaryTextOpacity: 0.60,
                    arcStart: "D08830", arcEnd: "B85A28", arcShadow: "D08830"
                )
            case .afternoon:
                return ThemePalette(
                    bgTop: "F2EEE6", bgMid: "E8E2D8", bgBottom: "DDD5C8",
                    accent: "9A7820",
                    primaryText: "1E1A14", secondaryText: "1E1A14", secondaryTextOpacity: 0.55,
                    arcStart: "B89838", arcEnd: "D4B050", arcShadow: "B89838"
                )
            case .evening:
                return ThemePalette(
                    bgTop: "EDE6DC", bgMid: "E2D8CC", bgBottom: "D6CABA",
                    accent: "A86838",
                    primaryText: "241E16", secondaryText: "241E16", secondaryTextOpacity: 0.58,
                    arcStart: "C07038", arcEnd: "8A4A20", arcShadow: "C07038"
                )
            case .night:
                return ThemePalette(
                    bgTop: "EAE4DA", bgMid: "DED6CA", bgBottom: "D2C8B8",
                    accent: "6A7A94",
                    primaryText: "22201A", secondaryText: "22201A", secondaryTextOpacity: 0.52,
                    arcStart: "7888A0", arcEnd: "5A6878", arcShadow: "7888A0"
                )
            }
        }
        switch period {
        case .brahmaMuhurta:
            return ThemePalette(
                bgTop: "10142A", bgMid: "1A2548", bgBottom: "2E3E64",
                accent: "C9A96E",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.60,
                arcStart: "6366F1", arcEnd: "A855F7", arcShadow: "6366F1"
            )
        case .morning:
            return ThemePalette(
                bgTop: "1C2840", bgMid: "8A5030", bgBottom: "C48040",
                accent: "D4984A",
                primaryText: "FAF3E8", secondaryText: "FAF3E8", secondaryTextOpacity: 0.70,
                arcStart: "E89840", arcEnd: "D06030", arcShadow: "E89840"
            )
        case .afternoon:
            return ThemePalette(
                bgTop: "1A3A5A", bgMid: "386890", bgBottom: "6898B8",
                accent: "B8860B",
                primaryText: "F0ECE4", secondaryText: "F0ECE4", secondaryTextOpacity: 0.65,
                arcStart: "D4A857", arcEnd: "F0C040", arcShadow: "D4A857"
            )
        case .evening:
            return ThemePalette(
                bgTop: "141828", bgMid: "3A2440", bgBottom: "5E3040",
                accent: "C4813D",
                primaryText: "F5EDE0", secondaryText: "F5EDE0", secondaryTextOpacity: 0.60,
                arcStart: "EA580C", arcEnd: "9A3412", arcShadow: "EA580C"
            )
        case .night:
            return ThemePalette(
                bgTop: "0A0E1C", bgMid: "121A2C", bgBottom: "1C2438",
                accent: "8A9BB8",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.55,
                arcStart: "94A3B8", arcEnd: "64748B", arcShadow: "94A3B8"
            )
        }
    }

    // MARK: - Vivid Temple
    // Oil-lamp-lit temple interior. Saffron/flame accent. Deep jewel backgrounds.

    private static func vividTemplePalette(_ period: TimePeriod, _ isLight: Bool) -> ThemePalette {
        if isLight {
            switch period {
            case .brahmaMuhurta:
                return ThemePalette(
                    bgTop: "F2ECE4", bgMid: "E8DED2", bgBottom: "DCD0C0",
                    accent: "C87A20",
                    primaryText: "281E14", secondaryText: "281E14", secondaryTextOpacity: 0.58,
                    arcStart: "8868C0", arcEnd: "B090D8", arcShadow: "8868C0"
                )
            case .morning:
                return ThemePalette(
                    bgTop: "F8F0E4", bgMid: "F0E2D0", bgBottom: "E6D2B8",
                    accent: "C84820",
                    primaryText: "2C1A10", secondaryText: "2C1A10", secondaryTextOpacity: 0.60,
                    arcStart: "E08028", arcEnd: "C84018", arcShadow: "E08028"
                )
            case .afternoon:
                return ThemePalette(
                    bgTop: "F0ECE4", bgMid: "E4DCD0", bgBottom: "D8CEB8",
                    accent: "C89C10",
                    primaryText: "1C1810", secondaryText: "1C1810", secondaryTextOpacity: 0.55,
                    arcStart: "D4A818", arcEnd: "C09010", arcShadow: "D4A818"
                )
            case .evening:
                return ThemePalette(
                    bgTop: "F0E8DE", bgMid: "E4D8C8", bgBottom: "D6C8B2",
                    accent: "B85A28",
                    primaryText: "261810", secondaryText: "261810", secondaryTextOpacity: 0.58,
                    arcStart: "D06830", arcEnd: "A04018", arcShadow: "D06830"
                )
            case .night:
                return ThemePalette(
                    bgTop: "ECE6DC", bgMid: "E0D8CC", bgBottom: "D4CABA",
                    accent: "7A6AA8",
                    primaryText: "201C16", secondaryText: "201C16", secondaryTextOpacity: 0.52,
                    arcStart: "8878B0", arcEnd: "685898", arcShadow: "8878B0"
                )
            }
        }
        switch period {
        case .brahmaMuhurta:
            return ThemePalette(
                bgTop: "100A28", bgMid: "201450", bgBottom: "3C2870",
                accent: "FFB347",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.60,
                arcStart: "7C6AFF", arcEnd: "C084FC", arcShadow: "7C6AFF"
            )
        case .morning:
            return ThemePalette(
                bgTop: "201838", bgMid: "884028", bgBottom: "D07838",
                accent: "E86830",
                primaryText: "FAF3E8", secondaryText: "FAF3E8", secondaryTextOpacity: 0.70,
                arcStart: "FFB020", arcEnd: "FF4444", arcShadow: "FFB020"
            )
        case .afternoon:
            return ThemePalette(
                bgTop: "103058", bgMid: "2870A8", bgBottom: "58A8D0",
                accent: "F1C40F",
                primaryText: "F0ECE4", secondaryText: "F0ECE4", secondaryTextOpacity: 0.65,
                arcStart: "FFD700", arcEnd: "FFA500", arcShadow: "FFD700"
            )
        case .evening:
            return ThemePalette(
                bgTop: "140A24", bgMid: "5C1840", bgBottom: "8E2840",
                accent: "E67E22",
                primaryText: "F5EDE0", secondaryText: "F5EDE0", secondaryTextOpacity: 0.60,
                arcStart: "FF6B35", arcEnd: "C0392B", arcShadow: "FF6B35"
            )
        case .night:
            return ThemePalette(
                bgTop: "080614", bgMid: "120E24", bgBottom: "1C1838",
                accent: "9B89D9",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.55,
                arcStart: "A8A3C7", arcEnd: "7B78A0", arcShadow: "A8A3C7"
            )
        }
    }

    // MARK: - Sunrise Garden
    // Zen garden through the day. Earth-clay accent. Organic backgrounds.

    private static func sunriseGardenPalette(_ period: TimePeriod, _ isLight: Bool) -> ThemePalette {
        if isLight {
            switch period {
            case .brahmaMuhurta:
                return ThemePalette(
                    bgTop: "EEE8E0", bgMid: "E2DAD0", bgBottom: "D6CCB8",
                    accent: "8A7040",
                    primaryText: "26221A", secondaryText: "26221A", secondaryTextOpacity: 0.58,
                    arcStart: "7860A8", arcEnd: "9878C0", arcShadow: "7860A8"
                )
            case .morning:
                return ThemePalette(
                    bgTop: "F0EDE6", bgMid: "E4DED2", bgBottom: "D8D0C0",
                    accent: "8A5830",
                    primaryText: "281E14", secondaryText: "281E14", secondaryTextOpacity: 0.60,
                    arcStart: "B87838", arcEnd: "A05828", arcShadow: "B87838"
                )
            case .afternoon:
                return ThemePalette(
                    bgTop: "ECF0E8", bgMid: "E0E8DC", bgBottom: "D2DCC8",
                    accent: "6A8838",
                    primaryText: "1C2018", secondaryText: "1C2018", secondaryTextOpacity: 0.55,
                    arcStart: "589050", arcEnd: "78A868", arcShadow: "589050"
                )
            case .evening:
                return ThemePalette(
                    bgTop: "EDE8E0", bgMid: "E2D8CC", bgBottom: "D4C8B4",
                    accent: "A06030",
                    primaryText: "241C14", secondaryText: "241C14", secondaryTextOpacity: 0.58,
                    arcStart: "C06840", arcEnd: "903828", arcShadow: "C06840"
                )
            case .night:
                return ThemePalette(
                    bgTop: "EAE6DE", bgMid: "DED8CE", bgBottom: "D0C8B8",
                    accent: "6E6890",
                    primaryText: "201E18", secondaryText: "201E18", secondaryTextOpacity: 0.52,
                    arcStart: "7E78A0", arcEnd: "5E5880", arcShadow: "7E78A0"
                )
            }
        }
        switch period {
        case .brahmaMuhurta:
            return ThemePalette(
                bgTop: "141024", bgMid: "281C42", bgBottom: "403060",
                accent: "E8B84D",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.60,
                arcStart: "8B6FD4", arcEnd: "C490E0", arcShadow: "8B6FD4"
            )
        case .morning:
            return ThemePalette(
                bgTop: "201410", bgMid: "784828", bgBottom: "B87838",
                accent: "C87020",
                primaryText: "FAF3E8", secondaryText: "FAF3E8", secondaryTextOpacity: 0.70,
                arcStart: "D89030", arcEnd: "C05828", arcShadow: "D89030"
            )
        case .afternoon:
            return ThemePalette(
                bgTop: "102820", bgMid: "286848", bgBottom: "509870",
                accent: "D4A017",
                primaryText: "F0ECE4", secondaryText: "F0ECE4", secondaryTextOpacity: 0.65,
                arcStart: "40B090", arcEnd: "70D4B8", arcShadow: "40B090"
            )
        case .evening:
            return ThemePalette(
                bgTop: "201018", bgMid: "582038", bgBottom: "884050",
                accent: "D4943C",
                primaryText: "F5EDE0", secondaryText: "F5EDE0", secondaryTextOpacity: 0.60,
                arcStart: "D46040", arcEnd: "8B2030", arcShadow: "D46040"
            )
        case .night:
            return ThemePalette(
                bgTop: "0C0A18", bgMid: "181228", bgBottom: "241C3A",
                accent: "A89BC8",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.55,
                arcStart: "9088B0", arcEnd: "6860A0", arcShadow: "9088B0"
            )
        }
    }

    // MARK: - Cosmic Jewel
    // Gemstone gallery. Per-period gem accent. Deep luxurious backgrounds.

    private static func cosmicJewelPalette(_ period: TimePeriod, _ isLight: Bool) -> ThemePalette {
        if isLight {
            switch period {
            case .brahmaMuhurta: // Amethyst light
                return ThemePalette(
                    bgTop: "F0ECF4", bgMid: "E6E0EC", bgBottom: "DAD2E2",
                    accent: "7A50A8",
                    primaryText: "221C28", secondaryText: "221C28", secondaryTextOpacity: 0.58,
                    arcStart: "8858B0", arcEnd: "A878C8", arcShadow: "8858B0"
                )
            case .morning: // Topaz light
                return ThemePalette(
                    bgTop: "F6F0E6", bgMid: "EDE4D4", bgBottom: "E2D6C0",
                    accent: "C86020",
                    primaryText: "2A1C10", secondaryText: "2A1C10", secondaryTextOpacity: 0.60,
                    arcStart: "D88830", arcEnd: "C06018", arcShadow: "D88830"
                )
            case .afternoon: // Sapphire light
                return ThemePalette(
                    bgTop: "ECF0F6", bgMid: "E0E6F0", bgBottom: "D2DAE8",
                    accent: "2868A8",
                    primaryText: "141828", secondaryText: "141828", secondaryTextOpacity: 0.55,
                    arcStart: "3878B8", arcEnd: "5898D0", arcShadow: "3878B8"
                )
            case .evening: // Ruby light
                return ThemePalette(
                    bgTop: "F4ECE8", bgMid: "EAE0DA", bgBottom: "DED2C8",
                    accent: "A82838",
                    primaryText: "281418", secondaryText: "281418", secondaryTextOpacity: 0.58,
                    arcStart: "C03040", arcEnd: "982028", arcShadow: "C03040"
                )
            case .night: // Onyx light
                return ThemePalette(
                    bgTop: "ECEAE8", bgMid: "E2DED8", bgBottom: "D6D0C8",
                    accent: "586070",
                    primaryText: "1E1E20", secondaryText: "1E1E20", secondaryTextOpacity: 0.52,
                    arcStart: "687080", arcEnd: "505860", arcShadow: "687080"
                )
            }
        }
        switch period {
        case .brahmaMuhurta: // Amethyst
            return ThemePalette(
                bgTop: "0E0820", bgMid: "1E1044", bgBottom: "382468",
                accent: "C9A0F0",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.60,
                arcStart: "9B59B6", arcEnd: "D4A0F0", arcShadow: "9B59B6"
            )
        case .morning: // Topaz
            return ThemePalette(
                bgTop: "181008", bgMid: "785020", bgBottom: "B88030",
                accent: "FF6B2C",
                primaryText: "FAF3E8", secondaryText: "FAF3E8", secondaryTextOpacity: 0.70,
                arcStart: "E89830", arcEnd: "FF5722", arcShadow: "E89830"
            )
        case .afternoon: // Sapphire
            return ThemePalette(
                bgTop: "0A1838", bgMid: "183C88", bgBottom: "3868C0",
                accent: "FFD700",
                primaryText: "F0F0F8", secondaryText: "F0F0F8", secondaryTextOpacity: 0.65,
                arcStart: "3498DB", arcEnd: "5DADE2", arcShadow: "3498DB"
            )
        case .evening: // Ruby
            return ThemePalette(
                bgTop: "160818", bgMid: "501028", bgBottom: "881838",
                accent: "F0C060",
                primaryText: "F5EDE0", secondaryText: "F5EDE0", secondaryTextOpacity: 0.60,
                arcStart: "E74C3C", arcEnd: "C0392B", arcShadow: "E74C3C"
            )
        case .night: // Onyx
            return ThemePalette(
                bgTop: "060608", bgMid: "0E0E18", bgBottom: "1A1A28",
                accent: "70A0C0",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.55,
                arcStart: "7F8C8D", arcEnd: "566573", arcShadow: "7F8C8D"
            )
        }
    }

    // MARK: - Golden Dawn
    // Golden hour photography. Gold-amber accent. Warm throughout.

    private static func goldenDawnPalette(_ period: TimePeriod, _ isLight: Bool) -> ThemePalette {
        if isLight {
            switch period {
            case .brahmaMuhurta:
                return ThemePalette(
                    bgTop: "F2EDE4", bgMid: "E8E0D4", bgBottom: "DCD2C0",
                    accent: "A88828",
                    primaryText: "282018", secondaryText: "282018", secondaryTextOpacity: 0.58,
                    arcStart: "7868B0", arcEnd: "9880C8", arcShadow: "7868B0"
                )
            case .morning:
                return ThemePalette(
                    bgTop: "F8F2E6", bgMid: "F0E6D2", bgBottom: "E6D8BA",
                    accent: "A87018",
                    primaryText: "2C2010", secondaryText: "2C2010", secondaryTextOpacity: 0.60,
                    arcStart: "D49828", arcEnd: "C07020", arcShadow: "D49828"
                )
            case .afternoon:
                return ThemePalette(
                    bgTop: "F0EDE6", bgMid: "E6E0D4", bgBottom: "DAD2C0",
                    accent: "A08010",
                    primaryText: "1C1810", secondaryText: "1C1810", secondaryTextOpacity: 0.55,
                    arcStart: "C8A020", arcEnd: "E0B838", arcShadow: "C8A020"
                )
            case .evening:
                return ThemePalette(
                    bgTop: "F0E8DE", bgMid: "E4DAC8", bgBottom: "D6C8B0",
                    accent: "B87020",
                    primaryText: "261C12", secondaryText: "261C12", secondaryTextOpacity: 0.58,
                    arcStart: "D47838", arcEnd: "A85020", arcShadow: "D47838"
                )
            case .night:
                return ThemePalette(
                    bgTop: "ECE8E0", bgMid: "E0DAD0", bgBottom: "D4CCB8",
                    accent: "6878A0",
                    primaryText: "201E18", secondaryText: "201E18", secondaryTextOpacity: 0.52,
                    arcStart: "8090B0", arcEnd: "607088", arcShadow: "8090B0"
                )
            }
        }
        switch period {
        case .brahmaMuhurta:
            return ThemePalette(
                bgTop: "141028", bgMid: "282050", bgBottom: "443878",
                accent: "FFD060",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.60,
                arcStart: "7B68EE", arcEnd: "BA55D3", arcShadow: "7B68EE"
            )
        case .morning:
            return ThemePalette(
                bgTop: "282010", bgMid: "886830", bgBottom: "C89840",
                accent: "E8A030",
                primaryText: "FAF3E8", secondaryText: "FAF3E8", secondaryTextOpacity: 0.70,
                arcStart: "FFB800", arcEnd: "FF6347", arcShadow: "FFB800"
            )
        case .afternoon:
            return ThemePalette(
                bgTop: "183860", bgMid: "3880B8", bgBottom: "78B0D8",
                accent: "C08808",
                primaryText: "F0ECE4", secondaryText: "F0ECE4", secondaryTextOpacity: 0.65,
                arcStart: "FFD700", arcEnd: "FFA500", arcShadow: "FFD700"
            )
        case .evening:
            return ThemePalette(
                bgTop: "181020", bgMid: "4C2840", bgBottom: "784850",
                accent: "E8A040",
                primaryText: "F5EDE0", secondaryText: "F5EDE0", secondaryTextOpacity: 0.60,
                arcStart: "FF7043", arcEnd: "B71C1C", arcShadow: "FF7043"
            )
        case .night:
            return ThemePalette(
                bgTop: "0A0A18", bgMid: "141428", bgBottom: "1E1E38",
                accent: "A0B8D8",
                primaryText: "E8E4DC", secondaryText: "E8E4DC", secondaryTextOpacity: 0.55,
                arcStart: "B0C4DE", arcEnd: "778899", arcShadow: "B0C4DE"
            )
        }
    }
}

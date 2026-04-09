// MARK: - Models/HoroscopeContentLibrary.swift
// Content library for the horoscope engine.
//
// Large content pools (house themes, category readings) are loaded from
// `horoscope_library.json` bundled in Devi/Resources/. The Python generator
// at `scripts/generate_horoscope_content.py` produces this JSON, enabling
// content scaling without touching Swift source.
//
// Small stable reference tables (nakshatra mantras, planet colors, Jupiter
// and Saturn house modifiers) remain hardcoded because they are (a) tiny,
// (b) scripturally fixed, and (c) gain nothing from externalization.
//
// If the JSON is missing or malformed, `fallbackMinimal` keeps the app
// functional with a tiny hand-written library — this is ship insurance,
// not product content.

import Foundation

enum HoroscopeContentLibrary {

    // MARK: - House Theme

    struct HouseTheme {
        let themeStatement: String
        let supportingText: String
        let doList: [String]
        let dontList: [String]
    }

    // MARK: - Lazy-Loaded Library Data

    /// Loads `horoscope_library.json` from the app bundle exactly once.
    /// Falls back to `fallbackMinimal` if the file is missing or malformed,
    /// so the app never crashes on content problems.
    private static let loaded: HoroscopeLibraryData = {
        guard let url = Bundle.main.url(
            forResource: "horoscope_library",
            withExtension: "json"
        ),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(HoroscopeLibraryData.self, from: data)
        else {
            assertionFailure("horoscope_library.json missing or malformed — falling back to minimal library")
            return Self.fallbackMinimal
        }
        return decoded
    }()

    // MARK: - Public Content Accessors

    /// 12-entry array of house themes, indexed 0..11 for houses 1..12.
    /// Each inner array contains the variant pool for that house.
    static var themes: [[HouseTheme]] {
        loaded.themesIndexed
    }

    /// Category readings keyed by house number (1..12), then by category.
    /// Each leaf is an ARRAY of variants; callers sample via the engine's
    /// variant seed.
    static var categoryReadings: [Int: [HoroscopeCategory: [CategoryReadingEntry]]] {
        loaded.categoriesIndexed
    }

    // MARK: - Nakshatra Mantras (27 entries)
    // Kept inline — scripturally fixed, no need to externalize.

    static let nakshatraMantra: [String: MantraReading] = [
        "Ashwini": MantraReading(
            sanskrit: "Om Ashwini Kumarabhyam Namaha",
            translation: "Salutations to the Ashwini Kumaras, the celestial healers",
            deity: "Ashwini Kumaras"
        ),
        "Bharani": MantraReading(
            sanskrit: "Om Yamaya Namaha",
            translation: "Salutations to Yama, lord of dharma and cosmic order",
            deity: "Yama"
        ),
        "Krittika": MantraReading(
            sanskrit: "Om Agnaye Namaha",
            translation: "Salutations to Agni, the sacred fire",
            deity: "Agni"
        ),
        "Rohini": MantraReading(
            sanskrit: "Om Brahmane Namaha",
            translation: "Salutations to Brahma, the creator",
            deity: "Brahma"
        ),
        "Mrigashira": MantraReading(
            sanskrit: "Om Somaya Namaha",
            translation: "Salutations to Soma, the lunar deity of nectar",
            deity: "Soma"
        ),
        "Ardra": MantraReading(
            sanskrit: "Om Rudraya Namaha",
            translation: "Salutations to Rudra, the cosmic transformer",
            deity: "Rudra"
        ),
        "Punarvasu": MantraReading(
            sanskrit: "Om Aditaye Namaha",
            translation: "Salutations to Aditi, the infinite mother",
            deity: "Aditi"
        ),
        "Pushya": MantraReading(
            sanskrit: "Om Brihaspataye Namaha",
            translation: "Salutations to Brihaspati, the divine teacher",
            deity: "Brihaspati"
        ),
        "Ashlesha": MantraReading(
            sanskrit: "Om Sarpebhyo Namaha",
            translation: "Salutations to the Nagas, the serpent deities",
            deity: "Nagas"
        ),
        "Magha": MantraReading(
            sanskrit: "Om Pitribhyo Namaha",
            translation: "Salutations to the Pitris, the ancestral spirits",
            deity: "Pitris"
        ),
        "Purva Phalguni": MantraReading(
            sanskrit: "Om Bhagaya Namaha",
            translation: "Salutations to Bhaga, the deity of fortune and delight",
            deity: "Bhaga"
        ),
        "Uttara Phalguni": MantraReading(
            sanskrit: "Om Aryamne Namaha",
            translation: "Salutations to Aryaman, the deity of patronage and honor",
            deity: "Aryaman"
        ),
        "Hasta": MantraReading(
            sanskrit: "Om Savitre Namaha",
            translation: "Salutations to Savitar, the vivifying solar deity",
            deity: "Savitar"
        ),
        "Chitra": MantraReading(
            sanskrit: "Om Tvashtre Namaha",
            translation: "Salutations to Tvashtar, the celestial architect",
            deity: "Tvashtar"
        ),
        "Swati": MantraReading(
            sanskrit: "Om Vayave Namaha",
            translation: "Salutations to Vayu, the lord of wind and breath",
            deity: "Vayu"
        ),
        "Vishakha": MantraReading(
            sanskrit: "Om Indragnibhyam Namaha",
            translation: "Salutations to Indra and Agni, lords of power and fire",
            deity: "Indragni"
        ),
        "Anuradha": MantraReading(
            sanskrit: "Om Mitraya Namaha",
            translation: "Salutations to Mitra, the deity of friendship and alliance",
            deity: "Mitra"
        ),
        "Jyeshtha": MantraReading(
            sanskrit: "Om Indraya Namaha",
            translation: "Salutations to Indra, king of the devas",
            deity: "Indra"
        ),
        "Mula": MantraReading(
            sanskrit: "Om Nirritaye Namaha",
            translation: "Salutations to Nirriti, the goddess of dissolution",
            deity: "Nirriti"
        ),
        "Purva Ashadha": MantraReading(
            sanskrit: "Om Apahe Namaha",
            translation: "Salutations to Apas, the cosmic waters",
            deity: "Apas"
        ),
        "Uttara Ashadha": MantraReading(
            sanskrit: "Om Vishvedebhyo Namaha",
            translation: "Salutations to the Vishvedevas, the universal gods",
            deity: "Vishvedevas"
        ),
        "Shravana": MantraReading(
            sanskrit: "Om Vishnave Namaha",
            translation: "Salutations to Vishnu, the all-pervading preserver",
            deity: "Vishnu"
        ),
        "Dhanishtha": MantraReading(
            sanskrit: "Om Vasubhyo Namaha",
            translation: "Salutations to the Vasus, the elemental deities of abundance",
            deity: "Vasus"
        ),
        "Shatabhisha": MantraReading(
            sanskrit: "Om Varunaya Namaha",
            translation: "Salutations to Varuna, lord of the cosmic waters",
            deity: "Varuna"
        ),
        "Purva Bhadrapada": MantraReading(
            sanskrit: "Om Ajaaikapadaya Namaha",
            translation: "Salutations to Aja Ekapada, the one-footed cosmic serpent",
            deity: "Aja Ekapada"
        ),
        "Uttara Bhadrapada": MantraReading(
            sanskrit: "Om Ahirbudhnyaya Namaha",
            translation: "Salutations to Ahir Budhnya, the serpent of the deep",
            deity: "Ahir Budhnya"
        ),
        "Revati": MantraReading(
            sanskrit: "Om Pushne Namaha",
            translation: "Salutations to Pushan, the nourishing guide of journeys",
            deity: "Pushan"
        ),
    ]

    // MARK: - Planet-to-Color Mapping (9 navagraha)

    static let planetColor: [String: AuspiciousColor] = [
        "Sun":     AuspiciousColor(name: "Copper",      hex: "#B87333"),
        "Moon":    AuspiciousColor(name: "Silver",       hex: "#C0C0C0"),
        "Mars":    AuspiciousColor(name: "Red",          hex: "#C45050"),
        "Mercury": AuspiciousColor(name: "Green",        hex: "#4AAD6E"),
        "Jupiter": AuspiciousColor(name: "Gold",         hex: "#D4A040"),
        "Venus":   AuspiciousColor(name: "Pink",         hex: "#D47AAD"),
        "Saturn":  AuspiciousColor(name: "Blue",         hex: "#4A6FA5"),
        "Rahu":    AuspiciousColor(name: "Smoky Grey",   hex: "#808080"),
        "Ketu":    AuspiciousColor(name: "Saffron",      hex: "#FF9933"),
    ]

    // MARK: - Jupiter Modifiers (12 houses)
    // Describes how Jupiter's transit through each house modifies the daily reading.

    static let jupiterModifiers: [Int: String] = [
        1:  "Jupiter's grace illuminates your sense of self, bringing optimism and expansion to personal endeavors. Growth feels effortless — just make sure confidence does not tip into overreach.",
        2:  "Jupiter in your house of wealth amplifies financial opportunities and family blessings. Resources may flow more generously than expected. Use abundance wisely rather than spending it all at once.",
        3:  "Jupiter expands your communicative reach and intellectual curiosity. Teaching, writing, and media projects are blessed. Your words carry more authority and your ideas find a wider audience.",
        4:  "Jupiter brings growth and comfort to your home life and emotional foundations. A move, renovation, or deepening of family bonds is possible. Inner peace becomes your greatest asset.",
        5:  "Jupiter in the house of creativity supercharges romance, artistic output, and joy. Children or creative projects may bring unexpected blessings. Take the risk — fortune favors your self-expression.",
        6:  "Jupiter's presence in the sixth house helps you overcome obstacles and improve health habits. Enemies lose their power, debts become manageable, and service to others brings unexpected rewards.",
        7:  "Jupiter blesses partnerships of all kinds. Marriage prospects improve, business alliances strengthen, and negotiations go smoothly. The right person may walk into your life at the right time.",
        8:  "Jupiter in the eighth house deepens your spiritual transformation and may bring gains through inheritance, insurance, or shared resources. The mysteries of life feel less frightening and more fascinating.",
        9:  "Jupiter is at home in the ninth house, multiplying your good fortune. Travel, higher education, and spiritual growth are all powerfully supported. Teachers and mentors appear when you need them.",
        10: "Jupiter elevates your career and public standing. Promotions, recognition, and professional milestones are within reach. Your reputation grows and leadership opportunities present themselves.",
        11: "Jupiter in the house of gains fulfills long-held wishes. Social circles expand, income from side ventures increases, and the support of friends and community lifts you higher than solo effort could.",
        12: "Jupiter in the twelfth house brings spiritual expansion and blessings through surrender. Foreign travel, meditation retreats, and charitable giving are all deeply rewarding. Letting go becomes a form of receiving.",
    ]

    // MARK: - Saturn Modifiers (12 houses)
    // Describes how Saturn's transit through each house modifies the daily reading.

    static let saturnModifiers: [Int: String] = [
        1:  "Saturn's weight on your first house demands discipline and self-honesty. Progress feels slower, but what you build now is built to last. Patience with yourself is not optional — it is essential.",
        2:  "Saturn in the house of wealth requires financial prudence and careful planning. Income may feel constrained, but this is the universe teaching you the difference between what you need and what you want.",
        3:  "Saturn tests your courage and communication. Words may feel heavier, and bold action requires more effort than usual. Persist — the skills you sharpen under pressure become your greatest strengths.",
        4:  "Saturn's transit through your fourth house may bring responsibilities at home or emotional heaviness. A parent may need your support, or your living situation demands restructuring. Build the foundation patiently.",
        5:  "Saturn in the house of joy asks you to take creativity seriously. Romance may feel weighty, and fun requires effort. The reward is depth — anything you create now has lasting substance and meaning.",
        6:  "Saturn in the sixth house strengthens your ability to handle adversity. Health routines become non-negotiable, and daily discipline yields real results. Your enemies and obstacles gradually lose their grip.",
        7:  "Saturn in the seventh house tests your most important relationships. Commitments deepen or dissolve depending on their integrity. This is not punishment — it is a filter that keeps only what is real.",
        8:  "Saturn's presence in the eighth house can feel heavy, bringing confrontation with mortality, debt, or deep psychological patterns. Transformation is not comfortable, but what emerges is unshakeable.",
        9:  "Saturn challenges your beliefs and tests your faith. Dogma crumbles, but genuine wisdom survives. Teachers may disappoint, pushing you to find your own authority. The path narrows but becomes yours.",
        10: "Saturn in your tenth house demands professional excellence without shortcuts. Career progress slows but becomes more meaningful. Authority figures scrutinize your work — give them nothing to criticize.",
        11: "Saturn in the house of gains filters your social circle. Fair-weather friends disappear, but the ones who remain are allies for life. Financial gains come slowly but reliably through sustained effort.",
        12: "Saturn in the twelfth house intensifies solitude and spiritual reckoning. Hidden fears surface, and sleep may be disrupted. This is the final exam before a new cycle — face what remains unfaced.",
    ]

    // MARK: - Fallback Minimal Library
    //
    // Ship insurance: if `horoscope_library.json` is missing or corrupt, this
    // keeps the engine producing valid (if minimal) readings. It is NOT meant
    // as product content — 3 themes per house + 1 category entry per slot.

    private static let fallbackMinimal: HoroscopeLibraryData = {
        let neutralTheme = HouseThemeEntry(
            themeStatement: "A steady, grounded day awaits.",
            supportingText: "Honor what is in front of you with presence. Small actions, done with care, matter more than you know.",
            doList: ["Be kind to yourself", "Move your body gently", "Pause before reacting"],
            dontList: ["Force outcomes", "Ignore your needs", "Compare yourself to others"]
        )

        let neutralReading = CategoryReadingEntry(
            summary: "A day of steady progress. Stay mindful and present.",
            intensity: 3
        )

        var houseThemes: [String: [HouseThemeEntry]] = [:]
        var categoryReadings: [String: CategoryReadingBucket] = [:]

        for house in 1...12 {
            houseThemes[String(house)] = [neutralTheme]
            categoryReadings[String(house)] = CategoryReadingBucket(
                love: [neutralReading],
                work: [neutralReading],
                spirituality: [neutralReading],
                health: [neutralReading]
            )
        }

        return HoroscopeLibraryData(
            version: 0,
            generatedAt: "fallback",
            model: "minimal",
            houseThemes: houseThemes,
            categoryReadings: categoryReadings
        )
    }()
}

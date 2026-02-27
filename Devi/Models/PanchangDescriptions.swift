import Foundation

// MARK: - Models/PanchangDescriptions.swift
// Static educational content for all panchang elements — real Vedic descriptions
// This file provides authentic Hindu/Vedic information for educational purposes.

// MARK: - Info Structs

struct TithiInfo {
    let name: String
    let meaning: String
    let description: String
    let rulingDeity: String
    let significance: String
    let auspiciousActivities: [String]
}

struct NakshatraInfo {
    let name: String
    let meaning: String
    let rulingPlanet: String
    let presidingDeity: String
    let symbol: String
    let quality: String
    let auspiciousActivities: [String]
    let description: String
}

struct YogaInfo {
    let name: String
    let meaning: String
    let quality: String
    let description: String
}

struct KaranaInfo {
    let name: String
    let type: String
    let description: String
    let suitability: String
}

struct VaraInfo {
    let weekday: String
    let deity: String
    let planet: String
    let description: String
    let auspiciousActivities: [String]
    let associatedColor: String
}

struct TimeWindowInfo {
    let name: String
    let meaning: String
    let origin: String
    let recommendation: String
    let description: String
}

struct EclipseInfo {
    let description: String
    let mythology: String
    let spiritualSignificance: String
    let dosAndDonts: (doItems: [String], dontItems: [String])
    let mantras: [(devanagari: String, transliteration: String, purpose: String)]
}

// MARK: - PanchangDescriptions Namespace

enum PanchangDescriptions {

    // MARK: - Tithis (15 Lunar Days)

    static let tithis: [String: TithiInfo] = [
        "Pratipada": TithiInfo(
            name: "Pratipada",
            meaning: "The First",
            description: "Pratipada is the first tithi of each lunar fortnight, marking the beginning of a new cycle. It represents initiation and fresh starts. The energy of this tithi supports laying foundations for new ventures.",
            rulingDeity: "Agni (Fire God)",
            significance: "Pratipada signifies new beginnings and the spark of creation. In the Shukla Paksha, it follows Amavasya and heralds the waxing moon; in Krishna Paksha, it follows Purnima and begins the waning phase.",
            auspiciousActivities: [
                "Starting new ventures",
                "Laying foundations",
                "Beginning spiritual practices",
                "Performing havan or fire rituals",
                "Initiating journeys"
            ]
        ),
        "Dwitiya": TithiInfo(
            name: "Dwitiya",
            meaning: "The Second",
            description: "Dwitiya is the second tithi, governed by Brahma the Creator. It carries creative and nurturing energy, making it favorable for constructive activities. This tithi is associated with growth and expansion.",
            rulingDeity: "Brahma (The Creator)",
            significance: "Dwitiya is considered highly auspicious for laying the groundwork of lasting endeavors. The creative energy of Brahma blesses activities that require sustained effort and building.",
            auspiciousActivities: [
                "House construction or foundation laying",
                "Travel and journeys",
                "Marriage ceremonies",
                "Starting education",
                "Creative projects"
            ]
        ),
        "Tritiya": TithiInfo(
            name: "Tritiya",
            meaning: "The Third",
            description: "Tritiya is the third tithi, ruled by Gauri (Parvati). It is a highly auspicious day associated with beauty, prosperity, and marital happiness. Akshaya Tritiya, which falls on this tithi in Vaishakha month, is one of the most sacred days.",
            rulingDeity: "Gauri (Parvati)",
            significance: "Tritiya is one of the most favorable tithis in the Hindu calendar. The blessings of Goddess Gauri bring abundance, beauty, and auspiciousness. Akshaya Tritiya on this day is believed to bring imperishable merit.",
            auspiciousActivities: [
                "Marriage and engagement ceremonies",
                "Purchasing gold and jewelry",
                "Starting new businesses",
                "Performing charitable acts",
                "Sowing seeds and agriculture"
            ]
        ),
        "Chaturthi": TithiInfo(
            name: "Chaturthi",
            meaning: "The Fourth",
            description: "Chaturthi is the fourth tithi, sacred to Lord Ganesh, the remover of obstacles. Vinayaka Chaturthi and Sankashti Chaturthi are observed on this day. It carries both creative and destructive energy depending on the paksha.",
            rulingDeity: "Ganesh (Remover of Obstacles)",
            significance: "Chaturthi holds special importance for Ganesh worship. Shukla Chaturthi is generally auspicious, while Krishna Chaturthi (Sankashti) is observed with fasting for removing obstacles. This tithi is considered Rikta (empty) and requires care in choosing activities.",
            auspiciousActivities: [
                "Ganesh puja and worship",
                "Removing obstacles from projects",
                "Sankashti Chaturthi vrata",
                "Seeking blessings for new endeavors",
                "Overcoming difficulties"
            ]
        ),
        "Panchami": TithiInfo(
            name: "Panchami",
            meaning: "The Fifth",
            description: "Panchami is the fifth tithi, ruled by the Nagas (serpent deities). It is associated with wisdom, learning, and creative expression. Vasant Panchami, celebrating Goddess Saraswati, falls on this tithi.",
            rulingDeity: "Nagas (Serpent Deities)",
            significance: "Panchami is a Purna (complete) tithi that supports intellectual and creative pursuits. Naga Panchami honors the serpent deities, while Vasant Panchami celebrates the goddess of learning. It is favorable for education and arts.",
            auspiciousActivities: [
                "Beginning education and studies",
                "Worship of Saraswati",
                "Naga Panchami observances",
                "Artistic and creative pursuits",
                "Installing deities and sacred objects"
            ]
        ),
        "Shashthi": TithiInfo(
            name: "Shashthi",
            meaning: "The Sixth",
            description: "Shashthi is the sixth tithi, governed by Kartikeya (Skanda/Murugan), the commander of the divine armies. It carries martial and protective energy. This tithi is especially important for child welfare.",
            rulingDeity: "Kartikeya (Skanda/Murugan)",
            significance: "Shashthi is sacred for the worship of Kartikeya and Shashthi Devi, the protector of children. Skanda Shashthi is a major festival in South India. This tithi supports activities requiring courage, discipline, and protection.",
            auspiciousActivities: [
                "Worship of Kartikeya/Murugan",
                "Prayers for children's welfare",
                "Skanda Shashthi vrata",
                "Military or competitive endeavors",
                "Seeking protection and courage"
            ]
        ),
        "Saptami": TithiInfo(
            name: "Saptami",
            meaning: "The Seventh",
            description: "Saptami is the seventh tithi, ruled by Surya (the Sun God). It radiates solar energy associated with vitality, health, and illumination. Ratha Saptami is an important festival celebrating the Sun.",
            rulingDeity: "Surya (Sun God)",
            significance: "Saptami carries the brilliant energy of the Sun, making it favorable for activities requiring leadership, visibility, and vitality. Ratha Saptami marks the Sun's chariot turning northward. This tithi blesses health-related activities.",
            auspiciousActivities: [
                "Surya puja and Surya Namaskar",
                "Travel and long journeys",
                "Government and official work",
                "Health-related activities",
                "Starting leadership roles"
            ]
        ),
        "Ashtami": TithiInfo(
            name: "Ashtami",
            meaning: "The Eighth",
            description: "Ashtami is the eighth tithi, ruled by Rudra (fierce form of Shiva). It carries intense transformative energy. Krishna Janmashtami, the birth of Lord Krishna, and Durga Ashtami during Navratri fall on this tithi.",
            rulingDeity: "Rudra (Shiva)",
            significance: "Ashtami is a powerful but intense tithi classified as Rikta (empty). While it is sacred for worship of Shiva and Devi, worldly activities should be undertaken with caution. Major festivals like Janmashtami and Durga Ashtami make specific Ashtamis highly sacred.",
            auspiciousActivities: [
                "Shiva and Devi worship",
                "Fasting and spiritual practices",
                "Tantra and intense sadhana",
                "Durga Ashtami celebrations",
                "Krishna Janmashtami observances"
            ]
        ),
        "Navami": TithiInfo(
            name: "Navami",
            meaning: "The Ninth",
            description: "Navami is the ninth tithi, ruled by Durga, the supreme goddess of power. It carries fierce protective energy. Ram Navami (birth of Lord Rama) and Maha Navami during Navratri are celebrated on this day.",
            rulingDeity: "Durga (The Invincible Goddess)",
            significance: "Navami embodies the protective and fierce energy of the Divine Mother. During Navratri, Maha Navami represents the culmination of Devi worship. Ram Navami celebrates the avatar of dharma. This tithi supports acts of courage and righteousness.",
            auspiciousActivities: [
                "Durga puja and Devi worship",
                "Ram Navami celebrations",
                "Acts of courage and righteousness",
                "Navratri observances",
                "Protective rituals and prayers"
            ]
        ),
        "Dashami": TithiInfo(
            name: "Dashami",
            meaning: "The Tenth",
            description: "Dashami is the tenth tithi, ruled by Yama, the lord of dharma and death. It represents the completion of a cycle and victory of righteousness. Vijayadashami (Dussehra) is the most celebrated Dashami.",
            rulingDeity: "Yama (Lord of Dharma)",
            significance: "Dashami carries the energy of victory and completion. Vijayadashami marks Rama's victory over Ravana and Durga's triumph over Mahishasura. It is considered one of the most auspicious days for beginning important endeavors.",
            auspiciousActivities: [
                "Vijayadashami celebrations",
                "Starting new learning (Vidyarambham)",
                "Beginning important ventures",
                "Victory celebrations",
                "Crossing boundaries and journeys"
            ]
        ),
        "Ekadashi": TithiInfo(
            name: "Ekadashi",
            meaning: "The Eleventh",
            description: "Ekadashi is the eleventh tithi, sacred to Lord Vishnu. It is one of the most important days for fasting and spiritual practice in Hinduism. There are 24 Ekadashis in a year, each with a unique name and significance.",
            rulingDeity: "Vishnu (The Preserver)",
            significance: "Ekadashi is considered the most spiritually potent tithi for devotion and self-purification. Fasting on Ekadashi is believed to cleanse sins and bring one closer to Vishnu. Major Ekadashis include Nirjala, Devshayani, and Prabodhini.",
            auspiciousActivities: [
                "Fasting (Ekadashi Vrata)",
                "Vishnu puja and chanting",
                "Reading Vishnu Sahasranama",
                "Meditation and spiritual practice",
                "Charity and feeding the needy"
            ]
        ),
        "Dwadashi": TithiInfo(
            name: "Dwadashi",
            meaning: "The Twelfth",
            description: "Dwadashi is the twelfth tithi, ruled by Vishnu. It is the day for breaking the Ekadashi fast (parana). Dwadashi holds significance for Vaishnava traditions and is considered favorable for sacred rituals.",
            rulingDeity: "Vishnu (The Preserver)",
            significance: "Dwadashi completes the spiritual cycle begun on Ekadashi. The parana (breaking of fast) must be done during the correct window on Dwadashi. This tithi supports devotional activities and is considered auspicious for Vishnu worship.",
            auspiciousActivities: [
                "Breaking Ekadashi fast (Parana)",
                "Vishnu worship and devotion",
                "Charitable giving (Dana)",
                "Sacred rituals and ceremonies",
                "Feeding Brahmins and the needy"
            ]
        ),
        "Trayodashi": TithiInfo(
            name: "Trayodashi",
            meaning: "The Thirteenth",
            description: "Trayodashi is the thirteenth tithi, ruled by Kamadeva (god of love) and also associated with Shiva. Pradosh Vrata observed on this tithi is highly auspicious for Shiva worship. Dhanteras falls on Krishna Trayodashi of Kartik month.",
            rulingDeity: "Kamadeva (God of Love) / Shiva",
            significance: "Trayodashi is a Jaya (victorious) tithi that brings success and auspiciousness. Pradosh Kaal on Trayodashi is one of the most powerful times for Shiva worship. Dhanteras marks the beginning of Diwali festivities.",
            auspiciousActivities: [
                "Pradosh Vrata for Lord Shiva",
                "Dhanteras celebrations and purchases",
                "Worship during Pradosh Kaal",
                "Purchasing precious metals",
                "Romantic and marital celebrations"
            ]
        ),
        "Chaturdashi": TithiInfo(
            name: "Chaturdashi",
            meaning: "The Fourteenth",
            description: "Chaturdashi is the fourteenth tithi, ruled by Shiva. It is the penultimate day of each lunar fortnight. Maha Shivaratri falls on Krishna Chaturdashi of Magha/Phalguna month and is the holiest night for Shiva devotees.",
            rulingDeity: "Shiva (The Transformer)",
            significance: "Chaturdashi carries the intense transformative energy of Shiva. Maha Shivaratri is the 'Great Night of Shiva' when devotees observe all-night vigils. Narak Chaturdashi (Choti Diwali) is celebrated the day before Diwali.",
            auspiciousActivities: [
                "Maha Shivaratri observances",
                "All-night Shiva worship",
                "Fasting and meditation",
                "Narak Chaturdashi rituals",
                "Spiritual transformation practices"
            ]
        ),
        "Purnima": TithiInfo(
            name: "Purnima",
            meaning: "Full Moon",
            description: "Purnima is the fifteenth and final tithi of the Shukla Paksha (bright fortnight), when the moon is fully illuminated. It is one of the most auspicious days in the Hindu calendar, associated with completion, abundance, and spiritual fullness.",
            rulingDeity: "Chandra (Moon God) / Satya Narayana",
            significance: "Purnima represents fullness and the peak of lunar energy. Major festivals like Guru Purnima, Sharad Purnima, Kartik Purnima, and Holi fall on Purnima. Satyanarayan Puja is traditionally performed on this day.",
            auspiciousActivities: [
                "Satyanarayan Puja",
                "Guru worship (Guru Purnima)",
                "Full moon fasting",
                "Charity and donations",
                "Sacred bathing in rivers"
            ]
        ),
        "Amavasya": TithiInfo(
            name: "Amavasya",
            meaning: "New Moon",
            description: "Amavasya is the fifteenth and final tithi of the Krishna Paksha (dark fortnight), when the moon is not visible. It is a powerful day for ancestral rites and introspection. Diwali is celebrated on Kartik Amavasya.",
            rulingDeity: "Pitru Devatas (Ancestral Deities)",
            significance: "Amavasya is deeply connected to the ancestors (Pitrus). Tarpanam and Shraddha rituals for departed souls are most effective on this day. While generally considered inauspicious for worldly activities, Diwali Amavasya is a major exception and is celebrated with great joy.",
            auspiciousActivities: [
                "Pitru Tarpanam (ancestral offerings)",
                "Shraddha rituals",
                "Diwali celebrations (Kartik Amavasya)",
                "Meditation and introspection",
                "Visiting sacred rivers for holy bath"
            ]
        )
    ]

    // MARK: - Nakshatras (27 Lunar Mansions)

    static let nakshatras: [String: NakshatraInfo] = [
        "Ashwini": NakshatraInfo(
            name: "Ashwini",
            meaning: "Born of a Female Horse",
            rulingPlanet: "Ketu",
            presidingDeity: "Ashwini Kumaras (Divine Twin Physicians)",
            symbol: "Horse's Head",
            quality: "Deva (Divine) / Laghu (Light)",
            auspiciousActivities: ["Healing and medicine", "Beginning travel", "Learning new skills", "Wearing new clothes", "Vehicle-related activities"],
            description: "Ashwini is the first nakshatra, spanning 0° to 13°20' Aries. Governed by the Ashwini Kumaras, the celestial healers, it embodies speed, healing, and fresh beginnings. People born under this star are quick, energetic, and drawn to healing arts."
        ),
        "Bharani": NakshatraInfo(
            name: "Bharani",
            meaning: "She Who Bears",
            rulingPlanet: "Venus",
            presidingDeity: "Yama (Lord of Death and Dharma)",
            symbol: "Yoni (Female Reproductive Organ)",
            quality: "Manushya (Human) / Ugra (Fierce)",
            auspiciousActivities: ["Agriculture and planting", "Acts requiring endurance", "Creative arts", "Resolving difficult matters", "Fertility rituals"],
            description: "Bharani spans 13°20' to 26°40' Aries. Ruled by Yama, it represents the cycle of birth, death, and transformation. It carries intense creative and restraining energy. Those born here are resilient, responsible, and possess deep inner strength."
        ),
        "Krittika": NakshatraInfo(
            name: "Krittika",
            meaning: "The Cutters",
            rulingPlanet: "Sun",
            presidingDeity: "Agni (Fire God)",
            symbol: "Razor / Flame",
            quality: "Rakshasa (Demonic) / Mishra (Mixed)",
            auspiciousActivities: ["Fire rituals (havan/homa)", "Cooking and food preparation", "Purification ceremonies", "Acts requiring sharpness and precision", "Military activities"],
            description: "Krittika spans 26°40' Aries to 10° Taurus. Named after the six Krittika sisters (Pleiades) who nursed Kartikeya, it is ruled by Agni. It bestows sharp intellect, purifying energy, and the ability to cut through illusion. This nakshatra burns away impurities."
        ),
        "Rohini": NakshatraInfo(
            name: "Rohini",
            meaning: "The Red One / The Growing One",
            rulingPlanet: "Moon",
            presidingDeity: "Brahma (The Creator)",
            symbol: "Chariot / Ox Cart",
            quality: "Manushya (Human) / Dhruva (Fixed)",
            auspiciousActivities: ["Marriage ceremonies", "Agriculture and planting", "Purchasing property", "Beauty treatments", "Business ventures"],
            description: "Rohini spans 10° to 23°20' Taurus. It is considered the Moon's favorite nakshatra and the birth star of Lord Krishna. Ruled by Brahma, it represents fertility, beauty, and material abundance. It is one of the most auspicious nakshatras for worldly success."
        ),
        "Mrigashira": NakshatraInfo(
            name: "Mrigashira",
            meaning: "Deer's Head",
            rulingPlanet: "Mars",
            presidingDeity: "Soma (Moon God / Sacred Plant)",
            symbol: "Deer's Head",
            quality: "Deva (Divine) / Mridu (Gentle)",
            auspiciousActivities: ["Travel and exploration", "Learning and research", "Making garments", "Romantic pursuits", "Artistic activities"],
            description: "Mrigashira spans 23°20' Taurus to 6°40' Gemini. Associated with the searching nature of a deer, it represents curiosity, seeking, and gentle exploration. Soma's influence brings a love of beauty and the quest for the divine nectar of experience."
        ),
        "Ardra": NakshatraInfo(
            name: "Ardra",
            meaning: "The Moist One / The Green One",
            rulingPlanet: "Rahu",
            presidingDeity: "Rudra (Storm Form of Shiva)",
            symbol: "Teardrop / Diamond",
            quality: "Manushya (Human) / Tikshna (Sharp)",
            auspiciousActivities: ["Research and analysis", "Destruction of obstacles", "Electrical and technology work", "Dealing with poisons or medicines", "Activities requiring mental sharpness"],
            description: "Ardra spans 6°40' to 20° Gemini. Ruled by Rudra, the fierce howler, it represents storms of transformation, intellectual power, and the tears that precede renewal. This nakshatra brings sharp analytical ability and the capacity for deep research."
        ),
        "Punarvasu": NakshatraInfo(
            name: "Punarvasu",
            meaning: "Return of the Light / Restoration of Goods",
            rulingPlanet: "Jupiter",
            presidingDeity: "Aditi (Mother of the Gods)",
            symbol: "Bow and Quiver of Arrows",
            quality: "Deva (Divine) / Chara (Movable)",
            auspiciousActivities: ["Returning home", "Renewal and restoration", "Spiritual practices", "Starting education", "Laying foundations"],
            description: "Punarvasu spans 20° Gemini to 3°20' Cancer. Birth star of Lord Rama, it is ruled by Aditi, the cosmic mother of boundless freedom. It represents renewal, return to goodness, and the restoration of what was lost. It carries deeply nurturing and optimistic energy."
        ),
        "Pushya": NakshatraInfo(
            name: "Pushya",
            meaning: "Nourisher / The Flower",
            rulingPlanet: "Saturn",
            presidingDeity: "Brihaspati (Jupiter, Guru of the Devas)",
            symbol: "Cow's Udder / Lotus / Circle",
            quality: "Deva (Divine) / Laghu (Light)",
            auspiciousActivities: ["Nearly all auspicious activities", "Business ventures", "Spiritual initiation", "Coronation and assuming authority", "Purchasing valuables"],
            description: "Pushya spans 3°20' to 16°40' Cancer. Widely regarded as the most auspicious of all 27 nakshatras, it is ruled by Brihaspati. It nourishes, supports, and expands everything it touches. The energy of Pushya is profoundly benevolent and spiritually uplifting."
        ),
        "Ashlesha": NakshatraInfo(
            name: "Ashlesha",
            meaning: "The Entwiner / The Clinging Star",
            rulingPlanet: "Mercury",
            presidingDeity: "Sarpa (Serpent Deities / Nagas)",
            symbol: "Coiled Serpent",
            quality: "Rakshasa (Demonic) / Tikshna (Sharp)",
            auspiciousActivities: ["Kundalini practices", "Filing legal actions", "Political maneuvering", "Administering medicines", "Research into hidden matters"],
            description: "Ashlesha spans 16°40' to 30° Cancer. Ruled by the Nagas (serpent deities), it represents the mystical kundalini energy, hypnotic power, and deep insight. This nakshatra grants penetrating wisdom but requires careful handling of its intense, serpentine energy."
        ),
        "Magha": NakshatraInfo(
            name: "Magha",
            meaning: "The Mighty One / The Great",
            rulingPlanet: "Ketu",
            presidingDeity: "Pitrus (Ancestral Spirits)",
            symbol: "Royal Throne / Palanquin",
            quality: "Rakshasa (Demonic) / Ugra (Fierce)",
            auspiciousActivities: ["Ancestral rites (Shraddha)", "Government affairs", "Grand ceremonies", "Honoring elders and traditions", "Assuming positions of authority"],
            description: "Magha spans 0° to 13°20' Leo. Ruled by the Pitrus (ancestors), it represents royal lineage, authority, and the power of heritage. Those born under Magha carry a regal bearing and deep connection to tradition. It is highly important for ancestral ceremonies."
        ),
        "Purva Phalguni": NakshatraInfo(
            name: "Purva Phalguni",
            meaning: "The Former Reddish One",
            rulingPlanet: "Venus",
            presidingDeity: "Bhaga (God of Marital Bliss and Prosperity)",
            symbol: "Front Legs of a Bed / Hammock / Fig Tree",
            quality: "Manushya (Human) / Ugra (Fierce)",
            auspiciousActivities: ["Marriage and romance", "Rest and relaxation", "Creative arts and music", "Celebrations and festivities", "Purchasing luxury items"],
            description: "Purva Phalguni spans 13°20' to 26°40' Leo. Ruled by Bhaga, the god of delight and marital happiness, it represents love, pleasure, creativity, and the enjoyment of life. This nakshatra brings warmth, generosity, and a love of beauty and comfort."
        ),
        "Uttara Phalguni": NakshatraInfo(
            name: "Uttara Phalguni",
            meaning: "The Latter Reddish One",
            rulingPlanet: "Sun",
            presidingDeity: "Aryaman (God of Patronage and Friendship)",
            symbol: "Back Legs of a Bed / Fig Tree",
            quality: "Manushya (Human) / Dhruva (Fixed)",
            auspiciousActivities: ["Marriage (one of the best nakshatras)", "Entering a new home", "Forming partnerships", "Making agreements and contracts", "Leadership activities"],
            description: "Uttara Phalguni spans 26°40' Leo to 10° Virgo. Ruled by Aryaman, god of sacred contracts and friendship, it represents commitment, partnership, and social responsibility. It is considered one of the most auspicious nakshatras for marriage and lasting unions."
        ),
        "Hasta": NakshatraInfo(
            name: "Hasta",
            meaning: "The Hand",
            rulingPlanet: "Moon",
            presidingDeity: "Savitar (Sun God of Inspiration / Creative Solar Force)",
            symbol: "Open Hand / Palm / Fist",
            quality: "Deva (Divine) / Laghu (Light)",
            auspiciousActivities: ["Craftsmanship and handiwork", "Healing and therapy", "Trade and commerce", "Learning skills", "Beginning new ventures"],
            description: "Hasta spans 10° to 23°20' Virgo. Ruled by Savitar, the inspiring solar deity, it represents skill, dexterity, and creative craftsmanship. The symbol of the open hand signifies giving, receiving, and the power of manifestation through effort."
        ),
        "Chitra": NakshatraInfo(
            name: "Chitra",
            meaning: "The Brilliant / The Beautiful",
            rulingPlanet: "Mars",
            presidingDeity: "Tvashtar (Vishwakarma, Divine Architect)",
            symbol: "Bright Jewel / Pearl",
            quality: "Rakshasa (Demonic) / Mridu (Gentle)",
            auspiciousActivities: ["Creating art and design", "Architecture and construction", "Wearing new clothes and jewelry", "Decorating", "Technological innovation"],
            description: "Chitra spans 23°20' Virgo to 6°40' Libra. Ruled by Tvashtar, the celestial architect, it represents brilliance, beauty, and artistic creation. The star Spica (Chitra) is one of the brightest in the sky. This nakshatra grants aesthetic vision and creative mastery."
        ),
        "Swati": NakshatraInfo(
            name: "Swati",
            meaning: "The Independent One / The Sword",
            rulingPlanet: "Rahu",
            presidingDeity: "Vayu (Wind God)",
            symbol: "Young Plant Shoot Blown by the Wind / Coral",
            quality: "Deva (Divine) / Chara (Movable)",
            auspiciousActivities: ["Trade and business", "Travel", "Learning new subjects", "Purchasing vehicles", "Activities requiring flexibility"],
            description: "Swati spans 6°40' to 20° Libra. Ruled by Vayu, the wind god, it represents independence, flexibility, and the ability to adapt. Like a young plant bending in the wind without breaking, Swati natives are resilient and self-reliant. It favors business and trade."
        ),
        "Vishakha": NakshatraInfo(
            name: "Vishakha",
            meaning: "The Forked / The Two-Branched",
            rulingPlanet: "Jupiter",
            presidingDeity: "Indra (King of Gods) and Agni (Fire God)",
            symbol: "Triumphal Archway / Potter's Wheel",
            quality: "Rakshasa (Demonic) / Mishra (Mixed)",
            auspiciousActivities: ["Goal-oriented activities", "Religious ceremonies", "Competitive endeavors", "Agriculture", "Activities requiring determination"],
            description: "Vishakha spans 20° Libra to 3°20' Scorpio. Ruled jointly by Indra and Agni, it represents single-minded determination, the triumph of focused effort, and the energy to achieve one's goals. Vishakha natives are determined, purposeful, and capable of great achievement."
        ),
        "Anuradha": NakshatraInfo(
            name: "Anuradha",
            meaning: "Following Radha / Subsequent Success",
            rulingPlanet: "Saturn",
            presidingDeity: "Mitra (God of Friendship and Partnership)",
            symbol: "Lotus / Triumphal Archway",
            quality: "Deva (Divine) / Mridu (Gentle)",
            auspiciousActivities: ["Building friendships and alliances", "Organizational activities", "Travel to foreign lands", "Spiritual practice", "Cooperative ventures"],
            description: "Anuradha spans 3°20' to 16°40' Scorpio. Ruled by Mitra, god of friendship, it represents devotion, friendship, and the ability to succeed in foreign lands. Despite being in the intense sign of Scorpio, Anuradha brings warmth and the lotus's ability to bloom in muddy waters."
        ),
        "Jyeshtha": NakshatraInfo(
            name: "Jyeshtha",
            meaning: "The Eldest / The Chief",
            rulingPlanet: "Mercury",
            presidingDeity: "Indra (King of the Gods)",
            symbol: "Circular Talisman / Earring / Umbrella",
            quality: "Rakshasa (Demonic) / Tikshna (Sharp)",
            auspiciousActivities: ["Taking charge and leadership", "Protective activities", "Overcoming enemies", "Administrative duties", "Occult studies"],
            description: "Jyeshtha spans 16°40' to 30° Scorpio. Ruled by Indra, the king of gods, it represents seniority, authority, and protective power. Jyeshtha is the star of the chief — those who must bear responsibility and protect others. It confers leadership and occult knowledge."
        ),
        "Mula": NakshatraInfo(
            name: "Mula",
            meaning: "The Root",
            rulingPlanet: "Ketu",
            presidingDeity: "Nirriti (Goddess of Dissolution / Alakshmi)",
            symbol: "Bunch of Roots / Tied Bundle / Elephant Goad",
            quality: "Rakshasa (Demonic) / Tikshna (Sharp)",
            auspiciousActivities: ["Researching root causes", "Ayurvedic medicine", "Planting and agriculture", "Spiritual investigation", "Destroying what is no longer needed"],
            description: "Mula spans 0° to 13°20' Sagittarius. Ruled by Nirriti, goddess of calamity and dissolution, it represents getting to the root of things, destruction of the old, and profound transformation. Mula natives are investigators and seekers who dig beneath surfaces to find fundamental truths."
        ),
        "Purva Ashadha": NakshatraInfo(
            name: "Purva Ashadha",
            meaning: "The Former Invincible One",
            rulingPlanet: "Venus",
            presidingDeity: "Apas (Water Deity / Cosmic Waters)",
            symbol: "Elephant Tusk / Fan / Winnowing Basket",
            quality: "Manushya (Human) / Ugra (Fierce)",
            auspiciousActivities: ["Initiating campaigns", "Water-related activities", "Purification ceremonies", "Declarations and proclamations", "Confronting opposition"],
            description: "Purva Ashadha spans 13°20' to 26°40' Sagittarius. Ruled by Apas (waters), it represents invincibility, purification, and the power of declaration. Like water that cannot be held back, this nakshatra grants the energy to overcome all obstacles and achieve victory."
        ),
        "Uttara Ashadha": NakshatraInfo(
            name: "Uttara Ashadha",
            meaning: "The Latter Invincible One",
            rulingPlanet: "Sun",
            presidingDeity: "Vishvedevas (Universal Gods / Ten Principles)",
            symbol: "Elephant Tusk / Small Bed",
            quality: "Manushya (Human) / Dhruva (Fixed)",
            auspiciousActivities: ["Permanent undertakings", "Government work", "Making lasting commitments", "Assuming authority", "Foundation ceremonies"],
            description: "Uttara Ashadha spans 26°40' Sagittarius to 10° Capricorn. Ruled by the Vishvedevas (universal gods representing truth, willpower, time, and other cosmic principles), it represents final and lasting victory. It is known as the 'universal star' — what is achieved here endures."
        ),
        "Shravana": NakshatraInfo(
            name: "Shravana",
            meaning: "Hearing / Listening",
            rulingPlanet: "Moon",
            presidingDeity: "Vishnu (The Preserver)",
            symbol: "Three Footprints / Ear / Trident",
            quality: "Deva (Divine) / Chara (Movable)",
            auspiciousActivities: ["Learning and studying", "Listening to sacred texts", "Music and sound-related activities", "Religious functions", "Travel"],
            description: "Shravana spans 10° to 23°20' Capricorn. Sacred to Vishnu, it represents the power of listening, learning, and connecting through knowledge. The three footprints symbolize Vishnu's cosmic strides (Vamana avatar). This nakshatra is deeply connected to Vedic learning and sacred sound."
        ),
        "Dhanishta": NakshatraInfo(
            name: "Dhanishta",
            meaning: "The Wealthiest / The Star of Symphony",
            rulingPlanet: "Mars",
            presidingDeity: "Ashtavasus (Eight Vasus — Elemental Gods)",
            symbol: "Drum (Mridanga) / Flute",
            quality: "Rakshasa (Demonic) / Chara (Movable)",
            auspiciousActivities: ["Music and performance", "Real estate and property", "Activities requiring rhythm and timing", "Moving into new homes", "Group activities"],
            description: "Dhanishta spans 23°20' Capricorn to 6°40' Aquarius. Ruled by the eight Vasus (elemental gods of earth, water, fire, air, space, moon, sun, and stars), it represents abundance, musical talent, and material prosperity. It is known as the star of symphony for its connection to rhythm and music."
        ),
        "Shatabhisha": NakshatraInfo(
            name: "Shatabhisha",
            meaning: "Hundred Physicians / Hundred Medicines",
            rulingPlanet: "Rahu",
            presidingDeity: "Varuna (God of Cosmic Waters and Law)",
            symbol: "Empty Circle / Thousand Flowers",
            quality: "Rakshasa (Demonic) / Chara (Movable)",
            auspiciousActivities: ["Healing and medicine", "Aquatic activities", "Research and investigation", "Technology and innovation", "Meditation and isolation"],
            description: "Shatabhisha spans 6°40' to 20° Aquarius. Ruled by Varuna, lord of the cosmic ocean and divine law, it represents healing, mysticism, and the veiling/unveiling of truth. Its symbol of the empty circle represents the void, wholeness, and the cosmos. It grants healing abilities and a penetrating mind."
        ),
        "Purva Bhadrapada": NakshatraInfo(
            name: "Purva Bhadrapada",
            meaning: "The Former Lucky Feet",
            rulingPlanet: "Jupiter",
            presidingDeity: "Aja Ekapada (One-footed Unborn One — Form of Shiva/Rudra)",
            symbol: "Front Legs of a Funeral Cot / Two-Faced Man / Sword",
            quality: "Manushya (Human) / Ugra (Fierce)",
            auspiciousActivities: ["Intense spiritual practices", "Penance and austerity", "Mechanical and industrial work", "Funerary rites", "Resolving dangerous situations"],
            description: "Purva Bhadrapada spans 20° Aquarius to 3°20' Pisces. Ruled by Aja Ekapada, a fierce one-footed form of Rudra, it represents the scorching transformative fire that precedes spiritual rebirth. This nakshatra carries immense mystical and occult power."
        ),
        "Uttara Bhadrapada": NakshatraInfo(
            name: "Uttara Bhadrapada",
            meaning: "The Latter Lucky Feet",
            rulingPlanet: "Saturn",
            presidingDeity: "Ahir Budhnya (Serpent of the Deep — Kundalini Shakti)",
            symbol: "Back Legs of a Funeral Cot / Two-Faced Man / Twins",
            quality: "Manushya (Human) / Dhruva (Fixed)",
            auspiciousActivities: ["Deep meditation", "Charitable activities", "Marriage", "Settling disputes", "Long-term commitments"],
            description: "Uttara Bhadrapada spans 3°20' to 16°40' Pisces. Ruled by Ahir Budhnya, the serpent of the cosmic depths, it represents deep wisdom, spiritual discipline, and the controlled fire of kundalini. It brings the calm after the storm of Purva Bhadrapada — depth, patience, and transcendence."
        ),
        "Revati": NakshatraInfo(
            name: "Revati",
            meaning: "The Wealthy / The Nourishing",
            rulingPlanet: "Mercury",
            presidingDeity: "Pushan (Nourisher, Protector of Flocks and Journeys)",
            symbol: "Fish / Drum",
            quality: "Deva (Divine) / Mridu (Gentle)",
            auspiciousActivities: ["Completing journeys", "Buying and selling", "Healing and nourishment", "Creative and artistic work", "Beginning spiritual pilgrimages"],
            description: "Revati spans 16°40' to 30° Pisces, the final nakshatra of the zodiac. Ruled by Pushan, the divine shepherd and nourisher, it represents safe travel, nourishment, and the completion of the cosmic cycle. As the last star, Revati holds the compassion and wisdom of the entire journey through all 27 nakshatras."
        )
    ]

    // MARK: - Yogas (27 Sun-Moon Combinations)

    static let yogas: [Int: YogaInfo] = [
        1: YogaInfo(
            name: "Vishkumbha",
            meaning: "Poison Pot / Supported",
            quality: "Inauspicious",
            description: "Vishkumbha is the first yoga, considered generally inauspicious. It can create obstacles and suppression. However, those born in this yoga may possess great power to overcome adversity. Avoid starting important ventures during this period."
        ),
        2: YogaInfo(
            name: "Priti",
            meaning: "Love / Delight",
            quality: "Auspicious",
            description: "Priti yoga brings love, affection, and joy. It is highly favorable for romantic endeavors, forming friendships, and any activity that benefits from warmth and goodwill. One of the most pleasant yogas for social activities and celebrations."
        ),
        3: YogaInfo(
            name: "Ayushman",
            meaning: "Long-lived / Vitality",
            quality: "Auspicious",
            description: "Ayushman yoga blesses with good health, longevity, and vitality. Excellent for health-related activities, beginning medical treatments, starting exercise routines, and any activity where sustained energy is needed."
        ),
        4: YogaInfo(
            name: "Saubhagya",
            meaning: "Good Fortune",
            quality: "Auspicious",
            description: "Saubhagya yoga bestows exceptional good fortune and prosperity. It is one of the most favorable yogas for marriage, business ventures, purchasing property, and any activity where luck and prosperity are desired."
        ),
        5: YogaInfo(
            name: "Shobhana",
            meaning: "Splendor / Beauty",
            quality: "Auspicious",
            description: "Shobhana yoga radiates beauty, elegance, and artistic inspiration. Favorable for creative pursuits, aesthetic endeavors, purchasing jewelry or clothing, and any activity related to beauty, art, or cultural expression."
        ),
        6: YogaInfo(
            name: "Atiganda",
            meaning: "Great Obstacle / Danger",
            quality: "Inauspicious",
            description: "Atiganda yoga brings obstacles and potential danger. It is advisable to avoid starting new ventures, traveling, or making major decisions during this period. A time for caution and restraint. However, it can be useful for overcoming existing barriers."
        ),
        7: YogaInfo(
            name: "Sukarma",
            meaning: "Good Deeds / Virtuous Action",
            quality: "Auspicious",
            description: "Sukarma yoga supports righteous action and good deeds. It is excellent for charitable activities, religious ceremonies, performing one's duties, and any action motivated by virtue. Results of good actions performed during this yoga are amplified."
        ),
        8: YogaInfo(
            name: "Dhriti",
            meaning: "Firmness / Determination",
            quality: "Auspicious",
            description: "Dhriti yoga brings steadfastness, patience, and determination. It supports activities requiring persistence and commitment — long-term projects, making vows, and undertakings that need sustained effort. It strengthens resolve."
        ),
        9: YogaInfo(
            name: "Shula",
            meaning: "Spear / Sharp Pain",
            quality: "Inauspicious",
            description: "Shula yoga can bring sharp difficulties, conflicts, or piercing problems. It is associated with Shiva's trident and carries destructive energy. Avoid initiating important activities. However, it can support activities requiring sharpness and penetration."
        ),
        10: YogaInfo(
            name: "Ganda",
            meaning: "Knot / Obstacle",
            quality: "Inauspicious",
            description: "Ganda yoga creates knots and complications. Plans may become entangled, and obstacles may arise unexpectedly. It is advisable to avoid starting new endeavors. A time for patience and untangling existing problems rather than creating new ventures."
        ),
        11: YogaInfo(
            name: "Vriddhi",
            meaning: "Growth / Increase",
            quality: "Auspicious",
            description: "Vriddhi yoga promotes growth, expansion, and increase in all areas. Excellent for financial investments, starting businesses, expanding operations, and any activity where growth is desired. It enhances prosperity and material success."
        ),
        12: YogaInfo(
            name: "Dhruva",
            meaning: "Fixed / Constant / Pole Star",
            quality: "Auspicious",
            description: "Dhruva yoga, named after the steadfast Pole Star (Dhruva), brings stability and permanence. Ideal for laying foundations, making long-term commitments, constructing buildings, and any activity whose results should endure over time."
        ),
        13: YogaInfo(
            name: "Vyaghata",
            meaning: "Slaughter / Obstruction",
            quality: "Inauspicious",
            description: "Vyaghata yoga brings destruction and obstruction. It is considered one of the more difficult yogas. Avoid important beginnings and major decisions. However, it can be channeled for destroying negative habits or ending harmful situations."
        ),
        14: YogaInfo(
            name: "Harshana",
            meaning: "Joy / Thrilling",
            quality: "Auspicious",
            description: "Harshana yoga fills the atmosphere with joy, excitement, and enthusiasm. Excellent for celebrations, festivities, creative performances, and any activity meant to bring happiness. Social gatherings and reunions are especially favored."
        ),
        15: YogaInfo(
            name: "Vajra",
            meaning: "Thunderbolt / Diamond",
            quality: "Mixed",
            description: "Vajra yoga carries the power of Indra's thunderbolt — immense strength that can be both constructive and destructive. It supports activities requiring great force, courage, and decisive action. Strong for military matters but unpredictable for gentle activities."
        ),
        16: YogaInfo(
            name: "Siddhi",
            meaning: "Accomplishment / Supernatural Power",
            quality: "Auspicious",
            description: "Siddhi yoga bestows success and the fulfillment of goals. One of the most favorable yogas for completing projects, achieving objectives, and realizing ambitions. Spiritual practices performed during Siddhi yoga yield powerful results."
        ),
        17: YogaInfo(
            name: "Vyatipata",
            meaning: "Calamity / Great Fall",
            quality: "Inauspicious",
            description: "Vyatipata is considered one of the most inauspicious yogas, associated with calamity and misfortune. Avoid all major activities, especially travel and financial transactions. It is observed as a day for ancestral rites (Shraddha) in some traditions."
        ),
        18: YogaInfo(
            name: "Variyan",
            meaning: "Comfort / Ease",
            quality: "Auspicious",
            description: "Variyan yoga brings comfort, ease, and a sense of well-being. Favorable for rest, recuperation, leisure activities, and domestic matters. It supports healing, relaxation, and any activity that benefits from a peaceful and comfortable environment."
        ),
        19: YogaInfo(
            name: "Parigha",
            meaning: "Iron Bar / Obstruction",
            quality: "Inauspicious",
            description: "Parigha yoga creates barriers and restrictions, like an iron bar blocking the way. Plans may be frustrated and efforts obstructed. Avoid launching new projects or making major commitments. A time for patience and working within existing constraints."
        ),
        20: YogaInfo(
            name: "Shiva",
            meaning: "Auspicious / Lord Shiva",
            quality: "Auspicious",
            description: "Shiva yoga is deeply auspicious, carrying the blessings of Lord Shiva. It is excellent for spiritual practices, worship, meditation, and sacred ceremonies. Material activities also benefit from the grace of this benevolent yoga."
        ),
        21: YogaInfo(
            name: "Siddha",
            meaning: "Accomplished / Perfected",
            quality: "Auspicious",
            description: "Siddha yoga, like Siddhi, brings accomplishment and success. It is particularly favorable for spiritual practices, where it helps the practitioner reach higher states. Worldly activities also find success and completion under this yoga."
        ),
        22: YogaInfo(
            name: "Sadhya",
            meaning: "Achievable / Accomplishable",
            quality: "Auspicious",
            description: "Sadhya yoga makes goals achievable and tasks accomplishable. What is attempted during this yoga is more likely to succeed. Favorable for all positive undertakings, especially those that have been planned and prepared for."
        ),
        23: YogaInfo(
            name: "Shubha",
            meaning: "Auspicious / Good",
            quality: "Auspicious",
            description: "Shubha yoga is inherently auspicious, its very name meaning 'good.' It blesses all activities with positive energy. Especially favorable for marriages, religious ceremonies, beginning education, and forming new partnerships."
        ),
        24: YogaInfo(
            name: "Shukla",
            meaning: "Bright / White / Pure",
            quality: "Auspicious",
            description: "Shukla yoga brings brightness, purity, and clarity. It supports activities requiring clear thinking, honest dealings, and pure intentions. Favorable for spiritual purification, education, and any endeavor that benefits from clarity and transparency."
        ),
        25: YogaInfo(
            name: "Brahma",
            meaning: "Creator / Supreme",
            quality: "Auspicious",
            description: "Brahma yoga carries the creative energy of Brahma, the supreme creator. It is excellent for initiating creative projects, laying foundations, beginning studies of sacred texts, and any activity involving creation and innovation. One of the most favored yogas."
        ),
        26: YogaInfo(
            name: "Indra",
            meaning: "King of Gods / Mighty",
            quality: "Auspicious",
            description: "Indra yoga carries the royal power of the king of the devas. It supports leadership, authority, grand undertakings, and activities requiring strength and command. Favorable for government work, assuming positions of power, and celebrations."
        ),
        27: YogaInfo(
            name: "Vaidhriti",
            meaning: "Great Support / Sustaining",
            quality: "Inauspicious",
            description: "Vaidhriti is the last of the 27 yogas and is considered inauspicious, similar to Vyatipata. It can bring instability and unexpected challenges. Avoid major undertakings and travel. Like Vyatipata, it is considered appropriate for ancestral rites in some traditions."
        )
    ]

    // MARK: - Karanas (11 Types — 4 Fixed + 7 Movable)

    static let karanas: [String: KaranaInfo] = [
        // Fixed Karanas (Sthira Karana) — each occurs only once in a lunar month
        "Shakuni": KaranaInfo(
            name: "Shakuni",
            type: "Fixed",
            description: "Shakuni Karana is a fixed karana that occurs only once in a lunar month, during the second half of Krishna Chaturdashi. Named after the bird (shakuni means 'bird'), it is associated with omens and divination. It supports activities related to prediction and resolving disputes.",
            suitability: "Favorable for preparing medicines and remedies, resolving legal disputes, interpreting omens, and activities requiring keen observation. Avoid starting new ventures."
        ),
        "Chatushpada": KaranaInfo(
            name: "Chatushpada",
            type: "Fixed",
            description: "Chatushpada Karana is a fixed karana occurring in the first half of Amavasya. Its name means 'four-footed,' connecting it to animal husbandry and stable foundations. It carries grounding and stabilizing energy.",
            suitability: "Favorable for activities related to animals and livestock, agriculture, building stable foundations, and activities requiring patience. Coronation and assuming power may also be supported."
        ),
        "Naga": KaranaInfo(
            name: "Naga",
            type: "Fixed",
            description: "Naga Karana is a fixed karana occurring in the second half of Amavasya. Named after the serpent deities (Nagas), it carries mysterious and potentially dangerous energy. It is connected to the underworld and hidden forces.",
            suitability: "Favorable for activities that are permanent and irreversible in nature, dealing with underground resources, serpent worship, and kundalini practices. Generally inauspicious for starting new worldly activities."
        ),
        "Kimstughna": KaranaInfo(
            name: "Kimstughna",
            type: "Fixed",
            description: "Kimstughna Karana is a fixed karana occurring in the first half of Shukla Pratipada. Its name means 'what can harm?' — implying a protective quality. It is the most benign of the four fixed karanas.",
            suitability: "Favorable for auspicious ceremonies, charitable acts, spiritual practices, and activities that benefit from divine protection. Generally good for positive activities as the name suggests nothing can cause harm."
        ),
        // Movable Karanas (Chara Karana) — cycle repeatedly through the lunar month
        "Bava": KaranaInfo(
            name: "Bava",
            type: "Movable",
            description: "Bava (also called Baba) is the first movable karana, ruled by Vishnu. It is also known as Simha (Lion) karana and carries assertive, noble energy. It repeats seven times in each lunar month.",
            suitability: "Favorable for government work and official duties, auspicious ceremonies, permanent and lasting activities, agricultural work, and activities requiring authority and dignity."
        ),
        "Balava": KaranaInfo(
            name: "Balava",
            type: "Movable",
            description: "Balava is the second movable karana, associated with strength and spiritual merit. Also known as Puli (Leopard) karana, it carries energetic and spiritual energy suitable for religious and virtuous activities.",
            suitability: "Favorable for religious ceremonies and spiritual practices, charitable donations, educational pursuits, activities benefiting from strength and determination, and healing practices."
        ),
        "Kaulava": KaranaInfo(
            name: "Kaulava",
            type: "Movable",
            description: "Kaulava is the third movable karana, associated with friendship, relationships, and social harmony. Also known as Mushika (Mouse) karana, it carries gentle social energy favorable for building connections.",
            suitability: "Favorable for forming friendships and alliances, romantic relationships and marriage, social gatherings and celebrations, reconciliation and peace-making, and community activities."
        ),
        "Taitila": KaranaInfo(
            name: "Taitila",
            type: "Movable",
            description: "Taitila is the fourth movable karana, associated with material prosperity and comfort. Also known as Gardabha (Donkey) karana, it carries industrious energy suitable for wealth-building activities.",
            suitability: "Favorable for financial activities and investments, decorating and beautifying spaces, purchasing luxury items, building and construction work, and activities focused on material comfort and prosperity."
        ),
        "Gara": KaranaInfo(
            name: "Gara",
            type: "Movable",
            description: "Gara is the fifth movable karana, associated with agriculture, cultivation, and domestic activities. Also known as Gaja (Elephant) karana, it carries nurturing and productive energy related to the earth.",
            suitability: "Favorable for agriculture, planting, and harvesting, domestic activities and home improvement, purchasing property and land, activities related to food and nourishment, and starting sustained long-term projects."
        ),
        "Vanija": KaranaInfo(
            name: "Vanija",
            type: "Movable",
            description: "Vanija (also spelled Vanij) is the sixth movable karana, directly named after commerce and trade. Also known as Kharasva karana, it is the most favorable karana for all commercial and business activities.",
            suitability: "Favorable for buying and selling, trade and commerce, business negotiations and deals, marketplace activities, financial transactions, and starting commercial ventures."
        ),
        "Vishti": KaranaInfo(
            name: "Vishti",
            type: "Movable",
            description: "Vishti, also called Bhadra, is the seventh movable karana and is considered the most inauspicious of all karanas. It is ruled by the fierce energy of Saturn and is generally avoided for all positive activities. Bhadra periods are carefully tracked in Hindu almanacs.",
            suitability: "Generally inauspicious for all positive activities. Avoid marriages, new ventures, travel, and important decisions. However, it may support fierce or destructive activities such as fighting enemies, administering harsh medicines, and activities requiring ruthless determination."
        )
    ]

    // MARK: - Varas (7 Weekdays)

    static let varas: [String: VaraInfo] = [
        "Sunday": VaraInfo(
            weekday: "Sunday (Ravivara)",
            deity: "Surya (Sun God)",
            planet: "Sun (Ravi/Surya)",
            description: "Ravivara (Sunday) is ruled by Surya, the Sun God who represents the soul (Atman), authority, vitality, and divine light. In Hindu tradition, Surya is worshipped as a visible form of the divine. Sunday carries solar energy of leadership, health, and spiritual illumination.",
            auspiciousActivities: [
                "Surya puja and Surya Namaskar",
                "Government and administrative work",
                "Meeting people of authority",
                "Starting medical treatments",
                "Wearing new clothes",
                "Initiating leadership roles"
            ],
            associatedColor: "Red / Copper"
        ),
        "Monday": VaraInfo(
            weekday: "Monday (Somavara)",
            deity: "Chandra / Shiva",
            planet: "Moon (Soma/Chandra)",
            description: "Somavara (Monday) is ruled by Chandra (Moon) and is deeply sacred to Lord Shiva. The name Somavara derives from Soma, the divine nectar associated with the Moon. Monday is the most popular day for Shiva worship, and Shravan Somavar is especially auspicious.",
            auspiciousActivities: [
                "Shiva puja and worship",
                "Fasting (Somavar Vrata)",
                "Agriculture and planting",
                "Travel, especially by water",
                "Purchasing silver and white items",
                "Creative and artistic activities"
            ],
            associatedColor: "White / Silver"
        ),
        "Tuesday": VaraInfo(
            weekday: "Tuesday (Mangalavara)",
            deity: "Hanuman / Mangala (Mars)",
            planet: "Mars (Mangala/Kuja)",
            description: "Mangalavara (Tuesday) is ruled by Mangala (Mars), the planet of energy, courage, and martial power. It is sacred to Lord Hanuman, the embodiment of devotion, strength, and selfless service. Hanuman Puja on Tuesdays is widely practiced across India.",
            auspiciousActivities: [
                "Hanuman puja and worship",
                "Reading Hanuman Chalisa",
                "Physical exercise and martial arts",
                "Real estate and property matters",
                "Surgical procedures",
                "Activities requiring courage and strength"
            ],
            associatedColor: "Red / Orange"
        ),
        "Wednesday": VaraInfo(
            weekday: "Wednesday (Budhavara)",
            deity: "Vishnu / Budha (Mercury)",
            planet: "Mercury (Budha)",
            description: "Budhavara (Wednesday) is ruled by Budha (Mercury), the planet of intellect, communication, and commerce. It is associated with Lord Vishnu in many traditions. Wednesday supports mental acuity, learning, and all forms of communication and trade.",
            auspiciousActivities: [
                "Education and learning",
                "Business and trade activities",
                "Writing and communication",
                "Accounting and financial planning",
                "Starting new courses of study",
                "Intellectual and analytical work"
            ],
            associatedColor: "Green"
        ),
        "Thursday": VaraInfo(
            weekday: "Thursday (Guruvara / Brihaspativara)",
            deity: "Brihaspati (Jupiter) / Vishnu / Sai Baba",
            planet: "Jupiter (Brihaspati/Guru)",
            description: "Guruvara (Thursday) is ruled by Brihaspati (Jupiter), the Guru of the Devas and the planet of wisdom, expansion, and divine grace. Thursday is sacred to spiritual teachers and is widely observed for Sai Baba worship. It is considered the most auspicious day for beginning education.",
            auspiciousActivities: [
                "Worship of Guru/Brihaspati",
                "Starting education and spiritual studies",
                "Marriage and engagement",
                "Visiting temples and holy places",
                "Charitable donations and acts of generosity",
                "Legal matters and seeking justice"
            ],
            associatedColor: "Yellow / Gold"
        ),
        "Friday": VaraInfo(
            weekday: "Friday (Shukravara)",
            deity: "Lakshmi / Shukra (Venus) / Santoshi Maa",
            planet: "Venus (Shukra)",
            description: "Shukravara (Friday) is ruled by Shukra (Venus), the Guru of the Asuras and the planet of love, beauty, luxury, and wealth. Friday is sacred to Goddess Lakshmi and Santoshi Maa. It is the most auspicious day for worship of the divine feminine in her benevolent forms.",
            auspiciousActivities: [
                "Lakshmi puja and worship",
                "Santoshi Maa vrata",
                "Purchasing jewelry, clothes, and vehicles",
                "Marriage and romantic activities",
                "Music, dance, and artistic pursuits",
                "Beauty treatments and self-care"
            ],
            associatedColor: "White / Pink"
        ),
        "Saturday": VaraInfo(
            weekday: "Saturday (Shanivara)",
            deity: "Shani (Saturn) / Hanuman / Yama",
            planet: "Saturn (Shani)",
            description: "Shanivara (Saturday) is ruled by Shani (Saturn), the planet of karma, discipline, justice, and hard-earned rewards. Shani is both feared and revered as the great teacher who delivers karmic consequences. Saturday is observed with Shani puja, oil offerings, and charity to mitigate Saturn's harsh lessons.",
            auspiciousActivities: [
                "Shani puja and worship",
                "Offering sesame oil and black items",
                "Charity to the poor and disabled",
                "Iron and steel-related work",
                "Discipline and austerity practices",
                "Resolving karmic debts"
            ],
            associatedColor: "Black / Dark Blue"
        )
    ]

    // MARK: - Time Windows (Muhurtas and Kalas)

    static let timeWindows: [String: TimeWindowInfo] = [
        "brahmaMuhurta": TimeWindowInfo(
            name: "Brahma Muhurta",
            meaning: "The Creator's Moment",
            origin: "Described in the Dharma Shastras and Ayurvedic texts, Brahma Muhurta occurs approximately 1 hour 36 minutes before sunrise (the last two muhurtas of the night, each muhurta being 48 minutes). It is referenced in the Ashtanga Hridaya of Vagbhata and numerous Vedic texts as the ideal time for spiritual practice.",
            recommendation: "Wake during Brahma Muhurta for meditation, prayer, study of sacred texts, and yoga. The atmosphere is sattvic (pure), the mind is fresh, and cosmic energy supports spiritual awakening. Ayurveda recommends rising at this time for optimal health. This is considered the most sacred time of day.",
            description: "Brahma Muhurta is the most spiritually charged period of the day, occurring roughly 96 to 48 minutes before sunrise. The name means 'the moment of Brahma (the Creator).' During this time, the veil between the physical and spiritual worlds is thinnest, prana (life force) is abundant in the atmosphere, and the mind naturally tends toward clarity and peace."
        ),
        "abhijitMuhurta": TimeWindowInfo(
            name: "Abhijit Muhurta",
            meaning: "The Victorious Moment",
            origin: "Abhijit Muhurta is described in Muhurta Shastra (the science of auspicious timing) as the most powerful muhurta of the daytime. It occurs around solar noon — specifically the 8th muhurta of the day when the day is divided into 15 equal parts. Lord Vishnu is said to preside over this period.",
            recommendation: "Use Abhijit Muhurta for starting any important venture, making crucial decisions, beginning journeys, or performing sacred rituals. Its victorious energy overrides many other doshas (defects) in the panchang. Even if other elements are unfavorable, Abhijit Muhurta can make the time auspicious.",
            description: "Abhijit Muhurta is a universally auspicious window occurring around midday (approximately 24 minutes before to 24 minutes after solar noon). The name means 'unconquered' or 'victorious.' It is so powerful that it is believed to neutralize other inauspicious factors in the panchang. Lord Rama is said to have been born during Abhijit Muhurta."
        ),
        "rahuKalam": TimeWindowInfo(
            name: "Rahu Kalam",
            meaning: "Period of Rahu",
            origin: "Rahu Kalam is derived from Vedic astrology's understanding of Rahu, the north lunar node (ascending node of the Moon). Rahu is a shadow planet (chhaya graha) that causes eclipses when he swallows the Sun or Moon. The mythology originates from the Samudra Manthan (churning of the ocean), where the asura Svarbhanu was beheaded by Vishnu's Sudarshana Chakra after drinking amrit, becoming Rahu (head) and Ketu (body).",
            recommendation: "Avoid starting new ventures, important meetings, travel, financial transactions, and auspicious ceremonies during Rahu Kalam. It is especially avoided in South Indian traditions. However, worship of Durga, Rahu, or performing remedial measures for Rahu dosha may be performed during this time.",
            description: "Rahu Kalam is an inauspicious period that occurs daily for approximately 90 minutes. The timing varies by weekday. Rahu's shadow energy can create confusion, deception, and unexpected obstacles. South Indian Hindus are particularly attentive to Rahu Kalam and avoid all important activities during this window."
        ),
        "gulikaKalam": TimeWindowInfo(
            name: "Gulika Kalam",
            meaning: "Period of Gulika (Son of Saturn)",
            origin: "Gulika (also called Mandi) is considered a sub-planet or upagraha, regarded as the son of Shani (Saturn). In Vedic astrology, Gulika is an invisible mathematical point that carries malefic energy. The concept originates from classical Jyotish texts like Brihat Parashara Hora Shastra, which describe Gulika as one of the most significant upagrahas for determining inauspicious periods.",
            recommendation: "Avoid starting new activities, signing contracts, making important purchases, and initiating travel during Gulika Kalam. It is particularly inauspicious for beginning medical treatments or surgical procedures. As with Rahu Kalam, this period is best used for routine work, spiritual practice, or remedial worship.",
            description: "Gulika Kalam is an inauspicious daily period of approximately 90 minutes, ruled by Gulika (Mandi), the offspring of Saturn. Like Rahu Kalam, its timing varies by weekday. The malefic influence of Saturn's son can cause delays, health issues, and unfavorable outcomes for activities initiated during this window."
        ),
        "yamaganda": TimeWindowInfo(
            name: "Yamaganda",
            meaning: "Period of Yama's Block",
            origin: "Yamaganda (also called Yama Ghantaka) derives from Yama, the god of death and dharma, combined with 'ghantaka' (deadly/obstructive). It represents a period ruled by Yama's restrictive and mortal energy. Classical Jyotish texts identify this as one of three daily inauspicious periods (along with Rahu Kalam and Gulika Kalam) that must be avoided for important activities.",
            recommendation: "Avoid all important new beginnings during Yamaganda, especially those related to health, longevity, and life-changing decisions. Travel is strongly discouraged. This period carries the energy of mortality and restriction. It is best used for quiet reflection, completion of routine tasks, or prayers to Yama Dharmaraja.",
            description: "Yamaganda is an inauspicious daily period of approximately 90 minutes, associated with Yama, the lord of death and righteousness. It is the third of the three major inauspicious time windows tracked in the Hindu panchang. Activities begun during Yamaganda may face serious obstacles, delays, or harmful consequences. Its timing, like Rahu Kalam and Gulika Kalam, rotates through the weekdays."
        )
    ]

    // MARK: - Lookup Helpers

    /// Returns TithiInfo for the given tithi name, trying common variations.
    static func tithiInfo(for name: String) -> TithiInfo? {
        if let info = tithis[name] { return info }
        // Try matching by removing "Shukla"/"Krishna" prefix
        let trimmed = name
            .replacingOccurrences(of: "Shukla ", with: "")
            .replacingOccurrences(of: "Krishna ", with: "")
        return tithis[trimmed]
    }

    /// Returns NakshatraInfo for the given nakshatra name.
    static func nakshatraInfo(for name: String) -> NakshatraInfo? {
        if let info = nakshatras[name] { return info }
        // Try partial match for alternate spellings
        return nakshatras.values.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Returns YogaInfo for the given yoga number (1-27).
    static func yogaInfo(for number: Int) -> YogaInfo? {
        return yogas[number]
    }

    /// Returns YogaInfo by name.
    static func yogaInfo(forName name: String) -> YogaInfo? {
        return yogas.values.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Returns KaranaInfo for the given karana name.
    static func karanaInfo(for name: String) -> KaranaInfo? {
        if let info = karanas[name] { return info }
        return karanas.values.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Returns VaraInfo for the given weekday name (e.g., "Sunday", "Monday").
    static func varaInfo(for weekday: String) -> VaraInfo? {
        return varas[weekday]
    }

    /// Returns TimeWindowInfo for the given window type key.
    static func timeWindowInfo(for key: String) -> TimeWindowInfo? {
        return timeWindows[key]
    }

    // MARK: - Eclipse (Grahan)

    static let eclipseInfo = EclipseInfo(
        description: "An eclipse (Grahan) is one of the most significant astronomical and spiritual events in the Hindu calendar. A lunar eclipse (Chandra Grahan) occurs when the Earth passes between the Sun and Moon, casting its shadow on the Moon. A solar eclipse (Surya Grahan) occurs when the Moon passes between the Earth and Sun, blocking its light. In Vedic tradition, eclipses are deeply sacred periods of intensified spiritual energy, when the normal flow of cosmic light is disrupted and the veil between worlds grows thin.",

        mythology: "The origin of eclipses traces to the Samudra Manthan (Churning of the Cosmic Ocean). When the Devas and Asuras churned the ocean to obtain Amrit (the nectar of immortality), Lord Vishnu took the form of Mohini to distribute the nectar only to the Devas. The Asura Svarbhanu disguised himself among the Devas and received a sip. Surya (Sun) and Chandra (Moon) recognized him and alerted Vishnu, who severed Svarbhanu's head with the Sudarshana Chakra. Having tasted Amrit, both halves survived — the head became Rahu and the body became Ketu. In revenge, Rahu periodically swallows the Sun and Moon, causing eclipses. Because he has no body, the luminaries pass through him and emerge again.",

        spiritualSignificance: "Eclipses are considered extraordinarily powerful periods for spiritual practice. The merit of mantra japa (chanting) performed during an eclipse is believed to be multiplied a thousandfold. Fasting during an eclipse purifies the body and mind. The Sutak period (inauspicious window before and during the eclipse) is observed by avoiding food preparation, eating, and beginning new activities. After the eclipse, a purifying bath and charity are recommended. Temples close their doors during the eclipse and reopen with fresh consecration afterward.",

        dosAndDonts: (
            doItems: [
                "Chant mantras — especially Maha Mrityunjaya, Gayatri, or Rahu mantra",
                "Meditate and perform japa (repetitive chanting)",
                "Fast during the Sutak period (begins 9 hours before lunar, 12 hours before solar eclipse)",
                "Take a purifying bath after the eclipse ends",
                "Donate food, clothing, or money to the needy after the eclipse",
                "Sprinkle Ganga jal (holy water) or tulsi leaves in stored food",
                "Pregnant women should rest and chant protective mantras"
            ],
            dontItems: [
                "Do not eat or cook during the Sutak period",
                "Do not begin new ventures, travel, or sign contracts",
                "Do not look directly at a solar eclipse without proper eye protection",
                "Do not sleep during the eclipse — remain awake for spiritual practice",
                "Do not use sharp objects (knives, needles) during the eclipse",
                "Avoid intimate relations during the Sutak period",
                "Do not keep leftover cooked food from before the eclipse"
            ]
        ),

        mantras: [
            (
                devanagari: "ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्",
                transliteration: "Om Bhur Bhuvah Svah Tat Savitur Varenyam Bhargo Devasya Dhimahi Dhiyo Yo Nah Prachodayat",
                purpose: "Gayatri Mantra — supreme prayer for divine light and wisdom"
            ),
            (
                devanagari: "ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् उर्वारुकमिव बन्धनान् मृत्योर्मुक्षीय मामृतात्",
                transliteration: "Om Tryambakam Yajamahe Sugandhim Pushti-Vardhanam Urvarukamiva Bandhanan Mrityor Mukshiya Maamritat",
                purpose: "Maha Mrityunjaya Mantra — protection and liberation from death"
            ),
            (
                devanagari: "ॐ रां राहवे नमः",
                transliteration: "Om Raam Rahave Namah",
                purpose: "Rahu Beej Mantra — pacifies Rahu's malefic influence during lunar eclipses"
            ),
            (
                devanagari: "ॐ कें केतवे नमः",
                transliteration: "Om Kem Ketave Namah",
                purpose: "Ketu Beej Mantra — pacifies Ketu's influence during solar eclipses"
            )
        ]
    )
}

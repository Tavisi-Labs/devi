// MARK: - Models/PanchangElement.swift
// Enum for tappable panchang element routing to detail sheets

import Foundation

enum PanchangElement: Identifiable {
    case tithi(Tithi)
    case nakshatra(Nakshatra)
    case yoga(Yoga)
    case karana([Karana])       // All karanas for the day (2-3 with transition times)
    case vara(String)           // varaDeity string e.g. "Surya (Sun)"
    case timeWindow(TimeWindow)
    case eclipse(EclipseEvent)
    case festival(String)           // Festival name → FestivalInfo lookup
    case fastingDay(String)         // "Ekadashi", "Amavasya", etc. → FastingDayInfo lookup
    case navratriDay(NavratriDay)   // Rich goddess/mantra data
    case hora(Hora)                  // Planetary hour detail
    case choghadiya(Choghadiya)      // Choghadiya period detail
    case mantra(DailyMantra)         // Daily weekday mantra detail
    case vedicSky                    // Full-screen ecliptic strip (Tier 1)
    case graha(Graha, Double)        // Individual graha detail (Tier 2) — graha + longitude

    var id: String {
        switch self {
        case .tithi(let t): return "tithi-\(t.name)"
        case .nakshatra(let n): return "nakshatra-\(n.name)"
        case .yoga(let y): return "yoga-\(y.name)"
        case .karana(let ks): return "karana-\(ks.first?.name ?? "")"
        case .vara(let v): return "vara-\(v)"
        case .timeWindow(let tw): return "timeWindow-\(tw.type.rawValue)"
        case .eclipse(let e): return "eclipse-\(e.id)"
        case .festival(let name): return "festival-\(name)"
        case .fastingDay(let name): return "fasting-\(name)"
        case .navratriDay(let day): return "navratri-\(day.dayNumber)"
        case .hora(let h): return "hora-\(h.sequenceIndex)"
        case .choghadiya(let c): return "choghadiya-\(c.sequenceIndex)"
        case .mantra(let m): return "mantra-\(m.weekday)"
        case .vedicSky: return "vedicSky"
        case .graha(let g, _): return "graha-\(g.rawValue)"
        }
    }

    var displayName: String {
        switch self {
        case .tithi(let t): return t.name
        case .nakshatra(let n): return n.name
        case .yoga(let y): return y.name
        case .karana(let ks): return ks.first?.name ?? ""
        case .vara(let v): return v.components(separatedBy: " (").first ?? v
        case .timeWindow(let tw): return tw.type.rawValue
        case .eclipse(let e): return e.displayName
        case .festival(let name): return name
        case .fastingDay(let name): return name
        case .navratriDay(let day): return day.goddessName
        case .hora(let h): return h.planetName
        case .choghadiya(let c): return c.name
        case .mantra(let m): return m.deity
        case .vedicSky: return "Vedic Sky"
        case .graha(let g, _): return g.rawValue
        }
    }

    var categoryLabel: String {
        switch self {
        case .tithi: return "TITHI"
        case .nakshatra: return "NAKSHATRA"
        case .yoga: return "YOGA"
        case .karana: return "KARANA"
        case .vara: return "VARA"
        case .timeWindow: return "TIME WINDOW"
        case .eclipse: return "GRAHAN"
        case .festival: return "UTSAV"
        case .fastingDay: return "VRATA"
        case .navratriDay: return "NAVRATRI"
        case .hora: return "HORA"
        case .choghadiya: return "CHOGHADIYA"
        case .mantra: return "MANTRA"
        case .vedicSky: return "VEDIC SKY"
        case .graha: return "GRAHA"
        }
    }
}

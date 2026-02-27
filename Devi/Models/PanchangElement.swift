// MARK: - Models/PanchangElement.swift
// Enum for tappable panchang element routing to detail sheets

import Foundation

enum PanchangElement: Identifiable {
    case tithi(Tithi)
    case nakshatra(Nakshatra)
    case yoga(Yoga)
    case karana(Karana)
    case vara(String)           // varaDeity string e.g. "Surya (Sun)"
    case timeWindow(TimeWindow)
    case eclipse(EclipseEvent)

    var id: String {
        switch self {
        case .tithi(let t): return "tithi-\(t.name)"
        case .nakshatra(let n): return "nakshatra-\(n.name)"
        case .yoga(let y): return "yoga-\(y.name)"
        case .karana(let k): return "karana-\(k.name)"
        case .vara(let v): return "vara-\(v)"
        case .timeWindow(let tw): return "timeWindow-\(tw.type.rawValue)"
        case .eclipse(let e): return "eclipse-\(e.id)"
        }
    }

    var displayName: String {
        switch self {
        case .tithi(let t): return t.name
        case .nakshatra(let n): return n.name
        case .yoga(let y): return y.name
        case .karana(let k): return k.name
        case .vara(let v): return v.components(separatedBy: " (").first ?? v
        case .timeWindow(let tw): return tw.type.rawValue
        case .eclipse(let e): return e.displayName
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
        }
    }
}

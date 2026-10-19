import SwiftUI

// Private, case-identifying display content — party names, cover blurbs, risk
// analysis, strategy and enforcement prose. Fetched at runtime from Supabase
// `brief_data` (key='fragments', `native` object), same pattern the web app uses
// via `window._fragTitles`. None of it lives in source: this file holds types and
// an empty container only.
//
// Everything degrades to neutral placeholders when the fetch fails (offline, RLS
// miss, or a new user with no row) — see `CaseFragment()` defaults and the
// `isEmpty` guards at the call sites. Never render a placeholder as if it were
// case content.

struct FragPair: Decodable, Hashable {
    let k: String
    let v: String
}

struct FragRisk: Decodable, Hashable {
    let t: String
    let d: String
    let c: String
    var color: Color { c == "danger" ? .briefDanger : .briefWarn }
}

struct FragProse: Decodable, Hashable {
    let t: String
    let s: String
}

struct FragCover: Decodable, Hashable {
    let l: String
    let r: String
}

struct CaseFragment: Decodable {
    var title: String = ""
    var sub: String = ""
    var cover: FragCover? = nil
    var stamp: FragCover? = nil
    var blurb: String = ""
    var meta: [FragPair] = []
    var risks: [FragRisk] = []
    var risksTitle: String = ""
    var strategy: [FragProse] = []
    var belt: String = ""
    var prose: [String: String] = [:]
    var claimed: [FragPair] = []   // Money tab rows: head, then what it covers

    init() {}

    // Every field is optional in the data: one case without a `belt` used to fail the whole
    // fragments row, and every case fell back to placeholder titles. Missing means empty.
    private enum CodingKeys: String, CodingKey {
        case title, sub, cover, stamp, blurb, meta, risks, risksTitle, strategy, belt, prose, claimed
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = (try? c.decodeIfPresent(String.self, forKey: .title)) ?? ""
        sub = (try? c.decodeIfPresent(String.self, forKey: .sub)) ?? ""
        cover = try? c.decodeIfPresent(FragCover.self, forKey: .cover)
        stamp = try? c.decodeIfPresent(FragCover.self, forKey: .stamp)
        blurb = (try? c.decodeIfPresent(String.self, forKey: .blurb)) ?? ""
        meta = (try? c.decodeIfPresent(LossyList<FragPair>.self, forKey: .meta))?.items ?? []
        risks = (try? c.decodeIfPresent(LossyList<FragRisk>.self, forKey: .risks))?.items ?? []
        risksTitle = (try? c.decodeIfPresent(String.self, forKey: .risksTitle)) ?? ""
        strategy = (try? c.decodeIfPresent(LossyList<FragProse>.self, forKey: .strategy))?.items ?? []
        belt = (try? c.decodeIfPresent(String.self, forKey: .belt)) ?? ""
        prose = (try? c.decodeIfPresent([String: String].self, forKey: .prose)) ?? [:]
        claimed = (try? c.decodeIfPresent(LossyList<FragPair>.self, forKey: .claimed))?.items ?? []
    }
}

/// A list that keeps the rows it can read and skips the rest, instead of failing whole.
struct LossyList<T: Decodable>: Decodable {
    let items: [T]
    private struct Skip: Decodable { init(from decoder: Decoder) throws {} }
    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        var out: [T] = []
        while !c.isAtEnd {
            if let v = try? c.decode(T.self) { out.append(v) } else { _ = try? c.decode(Skip.self) }
        }
        items = out
    }
}

@MainActor var caseFragments: [String: CaseFragment] = [:]

/// Fragment for a case, or an empty one if fragments haven't loaded.
@MainActor func frag(_ id: CaseID) -> CaseFragment {
    caseFragments[id.fragKey] ?? CaseFragment()
}

/// Only `native` is decoded here — the row also carries the web app's `hero`,
/// `main` and `titles` keys, which native doesn't use.
struct FragmentsValue: Decodable {
    let native: [String: CaseFragment]?
}

struct FragmentsValueRow: Decodable {
    let value: FragmentsValue
}

import SwiftUI

// MARK: - Types

struct Ground: Identifiable {
    let id: String
    let number: Int
    let title: String
    let section: String
    let value: String
    let accent: Color
    let description: String
    let citation: String
    var risk: String = ""
    var openByDefault: Bool = false
}

struct WitnessAnnotation: Identifiable {
    let id = UUID()
    let quote: String
    let note: String
}

struct Witness: Identifiable {
    let id = UUID()
    let initials: String
    let name: String
    let role: String
    let date: String
    let tags: [String]
    let statement: String
    let annotations: [WitnessAnnotation]
}

struct JournalEntry: Identifiable, Codable, Hashable {
    var id: String { date }
    let date: String
    var text: String
}

struct DocumentEntry: Identifiable, Codable, Hashable {
    var id: String { date + title }
    let date: String
    var title: String
    var text: String
}

struct ChecklistItem: Identifiable {
    let id: Int
    let label: String
    let priority: Priority
    enum Priority { case now, soon }
}

enum TagStyle { case good, urgent, fail, neutral }

struct LawyerTag {
    let label: String
    let style: TagStyle
}

struct Lawyer: Identifiable {
    let id: String
    let initials: String
    let name: String
    let subtitle: String
    let tags: [LawyerTag]
    let phone: String?
    let phoneNote: String?
    let email: String?
    let website: String?
}

struct Scenario: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let amount: String
    let probability: Double
    let accentColor: Color
}

struct TimelineStep: Identifiable {
    let id = UUID()
    let when: String
    let title: String
    let description: String
    let dotStyle: DotStyle
    var due: String? = nil   // v10: ISO day, written next to `when` so any language can read it
    var rule: String? = nil  // the law the date was worked out from
    enum DotStyle { case now, warn, good, danger, neutral }
    /// The date in the reader's language when it is known, else `when` as written.
    var shown: String { due.flatMap(Day.date)?.formatted(date: .abbreviated, time: .omitted) ?? when }
}

struct DamageHead: Identifiable {
    let id = UUID()
    let head: String
    let range: String
    let note: String
    var low: Double = 0   // thousands of dollars, like the DTO
    var high: Double = 0
}

struct CaseComparable: Identifiable {
    let id = UUID()
    let label: String
    let year: String
    let award: String
    let note: String?
    var highlight: Bool = false
}

struct CaseFact: Identifiable {
    let id = UUID()
    let key: String
    let value: String
    var fullWidth: Bool = false
}

enum CaseID: String, CaseIterable, Identifiable {
    case rcmp   = "CASE-0001"
    case family = "CASE-0002"
    case muni   = "CASE-0003"
    case bylaw  = "CASE-0004"
    var id: String { rawValue }
    /// Stable non-identifying key into the runtime fragments map.
    var fragKey: String {
        switch self {
        case .rcmp:   return "rcmp"
        case .family: return "family"
        case .muni:   return "muni"
        case .bylaw:  return "bylaw"
        }
    }
    /// Party-name title. Private — comes from the user's fragments row, never
    /// source. Falls back to the case number so the UI stays neutral if unloaded.
    /// Window titles, tabs and pickers show the case number. Party names live on the cover only.
    var title: String { rawValue }
    @MainActor var subtitle: String { frag(self).sub }
}

// MARK: - Colors

extension Color {
    static let briefDanger = Color(red: 0.753, green: 0.224, blue: 0.169)
    static let briefWarn   = Color(red: 0.788, green: 0.486, blue: 0.165)
    static let briefGreen  = Color(red: 0.165, green: 0.616, blue: 0.435)
    static var briefAccent: Color { .brandSlate } // one accent: brand/BRAND.md
}

extension ShapeStyle where Self == Color {
    static var briefDanger: Color { Color(red: 0.753, green: 0.224, blue: 0.169) }
    static var briefWarn:   Color { Color(red: 0.788, green: 0.486, blue: 0.165) }
    static var briefGreen:  Color { Color(red: 0.165, green: 0.616, blue: 0.435) }
    static var briefAccent: Color { .brandSlate }
}

// MARK: - Data
//
// CASE-0001 content (grounds, witnesses, journal, lawyers, checklist, scripts) is
// fetched at runtime from the Supabase `brief_data` table (key='cases') — see
// Store.loadCaseData() and CaseDataMapper.swift. Nothing here is hardcoded; these
// are empty defaults populated after sign-in.

@MainActor var caseGrounds: [Ground] = []
@MainActor var caseFacts: [CaseFact] = []
/// The name typed when the brief was started (`TITLE` in the cases row). Shown when there is no cover from fragments.
@MainActor var briefTitle = ""

extension CaseID {
    /// The owner's own layout (fragments) carries four cases. Every other account has one brief, so no picker.
    @MainActor static var shown: [CaseID] { caseFragments.isEmpty ? [.rcmp] : allCases }
    @MainActor var lawyers: [Lawyer] { switch self { case .rcmp: caseLawyers; case .family: familyCaseLawyers; case .muni: muniCaseLawyers; case .bylaw: bylawCaseLawyers } }
    @MainActor var timeline: [TimelineStep] { switch self { case .rcmp: caseTimeline; case .family: familyCaseTimeline; case .muni: muniCaseTimeline; case .bylaw: bylawCaseTimeline } }
    @MainActor var checklist: [ChecklistItem] { switch self { case .rcmp: caseChecklist; case .family: familyCaseChecklist; case .muni: muniCaseChecklist; case .bylaw: bylawCaseChecklist } }
}
@MainActor var caseWitnesses: [Witness] = []
@MainActor var journalSeed: [JournalEntry] = []
@MainActor var caseChecklist: [ChecklistItem] = []
@MainActor var caseLawyers: [Lawyer] = []
@MainActor var caseScenarios: [Scenario] = []
@MainActor var damageHeads: [DamageHead] = []
@MainActor var caseComparables: [CaseComparable] = []
@MainActor var caseTimeline: [TimelineStep] = []
@MainActor var callScript: String = ""
@MainActor var outreachEmail: String = ""

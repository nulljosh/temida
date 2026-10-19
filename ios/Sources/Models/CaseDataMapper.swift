import SwiftUI

// MARK: - Supabase brief_data:cases DTOs
//
// Decodes the compact JSON shapes used by web/script.js (the canonical reference
// implementation) and maps them into the existing native model types. No case
// content lives in source — it is fetched at runtime from the `brief_data` table
// (key='cases') and mapped here.

private struct GroundDTO: Decodable {
    let n: String
    let id: String
    let sec: String
    let val: String
    let cite: String
    let desc: String
    let high: Double?
    let risk: String?
    let grade: String
    let title: String
}

private struct LawyerTagDTO: Decodable {
    let c: String?
    let t: String
}

private struct LawyerContactDTO: Decodable {
    let href: String
    let kind: String
    let label: String
    let primary: Bool?
}

private struct LawyerDTO: Decodable {
    let id: String
    let fit: Int?
    let sub: String
    let `init`: String
    let name: String
    let tags: [LawyerTagDTO]
    let status: String?
    let contacts: [LawyerContactDTO]
}

private struct ScenarioDTO: Decodable {
    let name: String
    let desc: String
    let amt: String
    let pct: Double
    let color: String
}

private struct TimelineStepDTO: Decodable {
    let when: String
    let title: String
    let desc: String
    let state: String?
    let due: String?
    let rule: String?
}

private struct ChecklistItemDTO: Decodable {
    let i: String
    let lev: Int?
    let pri: String
    let done: Bool?
    let label: String
}

private struct DamageHeadDTO: Decodable {
    // Double, not Int: heads are in thousands of dollars, and a bylaw penalty is a
    // sub-$1k figure (e.g. 0.077). Int here silently failed to decode the bundle.
    let label: String
    let low: Double
    let high: Double
    let sub: String?
    let grade: String?
}

private struct JournalEntryDTO: Decodable {
    let date: String
    let text: String
}

private struct CaseFactDTO: Decodable {
    let key: String
    let value: String
    let fullWidth: Bool?

    // ponytail: tolerant on purpose. The web editor can leave a non-fact entry in a facts list;
    // a strict decoder used to drop the whole case over one stray row. Rows without key/value are
    // filtered out in toBundle().
    private enum CodingKeys: String, CodingKey { case key, value, fullWidth }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = (try? c.decode(String.self, forKey: .key)) ?? ""
        value = (try? c.decode(String.self, forKey: .value)) ?? ""
        fullWidth = try? c.decode(Bool.self, forKey: .fullWidth)
    }
}

private struct WitnessAnnotationDTO: Decodable {
    let quote: String
    let note: String
}

private struct WitnessDTO: Decodable {
    let initials: String
    let name: String
    let role: String
    let date: String
    let tags: [String]
    let statement: String
    let annotations: [WitnessAnnotationDTO]
}

private struct CaseComparableDTO: Decodable {
    let label: String
    let year: String
    let award: String
    let note: String?
    let highlight: Bool?
}

struct CaseDataDTO: Decodable {
    fileprivate let TITLE: String?
    fileprivate let FACTS: LossyList<CaseFactDTO>?
    fileprivate let GROUNDS: LossyList<GroundDTO>?
    fileprivate let LAWYERS: LossyList<LawyerDTO>?
    fileprivate let TIMELINE: LossyList<TimelineStepDTO>?
    fileprivate let CHECKLIST: LossyList<ChecklistItemDTO>?
    fileprivate let SCENARIOS: LossyList<ScenarioDTO>?
    fileprivate let WITNESSES: LossyList<WitnessDTO>?
    fileprivate let STACK_HEADS: LossyList<DamageHeadDTO>?
    fileprivate let COMPARABLES: LossyList<CaseComparableDTO>?
    fileprivate let JOURNAL_SEED: LossyList<JournalEntryDTO>?
    fileprivate let CALL_SCRIPT: String?
    fileprivate let OUTREACH_EMAIL: String?

    fileprivate let FAMILY_FACTS: LossyList<CaseFactDTO>?
    fileprivate let FAMILY_WITNESSES: LossyList<WitnessDTO>?
    fileprivate let FAMILY_GROUNDS: LossyList<GroundDTO>?
    fileprivate let FAMILY_LAWYERS: LossyList<LawyerDTO>?
    fileprivate let FAMILY_TIMELINE: LossyList<TimelineStepDTO>?
    fileprivate let FAMILY_CHECKLIST: LossyList<ChecklistItemDTO>?
    fileprivate let FAMILY_SCENARIOS: LossyList<ScenarioDTO>?
    fileprivate let FAMILY_STACK_HEADS: LossyList<DamageHeadDTO>?
    fileprivate let FAMILY_CALL_SCRIPT: String?

    fileprivate let MUNI_FACTS: LossyList<CaseFactDTO>?
    fileprivate let MUNI_WITNESSES: LossyList<WitnessDTO>?
    fileprivate let MUNI_GROUNDS: LossyList<GroundDTO>?
    fileprivate let MUNI_LAWYERS: LossyList<LawyerDTO>?
    fileprivate let MUNI_TIMELINE: LossyList<TimelineStepDTO>?
    fileprivate let MUNI_CHECKLIST: LossyList<ChecklistItemDTO>?
    fileprivate let MUNI_SCENARIOS: LossyList<ScenarioDTO>?
    fileprivate let MUNI_STACK_HEADS: LossyList<DamageHeadDTO>?
    fileprivate let MUNI_CALL_SCRIPT: String?

    fileprivate let BYLAW_FACTS: LossyList<CaseFactDTO>?
    fileprivate let BYLAW_WITNESSES: LossyList<WitnessDTO>?
    fileprivate let BYLAW_GROUNDS: LossyList<GroundDTO>?
    fileprivate let BYLAW_LAWYERS: LossyList<LawyerDTO>?
    fileprivate let BYLAW_TIMELINE: LossyList<TimelineStepDTO>?
    fileprivate let BYLAW_CHECKLIST: LossyList<ChecklistItemDTO>?
    fileprivate let BYLAW_SCENARIOS: LossyList<ScenarioDTO>?
    fileprivate let BYLAW_STACK_HEADS: LossyList<DamageHeadDTO>?
    fileprivate let BYLAW_CALL_SCRIPT: String?
}

// MARK: - Mapped output bundle

struct CaseDataBundle {
    var title = ""
    var facts: [CaseFact] = []
    var grounds: [Ground] = []
    var lawyers: [Lawyer] = []
    var timeline: [TimelineStep] = []
    var checklist: [ChecklistItem] = []
    var scenarios: [Scenario] = []
    var witnesses: [Witness] = []
    var familyWitnesses: [Witness] = []
    var muniWitnesses: [Witness] = []
    var bylawWitnesses: [Witness] = []
    var damageHeads: [DamageHead] = []
    var comparables: [CaseComparable] = []
    var journalSeed: [JournalEntry] = []
    var callScript: String = ""
    var outreachEmail: String = ""

    var familyFacts: [CaseFact] = []
    var familyGrounds: [Ground] = []
    var familyLawyers: [Lawyer] = []
    var familyTimeline: [TimelineStep] = []
    var familyChecklist: [ChecklistItem] = []
    var familyScenarios: [Scenario] = []
    var familyDamageHeads: [DamageHead] = []
    var familyCallScript: String = ""
    var familyOutreachEmail: String = ""

    var muniFacts: [CaseFact] = []
    var muniGrounds: [Ground] = []
    var muniLawyers: [Lawyer] = []
    var muniTimeline: [TimelineStep] = []
    var muniChecklist: [ChecklistItem] = []
    var muniScenarios: [Scenario] = []
    var muniDamageHeads: [DamageHead] = []
    var muniCallScript: String = ""

    var bylawFacts: [CaseFact] = []
    var bylawGrounds: [Ground] = []
    var bylawLawyers: [Lawyer] = []
    var bylawTimeline: [TimelineStep] = []
    var bylawChecklist: [ChecklistItem] = []
    var bylawScenarios: [Scenario] = []
    var bylawDamageHeads: [DamageHead] = []
    var bylawCallScript: String = ""
}

// MARK: - Visual override tables
//
// Opaque-id-keyed visual metadata (accent color, open-by-default). Not sensitive
// content — these ids ("s8", "s9", "likeness", "occ", etc.) are stable structural
// keys, not case facts.

private struct GroundVisual { let accent: Color; let openByDefault: Bool }

private let groundVisuals: [String: GroundVisual] = [
    "s8":          GroundVisual(accent: .briefDanger, openByDefault: true),
    "s9":          GroundVisual(accent: .briefDanger, openByDefault: false),
    "s7":          GroundVisual(accent: .briefDanger, openByDefault: false),
    "s10b":        GroundVisual(accent: .secondary,   openByDefault: false),
    "s12":         GroundVisual(accent: .briefWarn,   openByDefault: false),
    "battery":     GroundVisual(accent: .briefWarn,   openByDefault: false),
    "falseimp":    GroundVisual(accent: .briefWarn,   openByDefault: false),
    "neginv":      GroundVisual(accent: .secondary,   openByDefault: false),
    "likeness":    GroundVisual(accent: .briefDanger, openByDefault: true),
    "iims":        GroundVisual(accent: .briefDanger, openByDefault: false),
    "negligence":  GroundVisual(accent: .briefWarn,   openByDefault: false),
    "eviction":    GroundVisual(accent: .secondary,   openByDefault: false),
    "occ":         GroundVisual(accent: .briefDanger, openByDefault: true),
    "neg":         GroundVisual(accent: .briefWarn,   openByDefault: false),
    "notice":      GroundVisual(accent: .secondary,   openByDefault: false),
    "paid":        GroundVisual(accent: .briefDanger, openByDefault: true),
    "noflow":      GroundVisual(accent: .briefDanger, openByDefault: false),
    "noobstruct":  GroundVisual(accent: .briefWarn,   openByDefault: false),
    "window":      GroundVisual(accent: .briefWarn,   openByDefault: false),
]

private func visual(for id: String) -> GroundVisual {
    groundVisuals[id] ?? GroundVisual(accent: .secondary, openByDefault: false)
}

private func scenarioColor(_ raw: String) -> Color {
    let lower = raw.lowercased()
    if lower.contains("good") { return .briefGreen }
    if lower.contains("warn") { return .briefWarn }
    if lower.contains("danger") { return .briefDanger }
    return .secondary
}

private func timelineDotStyle(_ raw: String?) -> TimelineStep.DotStyle {
    switch raw ?? "" {
    case "now": return .now
    case "warn": return .warn
    case "good": return .good
    case "danger", "bad": return .danger
    default: return .neutral
    }
}

private func priority(_ raw: String) -> ChecklistItem.Priority {
    raw == "soon" ? .soon : .now
}

private func lawyerTagStyle(_ raw: String?) -> TagStyle {
    switch raw ?? "" {
    case "urgent": return .urgent
    case "good": return .good
    case "fail": return .fail
    default: return .neutral
    }
}

// Heads are denominated in thousands of dollars. Sub-$1k heads (bylaw penalties)
// render as plain dollars rather than a misleading "0.077k".
func formatRange(low: Double, high: Double) -> String {
    func fmt(_ v: Double) -> String {
        if v < 1 { return String(format: "%.0f", v * 1000) }
        if v < 1000 { return v == v.rounded() ? "\(Int(v))k" : String(format: "%.1fk", v) }
        return String(format: "%.2fM", v / 1000.0)
    }
    if low == high { return "$\(fmt(low))" }
    return "$\(fmt(low))–\(fmt(high))"
}

// MARK: - DTO -> model mapping

private extension GroundDTO {
    func toGround() -> Ground {
        let v = visual(for: id)
        return Ground(
            id: id,
            number: Int(n) ?? 0,
            title: title,
            section: sec,
            value: val,
            accent: v.accent,
            description: desc,
            citation: cite,
            risk: risk ?? "",
            openByDefault: v.openByDefault
        )
    }
}

private extension LawyerDTO {
    func toLawyer() -> Lawyer {
        var phone: String?
        var phoneNote: String?
        var email: String?
        var website: String?
        for c in contacts {
            switch c.kind {
            case "tel":
                phone = c.href.hasPrefix("tel:") ? String(c.href.dropFirst(4)) : c.href
                if c.primary != true { phoneNote = c.label }
            case "web":
                website = c.href
            case "email":
                email = c.href.hasPrefix("mailto:") ? String(c.href.dropFirst(7)) : c.href
            default:
                break
            }
        }
        return Lawyer(
            id: id,
            initials: `init`,
            name: name,
            subtitle: sub,
            tags: tags.map { LawyerTag(label: $0.t, style: lawyerTagStyle($0.c)) },
            phone: phone,
            phoneNote: phoneNote,
            email: email,
            website: website
        )
    }
}

private extension ScenarioDTO {
    func toScenario() -> Scenario {
        Scenario(name: name, description: desc, amount: amt, probability: pct / 100.0, accentColor: scenarioColor(color))
    }
}

private extension TimelineStepDTO {
    func toTimelineStep() -> TimelineStep {
        TimelineStep(when: when, title: title, description: desc, dotStyle: timelineDotStyle(state), due: due, rule: rule)
    }
}

private extension ChecklistItemDTO {
    func toChecklistItem() -> ChecklistItem {
        ChecklistItem(id: checklistIndex(for: i), label: label, priority: priority(pri))
    }
}

private extension DamageHeadDTO {
    func toDamageHead() -> DamageHead {
        DamageHead(head: label, range: formatRange(low: low, high: high), note: sub ?? "", low: low, high: high)
    }
}

private extension JournalEntryDTO {
    func toJournalEntry() -> JournalEntry {
        JournalEntry(date: date, text: text)
    }
}

private extension CaseFactDTO {
    func toCaseFact() -> CaseFact {
        CaseFact(key: key, value: value, fullWidth: fullWidth ?? false)
    }
}

private extension WitnessDTO {
    func toWitness() -> Witness {
        Witness(
            initials: initials,
            name: name,
            role: role,
            date: date,
            tags: tags,
            statement: statement,
            annotations: annotations.map { WitnessAnnotation(quote: $0.quote, note: $0.note) }
        )
    }
}

private extension CaseComparableDTO {
    func toCaseComparable() -> CaseComparable {
        CaseComparable(label: label, year: year, award: award, note: note, highlight: highlight ?? false)
    }
}

extension CaseDataDTO {
    func toBundle() -> CaseDataBundle {
        var b = CaseDataBundle()
        b.title = TITLE ?? ""

        b.facts = (FACTS?.items ?? []).filter { !$0.key.isEmpty }.map { $0.toCaseFact() }
        b.grounds = (GROUNDS?.items ?? []).map { $0.toGround() }
        b.lawyers = (LAWYERS?.items ?? []).map { $0.toLawyer() }
        b.timeline = (TIMELINE?.items ?? []).map { $0.toTimelineStep() }
        b.checklist = (CHECKLIST?.items ?? []).map { $0.toChecklistItem() }
        b.scenarios = (SCENARIOS?.items ?? []).map { $0.toScenario() }
        b.witnesses = (WITNESSES?.items ?? []).map { $0.toWitness() }
        b.familyWitnesses = (FAMILY_WITNESSES?.items ?? []).map { $0.toWitness() }
        b.muniWitnesses = (MUNI_WITNESSES?.items ?? []).map { $0.toWitness() }
        b.bylawWitnesses = (BYLAW_WITNESSES?.items ?? []).map { $0.toWitness() }
        b.damageHeads = (STACK_HEADS?.items ?? []).map { $0.toDamageHead() }
        b.comparables = (COMPARABLES?.items ?? []).map { $0.toCaseComparable() }
        b.journalSeed = (JOURNAL_SEED?.items ?? []).map { $0.toJournalEntry() }
        b.callScript = CALL_SCRIPT ?? ""
        b.outreachEmail = OUTREACH_EMAIL ?? ""

        b.familyFacts = (FAMILY_FACTS?.items ?? []).filter { !$0.key.isEmpty }.map { $0.toCaseFact() }
        b.familyGrounds = (FAMILY_GROUNDS?.items ?? []).map { $0.toGround() }
        b.familyLawyers = (FAMILY_LAWYERS?.items ?? []).map { $0.toLawyer() }
        b.familyTimeline = (FAMILY_TIMELINE?.items ?? []).map { $0.toTimelineStep() }
        b.familyChecklist = (FAMILY_CHECKLIST?.items ?? []).map { $0.toChecklistItem() }
        b.familyScenarios = (FAMILY_SCENARIOS?.items ?? []).map { $0.toScenario() }
        b.familyDamageHeads = (FAMILY_STACK_HEADS?.items ?? []).map { $0.toDamageHead() }
        b.familyCallScript = FAMILY_CALL_SCRIPT ?? ""
        b.familyOutreachEmail = b.familyCallScript

        b.muniFacts = (MUNI_FACTS?.items ?? []).filter { !$0.key.isEmpty }.map { $0.toCaseFact() }
        b.muniGrounds = (MUNI_GROUNDS?.items ?? []).map { $0.toGround() }
        b.muniLawyers = (MUNI_LAWYERS?.items ?? []).map { $0.toLawyer() }
        b.muniTimeline = (MUNI_TIMELINE?.items ?? []).map { $0.toTimelineStep() }
        b.muniChecklist = (MUNI_CHECKLIST?.items ?? []).map { $0.toChecklistItem() }
        b.muniScenarios = (MUNI_SCENARIOS?.items ?? []).map { $0.toScenario() }
        b.muniDamageHeads = (MUNI_STACK_HEADS?.items ?? []).map { $0.toDamageHead() }
        b.muniCallScript = MUNI_CALL_SCRIPT ?? ""

        b.bylawFacts = (BYLAW_FACTS?.items ?? []).filter { !$0.key.isEmpty }.map { $0.toCaseFact() }
        b.bylawGrounds = (BYLAW_GROUNDS?.items ?? []).map { $0.toGround() }
        b.bylawLawyers = (BYLAW_LAWYERS?.items ?? []).map { $0.toLawyer() }
        b.bylawTimeline = (BYLAW_TIMELINE?.items ?? []).map { $0.toTimelineStep() }
        b.bylawChecklist = (BYLAW_CHECKLIST?.items ?? []).map { $0.toChecklistItem() }
        b.bylawScenarios = (BYLAW_SCENARIOS?.items ?? []).map { $0.toScenario() }
        b.bylawDamageHeads = (BYLAW_STACK_HEADS?.items ?? []).map { $0.toDamageHead() }
        b.bylawCallScript = BYLAW_CALL_SCRIPT ?? ""

        return b
    }
}
